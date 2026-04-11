{
  perSystem =
    {
      pkgs,
      lib,
      mkOverlayfsRunner,
      ...
    }:
    let
      createPackage =
        name:
        let
          pkg = mkOverlayfsRunner name "${name} 2/${name}.exe";
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
            mainProgram = "affinity-${lib.toLower name}";
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
