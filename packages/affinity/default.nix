{
  perSystem =
    {
      pkgs,
      lib,
      mkOverlayfsRunner,
      wine-stuff,
      ...
    }:
    let
      createPackage =
        name:
        let
          inherit (wine-stuff)
            wine
            ;

          # pkg = mkOverlayfsRunner name ''
          #   ${lib.getExe (mkGraphicalCheck name)} || exit 1
          #   ${lib.getExe wine} "$WINEPREFIX/drive_c/Program Files/Affinity/${name} 2/${name}.exe" "$@"
          # '';

          pkg =
            mkOverlayfsRunner "v3" wine
              ''"WINEPREFIX/drive_c/Program Files/Affinity/${name} 2/${name}.exe"'';

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
          meta = {
            description = "Affinity ${name} 2";
            homepage = "https://affinity.serif.com/";
            # license = lib.licenses.unfree;
            # maintainers = with pkgs.lib.maintainers; [marshmallow];
            platforms = [ "x86_64-linux" ];
            mainProgram = "af-overlay-${lib.toLower name}";
          };
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
