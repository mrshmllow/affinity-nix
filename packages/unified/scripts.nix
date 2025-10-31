{
  pkgs,
  writeShellScriptBin,
  lib,
  sources,
  apps,
  updateApps,
  stdShellArgs,
  packages,
}:
rec {
  createScript =
    v3:
    let
      type = if v3 then "v3" else "v2";
      wine = packages."${type}-wine";
      wineboot = packages."${type}-wineboot";
      winetricks = packages."${type}-winetricks";
      wineserver = packages."${type}-wineserver";
    in
    name:
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
        update|repair|install   Update or repair the application
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
      v3 = name == "v3";

      app = apps.${lib.toLower name};
      pkg = createScript v3 name;

      version = if v3 then "" else sources._version;
      postfix = if v3 then "" else "-${version}";
    in
    pkgs.symlinkJoin {
      name = "Affinity ${name} ${version}";
      pname = "affinity-${lib.toLower name}${postfix}";
      # order is important because the script and the app both use the same
      # binary name...
      paths = [
        pkg
        app
      ];
      meta = {
        description = "Affinity ${name} ${version}";
        homepage = "https://affinity.serif.com/";
        platforms = [ "x86_64-linux" ];
        mainProgram = "affinity-${lib.toLower name}${postfix}";
      };
    };
}
