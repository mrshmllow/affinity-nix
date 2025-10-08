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
        directPhoto = scripts.createPackage "Photo";
        updateDesigner = scripts.createInstaller "Designer";
        directDesigner = scripts.createPackage "Designer";
        updatePublisher = scripts.createInstaller "Publisher";
        directPublisher = scripts.createPackage "Publisher";
      };
    };
}
