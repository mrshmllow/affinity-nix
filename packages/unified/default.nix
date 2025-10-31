{
  perSystem =
    {
      pkgs,
      self',
      sources,
      stdShellArgs,
      ...
    }:
    let
      scripts = pkgs.callPackage ./scripts.nix {
        inherit (self') packages;
        inherit sources stdShellArgs;
        apps = {
          photo = self'.packages.directPhoto;
          designer = self'.packages.directDesigner;
          publisher = self'.packages.directPublisher;
          v3 = self'.packages.v3-direct;
        };
        updateApps = {
          photo = self'.packages.updatePhoto;
          designer = self'.packages.updatePhoto;
          publisher = self'.packages.updatePublisher;
          v3 = self'.packages.v3-update;
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
