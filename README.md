# affinity-nix

![image](https://github.com/user-attachments/assets/eeb77651-8126-4899-a696-5bb154149753)

Affinity Photo, Designer, and Publisher applications packaged with nix.

Based on https://github.com/lf-/affinity-crimes and https://affinity.liz.pet/, and uses [ElementalWarrior's wine](https://gitlab.winehq.org/ElementalWarrior/wine).

## Usage Instructions
### 0. [Add garnix as a substituter](https://garnix.io/docs/caching)
... If you want to avoid building wine
### 1. Perform a first time setup
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

#### 2.2 Install on NixOS / Home Manager

<details>
<summary>Install on NixOS</summary>

The following is an example. **Installing this package does not differ to installing a package from any other flake.**

```nix
{
  inputs = {
    affinity-nix.url = "github:mrshmllow/affinity-nix";
    # ...
  };

  outputs = inputs @ {
    affinity-nix,
    ...
  }: {
    nixosConfigurations.my-system = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit inputs;};
      modules = [
        # ...
        {
          environment.systemPackages = [affinity-nix.packages.x86_64-linux.photo];
        }
      ];
    };
  }
}
```
</details>

<details>
<summary>Install with Home Manager</summary>

The following is an example. **Installing this package does not differ to installing a package from any other flake.**

```nix
{
  inputs = {
    affinity-nix.url = "github:mrshmllow/affinity-nix";
    # ...
  };

  outputs = inputs @ {
    affinity-nix,
    ...
  }: {
    homeConfigurations.my-user = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages."x86_64-linux";
      extraSpecialArgs = {inherit inputs;};
      modules = [
        # ...
        {
          home.packages = [affinity-nix.packages.x86_64-linux.photo];
        }
      ];
    };
  }
}
```
</details>

### 3. Updating the applications
Update installations in `$XDG_DATA_HOME/affinity/`.

```bash
nix run github:mrshmllow/affinity-nix#updatePhoto

nix run github:mrshmllow/affinity-nix#updateDesigner

nix run github:mrshmllow/affinity-nix#updatePublisher
```

### 4. Troubleshooting, winetricks, wineboot, and more
You can access winetricks, wine, and wineboot with the affinity environment & wine prefix baked in with nix run.

> [!TIP]
> Armed with these you should be able to follow https://affinity.liz.pet/docs/misc-troubleshooting.html for troubleshooting steps.

```bash
nix run github:mrshmllow/affinity-nix#winetricks

nix run github:mrshmllow/affinity-nix#wine

nix run github:mrshmllow/affinity-nix#wine -- winecfg

nix run github:mrshmllow/affinity-nix#wineboot
```
