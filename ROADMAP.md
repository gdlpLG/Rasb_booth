# 🎉 Rasb_booth - Roadmap & Documentation

**Projet Pibooth contrôlé par interface web sans boutons physiques**

---

## 📋 Table des matières

1. [Travail déjà réalisé](#travail-déjà-réalisé)
2. [Prochaine étape : Templates](#prochaine-étape--templates-personnalisés)
3. [Roadmap complète](#roadmap-complète)
4. [Procédures de sauvegarde](#procédures-de-sauvegarde)

---

## ✅ Travail déjà réalisé

### 🎯 Système de base fonctionnel

#### 1. **Pibooth sans boutons physiques GPIO**
- ✅ Plugin `pibooth-no-buttons` créé et fonctionnel
- ✅ Boutons virtuels compatibles avec la boucle Pygame de Pibooth
- ✅ Configuration `[WEB] disable_physical_buttons = yes`
- ✅ Pas d'erreur GPIO même sans broches connectées

#### 2. **Interface web complète** (port 3000)
- ✅ Page d'accueil avec boutons de capture
  - 1 photo sans timer
  - 1 photo avec timer 10s
  - 4 photos sans timer
  - 4 photos avec timer 10s
- ✅ Galerie photos avec miniatures
- ✅ Lightbox pour visualiser et imprimer
- ✅ Choix automatique de mise en page (left/right)
- ✅ Design responsive mobile-friendly

#### 3. **Fonctionnalités avancées**
- ✅ **Overlay animé pendant traitement**
  - Spinner élégant
  - Messages contextuels selon l'état
  - Désactivation automatique des boutons
  
- ✅ **Gestion déconnexion caméra**
  - Détection automatique toutes les 2 secondes
  - Reconnexion automatique sans redémarrage
  - Indicateur visuel 📷 (vert/rouge)
  - Toast notifications
  - Désactivation boutons si caméra déconnectée

- ✅ **Impression Canon SELPHY CP1300**
  - Impression directe via ipptool (port 60000)
  - Contournement du bug CUPS Raspberry Pi
  - Vérification par code retour (pas de stdout)

#### 4. **Architecture technique**
- ✅ Flask + SocketIO pour le serveur web
- ✅ API REST complète
- ✅ Communication temps réel via WebSocket
- ✅ Monitoring d'état Pibooth (500ms)
- ✅ Structure modulaire par plugins

#### 5. **Configuration et déploiement**
- ✅ Scripts d'installation automatique
- ✅ Configuration par défaut optimisée
- ✅ Port 3000 standardisé partout
- ✅ Environnement virtuel Python
- ✅ Documentation complète

---

## 🎨 Prochaine étape : Templates personnalisés

### Objectif
Permettre l'ajout de cadres, logos et textes personnalisés sur les photos finales via une interface web.

### Plan d'implémentation (PRIORITÉ 1)

#### Phase 1 : Installation sécurisée du plugin
**Durée estimée : 30 min**

```bash
# 1. Sauvegarde de la config actuelle
cp ~/.config/pibooth/pibooth.cfg ~/.config/pibooth/pibooth.cfg.backup

# 2. Installation du plugin
cd ~/Rasb_booth/pibooth
source venv/bin/activate
pip install pibooth-picture-template

# 3. Test de démarrage
pibooth --version
# Si erreur → restaurer : cp ~/.config/pibooth/pibooth.cfg.backup ~/.config/pibooth/pibooth.cfg
```

#### Phase 2 : Configuration de base
**Durée estimée : 15 min**

Ajouter dans `~/.config/pibooth/pibooth.cfg` :

```ini
[PICTURE]
# Templates (désactivés par défaut)
template_1 = 
template_4 = 
template_mode = overlay
```

**Tests :**
- ✅ Pibooth démarre sans erreur
- ✅ Photos 1 et 4 sans template fonctionnent
- ✅ Pas de changement de comportement

#### Phase 3 : Structure des fichiers
**Durée estimée : 10 min**

```bash
# Créer dossiers pour templates
mkdir -p ~/pibooth_templates/single
mkdir -p ~/pibooth_templates/quad
mkdir -p ~/pibooth_templates/preview

# Permissions
chmod 755 ~/pibooth_templates
chmod 755 ~/pibooth_templates/*
```

#### Phase 4 : Test avec templates par défaut
**Durée estimée : 30 min**

1. Créer 2 templates de test simples (PNG transparent)
2. Configurer les chemins dans pibooth.cfg
3. Tester capture 1 photo avec template
4. Tester capture 4 photos avec template
5. Vérifier l'impression

#### Phase 5 : Interface web de gestion
**Durée estimée : 3-4 heures**

**Page `/templates` avec :**
- Liste des templates disponibles (single/quad)
- Upload de nouveaux templates
- Prévisualisation
- Activation/désactivation
- Suppression
- Téléchargement

**API REST nécessaire :**
```
GET    /api/templates/list
POST   /api/templates/upload
POST   /api/templates/activate
DELETE /api/templates/:id
GET    /api/templates/preview/:id
GET    /api/templates/download/:id
```

**Validation upload :**
- Format : PNG uniquement
- Transparence : canal alpha requis
- Dimensions : selon résolution configurée
- Taille max : 10 MB

#### Phase 6 : Documentation utilisateur
**Durée estimée : 1 heure**

Créer `TEMPLATES.md` avec :
- Comment créer un template (guide Photoshop/GIMP)
- Dimensions recommandées
- Bonnes pratiques
- Exemples de templates

---

## 🗺️ Roadmap complète

### 🔴 Priorité 1 : Templates (EN COURS)
**Statut :** Planifié  
**Temps estimé :** 6 heures  
**Dépendances :** Aucune

- [ ] Installation plugin pibooth-picture-template
- [ ] Configuration de base
- [ ] Tests fonctionnels
- [ ] Interface web de gestion
- [ ] Documentation

---

### 🟠 Priorité 2 : Service systemd
**Statut :** À planifier  
**Temps estimé :** 2 heures  
**Dépendances :** Aucune

#### Objectif
Lancer Pibooth automatiquement au démarrage du Raspberry Pi comme service système.

#### Tâches
- [ ] Créer `/etc/systemd/system/pibooth.service`
- [ ] Configurer auto-restart en cas de crash
- [ ] Logs dans journald
- [ ] Commandes : `systemctl start/stop/status pibooth`
- [ ] Activer au démarrage : `systemctl enable pibooth`

**Avantages :**
- Démarre automatiquement au boot
- Redémarre automatiquement si crash
- Gestion professionnelle du service
- Logs centralisés

---

### 🟠 Priorité 3 : Mode Hotspot WiFi automatique
**Statut :** À planifier  
**Temps estimé :** 4 heures  
**Dépendances :** Aucune

#### Objectif
Créer automatiquement un hotspot WiFi si aucun réseau n'est disponible.

#### Comportement souhaité
- **Si réseau disponible** → Se connecte normalement, utilise son IP
- **Si pas de réseau** → Crée un hotspot "Rasb_Booth" ouvert
  - SSID : `Rasb_Booth`
  - Pas de mot de passe
  - IP fixe : `192.168.50.1`
  - Interface web accessible sur `http://192.168.50.1:3000`

#### Tâches
- [ ] Installer `hostapd` et `dnsmasq`
- [ ] Script de détection réseau
- [ ] Configuration hotspot
- [ ] Script de bascule automatique
- [ ] Intégrer au service systemd
- [ ] Page web avec QR code pour connexion facile

---

### 🟡 Priorité 4 : Page Logs
**Statut :** À planifier  
**Temps estimé :** 2 heures  
**Dépendances :** Aucune

#### Objectif
Visualiser les logs Pibooth en temps réel depuis l'interface web.

#### Tâches
- [ ] Page `/logs` dans interface web
- [ ] API `GET /api/logs` (dernières 500 lignes)
- [ ] WebSocket pour logs temps réel
- [ ] Filtres : ERROR, WARNING, INFO, DEBUG
- [ ] Bouton "Effacer les logs"
- [ ] Télécharger les logs (fichier .txt)

**Utilité :**
- Diagnostic à distance
- Pas besoin de SSH
- Utile pour le support

---

### 🟡 Priorité 5 : Page Configuration
**Statut :** À planifier  
**Temps estimé :** 3 heures  
**Dépendances :** Aucune

#### Objectif
Modifier la configuration Pibooth depuis l'interface web.

#### Tâches
- [ ] Page `/config` dans interface web
- [ ] Afficher `~/.config/pibooth/pibooth.cfg`
- [ ] Formulaire pour éditer les paramètres principaux :
  - Textes d'interface
  - Résolution photos
  - ISO caméra
  - Délais/timers
  - Chemins des dossiers
- [ ] Validation des valeurs
- [ ] Sauvegarde automatique
- [ ] Backup avant modification
- [ ] Bouton "Restaurer par défaut"
- [ ] Redémarrage Pibooth si nécessaire

**Sections importantes :**
- `[GENERAL]` : Langue, nom du photobooth
- `[CAMERA]` : ISO, résolution
- `[PICTURE]` : Nombre de captures, orientation
- `[PRINTER]` : Configuration impression
- `[WEB]` : Port, host

---

### 🟢 Fonctionnalités futures (Nice to have)

#### 6. Galerie avancée
- [ ] Filtrage par date
- [ ] Recherche
- [ ] Export ZIP multiple
- [ ] Partage par email/QR code

#### 7. Statistiques
- [ ] Nombre de photos prises
- [ ] Photos imprimées
- [ ] Graphiques d'utilisation
- [ ] Temps moyen par session

#### 8. Mode événement
- [ ] Timer global (ex: événement de 4h)
- [ ] Limite de photos
- [ ] Message de fin d'événement

#### 9. Prévisualisation live
- [ ] Stream caméra sur la page web
- [ ] Ajustement cadrage à distance

#### 10. Multi-langues
- [ ] Interface web en français/anglais
- [ ] Détection automatique

---

## 🛡️ Procédures de sauvegarde

### Avant toute modification importante

```bash
# 1. Sauvegarder la configuration
cp ~/.config/pibooth/pibooth.cfg ~/.config/pibooth/pibooth.cfg.backup.$(date +%Y%m%d_%H%M%S)

# 2. Lister les packages installés
pip freeze > ~/pip_freeze_backup_$(date +%Y%m%d_%H%M%S).txt

# 3. Sauvegarder le code
cd ~/Rasb_booth
git status
git add .
git commit -m "Backup avant modifications"
git push origin main

# 4. Créer un snapshot SD (si possible)
# Via Raspberry Pi Imager ou dd sur un autre PC
```

### En cas de problème

#### Restaurer la configuration
```bash
cp ~/.config/pibooth/pibooth.cfg.backup ~/.config/pibooth/pibooth.cfg
```

#### Désinstaller un plugin problématique
```bash
cd ~/Rasb_booth/pibooth
source venv/bin/activate
pip uninstall pibooth-picture-template
```

#### Restaurer version précédente du code
```bash
cd ~/Rasb_booth
git log --oneline  # Voir les commits
git reset --hard <commit-hash>  # Revenir à un commit
git push origin main --force  # Forcer la mise à jour
```

#### Réinstaller proprement
```bash
cd ~/Rasb_booth
rm -rf pibooth/venv
python3 -m venv pibooth/venv
source pibooth/venv/bin/activate
cd pibooth && pip install -e .
cd ../pibooth-web-interface && pip install -e .
cd ../pibooth-no-buttons && pip install -e .
```

---

## 📊 Estimation globale

| Priorité | Fonctionnalité | Temps estimé | Difficulté |
|----------|----------------|--------------|------------|
| 🔴 P1 | Templates | 6h | Moyenne |
| 🟠 P2 | Service systemd | 2h | Facile |
| 🟠 P3 | Hotspot WiFi | 4h | Moyenne |
| 🟡 P4 | Page Logs | 2h | Facile |
| 🟡 P5 | Page Config | 3h | Moyenne |
| 🟢 P6+ | Fonctionnalités futures | 10h+ | Variable |

**Total priorités 1-5 :** ~17 heures  
**Total avec futures :** ~27 heures

---

## 🎯 Objectif final

Un photobooth Raspberry Pi **100% autonome** :
- ✅ Contrôlé par interface web élégante
- ✅ Sans boutons physiques
- ✅ Templates personnalisables
- ✅ Logs et config accessibles via web
- ✅ Hotspot WiFi intégré (pas besoin de réseau)
- ✅ Démarre automatiquement
- ✅ Robuste aux déconnexions caméra
- ✅ Impression directe Canon SELPHY

---

## 📝 Notes importantes

### Configuration actuelle
- **Port web :** 3000
- **Chemin config :** `~/.config/pibooth/pibooth.cfg`
- **Dossier photos :** `~/Pictures/pibooth/`
- **Venv Python :** `~/Rasb_booth/pibooth/venv/`

### Commandes utiles
```bash
# Démarrer Pibooth
cd ~/Rasb_booth/pibooth
source venv/bin/activate
pibooth

# Voir les logs
tail -f ~/.pibooth/pibooth.log

# Vérifier le port web
sudo lsof -i :3000

# État de la caméra
gphoto2 --auto-detect

# Imprimante
lpstat -p -d
```

---

**Dernière mise à jour :** 2026-06-14  
**Version :** 1.0  
**Statut projet :** En développement actif 🚀