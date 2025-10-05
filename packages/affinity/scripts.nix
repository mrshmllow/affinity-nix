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

  createDownloader =
    name:
    let
      sources = import ./source.nix;
      escapedVersion = builtins.replaceStrings [ "." ] [ "\\." ] sources._version;
      lowerName = lib.toLower name;
    in
    pkgs.writers.writePyPy3Bin "download-affinity-${name}-installer"
      {
        libraries = [ ];
      }
      ''
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
      sources = import ./source.nix;
      source = sources.${lib.toLower name};
      downloader = createDownloader name;
    in
    writeShellScriptBin "install-Affinity-${name}-2" ''
      set -x

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

          if ! curl -L "$download_url" -o "$cache_dir/${source.name}"; then
              echo "download: Download failed"
              return 1
          fi

          if matches; then
              echo "download: Downloaded file matches sha256"

              return 0
          fi

          echo "download: Failed to verify the downloaded file"
          return 1
      }

      if ! ensure_exists; then
          echo "-------------------

      Could not successfully download ${source.name}
      Please create an issue: https://github.com/mrshmllow/affinity-nix/issues/new?template=bug_report.md.

      In the meantime try again after downloading ${source.name} from ${source.url} and placing it in the path $cache_dir/${source.name}

      -------------------"

          exit 1
      fi

      ${lib.getExe check} || exit 1
      ${lib.getExe wine} winecfg -v win11
      ${lib.getExe wineserver} -w
      ${lib.getExe wine} "$cache_dir/${source.name}"
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
