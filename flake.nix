{
  description = "An attempt at packaging affinity photo for nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    on-linux = {
      url = "github:seapear/AffinityOnLinux";
      flake = false;
    };

    plugin-loader = {
      url = "file+https://github.com/noahc3/AffinityPluginLoader/releases/download/v0.2.0/affinitypluginloader-plus-winefix.tar.xz";
      flake = false;
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    git-hooks.url = "github:cachix/git-hooks.nix";

    elemental-wine-source = {
      url = "gitlab:ElementalWarrior/wine?host=gitlab.winehq.org&ref=affinity-photo3-wine9.13-part3";
      flake = false;
    };

    flake-compat.url = "https://git.lix.systems/lix-project/flake-compat/archive/main.tar.gz";
  };

  outputs =
    inputs@{
      flake-parts,
      git-hooks,
      treefmt-nix,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        git-hooks.flakeModule
        treefmt-nix.flakeModule
        ./nix/hooks.nix
        ./nix/fmt.nix
        ./nix/shells.nix
        ./packages
      ];
      systems = [
        "x86_64-linux"
      ];
      perSystem = {
        _module.args = {
          affinityPathV2 = "$([[ -z \"$XDG_DATA_HOME\" ]] && echo \"$HOME/.local/share/affinity\" || echo \"$XDG_DATA_HOME/affinity\")";
          affinityPathV3 = "$([[ -z \"$XDG_DATA_HOME\" ]] && echo \"$HOME/.local/share/affinity-v3\" || echo \"$XDG_DATA_HOME/affinity-v3\")";
        };
      };
    };
}
