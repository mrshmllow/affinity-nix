{
  description = "An attempt at packging affinity photo for nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    elemental-wine-source = {
      url = "gitlab:ElementalWarrior/wine?host=gitlab.winehq.org&ref=affinity-photo3-wine9.13-part3";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    elemental-wine-source,
  }: let
    forAllSystems = function:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
      ] (system: function nixpkgs.legacyPackages.${system});
  in {
    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [nodejs playwright-driver.browsers];
        shellHook = ''
          export PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright-driver.browsers}
          export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
        '';
      };
    });

    packages = forAllSystems (pkgs: let
      affinityPath = "$([[ -z \"$XDG_DATA_HOME\" ]] && echo \"$HOME/.local/share/affinity\" || echo \"$XDG_DATA_HOME/affinity\")";
      symlink = pkgs.callPackage ./symlink.nix {};

      wineUnstable =
        (pkgs.wineWow64Packages.full.override {
          wineRelease = "unstable";
        })
        .overrideAttrs {
          src = elemental-wine-source;
          version = "9.13-part3";
        };
      wineUnwrapped = symlink {
        wine = wineUnstable;
      };

      wrapWithPrefix = pkgs.callPackage ./wrapWithPrefix.nix {inherit affinityPath wineUnwrapped;};

      winetricks = wrapWithPrefix pkgs.winetricks "winetricks";
      wine = wrapWithPrefix wineUnwrapped "wine";
      wineboot = wrapWithPrefix wineUnwrapped "wineboot";
    in
      with pkgs.callPackage ./scripts.nix {inherit wineUnwrapped wineboot winetricks wine affinityPath;}; {
        inherit winetricks wine wineboot;

        updatePhoto = createInstaller "Photo";
        photo = createPackage "Photo";
        updateDesigner = createInstaller "Designer";
        designer = createPackage "Designer";
        updatePublisher = createInstaller "Publisher";
        publisher = createPackage "Publisher";
      });
  };
}
