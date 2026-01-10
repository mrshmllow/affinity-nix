{ inputs, ... }:
{
  perSystem =
    {
      affinityPathV2,
      affinityPathV3,
      pkgs,
      lib,
      sources,
      stdShellArgs,
      wine-stuff,
      wineUnwrapped,
      ...
    }:
    {
      _module.args = rec {
        mkInjectPluginLoader =
          affinityPath:
          pkgs.writeShellScriptBin "inject-plugin-loader" ''
            # Must be inserted after installer
            # installer gets mad if we make the directory for it, so only install
            # if it put something there
            if [ -d "${affinityPath}/drive_c/Program Files/Affinity/Affinity" ]; then
                pushd "${affinityPath}/drive_c/Program Files/Affinity/Affinity"
                tar -xvf ${inputs.plugin-loader}
                popd
            fi
          '';

        mkCheck =
          v3:
          let
            type = if v3 then "v3" else "v2";
            affinityPath = if v3 then affinityPathV3 else affinityPathV2;
            revisionPath = "${affinityPath}/.revision";
            latestRevision = "7";
            verbs = [
              "vcrun2022"
              "dotnet48"
              "corefonts"
              "win11"
              "tahoma"
            ];
            dependencies = pkgs.callPackage ./dependencies.nix { };
            injectPluginLoader = mkInjectPluginLoader affinityPath;

            inherit (wine-stuff."${type}")
              wine
              wineboot
              winetricks
              wineserver
              ;
          in
          pkgs.writeShellScriptBin "check" ''
            set -x -e
            ${lib.strings.toShellVars {
              inherit verbs type;
              tricksInstalled = 0;
            }}

            ${lib.getExe wine} --version

            function setup {
                local prefixRevision="$1"
                if [[ "$prefixRevision" -le 3 ]]; then
                    echo "affinity-nix: Initializing wine prefix with mono, vulkan renderer and WinMetadata"

                    ${lib.getExe wineboot} --update
                    ${lib.getExe wine} msiexec /i "${wineUnwrapped}/share/wine/mono/wine-mono-10.3.0-x86.msi"

                    ${lib.getExe winetricks} renderer=vulkan

                    install -D -t "${affinityPath}/drive_c/windows/system32/WinMetadata/" ${dependencies}/*.winmd
                fi

                if [[ "$prefixRevision" -le 4 ]]; then
                   echo "affinity-nix: Installing Microsoft WebView2 Runtime"

                   ${lib.getExe wine} winecfg -v win7
                   ${lib.getExe wine} "${dependencies}/MicrosoftEdgeWebView2RuntimeInstallerX64.exe" /silent /install
                   ${lib.getExe wine} winecfg -v win11

                   ${lib.getExe wine} regedit /S "${(pkgs.writeText "webview2-regedit-changes.reg" ''
                     Windows Registry Editor Version 5.00

                     [HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\edgeupdate]
                     "Start"=dword:00000004

                     [HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\edgeupdatem]
                     "Start"=dword:00000004

                     [HKEY_CURRENT_USER\Software\Wine\AppDefaults]

                     [HKEY_CURRENT_USER\Software\Wine\AppDefaults\msedgewebview2.exe]
                     "Version"="win7"
                   '').outPath}"

                   # The Edge Update service gets to start before we can deactivate it, so it must be stopped manually
                   ${lib.getExe wine} taskkill /f /im MicrosoftEdgeUpdate.exe
                fi

                if [[ "$prefixRevision" -le 6 ]]; then
                   echo "affinity-nix: PROPERLY disabling the menubuilder"

                   # by diffing a registry dump we found that you can disable the file association
                   # through a registry key.
                   ${lib.getExe wine} regedit /S "${(pkgs.writeText "file-association-disable.reg" ''
                     Windows Registry Editor Version 5.00

                     [HKEY_CURRENT_USER\Software\Wine\DllOverrides]
                     "winemenubuilder.exe"=""

                     [HKEY_CURRENT_USER\Software\Wine\FileOpenAssociations]
                     "Enable"="N"
                   '').outPath}"
                fi

                echo "${latestRevision}" > "${revisionPath}"
            }

            # older prefix with no revision number
            if [ ! -f "${revisionPath}" ]; then
                echo "affinity-nix: Running setup, no revision"

                setup "0"
            else
                prefixRevision=$(<"${revisionPath}")

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

                    mkdir -p "${affinityPath}/drive_c/users/$USER/AppData/Roaming/Affinity/$app/2.0/"

                    ${lib.getExe pkgs.rsync} -v \
                        --ignore-existing \
                        --chmod=644 \
                        --recursive \
                        "${inputs.on-linux}/Auxillary/Settings/$app/2.0/" \
                        "${affinityPath}/drive_c/users/$USER/AppData/Roaming/Affinity/$app/2.0/"
                done
            fi

            installed_tricks=$(${lib.getExe winetricks} list-installed)

            # kinda stolen from the nix-citizen project, tysm
            # we can be more smart about installing verbs other than relying on the revision number
            for verb in "${"\${verbs[@]}"}"; do
                # skip if verb is installed
                if ! echo "$installed_tricks" | grep -qw "$verb"; then
                    echo "winetricks: Installing $verb"

                    if ! ${lib.getExe winetricks} -q -f "$verb"; then
                        zenity --error \
                            --text="affinity-nix: Failed to install winetricks verb $verb. Please view logs"

                        exit 1
                    fi

                    tricksInstalled=1
                fi
            done

            # Ensure wineserver is restarted after tricks are installed
            if [ "$tricksInstalled" -eq 1 ]; then
                ${lib.getExe wineserver} -k
            fi

            if [[ "$type" == "v3" ]]; then
                ${lib.getExe injectPluginLoader}
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

        mkInstaller =
          name:
          let
            source = sources.${lib.toLower name};
            check = mkGraphicalCheck name;
            affinityPath = if name == "v3" then affinityPathV3 else affinityPathV2;
            injectPluginLoader = mkInjectPluginLoader affinityPath;
            type = if name == "v3" then "v3" else "v2";

            inherit (wine-stuff."${type}")
              wine
              wineserver
              ;
          in
          pkgs.writeShellScriptBin "install-Affinity-${name}" ''
            set -x
            ${stdShellArgs}
            ${lib.strings.toShellVars {
              inherit type;
              download_url = source.url;
            }}

            cache_dir="${"\${XDG_CACHE_HOME:-$HOME/.cache}"}"/affinity

            mkdir -p "$cache_dir"

            function matches {
                echo "${source.sha256} $cache_dir/${source.name}" | sha256sum --check --status
            }

            function ensure_exists {
                if matches; then
                    return 0
                fi

                echo "download: Downloading $download_url"

                # excerpt stolen from https://github.com/mactan-sc/rsilauncher/blob/main/scripts/rsi-run.sh
                FIFO=$(mktemp -u)

                mkfifo "$FIFO"

                curl -#L "$download_url" -o "$cache_dir/${source.name}" > "$FIFO" 2>&1 & curlpid="$!"

                stdbuf -oL tr '\r' '\n' < "$FIFO" | \
                grep --line-buffered -ve "100" | grep --line-buffered -o "[0-9]*\.[0-9]" | \
                (
                    trap 'kill "$curlpid"' ERR
                    zenity --progress \
                      --auto-close \
                      --title="Affinity ${name} (${type})" \
                      --text="Downloading the installer for ${name}.\n\nThis might take a moment.\n" 2>/dev/null
                )

                if [ "$?" -eq 1 ]; then
                    # user clicked cancel
                    echo "download: user aborted. removing $cache_dir/${source.name}..."
                    rm --interactive=never "$cache_dir/${source.name}"
                    rm --interactive=never "$FIFO"
                    exit 1
                fi

                rm --interactive=never "$FIFO"

                if matches; then
                    echo "download: Downloaded file matches sha256"

                    return 0
                fi

                echo "download: Failed to verify the downloaded file"
                return 1
            }

            if ! ensure_exists; then
                read -r -d ''' message << EOM
            Could not successfully download ${source.name}
            Please create an issue: https://github.com/mrshmllow/affinity-nix/issues/new?template=bug_report.md.

            In the meantime try again after downloading ${source.name} from ${source.url} and placing it in the path $cache_dir/${source.name}
            EOM

                zenity --error --text="$message"
                echo -e "-------------------\n\n$message\n\n-------------------"

                exit 1
            fi

            ${lib.getExe check} || exit 1
            ${lib.getExe wine} winecfg -v win11
            ${lib.getExe wineserver} -w

            zenity --info \
                --title="Affinity ${name} (${type})" \
                --text="You will be prompted to install ${name}.\n\nPlease do not change the installation path."

            ${lib.getExe wine} "$cache_dir/${source.name}"

            if [[ "$type" == "v3" ]]; then
                ${lib.getExe injectPluginLoader}
            fi

            echo "${source.sha256}" > ${affinityPath}/installed-hash
          '';
      };
    };
}
