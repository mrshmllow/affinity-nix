{
  perSystem =
    {
      pkgs,
      stdShellArgs,
      mkGraphicalCheck,
      mkInstaller,
      wine-stuff,
      mkPrefixBase,
      ...
    }:
    let
      scripts = pkgs.callPackage ./scripts.nix {
        inherit (wine-stuff.v3) wine;

        inherit
          stdShellArgs
          mkGraphicalCheck
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
