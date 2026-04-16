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
          name: script:
          let
            prefixBase = mkPrefixBase (name == "v3");

            inherit (wine-stuff)
              wineserver
              wineboot
              ;
          in
          pkgs.writeShellScriptBin "af-overlay-${lib.toLower name}" ''
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

            # migrate from the pre-overlayfs system before the overlayfs is mounted
            if [[ -f "$USER_UPPER/.revision" && $(<"$USER_UPPER/.revision") -lt 9 ]]; then
               echo "affinity-nix: migrating to overlayfs"

               backup_location="$HOME/affinity-nix-backup.tar.zst"

               if ! zenity --question --width 480 --text="There have been upgrades to affinity-nix!\n\nAffinity and it's dependencies are no longer installed directly, reducing startup time and manual updating.\n\nTo migrate, we need to delete the old installation. Your registry files and user data won't be touched. A backup will be created in at $backup_location. Is that OK?"; then
                   exit 1
               fi

               ${lib.getExe pkgs.gnutar} --zstd -cpf "$backup_location" $USER_UPPER || exit 1
               find "$USER_UPPER/drive_c" -mindepth 1 -maxdepth 1 ! -name "users" -print -exec rm -rf {} +
            fi

            if [ -d "$USER_WORK/work" ]; then
                chmod 700 "$USER_WORK/work"
                rm -rf "$USER_WORK/work"
            fi

            export WINEPREFIX="$(mktemp -d)"

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
                      if [ -f "${prefixBase}/$regfile" ] && [ ! -f "$USER_UPPER/$regfile" ]; then
                          sed "s/nixbld/$USER/g" "${prefixBase}/$regfile" > "$USER_UPPER/$regfile"
                          chmod u+w "$USER_UPPER/$regfile"
                      fi
                  done

                  # this update is required to fix memory corruption crashes when opening and
                  # saving files with a file selection prompt.
                  ${lib.getExe wineboot} --update
              ) | zenity --progress \
                --pulsate \
                --no-cancel \
                --auto-close \
                --auto-kill \
                --title="Affinity Setup" \
                --text="Initializing environment..."

              ${script}
            }

            export -f launch
            unshare_status=0

            echo "affinity-nix: attempting to mount via kernel"
            ${lib.getExe' pkgs.util-linux "unshare"} -U -m -p -f --map-root-user ${lib.getExe pkgs.bash} -c '
                set -x

                # exits so we can trigger the FUSE fallback if kernel does not support this.
                if ! mount -t overlay overlay -o lowerdir="${prefixBase}",upperdir="$USER_UPPER",workdir="$USER_WORK" "$WINEPREFIX"; then
                    exit 111
                fi

                launch "$@"

                ${lib.getExe wineserver} -w
            ' -- "$@" || unshare_status=$?

            if [ $unshare_status -eq 0 ]; then
                echo "affinity-nix: kernel overlayfs session ended cleanly"
            elif [ $unshare_status -eq 111 ]; then
                echo "affinity-nix: kernel mount blocked by host! falling back to FUSE overlayfs"

                function cleanup_fuse() {
                    ${lib.getExe wineserver} -k

                    # must use host binary because of setuid
                    if ! /usr/bin/env fusermount3 -u -z "$WINEPREFIX" 2>/dev/null; then
                        if ! /usr/bin/env fusermount -u -z "$WINEPREFIX" 2>/dev/null; then
                            echo "affinity-nix: both fusermount and fusermount3 failed to unmount"
                            return 1
                        fi
                    fi

                    return 0
                }

                trap cleanup_fuse EXIT

                ${lib.getExe pkgs.fuse-overlayfs} -o lowerdir="${prefixBase}",upperdir="$USER_UPPER",workdir="$USER_WORK" "$WINEPREFIX" || exit 1

                launch "$@"

                ${lib.getExe wineserver} -w
            else
                echo "affinity-nix: application exited with error ($unshare_status) inside kernel overlayfs"
                exit $unshare_status
            fi

            rmdir $WINEPREFIX
          '';
      };
    };
}
