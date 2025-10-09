{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      affinityPath,
      system,
      stdPath,
      self',
      ...
    }:
    let
      wineUnstable =
        (inputs.nixpkgs-wine.legacyPackages.${system}.wineWow64Packages.full.override {
          wineRelease = "unstable";
        }).overrideAttrs
          {
            src = inputs.elemental-wine-source;
            version = "9.13-part3";
          };

      symlink = pkgs.callPackage ./symlink.nix { };
      wineUnwrapped = symlink {
        wine = wineUnstable;
      };
      wrapWithPrefix = pkgs.callPackage ./wrapWithPrefix.nix {
        inherit affinityPath wineUnwrapped stdPath;
      };
    in
    {
      _module.args = {
        inherit wineUnwrapped;
      };
      packages = {
        wine = pkgs.symlinkJoin {
          name = "wine";
          pname = "wine";
          paths = [
            (wrapWithPrefix wineUnwrapped "wine")
            (wrapWithPrefix wineUnwrapped "wine64")
            self'.packages.winetricks
            self'.packages.wineboot
            self'.packages.wineserver
          ];
          meta = {
            mainProgram = "wine";
          };
        };

        winetricks = wrapWithPrefix pkgs.winetricks "winetricks";
        wineboot = wrapWithPrefix wineUnwrapped "wineboot";
        wineserver = wrapWithPrefix wineUnwrapped "wineserver";
      };
    };
}
