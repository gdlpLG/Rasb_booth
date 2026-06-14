# 🔧 Fix erreur Pillow - FreeTypeFont.getsize

## Problème

```
[ ERROR ] pibooth : 'FreeTypeFont' object has no attribute 'getsize'
```

Cette erreur apparaît quand le plugin `pibooth-picture-template` essaie de calculer la taille du texte avec une version récente de Pillow (10.0+).

---

## Cause

Le plugin utilise l'ancienne API Pillow :
```python
font.getsize(text)  # ❌ Deprecated dans Pillow 10+
```

Au lieu de la nouvelle API :
```python
bbox = font.getbbox(text)  # ✅ Nouvelle méthode
width = bbox[2] - bbox[0]
height = bbox[3] - bbox[1]
```

---

## Solutions

### Solution 1: Downgrade Pillow (RAPIDE)

Installer une version plus ancienne de Pillow qui supporte encore `getsize()` :

```bash
ssh lucas@192.168.1.60
cd ~/Rasb_booth/pibooth
source venv/bin/activate
pip install 'Pillow<10.0.0'
```

Puis redémarrer Pibooth.

### Solution 2: Patcher le plugin (PROPRE)

Modifier le fichier du plugin pour utiliser la nouvelle API.

**Fichier à modifier :**
```
~/Rasb_booth/pibooth-picture-template/pibooth_picture_template.py
```

**Chercher les lignes contenant :**
```python
font.getsize(text)
```

**Remplacer par :**
```python
bbox = font.getbbox(text)
width = bbox[2] - bbox[0]
height = bbox[3] - bbox[1]
```

### Solution 3: Attendre une mise à jour du plugin

Le plugin `pibooth-picture-template` devra être mis à jour pour supporter Pillow 10+.

En attendant, utilise la Solution 1 (downgrade).

---

## Vérifier la version de Pillow

```bash
cd ~/Rasb_booth/pibooth
source venv/bin/activate
pip show Pillow
```

Si tu vois `Version: 10.x.x` ou plus, downgrade vers `9.5.0` :

```bash
pip install 'Pillow==9.5.0'
```

---

## Après le fix

1. **Redémarrer Pibooth :**
   ```bash
   pkill -9 python3
   cd ~/Rasb_booth/pibooth
   source venv/bin/activate
   pibooth
   ```

2. **Prendre une photo de test**

3. **Vérifier les logs :**
   ```bash
   tail -f ~/.pibooth/pibooth.log
   ```

Tu ne devrais plus voir l'erreur `getsize`.

---

## Problème du nom de fichier bizarre

J'ai vu dans tes logs :
```
Diagramme sans nom-Page-.xlm.xml
```

Il y a `.xlm.xml` au lieu de `.xml`.

### Comment corriger

1. **Supprimer ce fichier :**
   ```bash
   rm ~/pibooth_templates/Diagramme\ sans\ nom-Page-.xlm.xml
   ```

2. **Réexporter depuis diagrams.net :**
   - Fichier → Exporter → XML
   - Cocher "Compressed"
   - **Renommer le fichier avant de télécharger** : `mon-template.xml`

3. **Uploader le fichier corrigé**

4. **Activer et redémarrer Pibooth**

---

## Script de fix automatique

```bash
#!/bin/bash
# fix_pillow.sh

echo "🔧 Fix Pillow pour pibooth-picture-template"
echo ""

cd ~/Rasb_booth/pibooth
source venv/bin/activate

echo "📋 Version Pillow actuelle:"
pip show Pillow | grep Version

echo ""
echo "📥 Installation Pillow 9.5.0..."
pip install 'Pillow==9.5.0'

echo ""
echo "✅ Pillow downgrade terminé"
echo ""
echo "🚀 Redémarrez Pibooth:"
echo "   pkill -9 python3"
echo "   cd ~/Rasb_booth/pibooth && source venv/bin/activate && pibooth"
```

Sauvegarder en tant que `fix_pillow.sh`, puis :

```bash
chmod +x fix_pillow.sh
./fix_pillow.sh
```

---

## Notes

- Le downgrade vers Pillow 9.x est **sûr** et n'affectera pas les autres fonctionnalités
- Ce problème touche **tous** les utilisateurs du plugin avec Pillow 10+
- Le plugin devra être mis à jour à terme pour supporter les nouvelles versions de Pillow