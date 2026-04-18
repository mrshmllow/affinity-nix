{
  pkgs,
  writeShellScriptBin,
  mkOverlayfsRunner,
  lib,
  apps,
  stdShellArgs,
  wine-stuff,
  wine,
}:
rec {
  createScript =
    type: name:
    let
      inherit (wine-stuff)
        wineboot
        winetricks
        wineserver
        ;
    in
    writeShellScriptBin "affinity-${lib.toLower name}" ''
      ${stdShellArgs}

      function show_help {
          cat << EOF
      Usage: $(basename "$0") [COMMAND] [OPTIONS]

      Commands:
        wine
        winetricks
        wineboot
        wineserver
        help                    Show this
        (nothing)               Launch Affinity ${name}
      EOF
      }

      case "${"\${1:-}"}" in
          -h|--help|help)
              show_help
              exit 0
              ;;
          wine)
              shift
              exec ${
                lib.getExe (mkOverlayfsRunner {
                  name = type;
                  package = wine;
                  args = "";
                  pre_run = null;
                })
              } "$@"
              ;;
          winetricks)
              shift
              exec ${
                lib.getExe (mkOverlayfsRunner {
                  name = type;
                  package = winetricks;
                  args = "";
                  pre_run = null;
                })
              } "$@"
              ;;
          wineboot)
              shift
              exec ${
                lib.getExe (mkOverlayfsRunner {
                  name = type;
                  package = wineboot;
                  args = "";
                  pre_run = null;
                })
              } "$@"
              ;;
          wineserver)
              shift
              exec ${
                lib.getExe (mkOverlayfsRunner {
                  name = type;
                  package = wineserver;
                  args = "";
                  pre_run = null;
                })
              } "$@"
              ;;
          *)
              exec ${lib.getExe apps.${lib.toLower name}} "$@"
              ;;
      esac
    '';

  createUnifiedPackage =
    name:
    let
      app = apps.${lib.toLower name};
      pkg = createScript (lib.toLower name) name;

      # last version of affinity v2 released
      lastV2Version = "2.6.5";
    in
    pkgs.symlinkJoin {
      name = "affinity-${if (name == "v3") then "v3" else "${lib.toLower name}-${lastV2Version}"}";
      # order is important because the script and the app both use the same
      # binary name...
      paths = [
        pkg
        app
      ];
      meta = {
        description = "Affinity ${if (name == "v3") then "v3" else "${name} ${lastV2Version}"}";
        license = lib.licenses.unfree;
        homepage = "https://affinity.serif.com/";
        platforms = [ "x86_64-linux" ];
        mainProgram = "affinity-${lib.toLower name}";
      };
    };
}
