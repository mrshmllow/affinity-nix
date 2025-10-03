{
  pkgs,
  writeShellScriptBin,
  lib,
  wineUnwrapped,
  wine,
  affinityPath,
  wineboot,
  winetricks,
  wineserver,
  on-linux,
}:
rec {
  check =
    let
      revisionPath = "${affinityPath}/.revision";
      revision = "1";
      verbs = [
        "dotnet48"
        "corefonts"
        "vcrun2022"

        "allfonts"
        # "dotnet35"
      ];
      winmetadata = pkgs.callPackage ./winmetadata.nix { };
    in
    writeShellScriptBin "check" ''
      set -x

      ${lib.strings.toShellVars {
        inherit verbs;
        tricksInstalled = 0;
        apps = [
          "Photo"
          "Designer"
          "Publisher"
        ];
      }}

      function setup {
          ${lib.getExe wineboot} --update
          ${lib.getExe wine} msiexec /i "${wineUnwrapped}/share/wine/mono/wine-mono-8.1.0-x86.msi"

          ${lib.getExe winetricks} renderer=vulkan

          install -D -t "${affinityPath}/drive_c/windows/system32/WinMetadata/" ${winmetadata}/*.winmd
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

      for app in "${"\${apps[@]}"}"; do
          echo "affinity-nix: Installing settings for $app"

          mkdir -p "${affinityPath}/drive_c/users/$USER/AppData/Roaming/Affinity/$app/2.0/"

          ${lib.getExe pkgs.rsync} -v \
              --ignore-existing \
              --chmod=644 \
              --recursive \
              "${on-linux}/Auxillary/Settings/$app/2.0/" \
              "${affinityPath}/drive_c/users/$USER/AppData/Roaming/Affinity/$app/2.0/"
      done

      # kinda stolen from the nix-citizen project, tysm
      # we can be more smart about installing verbs other than relying on the revision number
      for verb in "${"\${verbs[@]}"}"; do
          # skip if verb is installed
          if ! ${lib.getExe winetricks} list-installed | grep -qw "$verb"; then
              echo "winetricks: Installing $verb"
              ${lib.getExe winetricks} -q -f "$verb"
              tricksInstalled=1
          fi
      done

      # Ensure wineserver is restarted after tricks are installed
      if [ "$tricksInstalled" -eq 1 ]; then
          ${lib.getExe wineserver} -k
      fi
    '';

  createInstaller =
    name:
    let
      sources = pkgs.callPackage ./source.nix { };
    in
    writeShellScriptBin "install-Affinity-${name}-2" ''
      set -x

      ${lib.getExe check} || exit 1
      ${lib.getExe wine} winecfg -v win11
      ${lib.getExe wineserver} -w
      ${lib.getExe wine} ${sources.${lib.toLower name}}
    '';

  createRunner =
    name:
    let
      installer = createInstaller name;
    in
    writeShellScriptBin "run-Affinity-${name}-2" ''
      set -x

      if [ ! -f "${affinityPath}/drive_c/Program Files/Affinity/${name} 2/${name}.exe" ]; then
          ${lib.getExe installer} || exit 1
      else
          ${lib.getExe check} || exit 1
      fi

      if [ "$1" != "--verbose" ]; then
          export WINEDEBUG=-all,fixme-all
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
