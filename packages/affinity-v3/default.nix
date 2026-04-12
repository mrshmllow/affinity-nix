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
        let
          inherit (wine-stuff)
            wine
            ;

          pkg = mkOverlayfsRunner "v3" ''
            ${lib.getExe wine} "$MERGED_PREFIX/drive_c/Program Files/Affinity/Affinity/AffinityHook.exe" "$@"
          '';

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
            mainProgram = "af-overlay-v3";
          };
        };
    in
    {
      _module.args = {
        directV3 = createPackage;
      };
    };
}
