# 🔍 Debug - Pibooth ne montre plus de logs

## Problème

Après le patch Pillow, Pibooth démarre mais :
- ✅ L'interface web fonctionne
- ✅ Les boutons web fonctionnent
- ✅ La photo est prise
- ❌ La photo n'est pas traitée/sauvegardée
- ❌ Aucun log n'apparaît dans le terminal SSH

## Diagnostic

### 1. Vérifier les logs complets

```bash
ssh lucas@192.168.1.60

# Voir TOUS les logs depuis le démarrage
tail -f ~/.pibooth/pibooth.log
```

ou

```bash
# Voir les 100 dernières lignes
tail -100 ~/.pibooth/pibooth.log
```

### 2. Chercher les erreurs spécifiques

```bash
# Chercher "ERROR" dans les logs
grep ERROR ~/.pibooth/pibooth.log | tail -20

# Chercher "Traceback" (stack trace Python)
grep -A 10 "Traceback" ~/.pibooth/pibooth.log | tail -30
```

### 3. Vérifier que le plugin est bien chargé

```bash
grep "pibooth-picture-template" ~/.pibooth/pibooth.log | tail -5
```

Tu devrais voir:
```
[ INFO ] pibooth : pibooth-picture-template v1.1.0 loaded
```

### 4. Vérifier la version de Pillow

```bash
cd ~/Rasb_booth/pibooth
source venv/bin/activate
pip show Pillow
```

Tu dois avoir `Version: 10.4.0` ou plus.

### 5. Tester si le patch fonctionne

```bash
cd ~/Rasb_booth/pibooth
source venv/bin/activate
python3 << 'EOF'
from PIL import ImageFont
import os

# Créer un font par défaut
font = ImageFont.load_default()

# Tester l'ancienne API (doit échouer)
try:
    font.getsize("test")
    print("❌ ERREUR: getsize() existe encore (mauvaise version Pillow?)")
except AttributeError:
    print("✅ OK: getsize() n'existe plus (Pillow 10+)")

# Tester la nouvelle API (doit marcher)
try:
    bbox = font.getbbox("test")
    width = bbox[2] - bbox[0]
    height = bbox[3] - bbox[1]
    print(f"✅ OK: getbbox() marche - width={width}, height={height}")
except Exception as e:
    print(f"❌ ERREUR getbbox(): {e}")
EOF
```

### 6. Vérifier que le fichier patché est bien installé

```bash
# Chercher "Compatible with Pillow 10+" dans le plugin
grep -n "Compatible with Pillow 10+" ~/Rasb_booth/pibooth-picture-template/pibooth_picture_template.py
```

Tu devrais voir:
```
411:                # Compatible with Pillow 10+ (getsize deprecated)
```

Si cette ligne n'existe pas, le patch n'a pas été transféré correctement.

---

## Solutions possibles

### Solution A: Le patch n'a pas été transféré

```bash
# Depuis Windows, retransférer
scp pibooth-picture-template\pibooth_picture_template.py lucas@192.168.1.60:~/Rasb_booth/pibooth-picture-template/

# Sur Raspberry Pi, réinstaller
ssh lucas@192.168.1.60
cd ~/Rasb_booth/pibooth-picture-template
source ~/Rasb_booth/pibooth/venv/bin/activate
pip install -e .
```

### Solution B: Mauvaise version de Pillow

```bash
cd ~/Rasb_booth/pibooth
source venv/bin/activate
pip install --upgrade 'Pillow>=10.4.0'
pip install -e ~/Rasb_booth/pibooth-picture-template
```

### Solution C: Le plugin picture-template n'est pas installé

```bash
cd ~/Rasb_booth/pibooth
source venv/bin/activate
pip list | grep pibooth

# Si pibooth-picture-template n'apparaît pas:
cd ~/Rasb_booth/pibooth-picture-template
pip install -e .
```

### Solution D: Désactiver temporairement les templates

Éditer la config pour tester sans templates:

```bash
nano ~/.config/pibooth/pibooth.cfg
```

Commenter la ligne template:
```ini
[PICTURE]
# template = /home/lucas/pibooth_templates/fancy.xml
```

Sauvegarder (Ctrl+O, Enter, Ctrl+X), puis redémarrer Pibooth.

Si ça marche sans template, le problème vient du plugin ou du template.

---

## Commandes de debug à lancer

```bash
# 1. Voir les logs
tail -100 ~/.pibooth/pibooth.log

# 2. Chercher les erreurs
grep -i error ~/.pibooth/pibooth.log | tail -20

# 3. Vérifier plugins chargés
grep "Installed plugins" ~/.pibooth/pibooth.log

# 4. Vérifier version Pillow
cd ~/Rasb_booth/pibooth && source venv/bin/activate && pip show Pillow

# 5. Vérifier patch installé
grep "Compatible with Pillow 10+" ~/Rasb_booth/pibooth-picture-template/pibooth_picture_template.py
```

---

## À envoyer pour diagnostic

Lance ces commandes et copie-moi les résultats:

```bash
# LOG 1: Dernières lignes du log
echo "=== LOGS ===" && tail -50 ~/.pibooth/pibooth.log

# LOG 2: Erreurs
echo "=== ERRORS ===" && grep -i error ~/.pibooth/pibooth.log | tail -10

# LOG 3: Plugins
echo "=== PLUGINS ===" && grep "Installed plugins" ~/.pibooth/pibooth.log | tail -1

# LOG 4: Pillow
echo "=== PILLOW ===" && cd ~/Rasb_booth/pibooth && source venv/bin/activate && pip show Pillow | grep Version

# LOG 5: Patch
echo "=== PATCH ===" && grep -c "Compatible with Pillow 10+" ~/Rasb_booth/pibooth-picture-template/pibooth_picture_template.py
```

Avec ces infos, je pourrai identifier exactement ce qui ne va pas.