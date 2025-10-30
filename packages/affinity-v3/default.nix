{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      self',
      affinityPathV3,
      wineUnwrapped,
      sources,
      version,
      stdShellArgs,
      ...
    }:
    let
      scripts = pkgs.callPackage ./scripts.nix {
        inherit (self'.packages)
          wineboot
          winetricks
          wine
          wineserver
          ;
        inherit
          affinityPathV3
          wineUnwrapped
          sources
          version
          stdShellArgs
          ;
        inherit (inputs) on-linux;
      };
    in
    {
      packages = {
        updateV3 = scripts.createInstaller;
        directV3 = scripts.createPackage;
      };
    };
}
