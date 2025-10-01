{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      affinityPath,
      system,
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
      wrapWithPrefix = pkgs.callPackage ./wrapWithPrefix.nix { inherit affinityPath wineUnwrapped; };
    in
    {
      _module.args = {
        inherit wineUnwrapped;
      };
      packages = {
        wine = wrapWithPrefix wineUnwrapped "wine";
        winetricks = wrapWithPrefix pkgs.winetricks "winetricks";
        wineboot = wrapWithPrefix wineUnwrapped "wineboot";
        wineserver = wrapWithPrefix wineUnwrapped "wineserver";
      };
    };
}
