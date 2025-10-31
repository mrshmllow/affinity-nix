{
  perSystem =
    {
      pkgs,
      affinityPathV2,
      version,
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
          affinityPathV2
          version
          stdShellArgs
          mkGraphicalCheck
          mkInstaller
          ;
      };
    in
    {
      _module.args = {
        updatePhoto = mkInstaller "Photo";
        directPhoto = scripts.createPackage "Photo";
        updateDesigner = mkInstaller "Designer";
        directDesigner = scripts.createPackage "Designer";
        updatePublisher = mkInstaller "Publisher";
        directPublisher = scripts.createPackage "Publisher";
      };
    };
}
