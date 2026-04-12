{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      stdShellArgs,
      wine-stuff,
      wineUnwrapped,
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
            latestRevision = "8";
          in
          pkgs.writeShellScriptBin "check" ''
            set -x -e
            ${lib.strings.toShellVars {
              inherit type;
              tricksInstalled = 0;
              apps = [
                "Photo"
                "Designer"
                "Publisher"
              ];
            }}

            function setup {
                local prefixRevision="$1"

                if [[ "$prefixRevision" -le 7 ]]; then
                   echo "affinity-nix: Removing old APL Plugins directory"

                   # will delete the user's plugins, unfortunate.
                   # i dont know how many other plugins even exist, anyway
                   # they will be unsupported by newer apl, anyway.
                   # source: https://github.com/noahc3/AffinityPluginLoader/releases/tag/v0.3.0
                   rm -rf "$MERGED_PREFIX/drive_c/Program Files/Affinity/Affinity/plugins"
                fi

                echo "${latestRevision}" > $MERGED_PREFIX/.revision
            }

            # older prefix with no revision number
            if [ ! -f "$MERGED_PREFIX/.revision" ]; then
                echo "affinity-nix: Running setup, no revision"

                setup "0"
            else
                prefixRevision=$(<"$MERGED_PREFIX/.revision")

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

                    mkdir -p "$MERGED_PREFIX/drive_c/users/$USER/AppData/Roaming/Affinity/$app/2.0/"

                    ${lib.getExe pkgs.rsync} -v \
                        --ignore-existing \
                        --chmod=644 \
                        --recursive \
                        "${inputs.on-linux}/Auxillary/Settings/$app/2.0/" \
                        "$MERGED_PREFIX/drive_c/users/$USER/AppData/Roaming/Affinity/$app/2.0/"
                done
            fi
          '';

        mkGraphicalCheck =
          name:
          let
            check = mkCheck (name == "v3");
          in
          pkgs.writeShellScriptBin "affinity-v3-gui-check" ''
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
          name: executable_name:
          let
            check = mkGraphicalCheck name;
            prefixBase = mkPrefixBase (name == "v3");

            inherit (wine-stuff.${if name == "v3" then "v3" else "v2"})
              wine
              wineserver
              ;
          in
          pkgs.writeShellScriptBin "affinity-${lib.toLower name}" ''
            set -x
            ${stdShellArgs}

            export USER_WORK=$([[ -z "$XDG_STATE_HOME" ]] && echo "$HOME/.local/state/affinity-nix-2" || echo "$XDG_STATE_HOME/affinity-nix-2")

            ${
              if name == "v3" then
                ''
                  export USER_UPPER=$([[ -z "$XDG_DATA_HOME" ]] && echo "$HOME/.local/share/affinity-v3" || echo "$XDG_DATA_HOME/affinity-v3")
                ''
              else
                ''
                  export USER_UPPER=$([[ -z "$XDG_DATA_HOME" ]] && echo "$HOME/.local/share/affinity" || echo "$XDG_DATA_HOME/affinity")
                ''
            }

            mkdir -p "$USER_UPPER" "$USER_WORK"

            if [ -d "$USER_WORK/work" ]; then
                chmod 700 "$USER_WORK/work"
                rm -rf "$USER_WORK/work"
            fi

            export MERGED_PREFIX=$(mktemp -d)

            function launch() {
              if [ "$1" != "--verbose" ]; then
                  export WINEDEBUG=-all,fixme-all
              else
                  shift
              fi

              (
                  # this is necessary for the current user to have "permission" to read anything
                  # inside the overlayfs
                  echo "warming up upperdir"
                  (cd "${prefixBase}" && find . -type d -exec mkdir -p "$USER_UPPER/{}" \;)

                  # this lets the user change their registry files
                  for regfile in system.reg user.reg userdef.reg .update-timestamp; do
                      if [ -f "''${prefixBase}/$regfile" ] && [ ! -f "$USER_UPPER/$regfile" ]; then
                          cp "''${prefixBase}/$regfile" "$USER_UPPER/$regfile"
                          chmod u+w "$USER_UPPER/$regfile"
                      fi
                  done
              ) | zenity --progress \
                --pulsate \
                --title="Affinity Setup" \
                --text="Initializing environment..." \
                --auto-close \
                --auto-kill

              ${lib.getExe check} || exit 1
              ${lib.getExe wine} "$MERGED_PREFIX/drive_c/Program Files/Affinity/${executable_name}" "$@"
            }

            export -f launch

            echo "affinity-nix: attempting to mount via kernel"

            export WINEPREFIX="$MERGED_PREFIX"

            if ${lib.getExe' pkgs.util-linux "unshare"} -U -m -p -f --map-root-user ${lib.getExe pkgs.bash} -c '
                set -x

                # exits so we can trigger the FUSE fallback if kernel does not support this.
                mount -t overlay overlay -o lowerdir="${prefixBase}",upperdir="$USER_UPPER",workdir="$USER_WORK" "$MERGED_PREFIX" || exit 1

                launch "$@"
            ' -- "$@"; then
                echo "affinity-nix: kernel overlayfs session ended cleanly"
            else
                echo "affinity-nix: kernel mount blocked by host! falling back to FUSE overlayfs"

                function cleanup_fuse() {
                    ${lib.getExe wineserver} -k

                    # must use host binary because of setuid
                    if mountpoint -q "$MERGED_PREFIX"; then
                        /usr/bin/env fusermount3 -u -z "$MERGED_PREFIX" 2>/dev/null || \
                        /usr/bin/env fusermount -u -z "$MERGED_PREFIX" 2>/dev/null
                    fi
                }

                trap cleanup_fuse EXIT

                ${lib.getExe pkgs.fuse-overlayfs} -o lowerdir="${prefixBase}",upperdir="$USER_UPPER",workdir="$USER_WORK" "$MERGED_PREFIX" || exit 1

                launch "$@"

                ${lib.getExe wineserver} -w

                exit
            fi

            rmdir $MERGED_PREFIX
          '';
      };
    };
}
