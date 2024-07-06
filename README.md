# affinity-nix

Affinity Photo, Designer, and Publisher applications packaged with nix.

Based on https://github.com/lf-/affinity-crimes and https://codeberg.org/wanesty/affinity-wine-docs, and uses [ElementalWarrior's wine](https://gitlab.winehq.org/ElementalWarrior/wine).

## Usage Instructions

Perform the first time setup which will manipluate `~/.local/share/affinity/`.

```bash
nix run github:mrshmllow/affinity-nix#photo

nix run github:mrshmllow/affinity-nix#designer

nix run github:mrshmllow/affinity-nix#publisher
```

