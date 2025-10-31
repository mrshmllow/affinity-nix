{
  perSystem =
    {
      pkgs,
      self',
      affinityPath,
      version,
      stdShellArgs,
      mkGraphicalCheck,
      mkInstaller,
      ...
    }:
    let
      scripts = pkgs.callPackage ./scripts.nix {
        wine = self'.packages.v2-wine;
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
      packages = {
        updatePhoto = mkInstaller "Photo";
        directPhoto = scripts.createPackage "Photo";
        updateDesigner = mkInstaller "Designer";
        directDesigner = scripts.createPackage "Designer";
        updatePublisher = mkInstaller "Publisher";
        directPublisher = scripts.createPackage "Publisher";
      };
    };
}
