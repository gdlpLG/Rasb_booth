# Installation du service Pibooth

Ce guide explique comment installer Pibooth en tant que service système sur le Raspberry Pi pour qu'il démarre automatiquement au boot.

## 1. Prérequis

- Pibooth installé dans `~/Rasb_booth/pibooth`
- Environnement virtuel dans `~/Rasb_booth/pibooth/venv`
- Utilisateur `lucas` (si votre utilisateur est différent, modifiez le fichier `.service`)

## 2. Préparation du fichier service

Le fichier `pibooth.service` est déjà présent à la racine du projet. Voici son contenu pour rappel :

```ini
[Unit]
Description=Pibooth Photobooth Service
After=network.target

[Service]
Type=simple
User=lucas
Group=lucas
WorkingDirectory=/home/lucas/Rasb_booth/pibooth
Environment="PATH=/home/lucas/Rasb_booth/pibooth/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=/home/lucas/Rasb_booth/pibooth/venv/bin/pibooth
Restart=always
RestartSec=5
StandardOutput=append:/home/lucas/.pibooth/pibooth.log
StandardError=append:/home/lucas/.pibooth/pibooth.log

[Install]
WantedBy=multi-user.target
```

## 3. Installation

Exécutez les commandes suivantes sur le Raspberry Pi :

```bash
# Copier le fichier dans le répertoire système
sudo cp ~/Rasb_booth/pibooth/pibooth.service /etc/systemd/system/

# Recharger systemd
sudo systemctl daemon-reload

# Activer le service au démarrage
sudo systemctl enable pibooth.service

# Démarrer le service immédiatement
sudo systemctl start pibooth.service
```

## 4. Commandes utiles

- **Vérifier le statut** : `sudo systemctl status pibooth.service`
- **Arrêter le service** : `sudo systemctl stop pibooth.service`
- **Redémarrer le service** : `sudo systemctl restart pibooth.service`
- **Voir les logs en temps réel** : `tail -f ~/.pibooth/pibooth.log`

## 5. Accès Web

Une fois le service démarré, l'interface web est accessible sur le port 3000 :
`http://<ip-du-raspberry>:3000`

Vous pouvez maintenant consulter les logs directement depuis l'interface web dans l'onglet "Voir les logs".