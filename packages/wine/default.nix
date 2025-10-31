{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      affinityPathV3,
      affinityPath,
      system,
      stdPath,
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

      wrapWithPrefix-v2 = pkgs.callPackage ./wrapWithPrefix.nix {
        inherit affinityPath wineUnwrapped stdPath;
      };

      wrapWithPrefix-v3 = pkgs.callPackage ./wrapWithPrefix.nix {
        inherit wineUnwrapped stdPath;
        affinityPath = affinityPathV3;
      };
    in
    {
      _module.args = {
        inherit wineUnwrapped;

        wine-stuff = {
          v2 = {
            wine = wrapWithPrefix-v2 wineUnwrapped "wine";
            winetricks = wrapWithPrefix-v2 pkgs.winetricks "winetricks";
            wineboot = wrapWithPrefix-v2 wineUnwrapped "wineboot";
            wineserver = wrapWithPrefix-v2 wineUnwrapped "wineserver";
          };
          v3 = {
            wine = wrapWithPrefix-v3 wineUnwrapped "wine";
            winetricks = wrapWithPrefix-v3 pkgs.winetricks "winetricks";
            wineboot = wrapWithPrefix-v3 wineUnwrapped "wineboot";
            wineserver = wrapWithPrefix-v3 wineUnwrapped "wineserver";
          };
        };
      };
    };
}
