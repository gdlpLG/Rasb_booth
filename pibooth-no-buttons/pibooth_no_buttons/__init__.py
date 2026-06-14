# -*- coding: utf-8 -*-

"""Pibooth plugin to disable physical GPIO buttons.

This plugin replaces physical GPIO buttons and LEDs with virtual ones,
allowing Pibooth to run without any physical hardware buttons connected.

It is activated via the configuration:

    [NO_BUTTONS]
    enabled = yes

When enabled, it replaces app.buttons and app.leds with virtual objects
that expose the same API as gpiozero ButtonBoard/LEDBoard.
"""

__version__ = "1.0.0"

import logging
import pibooth

LOGGER = logging.getLogger("pibooth.no_buttons")

# ---------------------------------------------------------------------------
# Virtual GPIO classes – no hardware dependency
# ---------------------------------------------------------------------------

class VirtualButton(object):
    """Minimal stand-in for a gpiozero Button."""

    def __init__(self, name):
        self.name = name
        self.when_held = None
        self.hold_repeat = False
        self.is_active = False

    @property
    def value(self):
        return 1 if self.is_active else 0

    def close(self):
        self.when_held = None

class VirtualButtonBoard(object):
    """Minimal stand-in for a gpiozero ButtonBoard."""

    def __init__(self):
        self.capture = VirtualButton("capture")
        self.printer = VirtualButton("printer")

    @property
    def value(self):
        return (self.capture.value, self.printer.value)

    def close(self):
        self.capture.close()
        self.printer.close()

class VirtualLED(object):
    """Minimal stand-in for a gpiozero LED."""

    def __init__(self, name):
        self.name = name
        self.is_lit = False
        self._controller = None

    def on(self):
        self.is_lit = True
        self._controller = None

    def off(self):
        self.is_lit = False
        self._controller = None

    def blink(self, *args, **kwargs):
        self.is_lit = True
        self._controller = True  # Simulate blinking state

    def close(self):
        self.off()

class VirtualLEDBoard(object):
    """Minimal stand-in for a gpiozero LEDBoard."""

    def __init__(self):
        self.capture = VirtualLED("capture")
        self.printer = VirtualLED("printer")

    def on(self):
        self.capture.on()
        self.printer.on()

    def off(self):
        self.capture.off()
        self.printer.off()

    def blink(self, *args, **kwargs):
        self.capture.blink(*args, **kwargs)
        self.printer.blink(*args, **kwargs)

    def close(self):
        self.capture.close()
        self.printer.close()

# ---------------------------------------------------------------------------
# Pibooth plugin hooks
# ---------------------------------------------------------------------------

@pibooth.hookimpl
def pibooth_configure(cfg):
    """Declare plugin configuration options."""
    cfg.add_option('NO_BUTTONS', 'enabled', default='yes',
                   description="Disable physical GPIO buttons and use virtual ones",
                   menu_name="No buttons",
                   menu_choices=['yes', 'no'])

@pibooth.hookimpl
def pibooth_startup(cfg, app):
    """Replace physical buttons with virtual ones if enabled."""
    try:
        enabled = cfg.getboolean('NO_BUTTONS', 'enabled')
    except Exception:
        enabled = False

    if enabled:
        LOGGER.info("=== Physical buttons DISABLED (pibooth-no-buttons plugin) ===")
        app.buttons = VirtualButtonBoard()
        app.leds = VirtualLEDBoard()
        LOGGER.info("Virtual buttons and LEDs installed successfully")
    else:
        LOGGER.info("pibooth-no-buttons plugin is installed but disabled")