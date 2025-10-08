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
          inherit (self'.packages) photo designer publisher;
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
        _appimage_photo = scripts.createUnifiedPackage "Photo";
        _appimage_designer = scripts.createUnifiedPackage "Designer";
        _appimage_publisher = scripts.createUnifiedPackage "Publisher";
      };
    };
}
