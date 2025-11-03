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
      version,
      wine-stuff,
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
            revision = "3";
            verbs = [
              "remove_mono"
              "vcrun2022"
              "dotnet48"
              "corefonts"
              "win11"
            ];
            winmetadata = pkgs.callPackage ./winmetadata.nix { };

            inherit (wine-stuff."${type}")
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

            function setup {
                ${lib.getExe wineboot} --update

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
          '';

        mkGraphicalCheck =
          name:
          let
            check = mkCheck (name == "v3");
          in
          pkgs.writeShellScriptBin "affinity-v3-gui-check" ''
            ${lib.getExe check} | zenity --progress \
                --pulsate \
                --no-cancel \
                --auto-close \
                --title="Affinity" \
                --text="Preparing the wine prefix\n\nThis can take a while.\n"

            if [ ! $? -eq 0 ]; then
                zenity --error --text="Preparing the wine prefix failed."

                exit 1
            fi
          '';

        mkV2Downloader =
          name:
          let
            escapedVersion = builtins.replaceStrings [ "." ] [ "\\." ] version;
            lowerName = lib.toLower name;
          in
          pkgs.writers.writePyPy3Bin "download-affinity-${name}-installer" { } ''
            import urllib.request
            import re

            REGEX = re.compile(
                r'href="('
                r"https://[a-z0-9]+\.cloudfront\.net/"
                r"windows/${lowerName}2/${escapedVersion}/affinity-${lowerName}-msi-${escapedVersion}"
                r'\.exe\?[^"]*'
                r')"',
            )

            url = "https://store.serif.com/en-gb/update/windows/${name}/2/"
            f = urllib.request.urlopen(url)
            content = f.read().decode("utf-8")

            url_search = re.search(REGEX, content)

            print(url_search.group(1))
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

                ${
                  if type == "v3" then
                    ''download_url="${source.url}"''
                  else
                    ''download_url="$(${lib.getExe (mkV2Downloader name)} | sed 's/&amp;/\&/g')"''
                }

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
