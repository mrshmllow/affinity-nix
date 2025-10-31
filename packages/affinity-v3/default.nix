{
  perSystem =
    {
      pkgs,
      self',
      affinityPathV3,
      stdShellArgs,
      mkGraphicalCheck,
      mkInstaller,
      ...
    }:
    let
      scripts = pkgs.callPackage ./scripts.nix {
        wine = self'.packages.v3-wine;

        inherit
          affinityPathV3
          stdShellArgs
          mkGraphicalCheck
          mkInstaller
          ;
      };
    in
    {
      packages = {
        v3-update = mkInstaller "v3";
        v3-direct = scripts.createPackage;
      };
    };
}
