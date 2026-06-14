#!/bin/bash
# =============================================================================
# Pibooth – Quick Start Script (with web interface)
# =============================================================================
# Usage:
#   bash start-pibooth-web.sh
# =============================================================================

set -e

PIBOOTH_DIR="${HOME}/Rasb_booth/pibooth"
VENV_DIR="${PIBOOTH_DIR}/venv"

echo "🚀 Starting Pibooth with web interface..."

if [ ! -d "$VENV_DIR" ]; then
    echo "❌ Virtual environment not found at $VENV_DIR"
    echo "   Please install pibooth first."
    exit 1
fi

cd "$PIBOOTH_DIR"
source "$VENV_DIR/bin/activate"

echo "   Python: $(which python3)"
echo "   Venv:   $VIRTUAL_ENV"
echo ""
echo "   Web interface will be available at:"
echo "   http://$(hostname -I | awk '{print $1}'):3000"
echo ""

pibooth