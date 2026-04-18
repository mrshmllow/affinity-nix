{
  perSystem =
    {
      pkgs,
      lib,
      mkOverlayfsRunner,
      mkGraphicalCheck,
      self',
      ...
    }:
    let
      createPackage =
        name:
        let
          inherit (self'.packages) wine;

          pkg = mkOverlayfsRunner {
            name = lib.toLower name;
            package = wine;
            args = ''"WINEPREFIX/drive_c/Program Files/Affinity/${name} 2/${name}.exe"'';
            pre_run = lib.getExe (mkGraphicalCheck name);
          };

          desktop = pkgs.callPackage ./desktopItems.nix {
            ${lib.toLower name} = pkg;
          };

          icons = pkgs.callPackage ./icons.nix { };
          icon-package = icons.mkIconPackageFor name;
        in
        pkgs.symlinkJoin {
          name = "Affinity ${name}";
          pname = "affinity-${lib.toLower name}";
          paths = [
            pkg
            desktop.${lib.toLower name}
            icon-package
          ];
          meta.mainProgram = "af-overlay-${lib.toLower name}";
        };
    in
    {
      _module.args = {
        directPhoto = createPackage "Photo";
        directDesigner = createPackage "Designer";
        directPublisher = createPackage "Publisher";
      };
    };
}
