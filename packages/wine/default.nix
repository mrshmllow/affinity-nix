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
        (
          inputs.nixpkgs-wine.legacyPackages.${pkgs.stdenv.hostPlatform.system}.wineWow64Packages.full.override
          {
            wineRelease = "unstable";
          }
        ).overrideAttrs
          {
            src = inputs.elemental-wine-source;
            version = "9.13-part3";
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
      packages.wine = wrapWithPrefix wineUnwrapped "wine";

      _module.args = {
        inherit wineUnwrapped;

        wine-stuff = {
          winetricks = wrapWithPrefix pkgs.winetricks "winetricks";
          wineboot = wrapWithPrefix wineUnwrapped "wineboot";
          wineserver = wrapWithPrefix wineUnwrapped "wineserver";
        };
      };
    };
}
