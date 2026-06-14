# -*- coding: utf-8 -*-

"""Pibooth Web Interface Plugin.

This plugin adds a web-based control interface to Pibooth, allowing users
to control the photobooth from a phone, tablet, or computer browser.
It replaces the need for physical GPIO buttons.
"""

__version__ = "1.0.0"

import io
import logging
import threading
import time

import pygame
import pluggy

hookimpl = pluggy.HookimplMarker('pibooth')

LOGGER = logging.getLogger("pibooth.web")

# Reference to the running Flask server thread
_server_thread = None
# Reference to the application instance (shared with server)
_app_instance = None
# Reference to the current state name
_current_state = "unknown"
# Reference to the latest picture file path
_latest_picture = None
# Reference to the config
_cfg = None
# Preview frame buffer (JPEG bytes) for streaming
_preview_frame = None
_preview_frame_lock = threading.Lock()
_preview_last_capture_time = 0
_PREVIEW_FPS = 10  # Max frames per second for web preview

def _get_buttondown_event_type():
    """Return the BUTTONDOWN event type used by Pibooth."""
    return pygame.USEREVENT + 1

# ---------------------------------------------------------------------------
# Plugin hooks
# ---------------------------------------------------------------------------

@hookimpl
def pibooth_configure(cfg):
    """Register plugin configuration options."""
    cfg.add_option('WEB', 'enable', True,
                   "Enable the web interface plugin",
                   "Web interface enabled", ['yes', 'no'])
    cfg.add_option('WEB', 'host', '0.0.0.0',
                   "Host address for the web server")
    cfg.add_option('WEB', 'port', 3000,
                   "Port for the web server (default 3000)")
    cfg.add_option('WEB', 'disable_physical_buttons', True,
                   "Disable physical GPIO buttons (use virtual buttons instead)",
                   "Disable physical buttons", ['yes', 'no'])

@hookimpl
def pibooth_startup(cfg, app):
    """Start the web server when Pibooth starts."""
    global _server_thread, _app_instance, _cfg

    _cfg = cfg

    if not cfg.getboolean('WEB', 'enable'):
        LOGGER.info("Web interface plugin is disabled in configuration")
        return

    _app_instance = app
    host = cfg.get('WEB', 'host')
    port = cfg.getint('WEB', 'port')

    # Import here to avoid circular imports
    from pibooth_web.server import create_flask_app, run_server

    flask_app = create_flask_app()
    _server_thread = threading.Thread(
        target=run_server,
        args=(flask_app, host, port),
        daemon=True,
        name="pibooth-web-server"
    )
    _server_thread.start()
    LOGGER.info("Web interface started on http://%s:%s", host, port)

@hookimpl
def pibooth_cleanup(app):
    """Cleanup when Pibooth exits."""
    global _server_thread
    LOGGER.info("Web interface shutting down")
    _server_thread = None

# ---------------------------------------------------------------------------
# State tracking hooks – update _current_state so the API can report it
# ---------------------------------------------------------------------------

@hookimpl
def state_wait_enter(cfg, app, win):
    global _current_state
    _current_state = "wait"

@hookimpl
def state_choose_enter(cfg, app, win):
    global _current_state
    _current_state = "choose"

@hookimpl
def state_chosen_enter(cfg, app, win):
    global _current_state
    _current_state = "chosen"

@hookimpl
def state_preview_enter(cfg, app, win):
    global _current_state
    _current_state = "preview"

@hookimpl
def state_capture_enter(cfg, app, win):
    global _current_state
    _current_state = "capture"

@hookimpl
def state_processing_enter(cfg, app, win):
    global _current_state
    _current_state = "processing"

@hookimpl
def state_print_enter(cfg, app, win):
    global _current_state
    _current_state = "print"

@hookimpl
def state_finish_enter(cfg, app, win):
    global _current_state
    _current_state = "finish"

@hookimpl
def state_failsafe_enter(cfg, app, win):
    global _current_state
    _current_state = "failsafe"

# ---------------------------------------------------------------------------
# Preview frame capture for web streaming
# ---------------------------------------------------------------------------
# DISABLED: Preview not yet mapped to web page

# @hookimpl
# def state_preview_do(cfg, app, win):
#     """Capture the current Pygame display surface for web streaming."""
#     global _preview_frame, _preview_last_capture_time
#     now = time.time()
#     # Limit capture rate to _PREVIEW_FPS
#     if now - _preview_last_capture_time < 1.0 / _PREVIEW_FPS:
#         return
#     _preview_last_capture_time = now
#     try:
#         surface = pygame.display.get_surface()
#         if surface is None:
#             return
#         # Convert Pygame surface to JPEG bytes
#         raw_str = pygame.image.tostring(surface, 'RGB')
#         size = surface.get_size()
#         # Use PIL to create JPEG
#         from PIL import Image
#         img = Image.frombytes('RGB', size, raw_str)
#         buf = io.BytesIO()
#         img.save(buf, format='JPEG', quality=60)
#         with _preview_frame_lock:
#             _preview_frame = buf.getvalue()
#     except Exception as exc:
#         LOGGER.debug("Preview capture error: %s", exc)

# @hookimpl
# def state_preview_exit(cfg, app, win):
#     """Clear preview frame when leaving preview state."""
#     global _preview_frame
#     with _preview_frame_lock:
#         _preview_frame = None

# ---------------------------------------------------------------------------
# Track the latest picture
# ---------------------------------------------------------------------------

@hookimpl
def state_processing_exit(cfg, app, win):
    """When processing is done, record the latest picture path and emit event."""
    global _latest_picture
    if app.previous_picture_file:
        _latest_picture = app.previous_picture_file
        # Emit SocketIO event to notify web clients
        try:
            from pibooth_web.server import emit_new_picture
            emit_new_picture(_latest_picture)
        except Exception as exc:
            LOGGER.debug("Could not emit new_picture event: %s", exc)

# ---------------------------------------------------------------------------
# Public API used by the Flask server
# ---------------------------------------------------------------------------

def get_app():
    """Return the Pibooth application instance."""
    return _app_instance

def get_config():
    """Return the Pibooth configuration instance."""
    return _cfg

def get_state():
    """Return the current Pibooth state name."""
    return _current_state

def get_latest_picture():
    """Return the path to the latest generated picture."""
    return _latest_picture

def get_picture_dirs():
    """Return the list of picture directories from Pibooth config."""
    cfg = get_config()
    if cfg:
        try:
            return cfg.gettuple('GENERAL', 'directory', 'path')
        except Exception:
            pass
    return []

def post_capture_event():
    """Post a capture button event into Pygame's event queue."""
    BUTTONDOWN = _get_buttondown_event_type()
    app = get_app()
    if app is None:
        return False
    event = pygame.event.Event(BUTTONDOWN, capture=1, printer=0,
                               button=app.buttons.capture)
    pygame.event.post(event)
    LOGGER.info("Web: posted CAPTURE event")
    return True

def post_print_event():
    """Post a print button event into Pygame's event queue."""
    BUTTONDOWN = _get_buttondown_event_type()
    app = get_app()
    if app is None:
        return False
    event = pygame.event.Event(BUTTONDOWN, capture=0, printer=1,
                               button=app.buttons.printer)
    pygame.event.post(event)
    LOGGER.info("Web: posted PRINT event")
    return True

def post_choose_left_event():
    """Post a left-choice (capture) button event."""
    BUTTONDOWN = _get_buttondown_event_type()
    app = get_app()
    if app is None:
        return False
    event = pygame.event.Event(BUTTONDOWN, capture=1, printer=0,
                               button=app.buttons.capture)
    pygame.event.post(event)
    LOGGER.info("Web: posted CHOOSE LEFT event")
    return True

def post_choose_right_event():
    """Post a right-choice (printer) button event."""
    BUTTONDOWN = _get_buttondown_event_type()
    app = get_app()
    if app is None:
        return False
    event = pygame.event.Event(BUTTONDOWN, capture=0, printer=1,
                               button=app.buttons.printer)
    pygame.event.post(event)
    LOGGER.info("Web: posted CHOOSE RIGHT event")
    return True