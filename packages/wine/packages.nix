{
  callPackage,
  fetchurl,
  winetricks,
  wineWow64Packages,
  ...
}:
let
  wineUnstable = wineWow64Packages.full.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      (fetchurl {
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
  winetricks = wrapWithPrefix winetricks "winetricks";
  wineserver = wrapWithPrefix wineUnwrapped "wineserver";
}
