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
        mkCheck =
          v3:
          let
            type = if v3 then "v3" else "v2";
            affinityPath = if v3 then affinityPathV3 else affinityPathV2;
            revisionPath = "${affinityPath}/.revision";
            revision = "4";
            verbs = [
              "vcrun2022"
              "dotnet48"
              "corefonts"
              "win11"
              "tahoma"
            ];
            dependencies = pkgs.callPackage ./dependencies.nix { };

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

            function setup {
                local revision="$1"
                if [[ "$revision" -le 3 ]]; then
                    echo "affinity-nix: Initializing wine prefix with mono, vulkan renderer and WinMetadata"

                    ${lib.getExe wineboot} --update
                    ${lib.getExe wine} msiexec /i "${wineUnwrapped}/share/wine/mono/wine-mono-9.3.0-x86.msi"

                    ${lib.getExe winetricks} renderer=vulkan

                    install -D -t "${affinityPath}/drive_c/windows/system32/WinMetadata/" ${dependencies}/*.winmd
                fi

                echo "${revision}" > "${revisionPath}"
            }

            # older prefix with no revision number
            if [ ! -f "${revisionPath}" ]; then
                echo "affinity-nix: Running setup, no revision"

                setup "0"
            else
                content=$(<"${revisionPath}")

                # only install deps if the revision number is higher than the
                # one found in the prefix
                if [[ "${revision}" -gt "$content" ]]; then
                  echo "affinity-nix: Running setup, old prefix revision"

                  setup "$revision"
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
          '';
      };
    };
}
