{
  perSystem =
    {
      affinityPath,
      affinityPathV3,
      pkgs,
      lib,
    }:
    {
      check =
        v3:
        let
          revisionPath = if v3 then "${affinityPathV3}/.revision" else "${affinityPath}/.revision";
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
        pkgs.writeShellScriptBin "check" ''
          set -x
          ${lib.strings.toShellVars {
            inherit verbs;
            tricksInstalled = 0;
          }}

          function setup {
              ${lib.getExe wineboot} --update
              ${lib.getExe wine} msiexec /i "${wineUnwrapped}/share/wine/mono/wine-mono-8.1.0-x86.msi"

              ${lib.getExe winetricks} renderer=vulkan

              install -D -t "${affinityPathV3}/drive_c/windows/system32/WinMetadata/" ${winmetadata}/*.winmd
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

          # for app in "${"\${apps[@]}"}"; do
          #     echo "affinity-nix: Installing settings for $app"
          #
          #     mkdir -p "${affinityPathV3}/drive_c/users/$USER/AppData/Roaming/Affinity/$app/2.0/"
          #
          #     ${lib.getExe pkgs.rsync} -v \
          #         --ignore-existing \
          #         --chmod=644 \
          #         --recursive \
          #         "${on-linux}/Auxillary/Settings/$app/2.0/" \
          #         "${affinityPathV3}/drive_c/users/$USER/AppData/Roaming/Affinity/$app/2.0/"
          # done

          installed_tricks=$(${lib.getExe winetricks} list-installed)

          # kinda stolen from the nix-citizen project, tysm
          # we can be more smart about installing verbs other than relying on the revision number
          for verb in "${"\${verbs[@]}"}"; do
              # skip if verb is installed
              if ! echo "$installed_tricks" | grep -qw "$verb"; then
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
    };
}
