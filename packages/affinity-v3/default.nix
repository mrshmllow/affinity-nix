{
  perSystem =
    {
      pkgs,
      stdShellArgs,
      mkGraphicalCheck,
      mkInstaller,
      wine-stuff,
      sources,
      mkPrefixBase,
      ...
    }:
    let
      scripts = pkgs.callPackage ./scripts.nix {
        inherit (wine-stuff.v3) wine wineserver;

        inherit
          sources
          stdShellArgs
          mkGraphicalCheck
          mkInstaller
          mkPrefixBase
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
