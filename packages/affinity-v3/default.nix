{
  perSystem =
    {
      pkgs,
      mkOverlayfsRunner,
      wine-stuff,
      lib,
      mkGraphicalCheck,
      self',
      ...
    }:
    let
      createPackage =
        let
          inherit (self'.packages)
            wine
            ;

          pkg = mkOverlayfsRunner {
            name = "v3";
            package = wine;
            args = ''"WINEPREFIX/drive_c/Program Files/Affinity/Affinity/AffinityHook.exe"'';
            pre_run = lib.getExe (mkGraphicalCheck "v3");
          };

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
          meta.mainProgram = "af-overlay-v3";
        };
    in
    {
      _module.args = {
        directV3 = createPackage;
      };
    };
}
