#!/bin/bash
# =============================================================================
# Script de diagnostic Pibooth
# =============================================================================

BASEDIR="$HOME/30_pibooth"
VENV="$BASEDIR/pibooth/venv"

echo "=============================================="
echo "  Diagnostic Pibooth"
echo "=============================================="

# Activer le venv
source "$VENV/bin/activate" 2>/dev/null

echo ""
echo "--- Python ---"
which python3
python3 --version

echo ""
echo "--- Pibooth ---"
python3 -c "import pibooth; print('Version:', pibooth.__version__); print('Fichier:', pibooth.__file__)" 2>/dev/null || echo "ERREUR: pibooth non trouvé"

echo ""
echo "--- pibooth-no-buttons ---"
python3 -c "import pibooth_no_buttons; print('Version:', pibooth_no_buttons.__version__); print('Fichier:', pibooth_no_buttons.__file__)" 2>/dev/null || echo "ERREUR: pibooth-no-buttons non trouvé"

echo ""
echo "--- pibooth-web-interface ---"
python3 -c "import pibooth_web; print('Version:', pibooth_web.__version__); print('Fichier:', pibooth_web.__file__)" 2>/dev/null || echo "ERREUR: pibooth-web-interface non trouvé"

echo ""
echo "--- Port 3000 ---"
sudo lsof -i :3000 2>/dev/null || echo "Aucun processus sur le port 3000"

echo ""
echo "--- Port 5000 (ancien, ne devrait rien avoir) ---"
sudo lsof -i :5000 2>/dev/null || echo "OK: Aucun processus sur le port 5000"

echo ""
echo "--- Configuration ---"
CONFIG="$HOME/.config/pibooth/pibooth.cfg"
if [ -f "$CONFIG" ]; then
    echo "Fichier: $CONFIG"
    echo ""
    echo "Section [WEB]:"
    sed -n '/\[WEB\]/,/^\[/p' "$CONFIG" | head -10
    echo ""
    echo "Section [NO_BUTTONS]:"
    sed -n '/\[NO_BUTTONS\]/,/^\[/p' "$CONFIG" | head -5
else
    echo "Pas de fichier de configuration trouvé"
fi

echo ""
echo "--- Espace disque ---"
df -h / | tail -1

echo ""
echo "--- IP du Raspberry Pi ---"
hostname -I

echo ""
echo "=============================================="
echo "  Fin du diagnostic"
echo "=============================================="