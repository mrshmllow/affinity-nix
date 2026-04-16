{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      stdPath,
      ...
    }:
    let
      wineUnstable =
        (inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.wineWow64Packages.full.override {
          wineRelease = "unstable";
        }).overrideAttrs
          {
            src = inputs.wine-source;
            version = "11.0";
          };

      symlink = pkgs.callPackage ./symlink.nix { };
      wineUnwrapped = symlink {
        wine = wineUnstable;
      };

      wrapWithPrefix = pkgs.callPackage ./wrapWithPrefix.nix {
        inherit wineUnwrapped stdPath;
      };
    in
    {
      _module.args = {
        inherit wineUnwrapped;

        wine-stuff = {
          wine = wrapWithPrefix wineUnwrapped "wine";
          winetricks = wrapWithPrefix pkgs.winetricks "winetricks";
          wineboot = wrapWithPrefix wineUnwrapped "wineboot";
          wineserver = wrapWithPrefix wineUnwrapped "wineserver";
        };
      };
    };
}
