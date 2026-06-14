# -*- coding: utf-8 -*-

"""Virtual GPIO-compatible buttons and LEDs for no-hardware deployments.

This module intentionally has no gpiozero/RPi.GPIO dependency.  It provides
small objects exposing the attributes used by :mod:`pibooth.booth` so Pibooth
can run when physical buttons are disabled.
"""

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
        """Keep gpiozero-compatible API."""
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