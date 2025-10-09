{
  perSystem =
    {
      pkgs,
      self',
      sources,
      ...
    }:
    let
      scripts = pkgs.callPackage ./scripts.nix {
        inherit (self'.packages)
          wineboot
          winetricks
          wine
          wineserver
          ;
        inherit sources;
        apps = {
          photo = self'.packages.directPhoto;
          designer = self'.packages.directDesigner;
          publisher = self'.packages.directPublisher;
        };
        updateApps = {
          photo = self'.packages.updatePhoto;
          designer = self'.packages.updatePhoto;
          publisher = self'.packages.updatePublisher;
        };
      };
    in
    {
      packages = {
        default = self'.packages.photo;

        photo = scripts.createUnifiedPackage "Photo";
        designer = scripts.createUnifiedPackage "Designer";
        publisher = scripts.createUnifiedPackage "Publisher";
      };
    };
}
