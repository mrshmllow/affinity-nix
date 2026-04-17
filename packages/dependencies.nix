{
  fetchurl,
  lib,
  runCommand,
}:
let
  paths = {
    "Windows.winmd" = fetchurl {
      url = "https://github.com/microsoft/windows-rs/raw/576233a0db0d5937cf72b44c786aee929b464982/crates/libs/bindgen/default/Windows.winmd";
      hash = "sha256-lOtKvda8jv+oup5I9WFWurdJs0AuLl98PRiytasPxys=";
    };
    "wintypes.dll" = fetchurl {
      url = "https://github.com/ElementalWarrior/wine-wintypes.dll-for-affinity/raw/f8a2d42ba3abc5dcdc584daa6728a2fa019be72e/wintypes_shim.dll.so";
      hash = "sha256-pcrlA48/FHpuHolzoa8JfaOP4ohp6/HalCQ9ZL/rv/Y=";
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
