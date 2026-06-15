# Script de déploiement simplifié - Pibooth Web Interface
$IP = "192.168.1.60"
$User = "lucas"
$RemotePath = "/home/lucas/Rasb_booth"

Write-Host "🚀 Déploiement vers $IP..." -ForegroundColor Cyan

# --- Dossiers principaux ---
Write-Host "  📁 pibooth-web-interface..." -ForegroundColor Yellow
scp -r pibooth-web-interface "${User}@${IP}:${RemotePath}/"

Write-Host "  📁 pibooth-picture-template..." -ForegroundColor Yellow
scp -r pibooth-picture-template "${User}@${IP}:${RemotePath}/"

# --- Documentation ---
Write-Host "  📄 Documentation..." -ForegroundColor Yellow
scp ROADMAP.md "${User}@${IP}:${RemotePath}/"
scp TRANSFERT_RASPBERRY.md "${User}@${IP}:${RemotePath}/"
scp HOTSPOT.md "${User}@${IP}:${RemotePath}/"
scp INSTALL_SERVICE.md "${User}@${IP}:${RemotePath}/"

# --- Rappel post-déploiement ---
Write-Host ""
Write-Host "✅ Déploiement terminé !" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Commandes à exécuter sur le Raspberry Pi :" -ForegroundColor Cyan
Write-Host "  ssh ${User}@${IP}" -ForegroundColor White
Write-Host "  cd ${RemotePath}/pibooth \`\`&\`\`& source venv/bin/activate"
Write-Host "  cd ${RemotePath}/pibooth-web-interface \`\`&\`\`& pip install -r requirements.txt"
Write-Host "  sudo systemctl restart pibooth" -ForegroundColor White
Write-Host ""
Write-Host "📡 Pour configurer le hotspot AP+STA :" -ForegroundColor Cyan
Write-Host "  sudo bash ${RemotePath}/pibooth-web-interface/scripts/setup_hotspot.sh" -ForegroundColor White
Write-Host ""