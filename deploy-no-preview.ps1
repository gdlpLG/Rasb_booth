#!/usr/bin/env pwsh
# Script de deploiement du fichier view_plugin.py modifie (suppression du preview)

$RPI_USER = "lucas"
$RPI_HOST = "raspberrypi.local"
$RPI_PATH = "/home/lucas/Rasb_booth/pibooth"

Write-Host "=== Deploiement de la modification 'no preview' sur Raspberry Pi ===" -ForegroundColor Cyan
Write-Host ""

# Verification que le fichier modifie existe
if (-not (Test-Path "pibooth/plugins/view_plugin.py")) {
    Write-Host "ERREUR: Le fichier pibooth/plugins/view_plugin.py n'existe pas" -ForegroundColor Red
    exit 1
}

Write-Host "1. Creation d'un backup du fichier original sur le Raspberry Pi..." -ForegroundColor Yellow
ssh ${RPI_USER}@${RPI_HOST} "cp ${RPI_PATH}/pibooth/plugins/view_plugin.py ${RPI_PATH}/pibooth/plugins/view_plugin.py.backup.`$(date +%Y%m%d_%H%M%S)"

if ($LASTEXITCODE -eq 0) {
    Write-Host "   OK Backup cree" -ForegroundColor Green
} else {
    Write-Host "   ECHEC Erreur lors du backup" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "2. Transfert du fichier modifie..." -ForegroundColor Yellow
scp pibooth/plugins/view_plugin.py ${RPI_USER}@${RPI_HOST}:${RPI_PATH}/pibooth/plugins/

if ($LASTEXITCODE -eq 0) {
    Write-Host "   OK Fichier transfere" -ForegroundColor Green
} else {
    Write-Host "   ECHEC Erreur lors du transfert" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "3. Verification de la syntaxe Python sur le Raspberry Pi..." -ForegroundColor Yellow
ssh ${RPI_USER}@${RPI_HOST} "cd ${RPI_PATH} && source venv/bin/activate && python -m py_compile pibooth/plugins/view_plugin.py"

if ($LASTEXITCODE -eq 0) {
    Write-Host "   OK Syntaxe Python valide" -ForegroundColor Green
} else {
    Write-Host "   ECHEC Erreur de syntaxe Python" -ForegroundColor Red
    Write-Host ""
    Write-Host "Restauration du backup..." -ForegroundColor Yellow
    ssh ${RPI_USER}@${RPI_HOST} "cp ${RPI_PATH}/pibooth/plugins/view_plugin.py.backup.* ${RPI_PATH}/pibooth/plugins/view_plugin.py"
    exit 1
}

Write-Host ""
Write-Host "=== Deploiement termine avec succes ===" -ForegroundColor Green
Write-Host ""
Write-Host "PROCHAINES ETAPES:" -ForegroundColor Cyan
Write-Host "1. Redemarrer Pibooth sur le Raspberry Pi:" -ForegroundColor White
Write-Host "   sudo systemctl restart pibooth" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Tester le photobooth (plus de preview avant capture)" -ForegroundColor White
Write-Host ""
Write-Host "3. Pour restaurer l'ancien fichier si necessaire:" -ForegroundColor White
Write-Host "   ssh ${RPI_USER}@${RPI_HOST}" -ForegroundColor Gray
Write-Host "   cp ${RPI_PATH}/pibooth/plugins/view_plugin.py.backup.* ${RPI_PATH}/pibooth/plugins/view_plugin.py" -ForegroundColor Gray
Write-Host "   sudo systemctl restart pibooth" -ForegroundColor Gray
Write-Host ""