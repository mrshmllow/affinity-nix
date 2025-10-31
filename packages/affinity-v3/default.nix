{
  perSystem =
    {
      pkgs,
      affinityPathV3,
      stdShellArgs,
      mkGraphicalCheck,
      mkInstaller,
      v3-wine,
      ...
    }:
    let
      scripts = pkgs.callPackage ./scripts.nix {
        wine = v3-wine;

        inherit
          affinityPathV3
          stdShellArgs
          mkGraphicalCheck
          mkInstaller
          ;
      };
    in
    {
      _module.args = {
        updateV3 = mkInstaller "v3";
        directV3 = scripts.createPackage;
      };
    };
}
