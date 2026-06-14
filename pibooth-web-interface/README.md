# Pibooth Web Interface

Plugin pour [Pibooth](https://github.com/pibooth/pibooth) qui ajoute une **interface web** permettant de contrôler le photobooth depuis un téléphone, une tablette ou un ordinateur.

Ce plugin **remplace les boutons physiques GPIO** par des boutons virtuels accessibles via un navigateur web.

## Fonctionnalités

- 📷 **Bouton Capture/Démarrer** – déclenche une séquence photo
- 🖨️ **Bouton Imprimer** – lance l'impression
- ⬅️➡️ **Choix gauche/droite** – sélection du nombre de captures
- 📊 **Affichage de l'état** – état courant de Pibooth en temps réel
- 🖼️ **Dernière photo** – affichage de la dernière photo générée
- 🔌 **Mode sans GPIO** – fonctionne sans aucun bouton physique branché

## Architecture

```
pibooth-web-interface/
├── setup.py / setup.cfg     # Installation du plugin
├── install.sh               # Script d'installation automatique
├── start-pibooth-web.sh     # Script de démarrage rapide
├── pibooth_web/
│   ├── __init__.py          # Plugin principal (hooks Pibooth)
│   ├── server.py            # Serveur Flask (API + pages)
│   ├── templates/
│   │   └── index.html       # Interface web
│   └── static/
│       ├── style.css        # Styles
│       └── app.js           # JavaScript client
└── tests/
    └── test_plugin.py       # Tests automatisés
```

## Installation sur Raspberry Pi

### Prérequis

- Raspberry Pi avec Raspberry Pi OS
- Python 3.7+ (recommandé 3.11)
- Pibooth installé

### Étape 1 : Installer Pibooth

```bash
cd ~/Rasb_booth/pibooth
python3 -m venv venv
source venv/bin/activate
pip install -e .
```

### Étape 2 : Installer le plugin web

```bash
cd ~/Rasb_booth/pibooth-web-interface
source ~/Rasb_booth/pibooth/venv/bin/activate
pip install -e .
```

Ou avec le script automatique :

```bash
cd ~/Rasb_booth/pibooth-web-interface
source ~/Rasb_booth/pibooth/venv/bin/activate
bash install.sh
```

### Étape 3 : Vérifier l'installation

```bash
python3 -c "import pibooth_web; print(pibooth_web.__file__)"
python3 -c "import pibooth_web; print(pibooth_web.__version__)"
```

## Configuration

Le plugin ajoute une section `[WEB]` dans le fichier de configuration Pibooth (`~/.config/pibooth/pibooth.cfg`) :

```ini
[WEB]
# Activer l'interface web
enable = yes

# Adresse d'écoute du serveur web
host = 0.0.0.0

# Port du serveur web (défaut : 3000)
port = 3000

# Désactiver les boutons physiques GPIO
disable_physical_buttons = yes
```

### ⚠️ Port par défaut : 3000

Le port par défaut est **3000** (et non 5000). Si vous aviez une ancienne configuration avec `port = 5000`, mettez-la à jour.

## Démarrage

```bash
cd ~/Rasb_booth/pibooth
source venv/bin/activate
pibooth
```

Résultat attendu dans les logs :

```
Physical buttons disabled
Web interface started on http://0.0.0.0:3000
```

Puis ouvrez dans votre navigateur :

```
http://<ip-du-raspberry>:3000
```

Pour trouver l'IP du Raspberry Pi :

```bash
hostname -I
```

## API REST

| Méthode | Endpoint                 | Description                          |
|---------|--------------------------|--------------------------------------|
| POST    | `/api/action/capture`    | Déclencher une capture               |
| POST    | `/api/action/print`      | Lancer une impression                |
| POST    | `/api/action/choose/left`| Choisir l'option gauche              |
| POST    | `/api/action/choose/right`| Choisir l'option droite             |
| GET     | `/api/status`            | Obtenir l'état courant               |
| GET     | `/api/pictures/latest`   | Récupérer la dernière photo (JPEG)   |

### Exemple avec curl

```bash
# Déclencher une capture
curl -X POST http://localhost:3000/api/action/capture

# Voir l'état
curl http://localhost:3000/api/status

# Télécharger la dernière photo
curl -o photo.jpg http://localhost:3000/api/pictures/latest
```

## Dépannage

### Le serveur ne démarre pas

Vérifiez que le port 3000 n'est pas déjà utilisé :

```bash
sudo lsof -i :3000
# ou
sudo netstat -tulpn | grep :3000
```

### Ancien serveur sur le port 5000

Vérifiez qu'il ne reste pas un processus sur l'ancien port :

```bash
sudo lsof -i :5000
```

### Warning gpiozero "NativePinFactoryFallback"

Ce warning est normal quand `disable_physical_buttons = yes`. Il est automatiquement filtré par Pibooth et n'empêche pas le fonctionnement.

### Vérifier quel plugin est chargé

```bash
python3 -c "import pibooth_web; print(pibooth_web.__file__)"
```

Si le chemin ne pointe pas vers votre installation, vérifiez que vous utilisez le bon environnement virtuel.

### La config utilise encore le port 5000

Éditez manuellement le fichier de configuration :

```bash
nano ~/.config/pibooth/pibooth.cfg
```

Changez `port = 5000` en `port = 3000` dans la section `[WEB]`.

## Fonctionnement technique

### Boutons virtuels

Quand `disable_physical_buttons = yes`, Pibooth utilise `VirtualButtonBoard` et `VirtualLEDBoard` (définis dans `pibooth/plugins/virtual_buttons.py`) au lieu des vrais GPIO. Ces objets exposent la même API que `gpiozero.ButtonBoard` et `gpiozero.LEDBoard`.

### Injection d'événements

Le plugin web injecte des événements Pygame `BUTTONDOWN` dans la boucle événementielle de Pibooth, exactement comme le feraient les boutons physiques :

```python
event = pygame.event.Event(BUTTONDOWN, capture=1, printer=0, button=app.buttons.capture)
pygame.event.post(event)
```

### Serveur Flask

Le serveur Flask tourne dans un **thread daemon** séparé pour ne pas bloquer la boucle principale Pygame de Pibooth.

## Licence

MIT – voir le fichier [LICENSE](../LICENSE).