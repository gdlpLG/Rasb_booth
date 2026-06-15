#!/usr/bin/env pwsh
# Script de deploiement des 2 corrections:
# 1. Suppression du preview (view_plugin.py)
# 2. Synchronisation du retardateur (app.js)

$RPI_USER = "lucas"
$RPI_HOST = "raspberrypi.local"
$RPI_PATH = "/home/lucas/Rasb_booth"

Write-Host "=== Deploiement des corrections sur Raspberry Pi ===" -ForegroundColor Cyan
Write-Host ""

# Verification que les fichiers modifies existent
$files_ok = $true
if (-not (Test-Path "pibooth/plugins/view_plugin.py")) {
    Write-Host "ERREUR: pibooth/plugins/view_plugin.py manquant" -ForegroundColor Red
    $files_ok = $false
}
if (-not (Test-Path "pibooth-web-interface/pibooth_web/static/js/app.js")) {
    Write-Host "ERREUR: app.js manquant" -ForegroundColor Red
    $files_ok = $false
}
if (-not $files_ok) { exit 1 }

Write-Host "Fichiers a deployer:" -ForegroundColor Yellow
Write-Host "  - view_plugin.py (suppression preview)" -ForegroundColor Gray
Write-Host "  - app.js (synchronisation retardateur)" -ForegroundColor Gray
Write-Host ""

# ===== BACKUP =====
Write-Host "1. Creation des backups sur le Raspberry Pi..." -ForegroundColor Yellow
ssh ${RPI_USER}@${RPI_HOST} "cp ${RPI_PATH}/pibooth/pibooth/plugins/view_plugin.py ${RPI_PATH}/pibooth/pibooth/plugins/view_plugin.py.backup.`$(date +%Y%m%d_%H%M%S)"
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ECHEC backup view_plugin.py" -ForegroundColor Red
    exit 1
}

ssh ${RPI_USER}@${RPI_HOST} "cp ${RPI_PATH}/pibooth-web-interface/pibooth_web/static/js/app.js ${RPI_PATH}/pibooth-web-interface/pibooth_web/static/js/app.js.backup.`$(date +%Y%m%d_%H%M%S)"
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ECHEC backup app.js" -ForegroundColor Red
    exit 1
}
Write-Host "   OK Backups crees" -ForegroundColor Green

# ===== TRANSFERT view_plugin.py =====
Write-Host ""
Write-Host "2. Transfert de view_plugin.py..." -ForegroundColor Yellow
scp pibooth/plugins/view_plugin.py ${RPI_USER}@${RPI_HOST}:${RPI_PATH}/pibooth/pibooth/plugins/
if ($LASTEXITCODE -eq 0) {
    Write-Host "   OK Transfert reussi" -ForegroundColor Green
} else {
    Write-Host "   ECHEC" -ForegroundColor Red
    exit 1
}

# ===== TRANSFERT app.js =====
Write-Host ""
Write-Host "3. Transfert de app.js..." -ForegroundColor Yellow
scp pibooth-web-interface/pibooth_web/static/js/app.js ${RPI_USER}@${RPI_HOST}:${RPI_PATH}/pibooth-web-interface/pibooth_web/static/js/
if ($LASTEXITCODE -eq 0) {
    Write-Host "   OK Transfert reussi" -ForegroundColor Green
} else {
    Write-Host "   ECHEC" -ForegroundColor Red
    exit 1
}

# ===== VERIFICATION SYNTAXE =====
Write-Host ""
Write-Host "4. Verification syntaxe Python..." -ForegroundColor Yellow
ssh ${RPI_USER}@${RPI_HOST} "cd ${RPI_PATH}/pibooth && source venv/bin/activate && python -m py_compile pibooth/plugins/view_plugin.py"
if ($LASTEXITCODE -eq 0) {
    Write-Host "   OK Syntaxe Python valide" -ForegroundColor Green
} else {
    Write-Host "   ECHEC Erreur de syntaxe" -ForegroundColor Red
    Write-Host ""
    Write-Host "Restauration des backups..." -ForegroundColor Yellow
    ssh ${RPI_USER}@${RPI_HOST} "cp ${RPI_PATH}/pibooth/pibooth/plugins/view_plugin.py.backup.* ${RPI_PATH}/pibooth/pibooth/plugins/view_plugin.py"
    ssh ${RPI_USER}@${RPI_HOST} "cp ${RPI_PATH}/pibooth-web-interface/pibooth_web/static/js/app.js.backup.* ${RPI_PATH}/pibooth-web-interface/pibooth_web/static/js/app.js"
    exit 1
}

# ===== SUCCES =====
Write-Host ""
Write-Host "=== Deploiement termine avec succes ===" -ForegroundColor Green
Write-Host ""
Write-Host "PROCHAINES ETAPES:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Redemarrer Pibooth:" -ForegroundColor White
Write-Host "   sudo systemctl restart pibooth" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Tests a effectuer:" -ForegroundColor White
Write-Host "   - Capture immediate: plus de preview avant la photo" -ForegroundColor Gray
Write-Host "   - Retardateur: l'appareil photo fait son compte a rebours (10s)" -ForegroundColor Gray
Write-Host "   - Pas de double compte a rebours (web puis appareil)" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Pour restaurer si necessaire:" -ForegroundColor White
Write-Host "   ssh ${RPI_USER}@${RPI_HOST}" -ForegroundColor Gray
Write-Host "   cp ${RPI_PATH}/pibooth/pibooth/plugins/view_plugin.py.backup.* ${RPI_PATH}/pibooth/pibooth/plugins/view_plugin.py" -ForegroundColor Gray
Write-Host "   cp ${RPI_PATH}/pibooth-web-interface/pibooth_web/static/js/app.js.backup.* ${RPI_PATH}/pibooth-web-interface/pibooth_web/static/js/app.js" -ForegroundColor Gray
Write-Host "   sudo systemctl restart pibooth" -ForegroundColor Gray
Write-Host ""