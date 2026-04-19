{
  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    let
      createPackage =
        name:
        let
          pkg = self'.packages.runner.override {
            inherit name;
          };

          desktop = pkgs.callPackage ./desktopItems.nix {
            ${lib.toLower name} = pkg;
          };

          icons = pkgs.callPackage ./icons.nix { };
          icon-package = icons.mkIconPackageFor name;

          # last version of affinity v2 released
          lastV2Version = "2.6.5";
        in
        pkgs.symlinkJoin {
          name = "affinity-${name}-${lastV2Version}";
          pname = "affinity-${lib.toLower name}";
          paths = [
            pkg
            desktop.${lib.toLower name}
            icon-package
          ];
          meta = {
            mainProgram = "affinity-${lib.toLower name}";

            description = "Affinity ${name} ${lastV2Version}";
            license = lib.licenses.unfree;
            homepage = "https://affinity.serif.com/";
            platforms = [ "x86_64-linux" ];
          };
        };
    in
    {
      packages = {
        photo = createPackage "Photo";
        designer = createPackage "Designer";
        publisher = createPackage "Publisher";
      };
    };
}
