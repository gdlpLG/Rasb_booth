# pibooth-no-buttons

Plugin Pibooth pour désactiver les boutons physiques GPIO.

## Description

Ce plugin remplace les boutons physiques GPIO par des boutons virtuels,
permettant à Pibooth de fonctionner sans aucun bouton matériel connecté.

Idéal pour une utilisation avec le plugin `pibooth-web-interface` qui permet
de contrôler Pibooth depuis un navigateur web.

## Installation

```bash
cd ~/30_pibooth/pibooth-no-buttons
source ~/30_pibooth/pibooth/venv/bin/activate
pip install -e .
```

## Configuration

Dans `~/.config/pibooth/pibooth.cfg` :

```ini
[NO_BUTTONS]
enabled = yes
```

## Vérification

```bash
python3 -c "import pibooth_no_buttons; print(pibooth_no_buttons.__version__)"
```

## Logs attendus

Au démarrage de Pibooth :
```
Physical buttons DISABLED (pibooth-no-buttons plugin)
Virtual buttons and LEDs installed successfully