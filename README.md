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

### Updating the applications

These will graphically prompt you to update the affinity application.

```bash
$ nix run github:mrshmllow/affinity-nix#{photo,designer,publisher} -- update
```

### Troubleshooting, winetricks, wineboot, and more

Each package (`photo|designer|publisher`) has the following usage:

```sh
$ affinity-photo-2 --help
Usage: affinity-photo-2 [COMMAND] [OPTIONS]

Commands:
  wine
  winetricks
  wineboot
  wineserver
  update|repair|install   Update or repair the application
  help                    Show this
  (nothing)               Launch Affinity Photo 2

```

> [!TIP]
> Armed with these you should be able to follow https://affinity.liz.pet/docs/misc-troubleshooting.html for troubleshooting steps.

For example, accessing `wine`:

```sh
$ affinity-photo-2 wine
Usage: wine PROGRAM [ARGUMENTS...]   Run the specified program
       wine --help                   Display this help and exit
       wine --version                Output version information and exit

```

Or `winecfg`:

```sh
$ affinity-photo-2 wine winecfg
```

`wine`, `wineboot`, `wineserver`, and `winetricks` are also exposed as nix packages
that you can run with `nix run`.

