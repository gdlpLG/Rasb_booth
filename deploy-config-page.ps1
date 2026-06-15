# Script de deploiement de la page de configuration
# Usage: .\deploy-config-page.ps1

$PI_USER = "lucas"
$PI_HOST = "raspberrypi.local"
$PI_PATH = "~/Rasb_booth/pibooth-web-interface/pibooth_web"

Write-Host "=== Deploiement de la page de configuration ===" -ForegroundColor Cyan
Write-Host ""

# Deployer api.py
Write-Host "[1/2] Deploiement de api.py..." -ForegroundColor Yellow
scp pibooth-web-interface/pibooth_web/api.py "${PI_USER}@${PI_HOST}:${PI_PATH}/"
if ($LASTEXITCODE -eq 0) {
    Write-Host "OK api.py deploye" -ForegroundColor Green
} else {
    Write-Host "ERREUR lors du deploiement de api.py" -ForegroundColor Red
    exit 1
}

# Deployer config.html
Write-Host "[2/2] Deploiement de config.html..." -ForegroundColor Yellow
scp pibooth-web-interface/pibooth_web/templates/config.html "${PI_USER}@${PI_HOST}:${PI_PATH}/templates/"
if ($LASTEXITCODE -eq 0) {
    Write-Host "OK config.html deploye" -ForegroundColor Green
} else {
    Write-Host "ERREUR lors du deploiement de config.html" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Deploiement termine ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Prochaines etapes :" -ForegroundColor Yellow
Write-Host "1. Redemarrez Pibooth sur le Raspberry Pi :" -ForegroundColor White
Write-Host "   sudo systemctl restart pibooth" -ForegroundColor White
Write-Host ""
Write-Host "2. Accedez a la page de configuration :" -ForegroundColor White
Write-Host "   http://192.168.4.1:3000/config" -ForegroundColor White
Write-Host ""
Write-Host "Vous devriez maintenant voir :" -ForegroundColor Cyan
Write-Host "  - Des switchs ON/OFF pour les booleens" -ForegroundColor Green
Write-Host "  - Des selecteurs de couleur pour les RGB" -ForegroundColor Green
Write-Host "  - Une liste deroulante pour la langue" -ForegroundColor Green
Write-Host "  - Les descriptions sous chaque champ" -ForegroundColor Green