{
  fetchurl,
  lib,
  runCommand,
}:
let
  paths = {
    "Windows.Services.winmd" = fetchurl {
      url = "https://archive.org/download/windows.services-system.winmd/Windows.Services.winmd";
      hash = "sha256-l9TRXyyacQFHoVsq6s8zGvJ+SLl4pTNv6yesNksAzdQ=";
    };
    "Windows.System.winmd" = fetchurl {
      url = "https://archive.org/download/windows.services-system.winmd/Windows.System.winmd";
      hash = "sha256-EOh5DJXzF+gdqW1Jc4lS1/J2x3hC/SxRkHMzzS4h0TM=";
    };
    "MicrosoftEdgeWebView2RuntimeInstallerX64.exe" = fetchurl {
      url = "https://archive.org/download/microsoft-edge-web-view-2-runtime-installer-v109.0.1518.78/MicrosoftEdgeWebView2RuntimeInstallerX64.exe";
      hash = "sha256-8sxJhj4iFALUZk2fqUSkfyJUPaLcs2NDjD5Zh4m5/Vs=";
    };
  };
in
runCommand "dependencies" { } ''
  mkdir -p $out

  ${lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: content: ''
      ln -s ${content} $out/${name}
    '') paths
  )}
''
