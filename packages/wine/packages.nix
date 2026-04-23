{
  stdenv,
  callPackage,
  pkgs,
  nixpkgs-wine,
  src,
  stdPath,
}:
let
  wineUnstable =
    (nixpkgs-wine.legacyPackages.${stdenv.hostPlatform.system}.wineWow64Packages.full.override {
      wineRelease = "unstable";
    }).overrideAttrs
      {
        inherit src;
        version = "9.13-part3";
      };

  symlink = callPackage ./symlink.nix { };

  wineUnwrapped = symlink {
    wine = wineUnstable;
  };

  wrapWithPrefix = callPackage ./wrapWithPrefix.nix {
    inherit wineUnwrapped;
    stdPath = stdPath pkgs;
  };
in
{
  inherit wineUnwrapped;

  wine = wrapWithPrefix wineUnwrapped "wine";
  winetricks = wrapWithPrefix pkgs.winetricks "winetricks";
  wineboot = wrapWithPrefix wineUnwrapped "wineboot";
  wineserver = wrapWithPrefix wineUnwrapped "wineserver";
}
