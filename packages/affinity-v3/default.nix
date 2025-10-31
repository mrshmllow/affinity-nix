{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      self',
      affinityPathV3,
      wineUnwrapped,
      sources,
      stdShellArgs,
      ...
    }:
    let
      scripts = pkgs.callPackage ./scripts.nix {
        inherit (self'.packages)
          wineboot-v3
          winetricks-v3
          wine-v3
          wineserver-v3
          ;
        inherit
          affinityPathV3
          wineUnwrapped
          sources
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
