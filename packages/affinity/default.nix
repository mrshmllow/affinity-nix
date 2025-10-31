{
  perSystem =
    {
      pkgs,
      affinityPath,
      version,
      stdShellArgs,
      mkGraphicalCheck,
      mkInstaller,
      v2-wine,
      ...
    }:
    let
      scripts = pkgs.callPackage ./scripts.nix {
        wine = v2-wine;
        inherit
          affinityPath
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
