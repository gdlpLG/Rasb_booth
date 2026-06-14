# 📡 Commandes SCP pour déploiement manuel

Copie-colle ces commandes une par une dans PowerShell ou CMD.

---

## 🔧 Depuis Windows (PowerShell ou CMD)

### 1. Aller dans le dossier du projet

```powershell
cd "C:\Users\godel\Downloads\pibooth-master (1)\pibooth-master"
```

---

### 2. Transférer le plugin pibooth-picture-template (GROS DOSSIER)

```powershell
scp -r pibooth-picture-template lucas@192.168.1.60:/home/lucas/Rasb_booth/
```

---

### 3. Transférer les fichiers de l'interface web (4 fichiers)

```powershell
scp pibooth-web-interface\pibooth_web\templates\templates.html lucas@192.168.1.60:/home/lucas/Rasb_booth/pibooth-web-interface/pibooth_web/templates/
```

```powershell
scp pibooth-web-interface\pibooth_web\server.py lucas@192.168.1.60:/home/lucas/Rasb_booth/pibooth-web-interface/pibooth_web/
```

```powershell
scp pibooth-web-interface\pibooth_web\templates\index.html lucas@192.168.1.60:/home/lucas/Rasb_booth/pibooth-web-interface/pibooth_web/templates/
```

```powershell
scp pibooth-web-interface\setup.cfg lucas@192.168.1.60:/home/lucas/Rasb_booth/pibooth-web-interface/
```

---

### 4. Transférer les fichiers de documentation et scripts (4 fichiers)

```powershell
scp install_templates.sh lucas@192.168.1.60:/home/lucas/Rasb_booth/
```

```powershell
scp TEMPLATES.md lucas@192.168.1.60:/home/lucas/Rasb_booth/
```

```powershell
scp ROADMAP.md lucas@192.168.1.60:/home/lucas/Rasb_booth/
```

```powershell
scp TRANSFERT_RASPBERRY.md lucas@192.168.1.60:/home/lucas/Rasb_booth/
```

---

## ✅ Résumé des commandes (9 au total)

```powershell
# 1. Aller dans le dossier
cd "C:\Users\godel\Downloads\pibooth-master (1)\pibooth-master"

# 2. Plugin complet
scp -r pibooth-picture-template lucas@192.168.1.60:/home/lucas/Rasb_booth/

# 3. Interface web (4 fichiers)
scp pibooth-web-interface\pibooth_web\templates\templates.html lucas@192.168.1.60:/home/lucas/Rasb_booth/pibooth-web-interface/pibooth_web/templates/
scp pibooth-web-interface\pibooth_web\server.py lucas@192.168.1.60:/home/lucas/Rasb_booth/pibooth-web-interface/pibooth_web/
scp pibooth-web-interface\pibooth_web\templates\index.html lucas@192.168.1.60:/home/lucas/Rasb_booth/pibooth-web-interface/pibooth_web/templates/
scp pibooth-web-interface\setup.cfg lucas@192.168.1.60:/home/lucas/Rasb_booth/pibooth-web-interface/

# 4. Documentation (4 fichiers)
scp install_templates.sh lucas@192.168.1.60:/home/lucas/Rasb_booth/
scp TEMPLATES.md lucas@192.168.1.60:/home/lucas/Rasb_booth/
scp ROADMAP.md lucas@192.168.1.60:/home/lucas/Rasb_booth/
scp TRANSFERT_RASPBERRY.md lucas@192.168.1.60:/home/lucas/Rasb_booth/
```

---

## 🚀 Sur le Raspberry Pi (après les transferts)

### 1. Se connecter

```bash
ssh lucas@192.168.1.60
```

### 2. Vérifier que tout est arrivé

```bash
cd ~/Rasb_booth
ls -la pibooth-picture-template/
ls -la install_templates.sh
```

### 3. Installer

```bash
chmod +x install_templates.sh
./install_templates.sh
```

### 4. Relancer Pibooth

```bash
pkill -9 python3
cd ~/Rasb_booth/pibooth
source venv/bin/activate
pibooth
```

### 5. Tester

Ouvre ton navigateur:
```
http://192.168.1.60:3000/templates
```

---

## 💡 Astuces

### Si tu veux tout faire d'un coup (copie-colle ce bloc entier)

```powershell
cd "C:\Users\godel\Downloads\pibooth-master (1)\pibooth-master" ; scp -r pibooth-picture-template lucas@192.168.1.60:/home/lucas/Rasb_booth/ ; scp pibooth-web-interface\pibooth_web\templates\templates.html lucas@192.168.1.60:/home/lucas/Rasb_booth/pibooth-web-interface/pibooth_web/templates/ ; scp pibooth-web-interface\pibooth_web\server.py lucas@192.168.1.60:/home/lucas/Rasb_booth/pibooth-web-interface/pibooth_web/ ; scp pibooth-web-interface\pibooth_web\templates\index.html lucas@192.168.1.60:/home/lucas/Rasb_booth/pibooth-web-interface/pibooth_web/templates/ ; scp pibooth-web-interface\setup.cfg lucas@192.168.1.60:/home/lucas/Rasb_booth/pibooth-web-interface/ ; scp install_templates.sh lucas@192.168.1.60:/home/lucas/Rasb_booth/ ; scp TEMPLATES.md lucas@192.168.1.60:/home/lucas/Rasb_booth/ ; scp ROADMAP.md lucas@192.168.1.60:/home/lucas/Rasb_booth/ ; scp TRANSFERT_RASPBERRY.md lucas@192.168.1.60:/home/lucas/Rasb_booth/
```

⚠️ Attention: ça va demander le mot de passe 9 fois (une fois par fichier/dossier)

### Pour éviter de taper le mot de passe 9 fois

Configure une clé SSH (optionnel):

```powershell
# Générer une clé (si tu n'en as pas)
ssh-keygen -t rsa

# Copier la clé sur le Raspberry
type $env:USERPROFILE\.ssh\id_rsa.pub | ssh lucas@192.168.1.60 "cat >> ~/.ssh/authorized_keys"
```

Après ça, tu n'auras plus besoin du mot de passe.

---

## ❌ Dépannage

### "scp: command not found"

Installe OpenSSH Client:
- Paramètres Windows → Applications → Fonctionnalités facultatives
- Cherche "OpenSSH Client"
- Installe

### "Permission denied"

Vérifie que tu peux te connecter:
```powershell
ssh lucas@192.168.1.60
```

### "No such file or directory" sur le Raspberry

Crée les dossiers manquants:
```bash
ssh lucas@192.168.1.60 "mkdir -p ~/Rasb_booth/pibooth-web-interface/pibooth_web/templates"
```

Puis recommence les scp.