{
  description = "An attempt at packging affinity photo for nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";

    elemental-wine-source = {
      url = "gitlab:ElementalWarrior/wine?host=gitlab.winehq.org&ref=affinity-photo3-wine9.13-part3";
      flake = false;
    };

    flake-compat.url = "github:edolstra/flake-compat";
  };

  outputs =
    {
      self,
      nixpkgs,
      elemental-wine-source,
      pre-commit-hooks,
      treefmt-nix,
      ...
    }:
    let
      forAllSystems =
        function:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
        ] (system: function nixpkgs.legacyPackages.${system});

      treefmtEval = forAllSystems (
        pkgs:
        treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          programs.nixfmt.enable = true;
        }
      );
    in
    {
      checks = forAllSystems (pkgs: {
        pre-commit-check = pre-commit-hooks.lib.${pkgs.system}.run {
          src = ./.;
          hooks = {
            nixfmt-rfc-style.enable = true;
            statix.enable = true;
            deadnix.enable = true;
          };
        };
      });

      formatter = forAllSystems (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);

      devShells = forAllSystems (pkgs: {
        default = nixpkgs.legacyPackages.${pkgs.system}.mkShell {
          inherit (self.checks.${pkgs.system}.pre-commit-check) shellHook;
          buildInputs = self.checks.${pkgs.system}.pre-commit-check.enabledPackages;
        };
      });

      packages = forAllSystems (
        pkgs:
        let
          affinityPath = "$([[ -z \"$XDG_DATA_HOME\" ]] && echo \"$HOME/.local/share/affinity\" || echo \"$XDG_DATA_HOME/affinity\")";
          symlink = pkgs.callPackage ./symlink.nix { };

          wineUnstable =
            (pkgs.wineWow64Packages.full.override {
              wineRelease = "unstable";
            }).overrideAttrs
              {
                src = elemental-wine-source;
                version = "9.13-part3";
              };
          wineUnwrapped = symlink {
            wine = wineUnstable;
          };

          wrapWithPrefix = pkgs.callPackage ./wrapWithPrefix.nix { inherit affinityPath wineUnwrapped; };

          winetricks = wrapWithPrefix pkgs.winetricks "winetricks";
          wine = wrapWithPrefix wineUnwrapped "wine";
          wineboot = wrapWithPrefix wineUnwrapped "wineboot";
        in
        with pkgs.callPackage ./scripts.nix {
          inherit
            wineUnwrapped
            wineboot
            winetricks
            wine
            affinityPath
            ;
        };
        {
          inherit winetricks wine wineboot;

          updatePhoto = createInstaller "Photo";
          photo = createPackage "Photo";
          updateDesigner = createInstaller "Designer";
          designer = createPackage "Designer";
          updatePublisher = createInstaller "Publisher";
          publisher = createPackage "Publisher";
        }
      );
    };
}
