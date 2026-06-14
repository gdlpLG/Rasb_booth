# ❓ FAQ Templates Pibooth

Questions fréquentes sur le système de templates.

---

## 🔴 J'ai activé un template mais Pibooth utilise toujours l'ancien

### Problème

Après avoir activé un template via l'interface web, Pibooth continue d'utiliser l'ancien template.

### Cause

Pibooth charge le template **au démarrage**. Il ne recharge pas automatiquement la configuration pendant son exécution.

### Solution

**Tu DOIS redémarrer Pibooth après avoir activé un template.**

```bash
# 1. Se connecter en SSH
ssh lucas@192.168.1.60

# 2. Tuer Pibooth
pkill -9 python3

# 3. Relancer Pibooth
cd ~/Rasb_booth/pibooth
source venv/bin/activate
pibooth
```

### Alternative rapide (1 commande)

```bash
ssh lucas@192.168.1.60 "pkill -9 python3 && cd ~/Rasb_booth/pibooth && source venv/bin/activate && pibooth"
```

---

## 🔍 Comment vérifier quel template est actif ?

### Dans les logs Pibooth

```bash
tail -f ~/.pibooth/pibooth.log
```

Cherche la ligne:
```
[ INFO ] pibooth : Parsing pictures template file: /home/lucas/pibooth_templates/ton-template.xml
```

### Dans la config

```bash
cat ~/.config/pibooth/pibooth.cfg | grep template
```

Tu devrais voir:
```
template = /home/lucas/pibooth_templates/fancy.xml
```

### Dans l'interface web

Va sur `http://192.168.1.60:3000/templates`

Le template actif a une coche verte ✅ et une bordure verte.

---

## 📤 Où vont les templates uploadés ?

Les templates uploadés via l'interface web sont stockés dans:

```
~/pibooth_templates/
```

Par exemple:
```
/home/lucas/pibooth_templates/
├── fancy.xml
├── pibooth.xml
└── mon-custom.xml
```

---

## 🎨 Comment créer un template personnalisé ?

### 1. Aller sur diagrams.net

https://app.diagrams.net

### 2. Créer une nouvelle page

- Fichier → Nouveau
- Page vide
- Taille: 4x6 inches (format photo standard)

### 3. Ajouter des rectangles numérotés

- Ajouter des rectangles pour les photos
- Les numéroter 1, 2, 3, 4 (dans l'ordre de capture)
- Pibooth remplacera ces rectangles par les vraies photos

### 4. (Optionnel) Ajouter du texte et des images

- Zones de texte pour titre, date, etc.
- Images pour logo, décorations

### 5. Exporter en XML

- Fichier → Exporter → XML
- Cocher "Compressed"
- Télécharger le fichier

### 6. Uploader via l'interface web

- `http://192.168.1.60:3000/templates`
- Cliquer "Uploader le template"
- Choisir ton fichier XML
- Cliquer "Activer"
- **Redémarrer Pibooth**

**Guide complet:** Voir `TEMPLATES.md`

---

## ❌ Mon template ne s'affiche pas dans la liste

### Vérifications

1. **Le fichier est-il bien dans le bon dossier ?**

```bash
ls -la ~/pibooth_templates/
```

2. **Le fichier est-il bien un .xml ?**

```bash
file ~/pibooth_templates/ton-fichier.xml
```

Tu dois voir: `XML document text`

3. **Les permissions sont-elles correctes ?**

```bash
chmod 644 ~/pibooth_templates/*.xml
```

4. **Rafraîchir la page web**

Appuie sur F5 dans ton navigateur.

---

## 🗑️ Comment supprimer un template ?

### Via l'interface web

1. `http://192.168.1.60:3000/templates`
2. Cliquer sur "Supprimer" à côté du template
3. Confirmer

### En ligne de commande

```bash
rm ~/pibooth_templates/nom-du-template.xml
```

⚠️ **Attention:** Tu ne peux pas supprimer le template actuellement actif.

---

## 🔄 Le template actif a une erreur, comment revenir à l'ancien ?

### Solution rapide

Activer un autre template via l'interface web, puis redémarrer Pibooth.

### Solution manuelle

1. **Éditer la config:**

```bash
nano ~/.config/pibooth/pibooth.cfg
```

2. **Changer la ligne `template`:**

```ini
[PICTURE]
template = /home/lucas/pibooth_templates/pibooth.xml
```

3. **Sauvegarder** (Ctrl+O, Enter, Ctrl+X)

4. **Redémarrer Pibooth:**

```bash
pkill -9 python3
cd ~/Rasb_booth/pibooth
source venv/bin/activate
pibooth
```

---

## 📊 Combien de photos peut contenir un template ?

Un fichier XML peut contenir **plusieurs pages**, chacune avec 1, 2, 3 ou 4 photos.

Exemple:
```
fancy.xml
├── Page-1: 1 photo
├── Page-2: 2 photos
├── Page-3: 3 photos
└── Page-4: 4 photos
```

Quand l'utilisateur choisit de prendre 2 photos, Pibooth utilisera automatiquement la page "Page-2".

---

## 🖼️ Quels formats d'images puis-je ajouter au template ?

Dans diagrams.net, tu peux ajouter:

- PNG
- JPEG
- SVG
- GIF

Ces images seront **intégrées** dans le XML exporté.

Utilise des images légères pour garder un XML petit.

---

## 🔧 Le plugin pibooth-picture-template n'est pas chargé

### Vérifier l'installation

```bash
cd ~/Rasb_booth/pibooth
source venv/bin/activate
pip list | grep pibooth-picture-template
```

### Si absent, l'installer

```bash
cd ~/Rasb_booth/pibooth-picture-template
pip install -e .
```

### Vérifier les logs

```bash
tail -f ~/.pibooth/pibooth.log
```

Cherche:
```
[ INFO ] pibooth : pibooth-picture-template v1.1.0 loaded
```

---

## 💾 Sauvegarder mes templates personnalisés

### Copier depuis le Raspberry Pi vers Windows

```powershell
scp lucas@192.168.1.60:~/pibooth_templates/*.xml "C:\Users\godel\Documents\Pibooth Templates\"
```

### Restaurer vers le Raspberry Pi

```powershell
scp "C:\Users\godel\Documents\Pibooth Templates\*.xml" lucas@192.168.1.60:~/pibooth_templates/
```

---

## 📝 Tester un template rapidement

### Sans redémarrer Pibooth (pour design uniquement)

1. Crée ton template sur diagrams.net
2. Exporte en PNG (pas XML)
3. Vérifie visuellement le design
4. Quand c'est bon, exporte en XML
5. Upload et active via l'interface web
6. Redémarre Pibooth
7. Prends une photo de test

---

## 🎯 Résumé du workflow complet

1. **Créer:** Template sur diagrams.net
2. **Exporter:** Fichier XML
3. **Uploader:** Via `http://192.168.1.60:3000/templates`
4. **Activer:** Cliquer sur "Activer"
5. **Redémarrer:** `pkill -9 python3 && cd ~/Rasb_booth/pibooth && source venv/bin/activate && pibooth`
6. **Tester:** Prendre une photo
7. **Ajuster:** Si besoin, retourner à l'étape 1

---

## 📞 Aide supplémentaire

- **Documentation complète:** `TEMPLATES.md`
- **Guide de transfert:** `COMMANDES_SCP.md`
- **Roadmap:** `ROADMAP.md`

Si tu as d'autres questions, ajoute-les ici !