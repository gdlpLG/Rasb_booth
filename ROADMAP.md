# 🚀 Roadmap Pibooth Web - Photobooth sans boutons physiques

## ✅ Ce qui fonctionne actuellement

### Infrastructure de base
- ✅ Pibooth installé sur Raspberry Pi
- ✅ Interface web accessible sur port 3000
- ✅ Plugin `pibooth-no-buttons` : désactive les boutons GPIO
- ✅ Plugin `pibooth-web-interface` : contrôle web complet
- ✅ WebSocket temps réel pour les mises à jour d'état
- ✅ API REST pour les actions (capture, print, choose)
- ✅ Affichage de la dernière photo générée
- ✅ Templates désactivables (mode basique ou avancé)

### Plugins développés
1. **pibooth-no-buttons** v1.0.0
   - Désactive les boutons GPIO
   - Crée des boutons virtuels compatibles Pibooth
   - Évite les erreurs gpiozero

2. **pibooth-web-interface** v1.0.0
   - Serveur Flask + SocketIO
   - Interface HTML/CSS/JS responsive
   - Boutons : Capture, Print, Choose Left/Right
   - Affichage état temps réel
   - Affichage dernière photo

3. **pibooth-picture-template** v1.1.0 (patché)
   - Compatible Pillow 10+
   - Utilise `getbbox()` au lieu de `getsize()`
   - Templates XML personnalisables

### Configuration active
```ini
[WEB]
enable = yes
host = 0.0.0.0
port = 3000
disable_physical_buttons = yes

[PICTURE]
# template = /home/lucas/pibooth_templates/pibooth.xml
```

---

## 🎯 Fonctionnalités à développer

### Priorité 1 : Interface web améliorée

#### 1.1 Prévisualisation temps réel de la caméra
- [ ] Stream vidéo de la caméra dans l'interface web
- [ ] Affichage du cadrage avant la capture
- [ ] Mise à jour temps réel pendant le compte à rebours

**Complexité :** Moyenne  
**Impact :** Fort - permet de cadrer avant de prendre la photo

#### 1.2 Galerie des photos
- [x] Liste des dernières photos prises
- [x] Scroll dans la galerie
- [x] Visualisation en lightbox
- [x] Impression depuis la lightbox
- [ ] Téléchargement individuel
- [ ] Suppression (avec confirmation)
- [ ] Partage (email, QR code)

**Complexité :** Moyenne  
**Impact :** Fort - permet de revoir et récupérer les photos

#### 1.3 Interface tablette/kiosque
- [ ] Mode plein écran
- [ ] Boutons plus gros pour usage tactile
- [ ] Navigation simplifiée
- [ ] Économiseur d'écran avec slideshow

**Complexité :** Faible  
**Impact :** Moyen - meilleure expérience utilisateur

---

### Priorité 2 : Configuration et administration

#### 2.1 Panel d'administration web
- [x] Édition de la config pibooth.cfg via web (`/config`)
- [x] Upload de templates XML (`/templates`)
- [ ] Gestion des dossiers de photos
- [ ] Redémarrage de Pibooth depuis le web
- [x] Visualisation des logs (page Logs)

**Complexité :** Moyenne  
**Impact :** Fort - facilite la maintenance

#### 2.2 Statistiques et monitoring
- [x] Nombre de photos prises (compteurs Pibooth)
- [ ] Graphiques d'utilisation
- [x] État de la caméra (indicateur temps réel)
- [x] Espace disque restant (barre sys-info)
- [x] Température Raspberry Pi (barre sys-info)

**Complexité :** Moyenne  
**Impact :** Moyen - utile pour suivre l'usage

#### 2.3 Multi-langues
- [ ] Français
- [ ] Anglais
- [ ] Autres langues via fichiers JSON
- [ ] Sélection de langue dans l'interface

**Complexité :** Faible  
**Impact :** Moyen - accessibilité internationale

---

### Priorité 3 : Fonctionnalités avancées

#### 3.1 Filtres et effets
- [ ] Filtres en temps réel (noir/blanc, sépia, etc.)
- [ ] Cadres/overlays personnalisables
- [ ] Ajout de stickers
- [ ] Réglages de luminosité/contraste

**Complexité :** Élevée  
**Impact :** Fort - valeur ajoutée créative

#### 3.2 Partage instantané
- [ ] QR code pour télécharger la photo
- [ ] Envoi par email automatique
- [ ] Upload vers réseaux sociaux
- [ ] Impression WiFi directe

**Complexité :** Moyenne à Élevée  
**Impact :** Fort - expérience moderne

#### 3.3 Mode événement
- [ ] Code d'accès pour événements privés
- [ ] Dossiers séparés par événement
- [ ] Branding personnalisable (logo, couleurs)
- [ ] Page de galerie publique dédiée

**Complexité :** Moyenne  
**Impact :** Moyen - usage professionnel

---

### Priorité 4 : Stabilité et performances

#### 4.1 Gestion d'erreurs robuste
- [x] Reconnexion automatique caméra
- [x] Messages d'erreur clairs dans l'interface web (toasts)
- [x] Mode dégradé si composant défaillant (no-buttons, fallback caméra)
- [x] Logs détaillés et traçabilité (page logs + journalctl)

**Complexité :** Moyenne  
**Impact :** Fort - fiabilité

#### 4.2 Optimisation
- [ ] Cache des images miniatures
- [ ] Compression intelligente des photos
- [ ] Nettoyage automatique des anciennes photos
- [ ] Optimisation mémoire Raspberry Pi

**Complexité :** Moyenne  
**Impact :** Moyen - performances

---

## 📋 Prochaines étapes immédiates

### Sprint 1 : Interface utilisateur améliorée (1-2 semaines)
1. Améliorer le design de l'interface web
2. Ajouter la galerie des photos
3. Ajouter le mode tablette/tactile

### Sprint 2 : Administration (1 semaine)
1. Panel d'administration web
2. Édition config via web
3. Upload de templates

### Sprint 3 : Fonctionnalités avancées (2-3 semaines)
1. Prévisualisation caméra temps réel
2. QR code pour téléchargement
3. Filtres de base

---

## 🛠️ Technologies et outils

### Backend
- Python 3.11
- Flask
- Flask-SocketIO
- Pillow 10+
- gPhoto2

### Frontend
- HTML5
- CSS3 (responsive)
- JavaScript vanilla
- Socket.IO client

### Déploiement
- Raspberry Pi 3B+ / 4 / 5
- Raspbian/Debian Bookworm
- Python venv
- SystemD service (`pibooth.service`)
- Hotspot WiFi AP+STA (`pibooth-hotspot.service`)
- Socket.IO embarqué localement (mode hors-ligne)

---

## 📚 Documentation

- [x] Guide d'installation (`TRANSFERT_RASPBERRY.md`)
- [x] Guide hotspot WiFi (`HOTSPOT.md`)
- [x] Guide service systemd (`INSTALL_SERVICE.md`)
- [x] Commandes SCP (`COMMANDES_SCP.md`)
- [ ] Guide utilisateur interface web
- [ ] API documentation
- [ ] Guide création de templates
- [ ] FAQ et troubleshooting complet
- [ ] Guide de contribution

---

## 🎓 Ressources et références

- [Pibooth Documentation](https://pibooth.readthedocs.io/)
- [Flask-SocketIO Documentation](https://flask-socketio.readthedocs.io/)
- [Pillow Documentation](https://pillow.readthedocs.io/)
- [gPhoto2 Documentation](http://www.gphoto.org/doc/manual/)

---

## 💡 Idées futures (backlog)

- Mode GIF animé (4 photos en boucle)
- Mode boomerang
- Reconnaissance faciale pour cadrage auto
- Impression en double (invité + souvenir)
- Mode photomaton (4 photos en strip)
- Intégration imprimante thermique
- Mode slow-motion
- Chromecast pour affichage sur TV
- PWA (Progressive Web App) pour installation mobile
- Mode hors-ligne complet (Socket.IO embarqué ✅, hotspot AP+STA ✅)

---

*Dernière mise à jour : 15 juin 2026*
