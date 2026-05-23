{
  stdenv,
  callPackage,
  pkgs,
  inputs,
  stdPath,
}:
let
  wineUnstable = inputs.nixpkgs.legacyPackages.${stdenv.hostPlatform.system}.wineWow64Packages.full;

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
