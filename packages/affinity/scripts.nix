{
  pkgs,
  writeShellScriptBin,
  lib,
  wine,
  affinityPath,
  version,
  stdShellArgs,
  mkInstaller,
  mkGraphicalCheck,
}:
rec {
  createRunner =
    name:
    let
      installer = mkInstaller name;
      check = mkGraphicalCheck name;
    in
    writeShellScriptBin "affinity-${lib.toLower name}-2" ''
      set -x
      ${stdShellArgs}

      if [ ! -f "${affinityPath}/drive_c/Program Files/Affinity/${name} 2/${name}.exe" ]; then
          ${lib.getExe installer} || exit 1
      else
          ${lib.getExe check} || exit 1
      fi

      if [ "$1" != "--verbose" ]; then
          export WINEDEBUG=-all,fixme-all
      else
        shift
      fi

      ${lib.getExe wine} "${affinityPath}/drive_c/Program Files/Affinity/${name} 2/${name}.exe" "$@"
    '';

  createPackage =
    name:
    let
      pkg = createRunner name;
      desktop = pkgs.callPackage ./desktopItems.nix {
        ${lib.toLower name} = pkg;
      };

      icons = pkgs.callPackage ./icons.nix { };
      icon-package = icons.mkIconPackageFor name;
    in
    pkgs.symlinkJoin {
      name = "Affinity ${name} ${version}";
      pname = "affinity-${lib.toLower name}-${version}";
      paths = [
        pkg
        desktop.${lib.toLower name}
        icon-package
      ];
      meta = {
        description = "Affinity ${name} 2";
        homepage = "https://affinity.serif.com/";
        # license = lib.licenses.unfree;
        # maintainers = with pkgs.lib.maintainers; [marshmallow];
        platforms = [ "x86_64-linux" ];
        mainProgram = "affinity-${lib.toLower name}-2";
      };
    };
}
