#!/bin/bash

# =============================================================================
# Pibooth Hotspot WiFi — Mode AP+STA (Access Point + Station simultané)
# =============================================================================
# Ce script configure le Raspberry Pi pour :
#   - Créer un hotspot WiFi permanent (ap0) → contrôle Pibooth depuis téléphone
#   - Garder la connexion WiFi normale (wlan0) → accès internet si disponible
#
# Compatible : Raspberry Pi 3B+, 4, 5 — Raspbian Bookworm
#
# Usage :
#   sudo bash setup_hotspot.sh
#
# Après exécution :
#   - Le Pi crée le réseau "Pibooth-WiFi" (mot de passe: piboothconnect)
#   - Interface web accessible sur http://192.168.4.1:3000
#   - Le Pi peut aussi se connecter à un WiFi normal pour internet
# =============================================================================

set -e

# --- Configuration ---
SSID="Pibooth-WiFi"
PASSWORD="piboothconnect"
AP_IP="192.168.4.1"
AP_NETMASK="255.255.255.0"
AP_DHCP_START="192.168.4.10"
AP_DHCP_END="192.168.4.50"
AP_CHANNEL="6"
AP_INTERFACE="ap0"
WIFI_INTERFACE="wlan0"

# --- Couleurs ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=======================================================${NC}"
echo -e "${GREEN}  🔧 Configuration Hotspot WiFi Pibooth (AP+STA)${NC}"
echo -e "${GREEN}=======================================================${NC}"

# --- Vérifier qu'on est root ---
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Ce script doit être lancé avec sudo${NC}"
    exit 1
fi

# --- Vérifier que wlan0 existe ---
if ! iw dev | grep -q "$WIFI_INTERFACE"; then
    echo -e "${RED}❌ Interface $WIFI_INTERFACE non trouvée${NC}"
    exit 1
fi

# --- Supprimer toute ancienne connexion NetworkManager "Pibooth-WiFi" ---
echo -e "${YELLOW}🧹 Nettoyage des anciennes configurations...${NC}"
nmcli connection delete "$SSID" 2>/dev/null || true

# --- Vérifier si le chip WiFi supporte AP+STA ---
echo -e "${YELLOW}📡 Vérification du support AP+STA...${NC}"
PHY=$(iw dev "$WIFI_INTERFACE" info | grep wiphy | awk '{print $2}')
COMBO=$(iw phy "phy${PHY}" info 2>/dev/null | grep -A 20 "valid interface combinations" || true)
if echo "$COMBO" | grep -q "AP"; then
    echo -e "${GREEN}  ✅ Le chip WiFi supporte le mode AP${NC}"
else
    echo -e "${YELLOW}  ⚠️  Impossible de confirmer le support AP+STA.${NC}"
    echo -e "${YELLOW}     On tente quand même (fonctionne sur la plupart des Pi)${NC}"
fi

# --- Installer les paquets nécessaires ---
echo -e "${YELLOW}📦 Installation de hostapd et dnsmasq...${NC}"
apt-get update -qq
apt-get install -y -qq hostapd dnsmasq iptables

# --- Arrêter les services pendant la configuration ---
systemctl stop hostapd 2>/dev/null || true
systemctl stop dnsmasq 2>/dev/null || true

# --- Supprimer l'ancienne interface ap0 si elle existe ---
iw dev "$AP_INTERFACE" del 2>/dev/null || true

# --- Créer l'interface virtuelle ap0 ---
echo -e "${YELLOW}📡 Création de l'interface virtuelle $AP_INTERFACE...${NC}"
iw dev "$WIFI_INTERFACE" interface add "$AP_INTERFACE" type __ap
sleep 1

# --- Empêcher NetworkManager de gérer ap0 ---
echo -e "${YELLOW}🔧 Configuration de NetworkManager pour ignorer $AP_INTERFACE...${NC}"
mkdir -p /etc/NetworkManager/conf.d
cat > /etc/NetworkManager/conf.d/unmanaged-ap0.conf << EOF
[keyfile]
unmanaged-devices=interface-name:$AP_INTERFACE
EOF
systemctl reload NetworkManager 2>/dev/null || systemctl restart NetworkManager 2>/dev/null || true

# Donner une adresse MAC légèrement différente
ORIGINAL_MAC=$(cat /sys/class/net/"$WIFI_INTERFACE"/address)
# Modifier le dernier octet pour éviter les conflits
AP_MAC=$(echo "$ORIGINAL_MAC" | sed 's/..$/a0/')
ip link set dev "$AP_INTERFACE" address "$AP_MAC"
ip link set dev "$AP_INTERFACE" up

echo -e "${GREEN}  ✅ Interface $AP_INTERFACE créée (MAC: $AP_MAC)${NC}"

# --- Configurer l'IP statique de ap0 ---
echo -e "${YELLOW}🔧 Configuration IP de $AP_INTERFACE ($AP_IP)...${NC}"
ip addr flush dev "$AP_INTERFACE" 2>/dev/null || true
ip addr add "${AP_IP}/24" dev "$AP_INTERFACE"

# --- Configurer hostapd ---
echo -e "${YELLOW}🔧 Configuration de hostapd...${NC}"
cat > /etc/hostapd/hostapd.conf << EOF
# Pibooth Hotspot Configuration
interface=$AP_INTERFACE
driver=nl80211
ssid=$SSID
hw_mode=g
channel=$AP_CHANNEL
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$PASSWORD
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF

# Pointer hostapd vers la config
cat > /etc/default/hostapd << EOF
DAEMON_CONF="/etc/hostapd/hostapd.conf"
EOF

# --- Configurer dnsmasq ---
echo -e "${YELLOW}🔧 Configuration de dnsmasq (DHCP pour les clients)...${NC}"

# Sauvegarder l'ancienne config si elle existe
if [ -f /etc/dnsmasq.conf ] && [ ! -f /etc/dnsmasq.conf.pibooth.bak ]; then
    cp /etc/dnsmasq.conf /etc/dnsmasq.conf.pibooth.bak
    echo -e "${GREEN}  📋 Backup de dnsmasq.conf créé${NC}"
fi

cat > /etc/dnsmasq.d/pibooth-hotspot.conf << EOF
# Pibooth Hotspot DHCP Configuration
# Ne servir le DHCP QUE sur ap0 (ne pas interférer avec wlan0)
interface=$AP_INTERFACE
bind-interfaces
dhcp-range=$AP_DHCP_START,$AP_DHCP_END,$AP_NETMASK,24h
# Résolution DNS locale
address=/pibooth.local/$AP_IP
EOF

# --- Configurer le NAT (optionnel - permet aux clients du hotspot d'avoir internet via wlan0) ---
echo -e "${YELLOW}🔧 Configuration du NAT (partage internet wlan0 → ap0)...${NC}"
# Activer le forwarding IP
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -w net.ipv4.ip_forward=1 > /dev/null

# Règles iptables pour le NAT
iptables -t nat -D POSTROUTING -o "$WIFI_INTERFACE" -j MASQUERADE 2>/dev/null || true
iptables -t nat -A POSTROUTING -o "$WIFI_INTERFACE" -j MASQUERADE
iptables -D FORWARD -i "$AP_INTERFACE" -o "$WIFI_INTERFACE" -j ACCEPT 2>/dev/null || true
iptables -A FORWARD -i "$AP_INTERFACE" -o "$WIFI_INTERFACE" -j ACCEPT
iptables -D FORWARD -i "$WIFI_INTERFACE" -o "$AP_INTERFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true
iptables -A FORWARD -i "$WIFI_INTERFACE" -o "$AP_INTERFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT

# Sauvegarder les règles iptables pour qu'elles persistent au redémarrage
mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4

# --- Créer le script de démarrage de ap0 (nécessaire car l'interface virtuelle ne persiste pas au reboot) ---
echo -e "${YELLOW}🔧 Création du script de démarrage...${NC}"
cat > /usr/local/bin/pibooth-hotspot-start.sh << 'STARTEOF'
#!/bin/bash
# Script de démarrage du hotspot Pibooth AP+STA
# Appelé par le service systemd pibooth-hotspot.service

WIFI_INTERFACE="wlan0"
AP_INTERFACE="ap0"
AP_IP="192.168.4.1"

# Attendre que wlan0 soit prêt
for i in $(seq 1 30); do
    if ip link show "$WIFI_INTERFACE" > /dev/null 2>&1; then
        break
    fi
    sleep 1
done

# Supprimer l'ancienne interface ap0 si elle existe
iw dev "$AP_INTERFACE" del 2>/dev/null || true
sleep 0.5

# Créer l'interface virtuelle
iw dev "$WIFI_INTERFACE" interface add "$AP_INTERFACE" type __ap
sleep 1

# Adresse MAC légèrement différente
ORIGINAL_MAC=$(cat /sys/class/net/"$WIFI_INTERFACE"/address)
AP_MAC=$(echo "$ORIGINAL_MAC" | sed 's/..$/a0/')
ip link set dev "$AP_INTERFACE" address "$AP_MAC"
ip link set dev "$AP_INTERFACE" up

# IP statique
ip addr flush dev "$AP_INTERFACE" 2>/dev/null || true
ip addr add "${AP_IP}/24" dev "$AP_INTERFACE"

# Restaurer les règles iptables
if [ -f /etc/iptables/rules.v4 ]; then
    iptables-restore < /etc/iptables/rules.v4
fi

echo "Hotspot interface $AP_INTERFACE ready at $AP_IP"
STARTEOF
chmod +x /usr/local/bin/pibooth-hotspot-start.sh

# --- Créer le service systemd ---
echo -e "${YELLOW}🔧 Création du service systemd pibooth-hotspot...${NC}"
cat > /etc/systemd/system/pibooth-hotspot.service << EOF
[Unit]
Description=Pibooth WiFi Hotspot (AP+STA)
After=network.target NetworkManager.service
Wants=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/pibooth-hotspot-start.sh
ExecStartPost=/bin/sleep 2
ExecStartPost=/bin/systemctl restart hostapd
ExecStartPost=/bin/systemctl restart dnsmasq

[Install]
WantedBy=multi-user.target
EOF

# --- Démasquer et activer les services ---
echo -e "${YELLOW}🔧 Activation des services...${NC}"
systemctl unmask hostapd 2>/dev/null || true
systemctl enable hostapd
systemctl enable dnsmasq
systemctl daemon-reload
systemctl enable pibooth-hotspot.service

# --- Démarrer maintenant ---
echo -e "${YELLOW}🚀 Démarrage du hotspot...${NC}"
systemctl start pibooth-hotspot.service
sleep 3

# --- Vérification ---
echo ""
echo -e "${GREEN}=======================================================${NC}"
echo -e "${GREEN}  ✅ Hotspot Pibooth configuré avec succès !${NC}"
echo -e "${GREEN}=======================================================${NC}"
echo ""
echo -e "  📡 SSID         : ${YELLOW}$SSID${NC}"
echo -e "  🔑 Mot de passe : ${YELLOW}$PASSWORD${NC}"
echo -e "  🌐 IP hotspot   : ${YELLOW}$AP_IP${NC}"
echo -e "  🖥️  Interface web : ${YELLOW}http://$AP_IP:3000${NC}"
echo ""
echo -e "  ${GREEN}Mode AP+STA :${NC}"
echo -e "    • $AP_INTERFACE → Hotspot (contrôle Pibooth)"
echo -e "    • $WIFI_INTERFACE → WiFi normal (internet si dispo)"
echo ""

# Vérifier si hostapd tourne
if systemctl is-active --quiet hostapd; then
    echo -e "  ${GREEN}✅ hostapd : actif${NC}"
else
    echo -e "  ${RED}❌ hostapd : inactif — vérifier avec : sudo journalctl -u hostapd${NC}"
fi

# Vérifier si dnsmasq tourne
if systemctl is-active --quiet dnsmasq; then
    echo -e "  ${GREEN}✅ dnsmasq : actif${NC}"
else
    echo -e "  ${RED}❌ dnsmasq : inactif — vérifier avec : sudo journalctl -u dnsmasq${NC}"
fi

# Vérifier si ap0 a une IP
if ip addr show "$AP_INTERFACE" 2>/dev/null | grep -q "$AP_IP"; then
    echo -e "  ${GREEN}✅ $AP_INTERFACE : IP $AP_IP configurée${NC}"
else
    echo -e "  ${RED}❌ $AP_INTERFACE : IP non configurée${NC}"
fi

echo ""
echo -e "${YELLOW}📋 Commandes utiles :${NC}"
echo "  sudo systemctl status pibooth-hotspot"
echo "  sudo systemctl status hostapd"
echo "  sudo systemctl status dnsmasq"
echo "  sudo journalctl -u hostapd -f"
echo "  iw dev"
echo ""
echo -e "${YELLOW}🔧 Pour désactiver le hotspot :${NC}"
echo "  sudo systemctl stop pibooth-hotspot hostapd dnsmasq"
echo "  sudo systemctl disable pibooth-hotspot hostapd dnsmasq"
echo ""
echo -e "${YELLOW}🔧 Pour connecter le Pi à un WiFi (en plus du hotspot) :${NC}"
echo "  sudo nmcli device wifi connect \"NomDuWiFi\" password \"motdepasse\" ifname wlan0"
echo ""