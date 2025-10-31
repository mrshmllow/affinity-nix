{
  perSystem =
    {
      pkgs,
      affinityPathV3,
      stdShellArgs,
      mkGraphicalCheck,
      mkInstaller,
      wine-stuff,
      ...
    }:
    let
      scripts = pkgs.callPackage ./scripts.nix {
        inherit (wine-stuff.v2) wine;

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
