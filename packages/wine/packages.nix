{
  stdenv,
  callPackage,
  pkgs,
  inputs,
  ...
}:
let
  wineUnstable =
    inputs.nixpkgs.legacyPackages.${stdenv.hostPlatform.system}.wineWow64Packages.full.overrideAttrs
      (old: {
        patches = (old.patches or [ ]) ++ [
          (pkgs.fetchurl {
            url = "https://gitlab.winehq.org/wine/wine/-/merge_requests/10060.diff";
            hash = "sha256-1znc785D0ZTGAUfSz690Kl0JzfToU1u1Yy5UXhpAYYk=";
          })
        ];
      });

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
