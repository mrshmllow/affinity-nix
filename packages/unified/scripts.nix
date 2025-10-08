{
  pkgs,
  writeShellScriptBin,
  lib,
  wine,
  wineboot,
  winetricks,
  wineserver,
  sources,
  apps,
  updateApps,
}:
rec {
  createScript =
    name:
    writeShellScriptBin "affinity-${lib.toLower name}-2" ''
      function show_help {
          cat << EOF
      Usage: $(basename "$0") [COMMAND] [OPTIONS]

      Commands:
        wine
        winetricks
        wineboot
        wineserver
        update|repair|install   Update or repair the application
        help                    Show this
        (nothing)               Launch Affinity ${name} 2
      EOF
      }

      case "${"\${1:-}"}" in
          -h|--help|help)
              show_help
              exit 0
              ;;
          wine)
              shift
              exec ${lib.getExe wine} "$@"
              ;;
          winetricks)
              shift
              exec ${lib.getExe winetricks} "$@"
              ;;
          wineboot)
              shift
              exec ${lib.getExe wineboot} "$@"
              ;;
          wineserver)
              shift
              exec ${lib.getExe wineserver} "$@"
              ;;
          update|repair|install)
              shift
              exec ${lib.getExe updateApps.${lib.toLower name}} "$@"
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
      pkg = createScript name;
    in
    pkgs.symlinkJoin {
      name = "Affinity ${name} ${sources._version}";
      pname = "affinity-${lib.toLower name}-${sources._version}";
      paths = [
        app
        pkg
      ];
      postBuild = ''
        rm $out/bin/run-affinity-${lib.toLower name}-2
      '';
      meta = {
        description = "Affinity ${name} 2";
        homepage = "https://affinity.serif.com/";
        platforms = [ "x86_64-linux" ];
        mainProgram = "affinity-${lib.toLower name}-2";
      };
    };
}
