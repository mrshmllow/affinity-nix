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
        let
          pkg = self'.packages.runner;

          desktop = pkgs.callPackage ./desktopItems.nix {
            affinity-v3 = pkg;
          };

          icons = pkgs.callPackage ./icons.nix { };
          icon-package = icons.iconPackage;
        in
        pkgs.symlinkJoin {
          name = "Affinity v3";
          pname = "affinity-v3";
          paths = [
            pkg
            desktop.affinity-v3
            icon-package
          ];
          meta = {
            mainProgram = "affinity-v3";

            description = "Affinity v3";
            license = lib.licenses.unfree;
            homepage = "https://affinity.serif.com/";
            platforms = [ "x86_64-linux" ];
          };
        };
    in
    {
      packages = {
        affinity-v3 = createPackage;
        default = self'.packages.affinity-v3;

        v3 = lib.warn "the `v3` package is deprecated, please use `affinity-v3` instead." self'.packages.affinity-v3;
      };
    };
}
