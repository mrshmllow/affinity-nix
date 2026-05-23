{
  description = "An attempt at packaging affinity photo for nix";

  inputs = {
    # a known working revision of nixpkgs for wine. somewhat tracked by #63
    nixpkgs-wine.url = "github:nixos/nixpkgs/6df24922a1400241dae323af55f30e4318a6ca65";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    on-linux = {
      url = "github:seapear/AffinityOnLinux";
      flake = false;
    };

    plugin-loader-src = {
      url = "github:noahc3/AffinityPluginLoader/1d7956d5b791bd6a213e8b28c1e25e1f4bcc6166";
      flake = false;
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    git-hooks.url = "github:cachix/git-hooks.nix";

    flake-compat.url = "https://git.lix.systems/lix-project/flake-compat/archive/main.tar.gz";

    corefonts = {
      url = "github:pushcx/corefonts";
      flake = false;
    };

    crane.url = "github:ipetkov/crane";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
        ./tests/default.nix
        ./overlay.nix
      ];
      systems = [
        "x86_64-linux"
      ];
      perSystem =
        {
          inputs',
          config,
          pkgs,
          system,
          ...
        }:
        {
          _module.args = {
            pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };

            toolchain = inputs'.fenix.packages.complete;
            craneLib = (inputs.crane.mkLib pkgs).overrideToolchain config._module.args.toolchain.toolchain;
          };
        };
    };
}
