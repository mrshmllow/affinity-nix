# affinity-nix

![image](https://github.com/user-attachments/assets/eeb77651-8126-4899-a696-5bb154149753)

Affinity Photo, Designer, and Publisher applications packaged with nix.

Based on https://github.com/lf-/affinity-crimes and https://affinity.liz.pet/, and uses [ElementalWarrior's wine](https://gitlab.winehq.org/ElementalWarrior/wine).

## Usage Instructions
## 1. Perform a first time setup
Perform the first time setup which will manipluate `$XDG_DATA_HOME/affinity/`.

```bash
nix run github:mrshmllow/affinity-nix#photo

nix run github:mrshmllow/affinity-nix#designer

nix run github:mrshmllow/affinity-nix#publisher
```

### 2. Install the applications on your system (Optional)

#### 2.1 Install with nix-profile

```bash
nix profile install github:mrshmllow/affinity-nix#photo

nix profile install github:mrshmllow/affinity-nix#designer

nix profile install github:mrshmllow/affinity-nix#publisher
```

#### 2.2 Install on NixOS
#### 2.3 Install with Home Manager

### 3. Updating the applications
Update installations in `$XDG_DATA_HOME/affinity/`.

```bash
nix run github:mrshmllow/affinity-nix#updatePhoto

nix run github:mrshmllow/affinity-nix#updateDesigner

nix run github:mrshmllow/affinity-nix#updatePublisher
```
