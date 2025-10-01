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
  check =
    let
      revisionPath = "${affinityPath}/.revision";
      revision = "1";
      tricks = [
        "dotnet48"
        "corefonts"
        "vcrun2022"

        "allfonts"
        # "dotnet35"
      ];
    in
    writeShellScriptBin "check" ''
      function setup {
          ${lib.getExe wineboot} --update
          ${lib.getExe wine} msiexec /i "${wineUnwrapped}/share/wine/mono/wine-mono-8.1.0-x86.msi"

          ${lib.strings.toShellVars {
            inherit tricks;
          }}

          for trick in "${"\${tricks[@]}"}"; do
            echo "winetricks: Installing $trick"
            ${lib.getExe winetricks} -q -f "$trick"
          done

          ${lib.getExe winetricks} renderer=vulkan
          ${lib.getExe wine} winecfg -v win11

          install -D -t "${affinityPath}/drive_c/windows/system32/WinMetadata/" ${./winmetadata}/*
          echo "${revision}" > "${revisionPath}"
      }

      # older prefix with no revision number
      if [ ! -f "${revisionPath}" ]; then
          echo "affinity-nix: Running setup, no revision"

          setup
      else
          content=$(<"${revisionPath}")

          # only install deps if the revision number is higher than the
          # one found in the prefix
          if [[ "${revision}" -gt "$content" ]]; then
            echo "affinity-nix: Running setup, old prefix revision"

            setup
          fi
      fi
    '';

  createInstaller =
    name:
    let
      sources = pkgs.callPackage ./source.nix { };
    in
    writeShellScriptBin "install-Affinity-${name}-2" ''
      ${lib.getExe check} || exit 1
      ${lib.getExe wine} ${sources.${lib.toLower name}}
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
