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
  sources,
  version,
  stdShellArgs,
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

  createGraphicalCheck =
    name:
    writeShellScriptBin "affinity-${name}-gui-check" ''
      ${lib.getExe check} | zenity --progress \
          --pulsate \
          --no-cancel \
          --auto-close \
          --title="Affinity ${name} 2" \
          --text="Preparing the wine prefix\n\nThis can take a while.\n"

      if [ ! $? -eq 0 ]; then
          zenity --error --text="Preparing the wine prefix failed."

          exit 1
      fi
    '';

  createDownloader =
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

  createInstaller =
    name:
    let
      source = sources.${lib.toLower name};
      downloader = createDownloader name;
      check = createGraphicalCheck name;
    in
    writeShellScriptBin "install-Affinity-${name}-2" ''
      set -x
      ${stdShellArgs}

      cache_dir="${"\${XDG_CACHE_HOME:-$HOME/.cache}"}"/affinity

      mkdir -p "$cache_dir"

      function matches {
          echo "${source.sha256} $cache_dir/${source.name}" | sha256sum --check --status
      }

      function ensure_exists {
          if matches; then
              return 0
          fi

          download_url=$(${lib.getExe downloader} | sed 's/&amp;/\&/g')

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
                --title="Affinity ${name} 2" \
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
          --title="Affinity ${name} 2" \
          --text="You will be prompted to install ${name} 2.\n\nPlease do not change the installation path."

      ${lib.getExe wine} "$cache_dir/${source.name}"
    '';

  createRunner =
    name:
    let
      installer = createInstaller name;
      check = createGraphicalCheck name;
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
