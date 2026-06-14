# 🚀 Déploiement rapide vers Raspberry Pi

Guide ultra-simple pour transférer les templates vers ton Raspberry Pi (192.168.1.60).

---

## ⚡ Méthode rapide (1 commande)

### Sur Windows (PowerShell)

```powershell
cd "C:\Users\godel\Downloads\pibooth-master (1)\pibooth-master"
.\deploy-templates-scp.ps1
```

Le script va:
1. ✅ Te montrer ce qui sera transféré
2. ✅ Demander confirmation
3. ✅ Transférer tous les fichiers modifiés vers 192.168.1.60
4. ✅ T'afficher les commandes à exécuter sur le Raspberry Pi

---

## 📋 Sur le Raspberry Pi (après le transfert)

### 1. Se connecter en SSH

```bash
ssh lucas@192.168.1.60
```

### 2. Vérifier que les fichiers sont arrivés

```bash
cd ~/Rasb_booth
ls -la pibooth-picture-template/
ls -la install_templates.sh
```

### 3. Installer les templates

```bash
cd ~/Rasb_booth
chmod +x install_templates.sh
./install_templates.sh
```

Le script va:
- Faire un backup de ta config
- Installer le plugin pibooth-picture-template
- Créer le dossier ~/pibooth_templates
- Copier les templates d'exemple
- Configurer pibooth.cfg

### 4. Redémarrer Pibooth

```bash
# Si Pibooth tourne déjà, le tuer
pkill -9 python3

# Relancer
cd ~/Rasb_booth/pibooth
source venv/bin/activate
pibooth
```

### 5. Tester l'interface web

Ouvre ton navigateur sur:
```
http://192.168.1.60:3000/templates
```

Tu devrais voir:
- La page de gestion des templates
- Les 2 templates d'exemple (fancy.xml, pibooth.xml)
- Un bouton "Uploader un template"

---

## 🔍 Vérifications

### Vérifier que le plugin est installé

```bash
cd ~/Rasb_booth/pibooth
source venv/bin/activate
pip list | grep pibooth
```

Tu dois voir:
```
pibooth
pibooth-no-buttons
pibooth-picture-template  ← NOUVEAU !
pibooth-web-interface
```

### Vérifier les logs

```bash
tail -f ~/.pibooth/pibooth.log
```

Cherche dans les logs:
```
[INFO] pibooth-picture-template v1.1.0 loaded
[INFO] Web interface started on http://0.0.0.0:3000
```

---

## ❌ Dépannage rapide

### Script PowerShell refuse de s'exécuter

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Connexion SSH refuse

```bash
# Vérifier que le Raspberry Pi est accessible
ping 192.168.1.60

# Tester SSH
ssh lucas@192.168.1.60
```

### Permission denied sur install_templates.sh

```bash
chmod +x ~/Rasb_booth/install_templates.sh
```

### Module pibooth_web not found après transfert

```bash
cd ~/Rasb_booth/pibooth-web-interface
source ../pibooth/venv/bin/activate
pip install -e .
```

---

## 📝 Résumé ultra-court

### Windows:
```powershell
.\deploy-templates-scp.ps1
```

### Raspberry Pi:
```bash
ssh lucas@192.168.1.60
cd ~/Rasb_booth
./install_templates.sh
cd pibooth && source venv/bin/activate && pibooth
```

### Navigateur:
```
http://192.168.1.60:3000/templates
```

C'est tout ! 🎉