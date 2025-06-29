{
  perSystem =
    {
      pkgs,
      self',
      affinityPath,
      wineUnwrapped,
      ...
    }:
    let
      scripts = pkgs.callPackage ./scripts.nix {
        inherit (self'.packages)
          wineboot
          winetricks
          wine
          ;
        inherit affinityPath wineUnwrapped;
      };
    in
    {
      packages = {
        updatePhoto = scripts.createInstaller "Photo";
        photo = scripts.createPackage "Photo";
        updateDesigner = scripts.createInstaller "Designer";
        designer = scripts.createPackage "Designer";
        updatePublisher = scripts.createInstaller "Publisher";
        publisher = scripts.createPackage "Publisher";
      };
    };
}
