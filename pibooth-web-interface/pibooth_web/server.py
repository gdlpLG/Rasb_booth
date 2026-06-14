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

from flask import Flask, Response, jsonify, render_template, send_file, abort

LOGGER = logging.getLogger("pibooth.web.server")

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
    template_dir = os.path.join(os.path.dirname(__file__), 'templates')
    static_dir = os.path.join(os.path.dirname(__file__), 'static')

    app = Flask(__name__,
                template_folder=template_dir,
                static_folder=static_dir)

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
        from pibooth_web import post_capture_event
        ok = post_capture_event()
        return jsonify({"success": ok, "action": "capture"})

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
        data = {
            "state": state,
            "ready": app_inst is not None,
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

        # Print via CUPS
        try:
            printer_name = _resolve_printer_name()
            if not printer_name:
                return jsonify({"success": False, "error": "No printer available"}), 500

            LOGGER.info("Printing %s on %s", filepath, printer_name)

            # Use subprocess to send JPEG natively (avoids raster conversion
            # which crashes on Raspberry Pi with SELPHY printers).
            import subprocess
            result = subprocess.run(
                ["lp", "-d", printer_name, "-o", "raw", "--", filepath],
                capture_output=True, text=True, timeout=30,
            )
            if result.returncode != 0:
                err = result.stderr.strip() or result.stdout.strip()
                LOGGER.error("lp error: %s", err)
                return jsonify({"success": False, "error": err}), 500

            # Extract job id from lp output like "request id is Printer-42 (1 file(s))"
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

    return app

def run_server(flask_app, host, port):
    """Run the Flask server (blocking – meant to be called in a thread).

    Uses werkzeug.serving.make_server directly to avoid the Werkzeug 3.x
    production-mode guard that blocks ``app.run()`` outside of debug mode.

    :param flask_app: configured Flask application
    :param host: bind address
    :param port: bind port
    """
    try:
        from werkzeug.serving import make_server
        LOGGER.info("Starting Flask server on %s:%s", host, port)
        srv = make_server(host, int(port), flask_app, threaded=True)
        srv.serve_forever()
    except OSError as exc:
        LOGGER.error("Failed to start web server on %s:%s – %s", host, port, exc)
    except Exception as exc:
        LOGGER.error("Web server error: %s", exc, exc_info=True)
