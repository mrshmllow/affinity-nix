{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      wine-stuff,
      wineUnwrapped,
      mkInjectPluginLoader,
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

            injectPluginLoader = mkInjectPluginLoader;

            v3_msix = pkgs.fetchurl {
              url = "https://web.archive.org/web/20260206191533/https://downloads.affinity.studio/Affinity%20x64.msix";
              hash = "sha256-Ys2YarvIjfWlEIGZyft3M0o+4tLAcfhn89t7ucRq+vY=";
            };

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
                  hash = "sha256-DAnyYRZgRBCEzg30JcUcEeFH5kR5Y8NpD5fgslxV7WQ=";
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

            layer_1 = pkgs.runCommand "base-prefix-1" { } ''
              set -x -e
              mkdir -p $out
              export WINEPREFIX="$out"

              echo "affinity-nix: Initializing wine prefix with mono, vulkan renderer and WinMetadata"

              ${lib.getExe wineboot} --update
              ${lib.getExe wine} msiexec /i "${wineUnwrapped}/share/wine/mono/wine-mono-9.3.0-x86.msi"

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

              ${lib.getExe winetricks} renderer=vulkan

              install -D -t "$WINEPREFIX/drive_c/windows/system32/WinMetadata/" ${dependencies}/*.winmd

              ${lib.getExe wineserver} -k || true
            '';

            layer_2 =
              pkgs.runCommand "base-prefix-2"
                {
                  buildInputs = [
                    pkgs.xvfb-run
                  ];
                }
                ''
                  set -x -e

                  cp -a ${layer_1} $out
                  chmod -R +w $out
                  export WINEPREFIX="$out"

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

                  ${lib.getExe wineserver} -k || true
                '';

            layer_3 =
              pkgs.runCommand "base-prefix-3"
                {
                  buildInputs = [
                    pkgs.xvfb-run
                  ];
                }
                ''
                  set -x -e

                  ${lib.strings.toShellVars {
                    inherit verbs;
                  }}

                  mkdir -p $out
                  mkdir -p /tmp/cache/winetricks/corefonts

                  cp -a ${layer_2} $out
                  chmod -R +w $out

                  export WINEPREFIX="$out"
                  export XDG_CACHE_HOME="/tmp/cache"

                  cp -R ${winetricksCache}/* /tmp/cache/winetricks
                  cp -R ${inputs.corefonts}/*.exe /tmp/cache/winetricks/corefonts

                  for verb in "${"\${verbs[@]}"}"; do
                      echo "winetricks: Installing $verb"

                      xvfb-run ${lib.getExe winetricks} -q -f "$verb"
                  done

                  ${lib.getExe wineserver} -k || true
                '';

            layer_4 = pkgs.runCommand "base-prefix-4" { } ''
              set -x -e

              ${lib.strings.toShellVars {
                inherit type;
              }}

              cp -a ${layer_3} $out
              chmod -R +w $out

              mkdir -p $out
              mkdir -p /tmp/cache/winetricks/corefonts

              export WINEPREFIX="$out"

              ${lib.getExe pkgs._7zz} x -y "${v3_msix}" "App/" -o"$WINEPREFIX/drive_c/Program Files/Affinity"
              mv "$WINEPREFIX/drive_c/Program Files/Affinity/App" "$WINEPREFIX/drive_c/Program Files/Affinity/Affinity"

              if [[ "$type" == "v3" ]]; then
                  ${lib.getExe injectPluginLoader}
              fi

              echo "removing nixbld directory"
              rm -rf $WINEPREFIX/drive_c/users/nixbld

              ${lib.getExe wineserver} -k || true
            '';
          in
          layer_4;
      };
    };
}
