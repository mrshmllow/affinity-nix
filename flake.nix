{
  description = "An attempt at packging affinity photo for nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    elemental-wine-source = {
      url = "gitlab:ElementalWarrior/wine?host=gitlab.winehq.org&ref=c12ed1469948f764817fa17efd2299533cf3fe1c";
      flake = false;
    };
    winetricks-source = {
      url = "github:winetricks/winetricks?ref=20240105";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    elemental-wine-source,
    winetricks-source,
  }: let
    forAllSystems = function:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
      ] (system: function nixpkgs.legacyPackages.${system});
  in {
    packages = forAllSystems (pkgs: let
      affinityPath = "$XDG_DATA_HOME/affinity/";
      symlink = pkgs.callPackage ./symlink.nix {};

      wineUnstable =
        (pkgs.wineWow64Packages.full.override {
          wineRelease = "unstable";
        })
        .overrideAttrs {
          src = elemental-wine-source;
          version = "8.14";
        };
      wineUnwrapped = symlink {
        wine = wineUnstable;
      };
      winetricksUnwrapped = pkgs.winetricks.overrideAttrs {
        src = winetricks-source;
      };

      wrapWithPrefix = pkgs.callPackage ./wrapWithPrefix.nix {inherit affinityPath wineUnwrapped;};

      winetricks = wrapWithPrefix winetricksUnwrapped "winetricks";
      wine = wrapWithPrefix wineUnwrapped "wine";
      wineboot = wrapWithPrefix wineUnwrapped "wineboot";
    in
      with pkgs.callPackage ./scripts.nix {inherit wineUnwrapped wineboot winetricks wine affinityPath;}; {
        inherit winetricks wine wineboot;

        _cached_wine_unwrapped = wineUnstable;
        _cached_winetricks_unwrapped = winetricksUnwrapped;

        updatePhoto = createInstaller "Photo";
        photo = createPackage "Photo";
        updateDesigner = createInstaller "Designer";
        designer = createPackage "Designer";
        updatePublisher = createInstaller "Publisher";
        publisher = createPackage "Publisher";
      });
  };
}
