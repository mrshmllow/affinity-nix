{
  pkgs,
  writeShellScriptBin,
  lib,
  wineUnwrapped,
  wine,
  affinityPath,
  wineboot,
  winetricks,
}:
rec {
  check = writeShellScriptBin "check" ''
    ${lib.getExe wineboot} --update
    ${lib.getExe wine} msiexec /i "${wineUnwrapped}/share/wine/mono/wine-mono-8.1.0-x86.msi"
    ${lib.getExe winetricks} -q dotnet48 corefonts vcrun2022
    ${lib.getExe wine} winecfg -v win11

    install -D -t "${affinityPath}/drive_c/windows/system32/WinMetadata/" ${./winmetadata}/*
  '';

  createInstaller =
    name:
    let
      sources = pkgs.callPackage ./source.nix { };
    in
    writeShellScriptBin "install-Affinity-${name}-2" ''
      ${lib.getExe check} || exit 1
      # block winemenubuilder.exe from making .desktop files and file associations
      WINEDLLOVERRIDES=winemenubuilder.exe=d ${lib.getExe wine} ${sources.${lib.toLower name}}
    '';

  createRunner =
    name:
    let
      installer = createInstaller name;
    in
    writeShellScriptBin "run-Affinity-${name}-2" ''
      if [ ! -f "${affinityPath}/drive_c/Program Files/Affinity/${name} 2/${name}.exe" ]; then
        ${lib.getExe installer} || exit 1
      else
        ${lib.getExe check} || exit 1
      fi

      ${lib.getExe wine} "${affinityPath}/drive_c/Program Files/Affinity/${name} 2/${name}.exe"
    '';

  createPackage =
    name:
    let
      pkg = createRunner name;

      desktop = pkgs.callPackage ./desktopItems.nix {
        ${lib.toLower name} = pkg;
      };
    in
    pkgs.symlinkJoin {
      name = "Affinity ${name} 2";
      paths = [
        pkg
        desktop.${lib.toLower name}
      ];
      meta = {
        description = "Affinity ${name} 2";
        homepage = "https://affinity.serif.com/";
        # license = lib.licenses.unfree;
        # maintainers = with pkgs.lib.maintainers; [marshmallow];
        platforms = [ "x86_64-linux" ];
        mainProgram = "run-Affinity-${name}-2";
      };
    };
}
