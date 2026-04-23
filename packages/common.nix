{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      self',
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
            latestRevision = "10";

            registry-patches = pkgs.callPackage ./registry-patches.nix { };

            inherit (self'.packages) wine;
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

                if [ $prefixRevision -lt 10 ]; then
                    ${lib.getExe wine} regedit /S "${registry-patches.one-vkd3d}"
                fi

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
      };
    };
}
