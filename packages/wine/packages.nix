{
  stdenv,
  callPackage,
  pkgs,
  inputs,
  ...
}:
let
  wineUnstable = inputs.nixpkgs.legacyPackages.${stdenv.hostPlatform.system}.wineWow64Packages.full;

  symlink = callPackage ./symlink.nix { };

  wineUnwrapped = symlink {
    wine = wineUnstable;
  };

  wrapWithPrefix = callPackage ./wrapWithPrefix.nix {
    inherit wineUnwrapped;
  };
in
{
  inherit wineUnwrapped;

  wine = wrapWithPrefix wineUnwrapped "wine";
  winetricks = wrapWithPrefix pkgs.winetricks "winetricks";
  wineserver = wrapWithPrefix wineUnwrapped "wineserver";
}
