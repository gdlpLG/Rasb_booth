# 🎨 Guide des Templates Pibooth

Ce document explique comment utiliser et créer des templates personnalisés pour vos photos Pibooth.

---

## 📋 Table des matières

1. [Qu'est-ce qu'un template ?](#quest-ce-quun-template)
2. [Installation](#installation)
3. [Utilisation de l'interface web](#utilisation-de-linterface-web)
4. [Créer un template avec diagrams.net](#créer-un-template-avec-diagramsnet)
5. [Templates d'exemple](#templates-dexemple)
6. [Dépannage](#dépannage)

---

## Qu'est-ce qu'un template ?

Un template Pibooth est un **fichier XML** créé avec [diagrams.net](https://app.diagrams.net) qui définit:

- **Position et taille des photos** (1 à 4 photos)
- **Position et taille des textes** (footer, légendes)
- **Images de fond ou overlays**
- **Mise en page portrait et/ou paysage**

Le plugin **pibooth-picture-template** permet à Pibooth d'utiliser ces templates pour générer des photos avec une mise en page professionnelle.

---

## Installation

### Méthode automatique (recommandée)

```bash
cd ~/Rasb_booth/pibooth-master
./install_templates.sh
```

Le script va:
- ✅ Installer le plugin pibooth-picture-template
- ✅ Créer le dossier `~/pibooth_templates`
- ✅ Copier les templates d'exemple
- ✅ Configurer pibooth.cfg
- ✅ Faire un backup de votre configuration

### Vérification

Après installation, démarrez Pibooth et vérifiez les logs:

```bash
cd ~/Rasb_booth/pibooth
source venv/bin/activate
pibooth
```

Vous devriez voir dans les logs:
```
[INFO] pibooth-picture-template v1.1.0 loaded
```

---

## Utilisation de l'interface web

### Accéder à la gestion des templates

1. Ouvrez l'interface web: `http://<ip-raspberry>:3000`
2. Cliquez sur **"🎨 Gérer les templates"**

### Uploader un template

1. Cliquez sur **"Choisir un fichier"**
2. Sélectionnez votre fichier `.xml`
3. Cliquez sur **"Uploader le template"**

### Activer un template

1. Dans la liste des templates, cliquez sur **"Activer"**
2. Le template est maintenant utilisé pour toutes les nouvelles photos
3. L'interface affiche ✅ à côté du template actif

### Désactiver les templates

Pour revenir à la mise en page par défaut de Pibooth:

1. Supprimez tous les templates **OU**
2. Éditez `~/.config/pibooth/pibooth.cfg` et mettez:
   ```ini
   [PICTURE]
   template = 
   ```

---

## Créer un template avec diagrams.net

### Étape 1: Ouvrir diagrams.net

Allez sur [https://app.diagrams.net](https://app.diagrams.net)

### Étape 2: Créer un nouveau diagramme

1. **Create New Diagram**
2. Choisissez **"Blank Diagram"**
3. Donnez un nom descriptif (ex: `mon_template_4photos`)

### Étape 3: Définir la taille de la page

1. Clic droit sur la page → **"Page Setup"**
2. Choisir **"Custom"** 
3. Définir les dimensions en **inches** (pouces):
   - **4x6 inches** → format photo standard
   - **6x4 inches** → format paysage
4. Cliquer **"Apply"**

💡 **Important**: 1 inch = 2.54 cm

### Étape 4: Définir la résolution (DPI)

1. Clic droit sur la page → **"Edit Data"**
2. Ajouter une propriété **"dpi"**
3. Valeur recommandée: **600** (haute qualité)
   - 300 = qualité standard
   - 600 = haute qualité (recommandé)
   - 1200 = très haute qualité (fichiers lourds)

### Étape 5: Placer les zones de photos

1. Insérer des **rectangles** depuis la barre latérale
2. Redimensionner et positionner selon votre mise en page
3. **Numéroter les rectangles** de 1 à 4:
   - Double-clic sur le rectangle
   - Taper le numéro (1, 2, 3 ou 4)

📸 **Règles importantes**:
- Les numéros définissent **l'ordre des photos**
- Photo 1 = première capture
- Photo 4 = quatrième capture
- Vous pouvez en mettre **1, 2, 3 ou 4 maximum**
- Les couleurs sont juste visuelles (non imprimées)

### Étape 6: Ajouter des zones de texte (optionnel)

1. Insérer des **Text boxes** depuis la barre latérale
2. Les nommer:
   - **"footer_text1"** → texte principal
   - **"footer_text2"** → texte secondaire
3. Redimensionner et positionner

Le texte configuré dans pibooth.cfg sera affiché dans ces zones.

### Étape 7: Ajouter des images de fond (optionnel)

1. **Insert** → **Image**
2. Uploader votre image (PNG, JPG)
3. Clic droit → **"To back"** pour mettre en arrière-plan

💡 Utilisez des **PNG transparents** pour des overlays (cadres, logos).

### Étape 8: Créer plusieurs mises en page

Un seul fichier XML peut contenir plusieurs mises en page:

1. Cliquez sur **"+"** en bas pour ajouter une page
2. Créez une mise en page différente (ex: portrait vs paysage)
3. Pibooth choisira automatiquement la bonne page selon:
   - Le nombre de photos demandé (1 ou 4)
   - L'orientation de la caméra

### Étape 9: Exporter en XML

1. **File** → **Export as** → **XML**
2. ✅ **Cochez "Compressed"** pour un fichier plus léger
3. Cliquez **"Export"**
4. Sauvegardez le fichier `.xml`

### Étape 10: Uploader via l'interface web

1. Allez sur `http://<ip-raspberry>:3000/templates`
2. Uploadez votre fichier XML
3. Activez-le
4. Testez en prenant une photo !

---

## Templates d'exemple

Deux templates sont fournis dans `~/pibooth_templates`:

### 📄 `pibooth.xml`

Template simple et épuré:
- 1 photo: centré
- 4 photos: grille 2x2
- Portrait et paysage disponibles

### 🎨 `fancy.xml`

Template élégant avec cadres:
- Designs artistiques
- Bordures décoratives
- Multiples variantes

### Tester les templates

```bash
cd ~/Rasb_booth/pibooth
source venv/bin/activate
pibooth
```

Prenez une photo et vérifiez le résultat dans `~/Pictures/pibooth/`.

---

## Cas d'usage

### Template avec logo d'entreprise

1. Créez un PNG transparent avec votre logo
2. Dans diagrams.net:
   - Ajoutez le logo en haut ou en coin
   - Placez les zones photos autour
3. Exportez et uploadez

### Template symétrique (double impression)

Si vous voulez imprimer 2 copies identiques sur une feuille:

1. Créez une mise en page avec 4 photos
2. Dupliquez les 4 rectangles
3. Numérotez les copies: 1, 2, 3, 4, 1, 2, 3, 4
4. Pibooth placera les mêmes photos 2 fois

### Template événement

Ajoutez du texte personnalisé:

```ini
[PICTURE]
footer_text1 = Mariage de Marie & Jean
footer_text2 = 14 Juin 2026
```

Le texte apparaîtra automatiquement dans les zones définies.

---

## Dépannage

### ❌ "Template file not found"

**Cause**: Le chemin dans pibooth.cfg est incorrect.

**Solution**:
```bash
# Vérifier que le fichier existe
ls -l ~/pibooth_templates/*.xml

# Vérifier la config
cat ~/.config/pibooth/pibooth.cfg | grep template

# Réactiver via l'interface web
```

### ❌ "TemplateParserError"

**Cause**: Le fichier XML est corrompu ou mal formaté.

**Solutions**:
1. Ré-exportez depuis diagrams.net
2. Vérifiez que vous avez bien choisi **"XML"** (pas SVG, PDF, etc.)
3. Vérifiez que le fichier n'est pas vide

### ❌ Photos mal positionnées

**Cause**: Dimensions ou résolution incorrectes.

**Solutions**:
1. Vérifiez le DPI configuré (600 recommandé)
2. Vérifiez les dimensions de la page (4x6 inches standard)
3. Vérifiez que les rectangles sont bien numérotés 1-4

### ❌ "No template found for X captures in Y orientation"

**Cause**: Le template ne contient pas de page pour ce cas.

**Solutions**:
1. Ajoutez une page dans diagrams.net pour cette configuration
2. Ou désactivez le template pour utiliser la mise en page par défaut

### 🔍 Logs utiles

Pour déboguer, regardez les logs Pibooth:

```bash
tail -f ~/.pibooth/pibooth.log
```

Cherchez les lignes:
```
[INFO] Parsing pictures template file: ...
[INFO] Template found for X captures in Y orientation
```

---

## Configuration avancée

### Désactiver temporairement les templates

```ini
[PICTURE]
template = 
```

### Forcer une orientation

```ini
[PICTURE]
orientation = portrait  # ou landscape
```

### Changer la résolution

Dans diagrams.net → Edit Data → dpi:
- 300 = standard
- 600 = haute qualité (recommandé)
- 1200 = très haute qualité

---

## Ressources

- **Créer des templates**: [https://app.diagrams.net](https://app.diagrams.net)
- **Documentation officielle**: [pibooth-picture-template](https://github.com/pibooth/pibooth-picture-template)
- **Templates d'exemple**: `~/pibooth_templates/`
- **Interface web**: `http://<ip-raspberry>:3000/templates`

---

## Aide et support

En cas de problème:

1. Vérifiez les logs: `tail -f ~/.pibooth/pibooth.log`
2. Testez avec les templates d'exemple fournis
3. Vérifiez que le plugin est bien installé: `pip list | grep pibooth-picture-template`
4. Restaurez la config: `cp ~/.config/pibooth/pibooth.cfg.backup.* ~/.config/pibooth/pibooth.cfg`

---

**Dernière mise à jour**: 2026-06-14  
**Version**: 1.0