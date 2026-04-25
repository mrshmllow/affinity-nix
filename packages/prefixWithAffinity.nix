{
  callPackage,
  runCommand,
  lndir,
  lib,

  inputs,
  v3 ? true,
  wine-packages,
  apl-combined,
  ...
}:
let
  layer_3 = callPackage ./basePrefix.nix {
    inherit inputs wine-packages;
  };

  installers = callPackage ./sources.nix { };

  inherit (wine-packages) wineserver;
in
runCommand "base-prefix-4" { } ''
  set -x -e

  mkdir -p $out
  cp -a ${layer_3}/. $out
  chmod -R +w $out
  export WINEPREFIX="$out"

  ${lib.optionalString v3 ''
    ${lib.getExe lndir} ${installers.v3} "$WINEPREFIX/drive_c/Program Files/"

    pushd "$WINEPREFIX/drive_c/Program Files/Affinity/Affinity"
    cp -r "${apl-combined}/." .
    popd
  ''}

  ${lib.optionalString (!v3) ''
    ${lib.getExe lndir} ${installers.photo} "$WINEPREFIX/drive_c/Program Files/"
    ${lib.getExe lndir} ${installers.designer} "$WINEPREFIX/drive_c/Program Files/"
    ${lib.getExe lndir} ${installers.publisher} "$WINEPREFIX/drive_c/Program Files/"
  ''}

  ${lib.getExe wineserver} -w

  rm -rf $WINEPREFIX/drive_c/users/nixbld
''
