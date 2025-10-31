{
  perSystem =
    {
      pkgs,
      self',
      sources,
      stdShellArgs,
      wine-stuff,
      updatePhoto,
      updateDesigner,
      updatePublisher,
      updateV3,
      directPhoto,
      directDesigner,
      directPublisher,
      directV3,
      ...
    }:
    let
      scripts = pkgs.callPackage ./scripts.nix {
        inherit sources stdShellArgs wine-stuff;
        apps = {
          photo = directPhoto;
          designer = directDesigner;
          publisher = directPublisher;
          v3 = directV3;
        };
        updateApps = {
          photo = updatePhoto;
          designer = updateDesigner;
          publisher = updatePublisher;
          v3 = updateV3;
        };
      };
    in
    {
      packages = {
        default = self'.packages.v3;

        photo = scripts.createUnifiedPackage "Photo";
        designer = scripts.createUnifiedPackage "Designer";
        publisher = scripts.createUnifiedPackage "Publisher";

        v3 = scripts.createUnifiedPackage "v3";
      };
    };
}
