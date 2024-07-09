# affinity-nix

Affinity Photo, Designer, and Publisher applications packaged with nix.

Based on https://github.com/lf-/affinity-crimes and https://codeberg.org/wanesty/affinity-wine-docs, and uses [ElementalWarrior's wine](https://gitlab.winehq.org/ElementalWarrior/wine).

## Usage Instructions

Perform the first time setup which will manipluate `$XDG_DATA_HOME/affinity/`.

```bash
nix run github:mrshmllow/affinity-nix#photo

nix run github:mrshmllow/affinity-nix#designer

nix run github:mrshmllow/affinity-nix#publisher
```

Update installations in `$XDG_DATA_HOME/affinity/`.

```bash
nix run github:mrshmllow/affinity-nix#updatePhoto

nix run github:mrshmllow/affinity-nix#updateDesigner

nix run github:mrshmllow/affinity-nix#updatePublisher
```
