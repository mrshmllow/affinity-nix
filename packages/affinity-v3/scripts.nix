{
  pkgs,
  writeShellScriptBin,
  lib,
  wine,
  affinityPathV3,
  stdShellArgs,
  mkInstaller,
  mkGraphicalCheck,
  sources,
}:
rec {
  createRunner =
    let
      installer = mkInstaller "v3";
      check = mkGraphicalCheck "v3";
    in
    writeShellScriptBin "affinity-v3" ''
      set -x
      ${stdShellArgs}

      if [ ! -f "${affinityPathV3}/drive_c/Program Files/Affinity/Affinity/Affinity.exe" ]; then
          ${lib.getExe installer} || exit 1
      elif [ -f "${affinityPathV3}/installed-hash" ]; then
          installed_hash=$(<"${affinityPathV3}/installed-hash")

          if [[ "$installed_hash" != "${sources.v3.sha256}" ]] && zenity --question --text="New update found, would you like to install it?"; then
            ${lib.getExe installer} || exit 1
          fi
      else
          ${lib.getExe check} || exit 1
      fi

      if [ "$1" != "--verbose" ]; then
          export WINEDEBUG=-all,fixme-all
      else
        shift
      fi

      ${lib.getExe wine} "${affinityPathV3}/drive_c/Program Files/Affinity/Affinity/AffinityHook.exe" "$@"
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
