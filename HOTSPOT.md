# 📡 Configuration du Hotspot WiFi – Mode AP+STA

Ce guide explique comment transformer le Raspberry Pi en **Point d'Accès WiFi** tout en conservant sa connexion internet existante (mode AP+STA).

Cela permet à votre téléphone/tablette de contrôler Pibooth via WiFi **même sans box internet**, tout en laissant le Pi connecté au réseau existant si disponible.

---

## Architecture réseau

```
Internet (optionnel)
    │
    ▼
┌─────────────────────┐
│   Box / Routeur     │
│   (réseau normal)   │
└────────┬────────────┘
         │ wlan0 (client WiFi)
    ┌────▼────────────────┐
    │   Raspberry Pi      │
    │                     │
    │   wlan0 → Internet  │
    │   ap0   → Hotspot   │
    └────┬────────────────┘
         │ ap0 (point d'accès)
    ┌────▼──────────────┐
    │  Téléphone/       │
    │  Tablette         │
    │  → 192.168.4.x    │
    └───────────────────┘
```

Le Pi crée une interface virtuelle `ap0` à partir de `wlan0`, permettant les deux modes simultanément.

---

## 1. Installation automatique

```bash
cd ~/Rasb_booth/pibooth-web-interface/scripts
chmod +x setup_hotspot.sh
sudo ./setup_hotspot.sh
```

Le script installe `hostapd` et `dnsmasq`, configure l'interface virtuelle `ap0`, et démarre le hotspot automatiquement.

### Paramètres par défaut

| Paramètre      | Valeur                |
|----------------|-----------------------|
| **SSID**       | `Pibooth-WiFi`        |
| **Mot de passe** | `piboothconnect`   |
| **IP du Pi**   | `192.168.4.1`         |
| **Plage DHCP** | `192.168.4.10 – .50`  |
| **Port web**   | `3000`                |

---

## 2. Se connecter

1. Sur votre téléphone/tablette, cherchez le réseau WiFi **`Pibooth-WiFi`**
2. Connectez-vous avec le mot de passe : **`piboothconnect`**
3. Ouvrez un navigateur et allez à :

```
http://192.168.4.1:3000
```

---

## 3. Vérifier que tout fonctionne

### Vérifier le hotspot
```bash
# État du service hotspot
sudo systemctl status pibooth-hotspot

# Vérifier l'interface ap0
ip addr show ap0

# Vérifier hostapd
sudo systemctl status hostapd

# Vérifier dnsmasq
sudo systemctl status dnsmasq

# Voir les clients connectés
cat /var/lib/misc/dnsmasq.leases
```

### Vérifier que Pibooth est accessible
```bash
# Depuis le Pi lui-même
curl -s http://192.168.4.1:3000/api/status

# Vérifier le port
sudo ss -tulpn | grep :3000
```

---

## 4. Gestion du hotspot

### Démarrer / Arrêter / Redémarrer
```bash
sudo systemctl start pibooth-hotspot
sudo systemctl stop pibooth-hotspot
sudo systemctl restart pibooth-hotspot
```

### Activer / Désactiver au démarrage
```bash
# Activer (démarrage automatique)
sudo systemctl enable pibooth-hotspot

# Désactiver
sudo systemctl disable pibooth-hotspot
```

### Voir les logs
```bash
sudo journalctl -u pibooth-hotspot -n 30
sudo journalctl -u hostapd -n 20
sudo journalctl -u dnsmasq -n 20
```

---

## 5. Modifier le nom ou le mot de passe

Éditez le fichier de configuration hostapd :

```bash
sudo nano /etc/hostapd/hostapd.conf
```

Modifiez les lignes :
```
ssid=Pibooth-WiFi
wpa_passphrase=piboothconnect
```

Puis redémarrez :
```bash
sudo systemctl restart hostapd
```

---

## 6. Dépannage

### Le réseau Pibooth-WiFi n'apparaît pas
```bash
# Vérifier que ap0 existe
ip link show ap0

# Si ap0 n'existe pas, recréer
sudo iw dev wlan0 interface add ap0 type __ap
sudo ip addr add 192.168.4.1/24 dev ap0
sudo ip link set ap0 up

# Vérifier les erreurs hostapd
sudo journalctl -u hostapd --no-pager -n 50
```

### Le téléphone se connecte mais pas d'accès web
```bash
# Vérifier que dnsmasq tourne
sudo systemctl status dnsmasq

# Vérifier que Pibooth écoute
sudo ss -tulpn | grep :3000

# Tester l'accès local
curl http://192.168.4.1:3000/
```

### Conflit avec NetworkManager
```bash
# Empêcher NM de gérer ap0
sudo nano /etc/NetworkManager/conf.d/unmanaged-ap0.conf
```
Contenu :
```ini
[keyfile]
unmanaged-devices=interface-name:ap0
```
Puis :
```bash
sudo systemctl restart NetworkManager
```

### Le Pi perd sa connexion internet
Le mode AP+STA permet normalement de garder la connexion via `wlan0`. Vérifiez :
```bash
# Connexion internet via wlan0
ping -I wlan0 8.8.8.8

# Route par défaut
ip route show
```

---

## 7. Désinstallation

Pour revenir au mode WiFi normal sans hotspot :

```bash
sudo systemctl stop pibooth-hotspot
sudo systemctl disable pibooth-hotspot
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq
sudo ip link delete ap0
```

Pour désinstaller complètement :
```bash
sudo apt remove --purge hostapd dnsmasq
sudo rm /etc/hostapd/hostapd.conf
sudo rm /etc/dnsmasq.d/pibooth-hotspot.conf
sudo rm /etc/systemd/system/pibooth-hotspot.service
sudo systemctl daemon-reload
```

---

*Dernière mise à jour : 15 juin 2026*