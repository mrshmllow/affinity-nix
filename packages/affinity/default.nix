{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      self',
      affinityPath,
      wineUnwrapped,
      sources,
      version,
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
        inherit
          affinityPath
          wineUnwrapped
          sources
          version
          ;
        inherit (inputs) on-linux;
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
