{
  perSystem =
    {
      pkgs,
      mkOverlayfsRunner,
      ...
    }:
    let
      createPackage =
        let
          pkg = mkOverlayfsRunner "v3" "Affinity/AffinityHook.exe";
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
            description = "Affinity v3";
            homepage = "https://www.affinity.studio";
            # license = lib.licenses.unfree;
            # maintainers = with pkgs.lib.maintainers; [marshmallow];
            platforms = [ "x86_64-linux" ];
            mainProgram = "affinity-v3";
          };
        };
    in
    {
      _module.args = {
        directV3 = createPackage;
      };
    };
}
