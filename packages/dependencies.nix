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
