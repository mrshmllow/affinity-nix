{
  pkgs,
  writeShellScriptBin,
  lib,
  wine,
  wineserver,
  stdShellArgs,
  mkGraphicalCheck,
  sources,
  mkPrefixBase,
}:
rec {
  createRunner =
    let
      check = mkGraphicalCheck "v3";
      prefixBase = mkPrefixBase true;
    in
    writeShellScriptBin "affinity-v3" ''
      set -x
      ${stdShellArgs}

      export USER_WORK=$([[ -z "$XDG_STATE_HOME" ]] && echo "$HOME/.local/state/affinity-nix" || echo "$XDG_DATA_HOME/affinity-nix")
      export USER_UPPER=$([[ -z "$XDG_DATA_HOME" ]] && echo "$HOME/.local/share/affinity-nix" || echo "$XDG_DATA_HOME/affinity-nix")

      mkdir -p "$USER_UPPER" "$USER_WORK"

      export MERGED_PREFIX=$(mktemp -d)

      echo "affinity-nix: attempting to mount via kernel"

      function launch_v3() {
        if [ "$1" != "--verbose" ]; then
            export WINEDEBUG=-all,fixme-all
        else
            shift
        fi

        ${lib.getExe check} || exit 1
        ${lib.getExe wine} "$MERGED_PREFIX/drive_c/Program Files/Affinity/Affinity/Affinity.exe" "$@"
      }

      export -f launch_v3

      export OVERLAY_LOWER_DIR=$(mktemp -d)

      if ${lib.getExe' pkgs.util-linux "unshare"} -U -m --map-root-user ${lib.getExe pkgs.bash} -c '
          set -x

          ${lib.getExe' pkgs.erofs-utils "erofsfuse"} ${prefixBase}/base.erofs.img $OVERLAY_LOWER_DIR

          # exits so we can trigger the FUSE fallback if kernel does not support this.
          mount -t overlay overlay -o lowerdir="$OVERLAY_LOWER_DIR",upperdir="$USER_UPPER",workdir="$USER_WORK" "$MERGED_PREFIX" || exit 1

          echo "warming up upperdir"
          # this is necessary for the current user to have "permission" to read anything
          (cd "$OVERLAY_LOWER_DIR" && find . -type d -exec mkdir -p "$USER_UPPER/{}" \;)
          
          export WINEPREFIX="$MERGED_PREFIX"

          launch_v3 "$@"
      ' -- "$@"; then
          echo "affinity-nix: kernel overlayfs session ended cleanly"
      else
          echo "affinity-nix: kernel mount blocked by host!!!"
          exit
      fi

      rmdir "$MERGED_PREFIX"
    '';

  createPackage =
    let
      pkg = createRunner;
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
}
