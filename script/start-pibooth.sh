#!/bin/bash
# =============================================================================
# Script de démarrage de Pibooth
# =============================================================================

BASEDIR="$HOME/30_pibooth"
VENV="$BASEDIR/pibooth/venv"

echo "Démarrage de Pibooth..."

cd "$BASEDIR/pibooth"
source "$VENV/bin/activate"

echo "Interface web: http://$(hostname -I | awk '{print $1}'):3000"
echo ""

pibooth "$@"