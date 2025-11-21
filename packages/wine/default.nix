{
  perSystem =
    {
      pkgs,
      affinityPathV3,
      affinityPathV2,
      system,
      stdPath,
      ...
    }:
    let
      symlink = pkgs.callPackage ./symlink.nix { };
      wineUnwrapped = symlink {
        wine = pkgs.wineWow64Packages.stagingFull;
      };

      wrapWithPrefix-v2 = pkgs.callPackage ./wrapWithPrefix.nix {
        inherit wineUnwrapped stdPath;
        affinityPath = affinityPathV2;
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
          v3-runtime = {
            wine = wrapWithPrefix-v3 wineUnwrapped "wine";
            winetricks = wrapWithPrefix-v3 pkgs.winetricks "winetricks";
            wineboot = wrapWithPrefix-v3 wineUnwrapped "wineboot";
            wineserver = wrapWithPrefix-v3 wineUnwrapped "wineserver";
          };
        };
      };
    };
}
