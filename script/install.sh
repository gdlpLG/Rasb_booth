#!/bin/bash
# =============================================================================
# Script d'installation complète de Pibooth + plugins
# À exécuter sur le Raspberry Pi
# =============================================================================

set -e

BASEDIR="$HOME/30_pibooth"
VENV="$BASEDIR/pibooth/venv"
CONFIG_DIR="$HOME/.config/pibooth"
CONFIG_FILE="$CONFIG_DIR/pibooth.cfg"

echo "=============================================="
echo "  Installation Pibooth + Plugins"
echo "=============================================="

# --- 1. Créer l'environnement virtuel ---
echo ""
echo "[1/5] Création de l'environnement virtuel..."
cd "$BASEDIR/pibooth"
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo "  -> venv créé"
else
    echo "  -> venv existe déjà"
fi
source "$VENV/bin/activate"

# --- 2. Installer pibooth ---
echo ""
echo "[2/5] Installation de pibooth..."
cd "$BASEDIR/pibooth"
pip install -e . 2>&1 | tail -5

# --- 3. Installer pibooth-no-buttons ---
echo ""
echo "[3/5] Installation de pibooth-no-buttons..."
cd "$BASEDIR/pibooth-no-buttons"
pip install -e . 2>&1 | tail -3

# --- 4. Installer pibooth-web-interface ---
echo ""
echo "[4/5] Installation de pibooth-web-interface..."
cd "$BASEDIR/pibooth-web-interface"
pip install -e . 2>&1 | tail -3

# --- 5. Configuration ---
echo ""
echo "[5/5] Configuration..."
mkdir -p "$CONFIG_DIR"

if [ -f "$CONFIG_FILE" ]; then
    # Backup de la config existante
    BACKUP="$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$CONFIG_FILE" "$BACKUP"
    echo "  -> Backup de la config existante: $BACKUP"

    # Mettre à jour le port si encore sur 5000
    if grep -q "port = 5000" "$CONFIG_FILE" 2>/dev/null; then
        sed -i 's/port = 5000/port = 3000/g' "$CONFIG_FILE"
        echo "  -> Port mis à jour de 5000 vers 3000"
    fi

    # Ajouter section [WEB] si absente
    if ! grep -q "\[WEB\]" "$CONFIG_FILE" 2>/dev/null; then
        echo "" >> "$CONFIG_FILE"
        echo "[WEB]" >> "$CONFIG_FILE"
        echo "enable = yes" >> "$CONFIG_FILE"
        echo "host = 0.0.0.0" >> "$CONFIG_FILE"
        echo "port = 3000" >> "$CONFIG_FILE"
        echo "  -> Section [WEB] ajoutée"
    fi

    # Ajouter section [NO_BUTTONS] si absente
    if ! grep -q "\[NO_BUTTONS\]" "$CONFIG_FILE" 2>/dev/null; then
        echo "" >> "$CONFIG_FILE"
        echo "[NO_BUTTONS]" >> "$CONFIG_FILE"
        echo "enabled = yes" >> "$CONFIG_FILE"
        echo "  -> Section [NO_BUTTONS] ajoutée"
    fi
else
    echo "  -> Pas de config existante, Pibooth en créera une au premier lancement"
fi

# --- Vérifications ---
echo ""
echo "=============================================="
echo "  Vérifications"
echo "=============================================="

echo ""
echo "pibooth:"
python3 -c "import pibooth; print('  Version:', pibooth.__version__)" 2>/dev/null || echo "  ERREUR: pibooth non installé"

echo ""
echo "pibooth-no-buttons:"
python3 -c "import pibooth_no_buttons; print('  Version:', pibooth_no_buttons.__version__); print('  Fichier:', pibooth_no_buttons.__file__)" 2>/dev/null || echo "  ERREUR: pibooth-no-buttons non installé"

echo ""
echo "pibooth-web-interface:"
python3 -c "import pibooth_web; print('  Version:', pibooth_web.__version__); print('  Fichier:', pibooth_web.__file__)" 2>/dev/null || echo "  ERREUR: pibooth-web-interface non installé"

echo ""
echo "=============================================="
echo "  Installation terminée!"
echo "=============================================="
echo ""
echo "Pour lancer pibooth:"
echo "  cd $BASEDIR/pibooth"
echo "  source venv/bin/activate"
echo "  pibooth"
echo ""
echo "Interface web accessible sur:"
echo "  http://$(hostname -I | awk '{print $1}'):3000"
echo ""