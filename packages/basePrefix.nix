{
  linkFarm,
  fetchurl,
  writeText,
  runCommand,
  callPackage,
  xvfb-run,
  lib,
  inputs,
  wine-packages,
  ...
}:
let
  verbs = [
    "tahoma"
    "vcrun2022"
    "dotnet20"
    "dotnet48"
    "corefonts"
    "win11"
  ];

  inherit (wine-packages)
    wine
    wineUnwrapped
    wineboot
    winetricks
    wineserver
    ;

  dependencies = callPackage ./dependencies.nix { };
  winetricksCache = linkFarm "winetricks-cache" [
    {
      name = "vcrun2022/vc_redist.x64.exe";
      path = fetchurl {
        url = "https://web.archive.org/web/20260405052133/https://aka.ms/vs/17/release/vc_redist.x64.exe";
        hash = "sha256-zA/w6x3D9RiK5jAPrvMr9b7rpL3W6ORFqRhAcglrcTs=";
      };
    }
    {
      name = "vcrun2022/vc_redist.x86.exe";
      path = fetchurl {
        url = "https://web.archive.org/web/20260330091736/https://aka.ms/vs/17/release/vc_redist.x86.exe";
        hash = "sha256-DAnyYRZgRBCEzg30JcUcEeFH5kR5Y8NpD5fgslxV7WQ=";
      };
    }
    {
      name = "dotnet48/ndp48-x86-x64-allos-enu.exe";
      path = fetchurl {
        url = "https://web.archive.org/web/20260313001348/https://download.visualstudio.microsoft.com/download/pr/7afca223-55d2-470a-8edc-6a1739ae3252/abd170b4b0ec15ad0222a809b761a036/ndp48-x86-x64-allos-enu.exe";
        hash = "sha256-lYidbePyBwwHeQrWzyAA0z2aG9/Go4FyWrgqscMU/VM=";
      };
    }
    {
      name = "dotnet40/dotNetFx40_Full_x86_x64.exe";
      path = fetchurl {
        url = "https://web.archive.org/web/20260319080641/https://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe";
        hash = "sha256-ZeBkJY8uQYgWswT2Rv+eh68QHkyVUqsGS7dNKBw4ZZ8=";
      };
    }
    {
      name = "tahoma/IELPKTH.CAB";
      path = fetchurl {
        url = "https://downloads.sourceforge.net/corefonts/OldFiles/IELPKTH.CAB";
        hash = "sha256-wb4/uPAEJXC+duxtqgOpkULIg2fBvIECQLhYJ8cVlho=";
      };
    }
    {
      name = "dotnet20/NetFx64.exe";
      path = fetchurl {
        url = "https://web.archive.org/web/20060509045320/https://download.microsoft.com/download/a/3/f/a3f1bf98-18f3-4036-9b68-8e6de530ce0a/NetFx64.exe";
        hash = "sha256-fqhtyo7q7cqkoXNwVHyizqnptndJcrjgPSyx+w55hmk=";
      };
    }
  ];

  layer_1 = runCommand "base-prefix-1" { } ''
    set -x -e
    mkdir -p $out
    export WINEPREFIX="$out"
    export WINETRICKS_UPDATE_CHECK=0
    export WINETRICKS_LATEST_VERSION_CHECK=disabled

    mkdir -p /tmp/cache
    export XDG_CACHE_HOME="/tmp/cache"

    ${lib.getExe wineboot} --update
    ${lib.getExe wine} msiexec /i "${wineUnwrapped}/share/wine/mono/wine-mono-9.3.0-x86.msi"

    # by diffing a registry dump we found that you can disable the file association
    # through a registry key.
    ${lib.getExe wine} regedit /S "${(writeText "file-association-disable.reg" ''
      Windows Registry Editor Version 5.00

      [HKEY_CURRENT_USER\Software\Wine\DllOverrides]
      "winemenubuilder.exe"=""

      [HKEY_CURRENT_USER\Software\Wine\FileOpenAssociations]
      "Enable"="N"
    '').outPath}"

    ${lib.getExe winetricks} renderer=vulkan

    install -D -t "$WINEPREFIX/drive_c/windows/system32/WinMetadata/" ${dependencies}/*.winmd

    ${lib.getExe wineserver} -w
  '';

  layer_2 =
    runCommand "base-prefix-2"
      {
        nativeBuildInputs = [
          xvfb-run
        ];
      }
      ''
        set -x -e

        mkdir -p $out
        cp -a ${layer_1}/. $out
        chmod -R +w $out
        export WINEPREFIX="$out"

        mkdir -p /tmp/cache
        export XDG_CACHE_HOME="/tmp/cache"

        ${lib.getExe wine} winecfg -v win7
        xvfb-run ${lib.getExe wine} "${dependencies}/MicrosoftEdgeWebView2RuntimeInstallerX64.exe" /silent /install
        ${lib.getExe wine} winecfg -v win11

        ${lib.getExe wine} regedit /S "${(writeText "webview2-regedit-changes.reg" ''
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

        ${lib.getExe wineserver} -w
      '';
in
runCommand "base-prefix-3"
  {
    nativeBuildInputs = [
      xvfb-run
    ];
  }
  ''
    set -x -e

    ${lib.strings.toShellVars {
      inherit verbs;
    }}

    mkdir -p /tmp/cache/winetricks/corefonts

    mkdir -p $out
    cp -a ${layer_2}/. $out
    chmod -R +w $out
    export WINEPREFIX="$out"

    export XDG_CACHE_HOME="/tmp/cache"
    export WINETRICKS_UPDATE_CHECK=0
    export WINETRICKS_LATEST_VERSION_CHECK=disabled

    export WINEDEBUG=-all
    export WINEESYNC=0
    export WINEFSYNC=0

    cp -R ${winetricksCache}/* /tmp/cache/winetricks
    cp -R ${inputs.corefonts}/*.exe /tmp/cache/winetricks/corefonts

    xvfb-run ${lib.getExe winetricks} -q -f "''${verbs[@]}"

    ${lib.getExe wineserver} -w
  ''
