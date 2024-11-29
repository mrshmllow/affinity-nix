# affinity-nix

Affinity Photo, Designer, and Publisher applications packaged with nix.

Based on https://github.com/lf-/affinity-crimes and https://affinity.liz.pet/, uses [ElementalWarrior's wine](https://gitlab.winehq.org/ElementalWarrior/wine).

## Usage Instructions

- Run these scripts to perform the first time setup which will manipulate `$XDG_DATA_HOME/affinity/`.
- Run these scripts again to launch the apps!

```bash
nix run github:mrshmllow/affinity-nix#photo

nix run github:mrshmllow/affinity-nix#designer

nix run github:mrshmllow/affinity-nix#publisher
```

## Update Instructions

- Run these scripts to update installations in `$XDG_DATA_HOME/affinity/`.

```bash
nix run github:mrshmllow/affinity-nix#updatePhoto

nix run github:mrshmllow/affinity-nix#updateDesigner

nix run github:mrshmllow/affinity-nix#updatePublisher
```
