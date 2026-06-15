#!/usr/bin/env pwsh
# Script de deploiement de la correction capture_date

$RPI_USER = "lucas"
$RPI_HOST = "raspberrypi.local"
$RPI_PATH = "/home/lucas/Rasb_booth"

Write-Host "=== Deploiement correction capture_date ===" -ForegroundColor Cyan
Write-Host ""

# Verification
if (-not (Test-Path "pibooth/plugins/view_plugin.py")) {
    Write-Host "ERREUR: pibooth/plugins/view_plugin.py manquant" -ForegroundColor Red
    exit 1
}

# Backup
Write-Host "1. Backup sur le Raspberry Pi..." -ForegroundColor Yellow
ssh ${RPI_USER}@${RPI_HOST} "cp ${RPI_PATH}/pibooth/pibooth/plugins/view_plugin.py ${RPI_PATH}/pibooth/pibooth/plugins/view_plugin.py.backup.`$(date +%Y%m%d_%H%M%S)"
if ($LASTEXITCODE -eq 0) {
    Write-Host "   OK Backup cree" -ForegroundColor Green
} else {
    Write-Host "   ECHEC" -ForegroundColor Red
    exit 1
}

# Transfert
Write-Host ""
Write-Host "2. Transfert du fichier..." -ForegroundColor Yellow
scp pibooth/plugins/view_plugin.py ${RPI_USER}@${RPI_HOST}:${RPI_PATH}/pibooth/pibooth/plugins/
if ($LASTEXITCODE -eq 0) {
    Write-Host "   OK Transfert reussi" -ForegroundColor Green
} else {
    Write-Host "   ECHEC" -ForegroundColor Red
    exit 1
}

# Verification
Write-Host ""
Write-Host "3. Verification syntaxe Python..." -ForegroundColor Yellow
ssh ${RPI_USER}@${RPI_HOST} "cd ${RPI_PATH}/pibooth && source venv/bin/activate && python -m py_compile pibooth/plugins/view_plugin.py"
if ($LASTEXITCODE -eq 0) {
    Write-Host "   OK Syntaxe valide" -ForegroundColor Green
} else {
    Write-Host "   ECHEC" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Correction deployee ===" -ForegroundColor Green
Write-Host ""
Write-Host "Redemarrer Pibooth:" -ForegroundColor Cyan
Write-Host "  sudo systemctl restart pibooth" -ForegroundColor Gray
Write-Host ""