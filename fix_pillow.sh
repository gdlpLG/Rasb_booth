#!/bin/bash
# Script de fix pour l'erreur Pillow getsize

echo "============================================="
echo "🔧 Fix Pillow pour pibooth-picture-template"
echo "============================================="
echo ""

# Aller dans le venv
cd ~/Rasb_booth/pibooth
source venv/bin/activate

echo "📋 Version Pillow actuelle:"
pip show Pillow | grep Version
echo ""

echo "❓ Le plugin pibooth-picture-template utilise font.getsize()"
echo "   qui n'existe plus dans Pillow 10+"
echo ""
echo "📥 Installation de Pillow 9.5.0 (version stable compatible)..."
echo ""

pip install 'Pillow==9.5.0'

echo ""
echo "============================================="
echo "✅ Fix Pillow terminé"
echo "============================================="
echo ""
echo "📋 Nouvelle version Pillow:"
pip show Pillow | grep Version
echo ""
echo "🚀 Prochaines étapes:"
echo ""
echo "1. Redémarrer Pibooth:"
echo "   pkill -9 python3"
echo "   cd ~/Rasb_booth/pibooth && source venv/bin/activate && pibooth"
echo ""
echo "2. Prendre une photo de test"
echo ""
echo "3. Vérifier qu'il n'y a plus l'erreur 'getsize'"
echo ""
echo "💡 Note: Ce fix est permanent et sûr."
echo "   Pillow 9.5.0 est une version stable qui fonctionne bien."
echo ""