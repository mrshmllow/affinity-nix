# affinity-nix

![image](https://github.com/user-attachments/assets/d81f1805-c72b-4999-909e-c5666b5e0a11)

Affinity Photo, Designer, and Publisher applications packaged with nix.

Based on https://github.com/lf-/affinity-crimes and https://affinity.liz.pet/, and uses [ElementalWarrior's wine](https://gitlab.winehq.org/ElementalWarrior/wine).

## Preamble

> [!TIP]
> [Add garnix as a substituter](https://garnix.io/docs/caching) to avoid compling yourself.

The prefix is located in `$XDG_DATA_HOME/affinity/` falling back to `$HOME/.local/share/affinity/`.

You will be prompted to provide affinity's installation exe on the first-time run, just follow the error's instructions to add the exe to your nix store and run again.

## Usage Instructions

> [!IMPORTANT]
> You will be graphically prompted to install the application: **Leave the installation path default.**

### Running Ad-hoc

```bash
$ nix run github:mrshmllow/affinity-nix#photo

$ nix run github:mrshmllow/affinity-nix#designer

$ nix run github:mrshmllow/affinity-nix#publisher
```

### Installing the applications on your system (Optional)

#### Install with nix-profile

```bash
$ nix profile install github:mrshmllow/affinity-nix#photo

$ nix profile install github:mrshmllow/affinity-nix#designer

$ nix profile install github:mrshmllow/affinity-nix#publisher
```

#### Install on NixOS / Home Manager

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

These will graphically prompt you to update the affinity application.

```bash
$ nix run github:mrshmllow/affinity-nix#updatePhoto

$ nix run github:mrshmllow/affinity-nix#updateDesigner

$ nix run github:mrshmllow/affinity-nix#updatePublisher
```

### 4. Troubleshooting, winetricks, wineboot, and more

You can access winetricks, wine, and wineboot with the affinity environment & wine prefix baked in with nix run.

> [!TIP]
> Armed with these you should be able to follow https://affinity.liz.pet/docs/misc-troubleshooting.html for troubleshooting steps.

```bash
$ nix run github:mrshmllow/affinity-nix#winetricks

$ nix run github:mrshmllow/affinity-nix#wine

$ nix run github:mrshmllow/affinity-nix#wine -- winecfg

$ nix run github:mrshmllow/affinity-nix#wineboot
```

## FAQ

### Im getting `Unfortunately, we cannot download file affinity-photo-msi-2.5.7.exe automatically.`

You got an error such as:

```
error: builder for '/nix/store/wnh96wlyi5f6ywr628mjfdpvsl8w03m0-affinity-designer-msi-2.5.7.exe.drv' failed with exit code 1;
       last 11 log lines:
       >
       > ***
       > Unfortunately, we cannot download file affinity-designer-msi-2.5.7.exe automatically.
       > Please go to https://store.serif.com/en-gb/update/windows/designer/2/ to download it yourself, and add it to the Nix store
       > using either
       >   nix-store --add-fixed sha256 affinity-designer-msi-2.5.7.exe
       > or
       >   nix-prefetch-url --type sha256 file:///path/to/affinity-designer-msi-2.5.7.exe
       >
       > ***
       >
       For full logs, run 'nix log /nix/store/wnh96wlyi5f6ywr628mjfdpvsl8w03m0-affinity-designer-msi-2.5.7.exe.drv'.
```

> [!TIP]
> **You must follow the instructions**

Download the exe from the url in the error, and run the example command to add it to the store.

### I ran the store command above but its still not building!

Double check which tool you are running. You likely added the exe for `Photo` but you are running `Designer` / `Publisher`. You must add the installation exe for every tool you want to run.
