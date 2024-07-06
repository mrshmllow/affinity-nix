{
  pkgs,
  writeScriptBin,
  lib,
  wineUnwrapped,
  wine,
  affinityPath,
  wineboot,
  winetricks,
}: rec {
  check = writeScriptBin "check" ''
    WINEDLLOVERRIDES="mscoree=" ${lib.getExe wineboot} --init
    ${lib.getExe wine} msiexec /i "${wineUnwrapped}/share/wine/mono/wine-mono-8.1.0-x86.msi"
    ${lib.getExe winetricks} -q dotnet48 corefonts vcrun2015
    ${lib.getExe wine} winecfg -v win11

    install -D -t "${affinityPath}/drive_c/windows/system32/WinMetadata/" ${./winmetadata}/*
  '';

  createInstaller = name: let
    sources = pkgs.callPackage ./source.nix {};
  in
    writeScriptBin "install-Affinity-${name}-2" ''
      ${lib.getExe check} || exit 1

      if [ ! -f "${affinityPath}/drive_c/Program Files/Affinity/${name} 2/${name}.exe" ]; then
          ${lib.getExe wine} ${sources.${lib.toLower name}}
      fi
    '';

  createRunner = name: let
    installer = createInstaller name;
  in
    writeScriptBin "run-Affinity-${name}-2" ''
      ${lib.getExe installer} || exit 1

      ${lib.getExe wine} "${affinityPath}/drive_c/Program Files/Affinity/${name} 2/${name}.exe"
    '';

  createPackage = name: let
    pkg = createRunner name;

    desktop = pkgs.callPackage ./desktopItems.nix {
      ${lib.toLower name} = pkg;
    };
  in
    pkgs.symlinkJoin {
      name = "Affinity ${name} 2";
      paths = [pkg desktop.${lib.toLower name}];
      meta = {
        description = "Affinity ${name} 2";
        homepage = "https://affinity.serif.com/";
        license = lib.licenses.unfree;
        # maintainers = with pkgs.lib.maintainers; [marshmallow];
        platforms = ["x86_64-linux"];
        mainProgram = "run-Affinity-${name}-2";
      };
    };
}
