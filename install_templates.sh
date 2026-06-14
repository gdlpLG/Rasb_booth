#!/bin/bash
# Script d'installation complète du système de templates Pibooth

set -e

echo "=============================================="
echo "Installation système de templates Pibooth"
echo "=============================================="
echo ""

# Couleurs pour l'affichage
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Chemins
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_PATH="$SCRIPT_DIR/pibooth/venv"
CONFIG_PATH="$HOME/.config/pibooth/pibooth.cfg"
TEMPLATES_DIR="$HOME/pibooth_templates"
PLUGIN_DIR="$SCRIPT_DIR/pibooth-picture-template"

echo -e "${BLUE}📍 Répertoire de travail: $SCRIPT_DIR${NC}"
echo ""

# Vérifier que les dossiers existent
if [ ! -d "$SCRIPT_DIR/pibooth" ]; then
    echo -e "${RED}❌ Erreur: Dossier pibooth/ introuvable${NC}"
    exit 1
fi

if [ ! -d "$SCRIPT_DIR/pibooth-web-interface" ]; then
    echo -e "${RED}❌ Erreur: Dossier pibooth-web-interface/ introuvable${NC}"
    exit 1
fi

if [ ! -d "$PLUGIN_DIR" ]; then
    echo -e "${RED}❌ Erreur: Dossier pibooth-picture-template/ introuvable${NC}"
    exit 1
fi

# ============================================
# Étape 1: Sauvegarde configuration
# ============================================
echo -e "${BLUE}📦 Étape 1/6 : Sauvegarde de la configuration${NC}"
if [ -f "$CONFIG_PATH" ]; then
    BACKUP_FILE="${CONFIG_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$CONFIG_PATH" "$BACKUP_FILE"
    echo -e "${GREEN}✅ Configuration sauvegardée: $BACKUP_FILE${NC}"
else
    echo -e "${YELLOW}⚠️  Aucune configuration existante trouvée${NC}"
fi
echo ""

# ============================================
# Étape 2: Activation environnement virtuel
# ============================================
echo -e "${BLUE}📦 Étape 2/6 : Activation de l'environnement virtuel${NC}"
if [ ! -d "$VENV_PATH" ]; then
    echo -e "${RED}❌ Erreur: Environnement virtuel non trouvé: $VENV_PATH${NC}"
    echo "Créez-le d'abord avec: python3 -m venv $VENV_PATH"
    exit 1
fi

source "$VENV_PATH/bin/activate"
echo -e "${GREEN}✅ Environnement virtuel activé${NC}"
echo ""

# ============================================
# Étape 3: Installation du plugin picture-template
# ============================================
echo -e "${BLUE}📦 Étape 3/6 : Installation du plugin pibooth-picture-template${NC}"
cd "$PLUGIN_DIR"
pip install -e . --quiet
echo -e "${GREEN}✅ Plugin pibooth-picture-template installé${NC}"
echo ""

# ============================================
# Étape 4: Réinstallation du plugin web
# ============================================
echo -e "${BLUE}📦 Étape 4/6 : Réinstallation du plugin web avec dépendances${NC}"
cd "$SCRIPT_DIR/pibooth-web-interface"
pip install -e . --quiet
echo -e "${GREEN}✅ Plugin web réinstallé${NC}"
echo ""

# ============================================
# Étape 5: Création de la structure de dossiers
# ============================================
echo -e "${BLUE}📁 Étape 5/6 : Création de la structure de dossiers${NC}"
mkdir -p "$TEMPLATES_DIR"
chmod 755 "$TEMPLATES_DIR"
echo -e "${GREEN}✅ Dossier créé: $TEMPLATES_DIR${NC}"

# Copier les templates d'exemple
if [ -d "$PLUGIN_DIR/templates" ]; then
    echo -e "${BLUE}📄 Copie des templates d'exemple...${NC}"
    cp "$PLUGIN_DIR/templates"/*.xml "$TEMPLATES_DIR/" 2>/dev/null || true
    TEMPLATE_COUNT=$(ls -1 "$TEMPLATES_DIR"/*.xml 2>/dev/null | wc -l)
    echo -e "${GREEN}✅ $TEMPLATE_COUNT template(s) copié(s)${NC}"
fi
echo ""

# ============================================
# Étape 6: Configuration de pibooth.cfg
# ============================================
echo -e "${BLUE}⚙️  Étape 6/6 : Configuration de pibooth.cfg${NC}"
mkdir -p "$(dirname $CONFIG_PATH)"

# Vérifier si la section [PICTURE] existe
if [ -f "$CONFIG_PATH" ]; then
    if ! grep -q "^\[PICTURE\]" "$CONFIG_PATH"; then
        echo "" >> "$CONFIG_PATH"
        echo "[PICTURE]" >> "$CONFIG_PATH"
        echo -e "${GREEN}✅ Section [PICTURE] ajoutée${NC}"
    fi
    
    # Vérifier si template est déjà configuré
    if grep -q "^template" "$CONFIG_PATH"; then
        echo -e "${YELLOW}ℹ️  Paramètre 'template' déjà présent dans la configuration${NC}"
    else
        # Ajouter la configuration template (vide par défaut)
        sed -i "/^\[PICTURE\]/a\\
# Template XML pour mise en page personnalisée (vide = pas de template)\\
template = " "$CONFIG_PATH"
        echo -e "${GREEN}✅ Paramètre 'template' ajouté à la configuration${NC}"
    fi
else
    # Créer une nouvelle configuration minimale
    cat > "$CONFIG_PATH" << 'EOF'
[PICTURE]
# Template XML pour mise en page personnalisée (vide = pas de template)
template = 
EOF
    echo -e "${GREEN}✅ Configuration créée${NC}"
fi
echo ""

# ============================================
# Résumé final
# ============================================
echo -e "${GREEN}=============================================="
echo -e "✅ Installation terminée avec succès !"
echo -e "==============================================${NC}"
echo ""
echo -e "${BLUE}📋 Résumé:${NC}"
echo -e "  • Plugin pibooth-picture-template: ${GREEN}installé${NC}"
echo -e "  • Plugin web: ${GREEN}mis à jour${NC}"
echo -e "  • Dossier templates: ${GREEN}$TEMPLATES_DIR${NC}"
echo -e "  • Configuration: ${GREEN}$CONFIG_PATH${NC}"
if [ -n "$BACKUP_FILE" ]; then
    echo -e "  • Backup: ${GREEN}$BACKUP_FILE${NC}"
fi
echo ""
echo -e "${BLUE}🎯 Prochaines étapes:${NC}"
echo -e "  1. Démarrer Pibooth:"
echo -e "     ${YELLOW}cd $SCRIPT_DIR/pibooth && source venv/bin/activate && pibooth${NC}"
echo ""
echo -e "  2. Accéder à l'interface web:"
echo -e "     ${YELLOW}http://localhost:3000${NC}"
echo ""
echo -e "  3. Gérer les templates:"
echo -e "     ${YELLOW}http://localhost:3000/templates${NC}"
echo ""
echo -e "${BLUE}📚 Documentation:${NC}"
echo -e "  • Créer des templates: https://app.diagrams.net"
echo -e "  • Templates d'exemple: $TEMPLATES_DIR"
echo -e "  • README: $PLUGIN_DIR/README.rst"
echo ""
echo -e "${BLUE}🔄 En cas de problème:${NC}"
echo -e "  Restaurer la config: ${YELLOW}cp $BACKUP_FILE $CONFIG_PATH${NC}"
echo -e "  Désinstaller: ${YELLOW}pip uninstall pibooth-picture-template${NC}"
echo ""