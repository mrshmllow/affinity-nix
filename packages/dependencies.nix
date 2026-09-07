{
  fetchurl,
  lib,
  runCommand,
}:
let
  paths = {
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
