# Script de déploiement des templates vers Raspberry Pi via SCP
# Usage: .\deploy-templates-scp.ps1

$RaspberryIP = "192.168.1.60"
$RaspberryUser = "lucas"
$RaspberryPath = "/home/lucas/Rasb_booth"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Déploiement templates vers Raspberry Pi" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "IP: $RaspberryIP" -ForegroundColor Yellow
Write-Host "User: $RaspberryUser" -ForegroundColor Yellow
Write-Host "Destination: $RaspberryPath" -ForegroundColor Yellow
Write-Host ""

# Vérifier que scp est disponible
try {
    $null = Get-Command scp -ErrorAction Stop
} catch {
    Write-Host "❌ Erreur: scp n'est pas installé ou pas dans le PATH" -ForegroundColor Red
    Write-Host "Installez OpenSSH Client depuis les paramètres Windows" -ForegroundColor Yellow
    exit 1
}

# Liste des fichiers et dossiers à transférer
$itemsToTransfer = @(
    @{
        Source = "pibooth-picture-template"
        Dest = "$RaspberryPath/"
        Type = "Directory"
        Description = "Plugin pibooth-picture-template complet"
    },
    @{
        Source = "pibooth-web-interface/pibooth_web/templates/templates.html"
        Dest = "$RaspberryPath/pibooth-web-interface/pibooth_web/templates/"
        Type = "File"
        Description = "Page web gestion templates"
    },
    @{
        Source = "pibooth-web-interface/pibooth_web/server.py"
        Dest = "$RaspberryPath/pibooth-web-interface/pibooth_web/"
        Type = "File"
        Description = "Serveur Flask avec routes templates"
    },
    @{
        Source = "pibooth-web-interface/pibooth_web/templates/index.html"
        Dest = "$RaspberryPath/pibooth-web-interface/pibooth_web/templates/"
        Type = "File"
        Description = "Page d'accueil avec lien templates"
    },
    @{
        Source = "pibooth-web-interface/setup.cfg"
        Dest = "$RaspberryPath/pibooth-web-interface/"
        Type = "File"
        Description = "Configuration setup.cfg mise à jour"
    },
    @{
        Source = "install_templates.sh"
        Dest = "$RaspberryPath/"
        Type = "File"
        Description = "Script d'installation templates"
    },
    @{
        Source = "TEMPLATES.md"
        Dest = "$RaspberryPath/"
        Type = "File"
        Description = "Documentation templates"
    },
    @{
        Source = "ROADMAP.md"
        Dest = "$RaspberryPath/"
        Type = "File"
        Description = "Roadmap mise à jour"
    },
    @{
        Source = "TRANSFERT_RASPBERRY.md"
        Dest = "$RaspberryPath/"
        Type = "File"
        Description = "Guide de transfert"
    }
)

Write-Host "📦 Fichiers à transférer:" -ForegroundColor Cyan
foreach ($item in $itemsToTransfer) {
    Write-Host "  • $($item.Description)" -ForegroundColor Gray
}
Write-Host ""

$confirm = Read-Host "Continuer? (o/N)"
if ($confirm -ne "o" -and $confirm -ne "O") {
    Write-Host "❌ Annulé" -ForegroundColor Red
    exit 0
}

Write-Host ""
Write-Host "🚀 Début du transfert..." -ForegroundColor Green
Write-Host ""

$success = 0
$failed = 0

foreach ($item in $itemsToTransfer) {
    Write-Host "📤 $($item.Description)..." -ForegroundColor Yellow -NoNewline
    
    try {
        if ($item.Type -eq "Directory") {
            # Transférer un dossier récursivement
            $result = scp -r $item.Source "${RaspberryUser}@${RaspberryIP}:$($item.Dest)" 2>&1
        } else {
            # Transférer un fichier
            $result = scp $item.Source "${RaspberryUser}@${RaspberryIP}:$($item.Dest)" 2>&1
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host " ✅" -ForegroundColor Green
            $success++
        } else {
            Write-Host " ❌" -ForegroundColor Red
            Write-Host "   Erreur: $result" -ForegroundColor Red
            $failed++
        }
    } catch {
        Write-Host " ❌" -ForegroundColor Red
        Write-Host "   Exception: $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    }
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Résumé du transfert" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "✅ Réussis: $success" -ForegroundColor Green
Write-Host "❌ Échoués: $failed" -ForegroundColor Red
Write-Host ""

if ($failed -eq 0) {
    Write-Host "🎉 Tous les fichiers ont été transférés avec succès !" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Prochaines étapes sur le Raspberry Pi:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. Se connecter en SSH:" -ForegroundColor White
    Write-Host "     ssh $RaspberryUser@$RaspberryIP" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  2. Installer les templates:" -ForegroundColor White
    Write-Host "     cd $RaspberryPath" -ForegroundColor Gray
    Write-Host "     chmod +x install_templates.sh" -ForegroundColor Gray
    Write-Host "     ./install_templates.sh" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  3. Redémarrer Pibooth:" -ForegroundColor White
    Write-Host "     cd $RaspberryPath/pibooth" -ForegroundColor Gray
    Write-Host "     source venv/bin/activate" -ForegroundColor Gray
    Write-Host "     pibooth" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  4. Tester l'interface web:" -ForegroundColor White
    Write-Host "     http://$RaspberryIP:3000/templates" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "⚠️  Certains fichiers n'ont pas pu être transférés." -ForegroundColor Yellow
    Write-Host "Vérifiez votre connexion SSH et réessayez." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "💡 Astuce: Testez la connexion SSH:" -ForegroundColor Cyan
    Write-Host "   ssh $RaspberryUser@$RaspberryIP" -ForegroundColor Gray
    Write-Host ""
}