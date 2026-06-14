#!/bin/bash
# =============================================================================
# Pibooth Web Interface – Installation Script
# =============================================================================
# Usage:
#   cd ~/Rasb_booth/pibooth-web-interface
#   bash install.sh
#
# This script installs the pibooth-web-interface plugin into the active
# Python virtual environment and configures pibooth to use it.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="${HOME}/.config/pibooth"
CONFIG_FILE="${CONFIG_DIR}/pibooth.cfg"

echo "========================================"
echo "  Pibooth Web Interface – Installation"
echo "========================================"

# --- Check virtual environment ---
if [ -z "$VIRTUAL_ENV" ]; then
    echo ""
    echo "⚠  No virtual environment detected."
    echo "   Please activate your pibooth venv first:"
    echo ""
    echo "   source ~/Rasb_booth/pibooth/venv/bin/activate"
    echo ""
    exit 1
fi

echo ""
echo "Using Python: $(which python3)"
echo "Virtual env:  $VIRTUAL_ENV"
echo ""

# --- Install the plugin ---
echo "📦 Installing pibooth-web-interface (editable mode)..."
pip install -e "$SCRIPT_DIR"

echo ""
echo "✅ Plugin installed."

# --- Update configuration ---
echo ""
echo "📝 Updating Pibooth configuration..."

if [ -f "$CONFIG_FILE" ]; then
    # Backup existing config
    BACKUP="${CONFIG_FILE}.backup.$(date +%Y%m%d%H%M%S)"
    cp "$CONFIG_FILE" "$BACKUP"
    echo "   Backup saved: $BACKUP"

    # Check if [WEB] section already exists
    if grep -q '^\[WEB\]' "$CONFIG_FILE"; then
        echo "   [WEB] section already exists – updating values..."
        # Update port to 3000 if it was 5000
        sed -i 's/^port\s*=\s*5000/port = 3000/' "$CONFIG_FILE"
        # Ensure disable_physical_buttons is set
        if ! grep -q 'disable_physical_buttons' "$CONFIG_FILE"; then
            sed -i '/^\[WEB\]/a disable_physical_buttons = yes' "$CONFIG_FILE"
        fi
        # Ensure enable is set
        if ! grep -q '^enable' "$CONFIG_FILE" | grep -A5 '^\[WEB\]'; then
            sed -i '/^\[WEB\]/a enable = yes' "$CONFIG_FILE"
        fi
    else
        echo "   Adding [WEB] section..."
        cat >> "$CONFIG_FILE" << 'EOF'

[WEB]
enable = yes
host = 0.0.0.0
port = 3000
disable_physical_buttons = yes
EOF
    fi
    echo "   ✅ Configuration updated."
else
    echo "   ℹ  No existing config found at $CONFIG_FILE"
    echo "   It will be created automatically on first pibooth launch."
fi

# --- Verify installation ---
echo ""
echo "🔍 Verifying installation..."
python3 -c "import pibooth_web; print('   Plugin location:', pibooth_web.__file__)"
python3 -c "import pibooth_web; print('   Plugin version:', pibooth_web.__version__)"

echo ""
echo "========================================"
echo "  ✅ Installation complete!"
echo "========================================"
echo ""
echo "To start Pibooth with the web interface:"
echo ""
echo "  cd ~/Rasb_booth/pibooth"
echo "  source venv/bin/activate"
echo "  pibooth"
echo ""
echo "Then open in your browser:"
echo "  http://<raspberry-pi-ip>:3000"
echo ""