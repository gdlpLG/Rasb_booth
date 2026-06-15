# Script de deploiement de la correction du texte coupe
# Usage: .\deploy-template-fix.ps1

$PI_USER = "lucas"
$PI_HOST = "raspberrypi.local"
$PI_PATH = "~/Rasb_booth/pibooth-picture-template"

Write-Host "=== Deploiement de la correction du texte ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Cette correction applique une marge de securite de 15%" -ForegroundColor Yellow
Write-Host "pour eviter que le texte soit coupe sur les photos finales." -ForegroundColor Yellow
Write-Host ""

# Deployer le fichier corrige
Write-Host "[1/1] Deploiement de pibooth_picture_template.py..." -ForegroundColor Yellow
scp pibooth-picture-template/pibooth_picture_template.py "${PI_USER}@${PI_HOST}:${PI_PATH}/"
if ($LASTEXITCODE -eq 0) {
    Write-Host "OK fichier deploye" -ForegroundColor Green
} else {
    Write-Host "ERREUR lors du deploiement" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Deploiement termine ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Prochaines etapes sur le Raspberry Pi :" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Reinstaller le plugin avec la correction :" -ForegroundColor White
Write-Host "   cd ~/Rasb_booth/pibooth-picture-template" -ForegroundColor White
Write-Host "   source ~/Rasb_booth/pibooth/venv/bin/activate" -ForegroundColor White
Write-Host "   pip install -e . --force-reinstall --no-deps" -ForegroundColor White
Write-Host ""
Write-Host "2. Redemarrer Pibooth :" -ForegroundColor White
Write-Host "   sudo systemctl restart pibooth" -ForegroundColor White
Write-Host ""
Write-Host "3. Prendre une photo de test pour verifier que le texte" -ForegroundColor White
Write-Host "   ne soit plus coupe." -ForegroundColor White
Write-Host ""
Write-Host "Note: La taille de police sera automatiquement reduite" -ForegroundColor Cyan
Write-Host "de 15% pour garantir que le texte rentre dans la zone." -ForegroundColor Cyan