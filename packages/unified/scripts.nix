{
  pkgs,
  writeShellScriptBin,
  lib,
  apps,
  stdShellArgs,
  wine-stuff,
}:
rec {
  createScript =
    v3: name:
    let
      type = if v3 then "v3" else "v2";
      inherit (wine-stuff."${type}")
        wine
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

      # last version of affinity v2 released
      version = if v3 then null else "2.6.5";
    in
    pkgs.symlinkJoin {
      name = "Affinity ${name}${lib.optionalString (version != null) " ${version}"}}";
      pname = "affinity-${lib.toLower name}";
      # order is important because the script and the app both use the same
      # binary name...
      paths = [
        pkg
        app
      ];
      meta = {
        description = "Affinity ${name}${lib.optionalString (version != null) " ${version}"}";
        homepage = "https://affinity.serif.com/";
        platforms = [ "x86_64-linux" ];
        mainProgram = "affinity-${lib.toLower name}";
      };
    };
}
