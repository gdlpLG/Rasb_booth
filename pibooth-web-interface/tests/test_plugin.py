# -*- coding: utf-8 -*-

"""Tests for the pibooth-web-interface plugin."""

import importlib
import os
import sys

def test_import_plugin():
    """Verify that pibooth_web can be imported."""
    import pibooth_web
    assert hasattr(pibooth_web, '__version__')
    assert pibooth_web.__version__ == "1.0.0"

def test_plugin_file_location():
    """Verify that the imported module comes from the expected location."""
    import pibooth_web
    location = pibooth_web.__file__
    assert location is not None
    assert 'pibooth_web' in location

def test_server_module_import():
    """Verify that the Flask server module can be imported."""
    from pibooth_web import server
    assert hasattr(server, 'create_flask_app')
    assert hasattr(server, 'run_server')

def test_flask_app_creation():
    """Verify that the Flask application can be created."""
    from pibooth_web.server import create_flask_app
    app = create_flask_app()
    assert app is not None
    # Check routes exist
    rules = [rule.rule for rule in app.url_map.iter_rules()]
    assert '/' in rules
    assert '/api/status' in rules
    assert '/api/action/capture' in rules
    assert '/api/action/print' in rules
    assert '/api/action/choose/left' in rules
    assert '/api/action/choose/right' in rules
    assert '/api/pictures/latest' in rules

def test_default_port_is_3000():
    """Verify that the default port in the code is 3000."""
    import pibooth_web
    # The pibooth_configure hook registers port with default 3000
    # We check the source code for the default value
    source_file = pibooth_web.__file__
    with open(source_file, 'r') as f:
        source = f.read()
    assert "'port', 3000" in source or '"port", 3000' in source

def test_hook_functions_exist():
    """Verify that the plugin exposes the expected Pibooth hooks."""
    import pibooth_web
    assert hasattr(pibooth_web, 'pibooth_configure')
    assert hasattr(pibooth_web, 'pibooth_startup')
    assert hasattr(pibooth_web, 'pibooth_cleanup')
    assert hasattr(pibooth_web, 'state_wait_enter')
    assert hasattr(pibooth_web, 'state_choose_enter')
    assert hasattr(pibooth_web, 'state_capture_enter')
    assert hasattr(pibooth_web, 'state_processing_enter')
    assert hasattr(pibooth_web, 'state_print_enter')
    assert hasattr(pibooth_web, 'state_finish_enter')

def test_public_api_functions():
    """Verify that the public API functions exist."""
    import pibooth_web
    assert callable(pibooth_web.get_app)
    assert callable(pibooth_web.get_state)
    assert callable(pibooth_web.get_latest_picture)
    assert callable(pibooth_web.post_capture_event)
    assert callable(pibooth_web.post_print_event)
    assert callable(pibooth_web.post_choose_left_event)
    assert callable(pibooth_web.post_choose_right_event)

def test_initial_state():
    """Verify initial state values."""
    import pibooth_web
    assert pibooth_web.get_state() == "unknown"
    assert pibooth_web.get_app() is None
    assert pibooth_web.get_latest_picture() is None

def test_templates_exist():
    """Verify that the HTML templates exist."""
    import pibooth_web
    plugin_dir = os.path.dirname(pibooth_web.__file__)
    template_path = os.path.join(plugin_dir, 'templates', 'index.html')
    assert os.path.isfile(template_path), f"Template not found: {template_path}"

def test_static_files_exist():
    """Verify that the static files exist."""
    import pibooth_web
    plugin_dir = os.path.dirname(pibooth_web.__file__)
    css_path = os.path.join(plugin_dir, 'static', 'style.css')
    js_path = os.path.join(plugin_dir, 'static', 'app.js')
    assert os.path.isfile(css_path), f"CSS not found: {css_path}"
    assert os.path.isfile(js_path), f"JS not found: {js_path}"

def test_flask_test_client_status_endpoint():
    """Test the /api/status endpoint with Flask test client."""
    from pibooth_web.server import create_flask_app
    app = create_flask_app()
    client = app.test_client()
    response = client.get('/api/status')
    assert response.status_code == 200
    data = response.get_json()
    assert 'state' in data
    assert 'ready' in data

def test_flask_test_client_capture_endpoint():
    """Test the /api/action/capture endpoint with Flask test client."""
    from pibooth_web.server import create_flask_app
    app = create_flask_app()
    client = app.test_client()
    response = client.post('/api/action/capture')
    assert response.status_code == 200
    data = response.get_json()
    assert 'success' in data
    assert data['action'] == 'capture'

def test_flask_test_client_latest_picture_404():
    """Test that /api/pictures/latest returns 404 when no picture exists."""
    from pibooth_web.server import create_flask_app
    app = create_flask_app()
    client = app.test_client()
    response = client.get('/api/pictures/latest')
    assert response.status_code == 404

def test_no_port_5000_in_defaults():
    """Verify that port 5000 is NOT used as a default anywhere in the plugin."""
    import pibooth_web
    source_file = pibooth_web.__file__
    with open(source_file, 'r') as f:
        source = f.read()
    # Port 5000 should not appear as a default
    assert 'port = 5000' not in source.lower().replace(' ', '')
    assert "'port', 5000" not in source
    assert '"port", 5000' not in source