{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      wine-stuff,
      wineUnwrapped,
      mkPrefixBase,
      ...
    }:
    {
      _module.args = {
        mkPrefixBase =
          v3:
          let
            verbs = [
              "tahoma"
              "vcrun2022"
              "dotnet48"
              "corefonts"
              "win11"
            ];

            type = if v3 then "v3" else "v2";

            inherit (wine-stuff."${type}")
              wine
              wineboot
              winetricks
              wineserver
              ;

            dependencies = pkgs.callPackage ./dependencies.nix { };

            winetricksCache = pkgs.linkFarm "winetricks-cache" [
              {
                name = "vcrun2022/vc_redist.x64.exe";
                path = pkgs.fetchurl {
                  url = "https://web.archive.org/web/20260405052133/https://aka.ms/vs/17/release/vc_redist.x64.exe";
                  hash = "sha256-zA/w6x3D9RiK5jAPrvMr9b7rpL3W6ORFqRhAcglrcTs=";
                };
              }
              {
                name = "vcrun2022/vc_redist.x86.exe";
                path = pkgs.fetchurl {
                  url = "https://web.archive.org/web/20260330091736/https://aka.ms/vs/17/release/vc_redist.x86.exe";
                  hash = "sha256-rHWoLYc+a2+YsdKTBCOAdk19JjxDQ45Q1WT6WMn4kcI=";
                };
              }
              {
                name = "dotnet48/ndp48-x86-x64-allos-enu.exe";
                path = pkgs.fetchurl {
                  url = "https://web.archive.org/web/20260313001348/https://download.visualstudio.microsoft.com/download/pr/7afca223-55d2-470a-8edc-6a1739ae3252/abd170b4b0ec15ad0222a809b761a036/ndp48-x86-x64-allos-enu.exe";
                  hash = "sha256-lYidbePyBwwHeQrWzyAA0z2aG9/Go4FyWrgqscMU/VM=";
                };
              }
              {
                name = "dotnet40/dotNetFx40_Full_x86_x64.exe";
                path = pkgs.fetchurl {
                  url = "https://web.archive.org/web/20260319080641/https://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe";
                  hash = "sha256-ZeBkJY8uQYgWswT2Rv+eh68QHkyVUqsGS7dNKBw4ZZ8=";
                };
              }
              {
                name = "tahoma/IELPKTH.CAB";
                path = pkgs.fetchurl {
                  url = "https://downloads.sourceforge.net/corefonts/OldFiles/IELPKTH.CAB";
                  hash = "sha256-wb4/uPAEJXC+duxtqgOpkULIg2fBvIECQLhYJ8cVlho=";
                };
              }
            ];
          in
          pkgs.runCommand "build-base-prefix"
            {
              buildInputs = [
                pkgs.xvfb-run
              ];
            }
            ''
              set -x -e

              ${lib.strings.toShellVars {
                inherit verbs type;
              }}

              mkdir -p $out
              mkdir -p /tmp/cache/winetricks/corefonts

              cp -R ${winetricksCache}/* /tmp/cache/winetricks
              cp -R ${inputs.corefonts}/*.exe /tmp/cache/winetricks/corefonts

              export WINEPREFIX="$out"
              export XDG_CACHE_HOME="/tmp/cache"

              echo "affinity-nix: Initializing wine prefix with mono, vulkan renderer and WinMetadata"

              ${lib.getExe wineboot} --update

              installed_tricks=$(${lib.getExe winetricks} list-installed)

              # kinda stolen from the nix-citizen project, tysm
              # we can be more smart about installing verbs other than relying on the revision number
              for verb in "${"\${verbs[@]}"}"; do
                  echo "winetricks: Installing $verb"

                  xvfb-run ${lib.getExe winetricks} -q -f "$verb"
              done

              ${lib.getExe wine} msiexec /i "${wineUnwrapped}/share/wine/mono/wine-mono-9.3.0-x86.msi"

              ${lib.getExe winetricks} renderer=vulkan

              install -D -t "$out/drive_c/windows/system32/WinMetadata/" ${dependencies}/*.winmd

              echo "affinity-nix: Installing Microsoft WebView2 Runtime"

              ${lib.getExe wine} winecfg -v win7
              xvfb-run ${lib.getExe wine} "${dependencies}/MicrosoftEdgeWebView2RuntimeInstallerX64.exe" /silent /install
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

              installed_tricks=$(${lib.getExe winetricks} list-installed)

              # kinda stolen from the nix-citizen project, tysm
              # we can be more smart about installing verbs other than relying on the revision number
              for verb in "${"\${verbs[@]}"}"; do
                  echo "winetricks: Installing $verb"

                  xvfb-run ${lib.getExe winetricks} -q -f "$verb"
              done

              ${lib.getExe wineserver} -k || true

              echo "created base prefix @ $out"
            '';
      };
    };
}
