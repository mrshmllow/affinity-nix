{
  pkgs,
  writeShellScriptBin,
  lib,
  wine,
  wineserver,
  affinityPathV3,
  stdShellArgs,
  mkInstaller,
  mkGraphicalCheck,
  sources,
  mkPrefixBase,
}:
rec {
  createRunner =
    let
      installer = mkInstaller "v3";
      check = mkGraphicalCheck "v3";
      prefixBase = mkPrefixBase true;
    in
    writeShellScriptBin "affinity-v3" ''
      set -x
      ${stdShellArgs}

      export USER_UPPER="$HOME/.local/share/affinity/upper"
      export USER_WORK="$HOME/.local/share/affinity/work"
      mkdir -p "$USER_UPPER" "$USER_WORK"

      (cd "${prefixBase}" && find . -type d -exec mkdir -p "$USER_UPPER/{}" \;)

      export MERGED_PREFIX=$(mktemp -d)

      mkdir -p $MERGED_PREFIX

      echo "affinity-nix: attempting to mount via kernel"

      function launch_v3() {
        if [ ! -f "$MERGED_PREFIX/drive_c/Program Files/Affinity/Affinity/Affinity.exe" ]; then
            ${lib.getExe installer} || exit 1
        elif [ -f "$MERGED_PREFIX/installed-hash" ]; then
            installed_hash=$(<"$MERGED_PREFIX/installed-hash")

            if [[ "$installed_hash" != "${sources.v3.sha256}" ]] && zenity --question --text="New update found, would you like to install it?"; then
              ${lib.getExe installer} || exit 1
            fi
        fi

        if [ "$1" != "--verbose" ]; then
            export WINEDEBUG=-all,fixme-all
        else
          shift
        fi

        ${lib.getExe check} || exit 1
        ${lib.getExe wine} "$MERGED_PREFIX/drive_c/Program Files/Affinity/Affinity/AffinityHook.exe" "$@"
      }

      export -f launch_v3

      if ${lib.getExe' pkgs.util-linux "unshare"} -U -m --map-root-user ${lib.getExe pkgs.bash} -c '
          set -x

          # exits so we can trigger the FUSE fallback if kernel does not support this.
          mount -t overlay overlay -o lowerdir="${prefixBase}",upperdir="$USER_UPPER",workdir="$USER_WORK" "$MERGED_PREFIX" || exit 1
          
          export WINEPREFIX="$MERGED_PREFIX"
          launch_v3 "$@"
      ' -- "$@"; then
          echo "affinity-nix: kernel overlayfs session ended cleanly"
      else
          echo "affinity-nix: kernel mount blocked by host. falling back to FUSE"
          
          ${lib.getExe pkgs.fuse-overlayfs} -o lowerdir="${prefixBase}",upperdir="$USER_UPPER",workdir="$USER_WORK" "$MERGED_PREFIX"
          
          export WINEPREFIX="$MERGED_PREFIX"
          
          launch_v3 "$@"
          
          # unmount FUSE when wine closes
          ${lib.getExe wineserver} -w
          mount -l "$MERGED_PREFIX"
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
