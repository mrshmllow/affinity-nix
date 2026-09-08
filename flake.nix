{
  description = "An attempt at packaging affinity photo for nix";

  inputs = {
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

    wintypes_shim = {
      url = "github:ElementalWarrior/wine-wintypes.dll-for-affinity";
      flake = false;
    };

    windows-rs = {
      # a known-working commit of the Windows.winmd file. this file has been moved and has had many
      # non-descriptive git changes, so it's pinned to a version which atleast works.
      url = "github:microsoft/windows-rs/628f84c51645217c7a06a20774ea1275dc7270ca";
      flake = false;
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
          pkgs,
          ...
        }:
        {
          _module.args = {
            craneLib = inputs.crane.mkLib pkgs;
          };
        };
    };
}
