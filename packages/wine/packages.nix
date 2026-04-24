{
  stdenv,
  callPackage,
  pkgs,
  inputs,
  stdPath,
}:
let
  wineUnstable =
    (inputs.nixpkgs-wine.legacyPackages.${stdenv.hostPlatform.system}.wineWow64Packages.full.override {
      wineRelease = "unstable";
    }).overrideAttrs
      {
        src = inputs.elemental-wine-source;
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
  wineserver = wrapWithPrefix wineUnwrapped "wineserver";
}
