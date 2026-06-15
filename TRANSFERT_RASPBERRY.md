# 📡 Transférer les modifications vers le Raspberry Pi

Ce guide explique comment récupérer les dernières modifications sur ton Raspberry Pi.

---

## Méthode 1: Via Git (RECOMMANDÉE)

### Sur ton PC Windows

1. **Push les modifications sur GitHub**

```powershell
cd "C:\Users\godel\Downloads\pibooth-master (1)\pibooth-master"
git push origin main
```

Si tu as une erreur d'authentification, utilise un token GitHub:
- Va sur GitHub.com → Settings → Developer settings → Personal access tokens
- Crée un token avec droits "repo"
- Utilise le token comme mot de passe

### Sur le Raspberry Pi

1. **Se connecter en SSH**

```bash
ssh pi@<ip-du-raspberry>
# Ou depuis PuTTY sur Windows
```

2. **Aller dans le dossier du projet**

```bash
cd ~/Rasb_booth/pibooth-master
```

3. **Récupérer les dernières modifications**

```bash
git pull origin main
```

4. **Installer le système de templates**

```bash
chmod +x install_templates.sh
./install_templates.sh
```

5. **Redémarrer Pibooth**

```bash
cd ~/Rasb_booth/pibooth
source venv/bin/activate
pibooth
```

---

## Méthode 2: Via transfert direct (si pas de GitHub)

### Option A: WinSCP (Interface graphique)

1. **Télécharger WinSCP**: https://winscp.net
2. **Se connecter au Raspberry Pi**:
   - Protocol: SCP
   - Host: IP du Raspberry
   - User: pi
   - Password: ton mot de passe
3. **Naviguer vers** `/home/pi/Rasb_booth/`
4. **Drag & drop** les dossiers modifiés:
   - `pibooth-picture-template/`
   - `pibooth-web-interface/`
   - `install_templates.sh`
   - `TEMPLATES.md`
   - `ROADMAP.md`

### Option B: SCP en ligne de commande

Depuis PowerShell sur Windows:

```powershell
# Transférer le dossier pibooth-picture-template
scp -r "pibooth-picture-template" lucas@raspberrypi:~/Rasb_booth/

# Transférer pibooth-web-interface
scp -r "pibooth-web-interface" lucas@raspberrypi:~/Rasb_booth/

# Transférer les fichiers individuels
scp "install_templates.sh" lucas@raspberrypi:~/Rasb_booth/
scp "TEMPLATES.md" lucas@raspberrypi:~/Rasb_booth/
scp "ROADMAP.md" lucas@raspberrypi:~/Rasb_booth/
scp "pibooth.service" lucas@raspberrypi:~/Rasb_booth/pibooth/
scp "INSTALL_SERVICE.md" lucas@raspberrypi:~/Rasb_booth/pibooth/
```

Puis sur le Raspberry:

```bash
cd ~/Rasb_booth/pibooth-master
chmod +x install_templates.sh
./install_templates.sh
```

---

## Méthode 3: Clonage complet (départ de zéro)

Si tu veux repartir proprement:

### Sur le Raspberry Pi

```bash
# Sauvegarder l'ancienne config
cp ~/.config/pibooth/pibooth.cfg ~/pibooth.cfg.backup

# Sauvegarder les photos
cp -r ~/Pictures/pibooth ~/Pictures/pibooth_backup

# Supprimer l'ancien dossier
rm -rf ~/Rasb_booth

# Cloner le nouveau dépôt
cd ~
mkdir Rasb_booth
cd Rasb_booth
git clone https://github.com/gdlpLG/Rasb_booth.git pibooth-master
cd pibooth-master

# Créer l'environnement virtuel
cd pibooth
python3 -m venv venv
source venv/bin/activate
pip install -e .

# Installer les plugins
cd ../pibooth-no-buttons
pip install -e .

cd ../pibooth-web-interface
pip install -e .

# Installer les templates
cd ..
chmod +x install_templates.sh
./install_templates.sh

# Restaurer l'ancienne config si besoin
cp ~/pibooth.cfg.backup ~/.config/pibooth/pibooth.cfg

# Restaurer les photos
cp -r ~/Pictures/pibooth_backup/* ~/Pictures/pibooth/
```

---

## Vérification après transfert

### 1. Vérifier que les fichiers sont là

```bash
cd ~/Rasb_booth/pibooth-master

# Vérifier le plugin templates
ls -la pibooth-picture-template/

# Vérifier le script d'installation
ls -la install_templates.sh

# Vérifier l'interface web
ls -la pibooth-web-interface/pibooth_web/templates/templates.html
```

### 2. Vérifier l'installation

```bash
cd ~/Rasb_booth/pibooth
source venv/bin/activate

# Vérifier les plugins installés
pip list | grep pibooth
```

Tu devrais voir:
```
pibooth
pibooth-no-buttons
pibooth-picture-template  ← NOUVEAU
pibooth-web-interface
```

### 3. Tester l'interface web

```bash
# Démarrer Pibooth
cd ~/Rasb_booth/pibooth
source venv/bin/activate
pibooth
```

Depuis ton navigateur:
- Accueil: `http://<ip-raspberry>:3000`
- Templates: `http://<ip-raspberry>:3000/templates`

---

## Commandes utiles

### Trouver l'IP du Raspberry Pi

```bash
hostname -I
```

### Redémarrer Pibooth

Si Pibooth tourne déjà:

```bash
# Trouver le processus
ps aux | grep pibooth

# Tuer le processus (remplacer XXXX par le PID)
kill XXXX

# Ou plus brutal
pkill -9 python3

# Relancer
cd ~/Rasb_booth/pibooth
source venv/bin/activate
pibooth
```

### Voir les logs en temps réel

```bash
tail -f ~/.pibooth/pibooth.log
```

### Vérifier l'espace disque

```bash
df -h
```

---

## Résolution de problèmes

### ❌ "Permission denied" sur install_templates.sh

```bash
chmod +x install_templates.sh
```

### ❌ Git pull échoue avec conflit

```bash
# Sauvegarder tes modifications locales
git stash

# Récupérer les modifications distantes
git pull origin main

# Réappliquer tes modifications
git stash pop
```

### ❌ Module 'pibooth_web' not found

```bash
cd ~/Rasb_booth/pibooth-master/pibooth-web-interface
source ../pibooth/venv/bin/activate
pip install -e .
```

### ❌ Port 3000 déjà utilisé

```bash
# Trouver ce qui utilise le port
sudo lsof -i :3000

# Tuer le processus
sudo kill -9 <PID>
```

---

## Synchronisation automatique (bonus)

Si tu veux automatiser la synchronisation:

### Créer un script de sync

```bash
nano ~/sync_from_github.sh
```

Contenu:

```bash
#!/bin/bash
cd ~/Rasb_booth/pibooth-master
git pull origin main
chmod +x install_templates.sh
echo "✅ Synchronisation terminée"
echo "ℹ️  Redémarrez Pibooth pour appliquer les changements"
```

Rendre exécutable:

```bash
chmod +x ~/sync_from_github.sh
```

Utiliser:

```bash
~/sync_from_github.sh
```

---

## Checklist de transfert

- [ ] Push sur GitHub depuis Windows (ou transfert SCP)
- [ ] SSH sur le Raspberry Pi
- [ ] `git pull` ou copie des fichiers
- [ ] `./install_templates.sh`
- [ ] Vérifier `pip list | grep pibooth`
- [ ] Démarrer Pibooth
- [ ] Tester l'interface web
- [ ] Tester un upload de template
- [ ] Prendre une photo de test

---

**Astuce**: Garde une session SSH ouverte avec `tail -f ~/.pibooth/pibooth.log` pendant que tu testes, ça aide énormément pour déboguer !