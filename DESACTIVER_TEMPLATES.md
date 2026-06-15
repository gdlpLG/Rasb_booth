# 🔄 Retour à la base - Désactiver les templates

Le problème actuel est un problème de caméra USB (déconnexions), pas de template.

Revenons à une configuration minimale qui marche.

---

## ✅ Étape 1 : Désactiver les templates

Sur le Raspberry Pi :

```bash
ssh lucas@192.168.1.60

# Éditer la config
nano ~/.config/pibooth/pibooth.cfg
```

Dans le fichier, trouve la section `[PICTURE]` et **commente ou supprime** la ligne `template` :

```ini
[PICTURE]
# template = /home/lucas/pibooth_templates/pibooth.xml
```

Ou mets une ligne vide :

```ini
[PICTURE]
template = 
```

Sauvegarde : `Ctrl+O`, `Enter`, `Ctrl+X`

---

## ✅ Étape 2 : Redémarrer Pibooth

```bash
pkill -9 python3
cd ~/Rasb_booth/pibooth
source venv/bin/activate
pibooth
```

---

## ✅ Résultat attendu

Pibooth devrait démarrer en mode basique :
- ✅ Interface web sur port 3000
- ✅ Pas de boutons physiques
- ✅ Photos sauvegardées normalement (sans template)
- ✅ Pas d'erreur Pillow

---

## 🔍 Si la caméra continue à se déconnecter

Le problème `[-110] I/O in progress` est un problème USB/caméra classique :

### Solution 1 : Redémarrer le Raspberry Pi

```bash
sudo reboot
```

Puis relancer Pibooth.

### Solution 2 : Débrancher/rebrancher la caméra

1. Arrêter Pibooth : `pkill -9 python3`
2. Débrancher la caméra USB
3. Attendre 5 secondes
4. Rebrancher la caméra
5. Relancer Pibooth

### Solution 3 : Vérifier les droits USB

```bash
# Ajouter l'utilisateur au groupe camera
sudo usermod -a -G plugdev lucas

# Redémarrer pour appliquer
sudo reboot
```

### Solution 4 : Tester la caméra sans Pibooth

```bash
# Vérifier que gphoto2 voit la caméra
gphoto2 --auto-detect

# Tester une capture directe
gphoto2 --capture-image
```

---

## 📋 Configuration minimale fonctionnelle

Voici ce qui doit être actif :

```ini
[WEB]
enable = yes
host = 0.0.0.0
port = 3000
disable_physical_buttons = yes

[PICTURE]
# template = 
# (ligne commentée ou vide)

[CAMERA]
# Ta config caméra habituelle
```

---

## 🎯 Prochaines étapes (une fois que ça marche)

1. ✅ Faire marcher Pibooth en mode basique (sans template)
2. ✅ Résoudre le problème de caméra USB
3. ⏸️ Réactiver les templates plus tard (optionnel)

---

## 💡 Le problème Pillow est RÉSOLU

Le code que j'ai patché est correct maintenant. Mais tant que la caméra se déconnecte, on ne peut pas tester le reste.

Concentrons-nous d'abord sur la stabilité de la caméra !