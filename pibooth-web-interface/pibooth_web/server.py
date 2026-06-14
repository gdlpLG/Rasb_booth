# -*- coding: utf-8 -*-

"""Flask web server for the Pibooth web interface.

This module creates a Flask application with:
- A main page serving the control interface
- REST API endpoints for actions and status
- Static file serving for CSS/JS
"""

import os
import glob
import logging
import time
import subprocess

from flask import Flask, Response, jsonify, render_template, send_file, abort, request
from flask_socketio import SocketIO, emit

LOGGER = logging.getLogger("pibooth.web.server")

# Global SocketIO instance
_socketio = None

def _resolve_printer_name():
    """Resolve the printer name to use for printing.

    Tries in order:
    1. Pibooth config printer_name
    2. CUPS default printer
    3. First available CUPS printer
    Returns None if no printer is found.
    """
    # Try to get printer from Pibooth app config
    cfg_printer = "default"
    try:
        from pibooth_web import get_app
        app_inst = get_app()
        if app_inst:
            try:
                cfg_printer = app_inst.find_print_event_option("printer_name", "default")
            except Exception:
                try:
                    cfg_printer = app_inst.printer.name if hasattr(app_inst, 'printer') else "default"
                except Exception:
                    cfg_printer = "default"
    except Exception:
        pass

    if cfg_printer and cfg_printer != "default":
        return cfg_printer

    # Fall back to CUPS
    try:
        import subprocess
        # Try CUPS default
        result = subprocess.run(["lpstat", "-d"], capture_output=True, text=True, timeout=5)
        if result.returncode == 0 and ":" in result.stdout:
            default_name = result.stdout.strip().split(":")[-1].strip()
            if default_name and default_name != "no system default destination":
                return default_name

        # Fall back to first available printer
        result = subprocess.run(["lpstat", "-p"], capture_output=True, text=True, timeout=5)
        if result.returncode == 0 and result.stdout.strip():
            # Parse first line: "printer NAME is ..."
            first_line = result.stdout.strip().split("\n")[0]
            parts = first_line.split()
            if len(parts) >= 2:
                return parts[1]
    except Exception as exc:
        LOGGER.warning("Could not resolve printer: %s", exc)

    return None

def create_flask_app():
    """Create and configure the Flask application."""
    global _socketio
    
    template_dir = os.path.join(os.path.dirname(__file__), 'templates')
    static_dir = os.path.join(os.path.dirname(__file__), 'static')

    app = Flask(__name__,
                template_folder=template_dir,
                static_folder=static_dir)

    # Initialize SocketIO
    _socketio = SocketIO(app, cors_allowed_origins="*", async_mode='threading')

    # Disable Flask's default logging noise in production
    log = logging.getLogger('werkzeug')
    log.setLevel(logging.WARNING)

    # -----------------------------------------------------------------------
    # Web pages
    # -----------------------------------------------------------------------

    @app.route('/')
    def index():
        """Main control page."""
        return render_template('index.html')

    # -----------------------------------------------------------------------
    # REST API
    # -----------------------------------------------------------------------

    @app.route('/api/action/capture', methods=['POST'])
    def api_capture():
        """Trigger a capture (same as pressing the capture button)."""
        # Check if timer mode is requested
        use_timer = False
        if request.is_json:
            data = request.get_json()
            use_timer = data.get('use_timer', False)
        
        # Now trigger Pibooth's capture process
        from pibooth_web import post_capture_event
        ok = post_capture_event(use_timer=use_timer)
        return jsonify({"success": ok, "action": "capture", "use_timer": use_timer})

    @app.route('/api/action/print', methods=['POST'])
    def api_print():
        """Trigger a print (same as pressing the print button)."""
        from pibooth_web import post_print_event
        ok = post_print_event()
        return jsonify({"success": ok, "action": "print"})

    @app.route('/api/action/choose/left', methods=['POST'])
    def api_choose_left():
        """Choose the left option (fewer captures)."""
        from pibooth_web import post_choose_left_event
        ok = post_choose_left_event()
        return jsonify({"success": ok, "action": "choose_left"})

    @app.route('/api/action/choose/right', methods=['POST'])
    def api_choose_right():
        """Choose the right option (more captures)."""
        from pibooth_web import post_choose_right_event
        ok = post_choose_right_event()
        return jsonify({"success": ok, "action": "choose_right"})

    @app.route('/api/status', methods=['GET'])
    def api_status():
        """Return the current Pibooth state and info."""
        from pibooth_web import get_state, get_app, get_latest_picture
        app_inst = get_app()
        state = get_state()
        
        # Check camera connection status
        camera_connected = False
        if app_inst and hasattr(app_inst, 'camera') and app_inst.camera:
            try:
                if hasattr(app_inst.camera, 'is_connected'):
                    camera_connected = app_inst.camera.is_connected()
                else:
                    # Fallback: assume connected if camera object exists
                    camera_connected = True
            except Exception:
                camera_connected = False
        
        data = {
            "state": state,
            "ready": app_inst is not None,
            "camera_connected": camera_connected,
            "capture_choices": list(app_inst.capture_choices) if app_inst else [],
            "capture_nbr": app_inst.capture_nbr if app_inst else None,
            "count_taken": app_inst.count.taken if app_inst else 0,
            "count_printed": app_inst.count.printed if app_inst else 0,
            "has_picture": get_latest_picture() is not None,
        }
        return jsonify(data)

    @app.route('/api/pictures/latest', methods=['GET'])
    def api_latest_picture():
        """Serve the latest generated picture."""
        from pibooth_web import get_latest_picture
        path = get_latest_picture()
        if path and os.path.isfile(path):
            return send_file(path, mimetype='image/jpeg')
        abort(404)

    # -------------------------------------------------------------------
    # Preview streaming
    # -------------------------------------------------------------------

    @app.route('/api/preview/stream', methods=['GET'])
    def api_preview_stream():
        """Return a MJPEG stream of the current Pibooth preview."""
        from pibooth_web import _preview_frame, _preview_frame_lock

        def generate():
            while True:
                # Import fresh reference each iteration
                import pibooth_web
                with pibooth_web._preview_frame_lock:
                    frame = pibooth_web._preview_frame
                if frame:
                    yield (b'--frame\r\n'
                           b'Content-Type: image/jpeg\r\n\r\n'
                           + frame + b'\r\n')
                else:
                    # No frame available, send a small delay
                    time.sleep(0.1)
                    continue
                time.sleep(0.08)  # ~12 fps max

        return Response(generate(),
                        mimetype='multipart/x-mixed-replace; boundary=frame')

    @app.route('/api/preview/frame', methods=['GET'])
    def api_preview_frame():
        """Return the latest single preview frame as JPEG."""
        import pibooth_web
        with pibooth_web._preview_frame_lock:
            frame = pibooth_web._preview_frame
        if frame:
            return Response(frame, mimetype='image/jpeg')
        abort(404)

    # -------------------------------------------------------------------
    # Gallery
    # -------------------------------------------------------------------

    @app.route('/api/pictures/gallery', methods=['GET'])
    def api_gallery():
        """Return list of all pictures in the pibooth pictures directory."""
        from pibooth_web import get_picture_dirs
        pic_dirs = get_picture_dirs()

        pictures = []
        used_dir = ""
        for pic_dir in pic_dirs:
            if pic_dir and os.path.isdir(pic_dir):
                used_dir = pic_dir
                # Search for images in the top-level directory only (skip raw/ subfolder)
                for ext in ('*.jpg', '*.jpeg', '*.png', '*.JPG', '*.JPEG', '*.PNG'):
                    for filepath in glob.glob(os.path.join(pic_dir, ext)):
                        if os.path.isfile(filepath):
                            relpath = os.path.relpath(filepath, pic_dir)
                            mtime = os.path.getmtime(filepath)
                            pictures.append({
                                "filename": relpath.replace("\\", "/"),
                                "mtime": mtime,
                                "dir": pic_dir,
                            })

        # Sort by modification time, newest first
        pictures.sort(key=lambda x: x["mtime"], reverse=True)

        return jsonify({"pictures": pictures, "directory": used_dir})

    @app.route('/api/pictures/print/<path:filename>', methods=['POST'])
    def api_print_picture(filename):
        """Print a specific picture file from the gallery via CUPS."""
        from pibooth_web import get_picture_dirs
        pic_dirs = get_picture_dirs()

        if not pic_dirs:
            return jsonify({"success": False, "error": "No picture directory configured"}), 404

        # Find the file
        filepath = None
        for pic_dir in pic_dirs:
            if not pic_dir:
                continue
            candidate = os.path.normpath(os.path.join(pic_dir, filename))
            if not candidate.startswith(os.path.normpath(pic_dir)):
                continue
            if os.path.isfile(candidate):
                filepath = candidate
                break

        if not filepath:
            return jsonify({"success": False, "error": "File not found"}), 404

        # Print via IPP for Canon SELPHY
        try:
            printer_name = _resolve_printer_name()
            if not printer_name:
                return jsonify({"success": False, "error": "No printer available"}), 500

            LOGGER.info("Printing %s on %s", filepath, printer_name)

            import subprocess
            import tempfile
            
            # For Canon SELPHY printers, use ipptool to send JPEG directly
            # This avoids CUPS raster conversion which crashes on Raspberry Pi
            if "SELPHY" in printer_name.upper() or "CP" in printer_name.upper():
                # Create temporary IPP test file with proper line breaks
                with tempfile.NamedTemporaryFile(mode='w', suffix='.test', delete=False) as tf:
                    tf.write('{\n')
                    tf.write('    OPERATION Print-Job\n')
                    tf.write('    GROUP operation-attributes-tag\n')
                    tf.write('    ATTR charset attributes-charset utf-8\n')
                    tf.write('    ATTR language attributes-natural-language en\n')
                    tf.write('    ATTR uri printer-uri $uri\n')
                    tf.write('    ATTR name requesting-user-name $user\n')
                    tf.write('    ATTR mimeMediaType document-format image/jpeg\n')
                    tf.write('    FILE $filename\n')
                    tf.write('}\n')
                    test_file = tf.name
                
                try:
                    # Use ipptool to send JPEG directly to printer via IPP
                    LOGGER.info("Sending print job via ipptool to ipp://localhost:60000/ipp/print")
                    result = subprocess.run(
                        ["ipptool", "-f", filepath, "ipp://localhost:60000/ipp/print", test_file],
                        capture_output=True, text=True, timeout=30,
                    )
                    
                    # Log full output for debugging
                    LOGGER.info("ipptool return code: %d", result.returncode)
                    if result.stdout:
                        LOGGER.info("ipptool stdout: %s", result.stdout)
                    if result.stderr:
                        LOGGER.info("ipptool stderr: %s", result.stderr)
                    
                    # Clean up test file
                    os.unlink(test_file)
                    
                    # If ipptool returns 0, the print was successful
                    # (even if stdout is empty, which seems to be the case for SELPHY)
                    if result.returncode == 0:
                        LOGGER.info("Print job submitted via IPP successfully (return code 0)")
                        return jsonify({"success": True, 
                                      "job_info": "Sent via IPP",
                                      "printer": printer_name,
                                      "file": os.path.basename(filepath)})
                    else:
                        err = result.stderr.strip() or result.stdout.strip() or "Unknown error"
                        LOGGER.error("ipptool command failed with code %d: %s", result.returncode, err)
                        return jsonify({"success": False, "error": f"ipptool failed: {err}"}), 500
                        
                except Exception as e:
                    # Clean up test file on error
                    if os.path.exists(test_file):
                        os.unlink(test_file)
                    raise e
            else:
                # For non-SELPHY printers, use standard lp command
                result = subprocess.run(
                    ["lp", "-d", printer_name, "--", filepath],
                    capture_output=True, text=True, timeout=30,
                )
                if result.returncode != 0:
                    err = result.stderr.strip() or result.stdout.strip()
                    LOGGER.error("lp error: %s", err)
                    return jsonify({"success": False, "error": err}), 500

                job_info = result.stdout.strip()
                LOGGER.info("Print job submitted: %s", job_info)
                return jsonify({"success": True, "job_info": job_info,
                              "printer": printer_name,
                              "file": os.path.basename(filepath)})

        except Exception as exc:
            LOGGER.error("Print error: %s", exc, exc_info=True)
            return jsonify({"success": False, "error": str(exc)}), 500

    @app.route('/api/pictures/file/<path:filename>', methods=['GET'])
    def api_picture_file(filename):
        """Serve a specific picture file from the pibooth pictures directory."""
        from pibooth_web import get_picture_dirs
        pic_dirs = get_picture_dirs()

        if not pic_dirs:
            abort(404)

        # Try each configured directory
        for pic_dir in pic_dirs:
            if not pic_dir:
                continue
            filepath = os.path.normpath(os.path.join(pic_dir, filename))
            # Security: ensure the file is within pic_dir
            if not filepath.startswith(os.path.normpath(pic_dir)):
                continue
            if os.path.isfile(filepath):
                return send_file(filepath, mimetype='image/jpeg')

        abort(404)

    # -------------------------------------------------------------------
    # Templates management
    # -------------------------------------------------------------------
    
    @app.route('/templates')
    def templates_page():
        """Templates management page."""
        return render_template('templates.html')

    @app.route('/api/templates/list', methods=['GET'])
    def api_templates_list():
        """List all available templates."""
        templates_dir = os.path.expanduser('~/pibooth_templates')
        os.makedirs(templates_dir, exist_ok=True)
        
        # Get active template from config
        active_template = None
        try:
            config_path = os.path.expanduser('~/.config/pibooth/pibooth.cfg')
            if os.path.isfile(config_path):
                import configparser
                config = configparser.ConfigParser()
                config.read(config_path)
                if config.has_option('PICTURE', 'template'):
                    active_path = config.get('PICTURE', 'template')
                    active_template = os.path.basename(active_path) if active_path else None
        except Exception as e:
            LOGGER.warning("Could not read active template: %s", e)
        
        # List XML files
        templates = []
        for xml_file in glob.glob(os.path.join(templates_dir, '*.xml')):
            name = os.path.basename(xml_file)
            templates.append({
                'name': name,
                'path': xml_file,
                'active': name == active_template
            })
        
        return jsonify({'templates': templates, 'active': active_template})

    @app.route('/api/templates/upload', methods=['POST'])
    def api_templates_upload():
        """Upload a new template XML file."""
        if 'file' not in request.files:
            return jsonify({'success': False, 'error': 'No file provided'}), 400
        
        file = request.files['file']
        if not file.filename:
            return jsonify({'success': False, 'error': 'Empty filename'}), 400
        
        if not file.filename.endswith('.xml'):
            return jsonify({'success': False, 'error': 'Only XML files allowed'}), 400
        
        templates_dir = os.path.expanduser('~/pibooth_templates')
        os.makedirs(templates_dir, exist_ok=True)
        
        # Sanitize filename
        filename = os.path.basename(file.filename)
        filepath = os.path.join(templates_dir, filename)
        
        try:
            file.save(filepath)
            LOGGER.info("Template uploaded: %s", filepath)
            return jsonify({'success': True, 'filename': filename})
        except Exception as e:
            LOGGER.error("Upload error: %s", e)
            return jsonify({'success': False, 'error': str(e)}), 500

    @app.route('/api/templates/activate', methods=['POST'])
    def api_templates_activate():
        """Activate a template by updating pibooth.cfg."""
        data = request.get_json()
        if not data or 'name' not in data:
            return jsonify({'success': False, 'error': 'No template name provided'}), 400
        
        template_name = data['name']
        templates_dir = os.path.expanduser('~/pibooth_templates')
        template_path = os.path.join(templates_dir, template_name)
        
        if not os.path.isfile(template_path):
            return jsonify({'success': False, 'error': 'Template not found'}), 404
        
        try:
            config_path = os.path.expanduser('~/.config/pibooth/pibooth.cfg')
            import configparser
            config = configparser.ConfigParser()
            config.read(config_path)
            
            if not config.has_section('PICTURE'):
                config.add_section('PICTURE')
            
            config.set('PICTURE', 'template', template_path)
            
            with open(config_path, 'w') as f:
                config.write(f)
            
            LOGGER.info("Template activated: %s", template_path)
            return jsonify({'success': True, 'template': template_name})
        except Exception as e:
            LOGGER.error("Activation error: %s", e)
            return jsonify({'success': False, 'error': str(e)}), 500

    @app.route('/api/templates/delete', methods=['POST'])
    def api_templates_delete():
        """Delete a template file."""
        data = request.get_json()
        if not data or 'name' not in data:
            return jsonify({'success': False, 'error': 'No template name provided'}), 400
        
        template_name = data['name']
        templates_dir = os.path.expanduser('~/pibooth_templates')
        template_path = os.path.join(templates_dir, template_name)
        
        if not os.path.isfile(template_path):
            return jsonify({'success': False, 'error': 'Template not found'}), 404
        
        try:
            os.remove(template_path)
            LOGGER.info("Template deleted: %s", template_path)
            return jsonify({'success': True})
        except Exception as e:
            LOGGER.error("Delete error: %s", e)
            return jsonify({'success': False, 'error': str(e)}), 500

    return app

def emit_new_picture(filename):
    """Emit a SocketIO event when a new picture is ready.
    
    :param filename: path to the new picture file
    """
    global _socketio
    if _socketio:
        try:
            basename = os.path.basename(filename)
            LOGGER.info("Emitting new_picture event: %s", basename)
            _socketio.emit('new_picture', {'filename': basename})
        except Exception as exc:
            LOGGER.error("Error emitting new_picture event: %s", exc)

def run_server(flask_app, host, port):
    """Run the Flask+SocketIO server (blocking – meant to be called in a thread).

    :param flask_app: configured Flask application with SocketIO
    :param host: bind address
    :param port: bind port
    """
    global _socketio
    try:
        LOGGER.info("Starting Flask+SocketIO server on %s:%s", host, port)
        if _socketio:
            # Use SocketIO's run method which handles everything
            _socketio.run(flask_app, 
                         host=host, 
                         port=int(port), 
                         debug=False,
                         use_reloader=False,
                         allow_unsafe_werkzeug=True)
        else:
            # Fallback to regular Flask if SocketIO not initialized
            from werkzeug.serving import make_server
            srv = make_server(host, int(port), flask_app, threaded=True)
            srv.serve_forever()
    except OSError as exc:
        LOGGER.error("Failed to start web server on %s:%s – %s", host, port, exc)
    except Exception as exc:
        LOGGER.error("Web server error: %s", exc, exc_info=True)
