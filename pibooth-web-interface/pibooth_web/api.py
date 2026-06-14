#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""Flask API for web-based remote control."""

import os
import glob
import subprocess
import pygame
from flask import Flask, render_template, jsonify, send_from_directory, send_file, abort, request
from flask_socketio import SocketIO, emit
from flask_cors import CORS

from pibooth.utils import LOGGER

# Custom event for button simulation
BUTTONDOWN = pygame.USEREVENT + 1

def _resolve_printer_name(pibooth_app=None):
    """Resolve the CUPS printer name to use."""
    # Try Pibooth config
    if pibooth_app:
        try:
            name = pibooth_app.printer.name if hasattr(pibooth_app, 'printer') else None
            if name and name != "default":
                return name
        except Exception:
            pass

    # Try CUPS default
    try:
        result = subprocess.run(["lpstat", "-d"], capture_output=True, text=True, timeout=5)
        if result.returncode == 0 and ":" in result.stdout:
            default_name = result.stdout.strip().split(":")[-1].strip()
            if default_name and "no system default" not in default_name:
                return default_name
    except Exception:
        pass

    # Try first available
    try:
        result = subprocess.run(["lpstat", "-p"], capture_output=True, text=True, timeout=5)
        if result.returncode == 0 and result.stdout.strip():
            parts = result.stdout.strip().split("\n")[0].split()
            if len(parts) >= 2:
                return parts[1]
    except Exception:
        pass

    return None

def _get_pictures_directory(pibooth_app):
    """Get the directory where pibooth stores pictures."""
    # Try savedir from config
    try:
        savedir = pibooth_app.savedir
        if savedir and os.path.isdir(savedir):
            return savedir
    except Exception:
        pass

    # Common default locations - prioritize Pictures/pibooth
    for candidate in [
        os.path.expanduser("~/Pictures/pibooth"),
        os.path.expanduser("~/.pibooth"),
        os.path.expanduser("~/pibooth"),
        "/tmp/pibooth",
    ]:
        if os.path.isdir(candidate):
            return candidate

    return None

class WebAPI:
    """Web API to control Pibooth remotely."""

    def __init__(self, app, cfg, host='0.0.0.0', port=3000):
        self.pibooth_app = app
        self.config = cfg
        self.host = host
        self.port = port
        self.current_state = 'wait'
        self.state_data = {}

        # Create Flask app
        self.flask_app = Flask(__name__,
                               template_folder=os.path.join(os.path.dirname(__file__), 'templates'),
                               static_folder=os.path.join(os.path.dirname(__file__), 'static'))

        CORS(self.flask_app)

        self.socketio = SocketIO(self.flask_app, cors_allowed_origins="*", async_mode='threading')

        self.running = False
        self._setup_routes()
        self._setup_socketio()

    # ------------------------------------------------------------------
    # Routes
    # ------------------------------------------------------------------

    def _setup_routes(self):
        """Setup Flask routes."""

        @self.flask_app.route('/')
        def index():
            return render_template('index.html')

        # ---- Status ----

        @self.flask_app.route('/api/status')
        def get_status():
            printer_installed = False
            try:
                printer_installed = self.pibooth_app.printer.is_installed()
            except Exception:
                pass

            return jsonify({
                'state': self.current_state,
                'data': self.state_data,
                'config': {
                    'capture_choices': list(self.pibooth_app.capture_choices) if self.pibooth_app else [],
                    'printer_installed': printer_installed,
                }
            })

        # ---- Actions ----

        @self.flask_app.route('/api/action/capture', methods=['POST'])
        def action_capture():
            try:
                # Check if timer mode is requested
                use_timer = False
                if request.is_json:
                    data = request.get_json()
                    use_timer = data.get('use_timer', False)
                
                # Configure gphoto2 drive mode before capture
                if use_timer:
                    try:
                        LOGGER.info("Setting camera to timer mode (10s)")
                        subprocess.run(['gphoto2', '--set-config', 'drivemode=1'], 
                                     capture_output=True, timeout=5, check=False)
                    except Exception as e:
                        LOGGER.warning("Could not set timer mode: %s", e)
                else:
                    try:
                        LOGGER.info("Setting camera to single shot mode")
                        subprocess.run(['gphoto2', '--set-config', 'drivemode=0'], 
                                     capture_output=True, timeout=5, check=False)
                    except Exception as e:
                        LOGGER.warning("Could not set single shot mode: %s", e)
                
                self._post_button_event(capture=True, printer=False)
                return jsonify({'success': True, 'message': 'Capture triggered'})
            except Exception as e:
                LOGGER.error("Error triggering capture: %s", e)
                return jsonify({'success': False, 'message': str(e)}), 500

        @self.flask_app.route('/api/action/print', methods=['POST'])
        def action_print():
            try:
                self._post_button_event(capture=False, printer=True)
                return jsonify({'success': True, 'message': 'Print triggered'})
            except Exception as e:
                LOGGER.error("Error triggering print: %s", e)
                return jsonify({'success': False, 'message': str(e)}), 500

        @self.flask_app.route('/api/action/choose/<direction>', methods=['POST'])
        def action_choose(direction):
            try:
                if direction == 'left':
                    ev = pygame.event.Event(pygame.KEYDOWN, key=pygame.K_LEFT)
                elif direction == 'right':
                    ev = pygame.event.Event(pygame.KEYDOWN, key=pygame.K_RIGHT)
                else:
                    return jsonify({'success': False, 'message': 'Invalid direction'}), 400
                pygame.event.post(ev)
                LOGGER.debug("Choice %s triggered from web", direction)
                return jsonify({'success': True, 'message': f'Choice {direction} triggered'})
            except Exception as e:
                LOGGER.error("Error triggering choice: %s", e)
                return jsonify({'success': False, 'message': str(e)}), 500

        # ---- Pictures ----

        @self.flask_app.route('/api/pictures/latest')
        def get_latest_picture():
            if self.pibooth_app.previous_picture_file:
                d = os.path.dirname(self.pibooth_app.previous_picture_file)
                f = os.path.basename(self.pibooth_app.previous_picture_file)
                return send_from_directory(d, f)
            return jsonify({'error': 'No picture available'}), 404

        # ---- Gallery ----

        @self.flask_app.route('/api/pictures/gallery')
        def api_gallery():
            pic_dir = _get_pictures_directory(self.pibooth_app)
            if not pic_dir:
                return jsonify({'pictures': [], 'directory': ''})

            pictures = []
            for ext in ('*.jpg', '*.jpeg', '*.png', '*.JPG', '*.JPEG', '*.PNG'):
                for filepath in glob.glob(os.path.join(pic_dir, ext)):
                    if os.path.isfile(filepath):
                        pictures.append({
                            'filename': os.path.basename(filepath),
                            'mtime': os.path.getmtime(filepath),
                        })

            pictures.sort(key=lambda x: x['mtime'], reverse=True)
            return jsonify({'pictures': pictures, 'directory': pic_dir})

        @self.flask_app.route('/api/pictures/file/<path:filename>')
        def api_picture_file(filename):
            pic_dir = _get_pictures_directory(self.pibooth_app)
            if not pic_dir:
                abort(404)
            filepath = os.path.normpath(os.path.join(pic_dir, filename))
            if not filepath.startswith(os.path.normpath(pic_dir)):
                abort(403)
            if os.path.isfile(filepath):
                return send_file(filepath, mimetype='image/jpeg')
            abort(404)

        @self.flask_app.route('/api/pictures/print/<path:filename>', methods=['POST'])
        def api_print_picture(filename):
            pic_dir = _get_pictures_directory(self.pibooth_app)
            if not pic_dir:
                return jsonify({'success': False, 'error': 'No picture directory'}), 404
            filepath = os.path.normpath(os.path.join(pic_dir, filename))
            if not filepath.startswith(os.path.normpath(pic_dir)):
                return jsonify({'success': False, 'error': 'Invalid path'}), 403
            if not os.path.isfile(filepath):
                return jsonify({'success': False, 'error': 'File not found'}), 404

            try:
                LOGGER.info("Printing %s via IPP direct", filepath)
                
                # Use ipptool to send JPEG directly to Canon SELPHY via ipp-usb
                result = subprocess.run(
                    [
                        "ipptool", "-tv",
                        "-d", "filetype=image/jpeg",
                        "ipp://localhost:60000/ipp/print",
                        "-f", filepath,
                        "/usr/share/cups/ipptool/print-job.test"
                    ],
                    capture_output=True, text=True, timeout=30,
                )
                
                # ipptool returns 0 on success, check for "successful-ok" in output
                if result.returncode != 0 or "successful-ok" not in result.stdout:
                    err = result.stderr.strip() or result.stdout.strip()
                    LOGGER.error("ipptool error: %s", err)
                    return jsonify({'success': False, 'error': 'Print failed'}), 500

                LOGGER.info("Print job sent successfully via IPP")
                return jsonify({'success': True, 'message': 'Print job sent', 'method': 'ipptool'})
            except Exception as exc:
                LOGGER.error("Print error: %s", exc, exc_info=True)
                return jsonify({'success': False, 'error': str(exc)}), 500

    # ------------------------------------------------------------------
    # SocketIO
    # ------------------------------------------------------------------

    def _setup_socketio(self):
        @self.socketio.on('connect')
        def handle_connect():
            LOGGER.info("Web client connected")
            emit('status_update', {'state': self.current_state, 'data': self.state_data})

        @self.socketio.on('disconnect')
        def handle_disconnect():
            LOGGER.info("Web client disconnected")

        @self.socketio.on('request_status')
        def handle_status_request():
            emit('status_update', {'state': self.current_state, 'data': self.state_data})

    # ------------------------------------------------------------------
    # Internal
    # ------------------------------------------------------------------

    def _post_button_event(self, capture=False, printer=False):
        event = pygame.event.Event(BUTTONDOWN,
                                   capture=1 if capture else 0,
                                   printer=1 if printer else 0,
                                   button=self.pibooth_app.buttons)
        pygame.event.post(event)
        LOGGER.debug("Button event posted: capture=%s, printer=%s", capture, printer)

    def update_status(self, state, data):
        self.current_state = state
        self.state_data = data
        self.socketio.emit('status_update', {'state': state, 'data': data})

    def run(self):
        self.running = True
        try:
            self.socketio.run(self.flask_app,
                              host=self.host,
                              port=self.port,
                              debug=False,
                              use_reloader=False,
                              log_output=False,
                              allow_unsafe_werkzeug=True)
        except Exception as e:
            LOGGER.error("Error running web server: %s", e)
            self.running = False

    def stop(self):
        self.running = False
        LOGGER.info("Web API stopped")