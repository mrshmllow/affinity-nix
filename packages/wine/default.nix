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
      };
      packages = {
        v2-wine = wrapWithPrefix-v2 wineUnwrapped "wine";
        v2-winetricks = wrapWithPrefix-v2 pkgs.winetricks "winetricks";
        v2-wineboot = wrapWithPrefix-v2 wineUnwrapped "wineboot";
        v2-wineserver = wrapWithPrefix-v2 wineUnwrapped "wineserver";

        v3-wine = wrapWithPrefix-v3 wineUnwrapped "wine";
        v3-winetricks = wrapWithPrefix-v3 pkgs.winetricks "winetricks";
        v3-wineboot = wrapWithPrefix-v3 wineUnwrapped "wineboot";
        v3-wineserver = wrapWithPrefix-v3 wineUnwrapped "wineserver";
      };
    };
}
