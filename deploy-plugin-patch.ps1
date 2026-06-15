# Script de déploiement du patch pibooth-picture-template
# Pour corriger l'erreur Pillow 10+ getsize

$raspberryIP = "192.168.1.60"
$raspberryUser = "lucas"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Déploiement du patch pibooth-picture-template" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier que le fichier local contient le patch
Write-Host "1. Vérification du fichier local..." -ForegroundColor Yellow
$localFile = "pibooth-picture-template\pibooth_picture_template.py"

if (!(Test-Path $localFile)) {
    Write-Host "❌ ERREUR: Fichier local non trouvé: $localFile" -ForegroundColor Red
    exit 1
}

$content = Get-Content $localFile -Raw
if ($content -match "Compatible with Pillow 10\+") {
    Write-Host "✅ Le fichier local contient le patch" -ForegroundColor Green
} else {
    Write-Host "❌ ERREUR: Le fichier local ne contient PAS le patch!" -ForegroundColor Red
    Write-Host "   Le fichier pibooth_picture_template.py n'a pas été modifié correctement." -ForegroundColor Red
    exit 1
}

# Transférer le fichier
Write-Host ""
Write-Host "2. Transfert du fichier vers Raspberry Pi..." -ForegroundColor Yellow
$remotePath = "${raspberryUser}@${raspberryIP}:~/Rasb_booth/pibooth-picture-template/pibooth_picture_template.py"

scp $localFile $remotePath

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Fichier transféré avec succès" -ForegroundColor Green
} else {
    Write-Host "❌ ERREUR lors du transfert SCP" -ForegroundColor Red
    exit 1
}

# Vérifier sur le Raspberry Pi
Write-Host ""
Write-Host "3. Vérification sur le Raspberry Pi..." -ForegroundColor Yellow
$checkCommand = "grep -c 'Compatible with Pillow 10+' ~/Rasb_booth/pibooth-picture-template/pibooth_picture_template.py"
$result = ssh "${raspberryUser}@${raspberryIP}" $checkCommand

if ($result -eq "1") {
    Write-Host "✅ Le patch est bien présent sur le Raspberry Pi" -ForegroundColor Green
} else {
    Write-Host "❌ Le patch n'est pas détecté sur le Raspberry Pi" -ForegroundColor Red
    Write-Host "   Résultat grep: $result" -ForegroundColor Red
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Prochaines étapes sur le Raspberry Pi:" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "ssh $raspberryUser@$raspberryIP" -ForegroundColor White
Write-Host "cd ~/Rasb_booth/pibooth-picture-template" -ForegroundColor White
Write-Host "source ~/Rasb_booth/pibooth/venv/bin/activate" -ForegroundColor White
Write-Host "pip install -e ." -ForegroundColor White
Write-Host "pkill -9 python3" -ForegroundColor White
Write-Host "cd ~/Rasb_booth/pibooth && pibooth" -ForegroundColor White
Write-Host ""