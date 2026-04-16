{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      stdShellArgs,
      wine-stuff,
      self',
      mkPrefixBase,
      ...
    }:
    {
      _module.args = rec {
        mkInjectPluginLoader = pkgs.writeShellScriptBin "inject-plugin-loader" ''
          set -x -e
          pushd "$WINEPREFIX/drive_c/Program Files/Affinity/Affinity"
          cp -r "${self'.packages.apl-combined}/." .
          popd
        '';

        mkCheck =
          v3:
          let
            type = if v3 then "v3" else "v2";
            latestRevision = "9";
          in
          pkgs.writeShellScriptBin "check" ''
            set -x -e
            ${lib.strings.toShellVars {
              inherit type;
              apps = [
                "Photo"
                "Designer"
                "Publisher"
              ];
            }}

            function setup {
                local prefixRevision="$1"

                # no upgrade migrations currently exist

                echo "${latestRevision}" > $WINEPREFIX/.revision
            }

            # older prefix with no revision number
            if [ ! -f "$WINEPREFIX/.revision" ]; then
                echo "affinity-nix: Running setup, no revision"

                setup "0"
            else
                prefixRevision=$(<"$WINEPREFIX/.revision")

                # only install deps if the revision number is higher than the
                # one found in the prefix
                if [[ "${latestRevision}" -gt "$prefixRevision" ]]; then
                  echo "affinity-nix: Running setup, old prefix revision"

                  setup "$prefixRevision"
                fi
            fi

            if [[ "$type" == "v2" ]]; then
                for app in "${"\${apps[@]}"}"; do
                    echo "affinity-nix: Installing settings for $app"

                    mkdir -p "$WINEPREFIX/drive_c/users/$USER/AppData/Roaming/Affinity/$app/2.0/"

                    ${lib.getExe pkgs.rsync} -v \
                        --ignore-existing \
                        --chmod=D755,F644 \
                        --recursive \
                        "${inputs.on-linux}/Auxiliary/Settings/$app/2.0/" \
                        "$WINEPREFIX/drive_c/users/$USER/AppData/Roaming/Affinity/$app/2.0/"
                done
            fi
          '';

        mkGraphicalCheck =
          name:
          let
            check = mkCheck (name == "v3");
          in
          pkgs.writeShellScriptBin "affinity-v3-gui-check" ''
            ${stdShellArgs}

            FIFO=$(mktemp -u)

            mkfifo "$FIFO"

            zenity --progress \
                --pulsate \
                --no-cancel \
                --auto-close \
                --title="Affinity" \
                --text="Preparing the wine prefix\n\nThis can take a while.\n" \
                < $FIFO &

            zenity_pid=$!

            ${lib.getExe check} > $FIFO

            if [ ! $? -eq 0 ]; then
                zenity --error --text="Preparing the wine prefix failed."

                exit 1
            fi
          '';

        mkOverlayfsRunner =
          {
            name,
            package,
            args,
            pre_run,
          }:
          let
            prefixBase = mkPrefixBase (name == "v3");

            inherit (wine-stuff) wineboot;
          in
          pkgs.writeShellScriptBin "af-overlay-${lib.toLower name}" ''
            set -x
            ${stdShellArgs}

            verbose="true"

            if [ "$1" != "--verbose" ]; then
                verbose="false"
            else
                shift
            fi

            ${lib.getExe self'.packages.runner} \
                --lower="${prefixBase}" ${
                  lib.optionalString (!(builtins.isNull pre_run)) "--pre-run ${pre_run}"
                } \
                --verbose=$verbose \
                --wineboot="${lib.getExe wineboot}" ${lib.optionalString (name == "v3") "--v3"} \
                --command="${lib.getExe package}" -- ${args} "$@"
          '';
      };
    };
}
