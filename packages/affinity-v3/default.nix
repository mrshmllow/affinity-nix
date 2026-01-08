{
  perSystem =
    {
      pkgs,
      affinityPathV3,
      stdShellArgs,
      mkGraphicalCheck,
      mkInstaller,
      wine-stuff,
      sources,
      ...
    }:
    let
      scripts = pkgs.callPackage ./scripts.nix {
        inherit (wine-stuff.v3) wine;

        inherit
          sources
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
