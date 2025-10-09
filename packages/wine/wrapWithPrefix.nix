{
  stdenv,
  lib,
  pkgs,
  affinityPath,
  wineUnwrapped,
  stdPath,
}:
pkg: pname:
stdenv.mkDerivation rec {
  name = pname;
  src = ./.;
  nativeBuildInputs = [ pkgs.makeWrapper ];
  installPhase = ''
    makeWrapper ${lib.getExe' pkg pname} $out/bin/${name} \
      --run 'export WINEPREFIX="${affinityPath}"' \
      --set LD_LIBRARY_PATH "${wineUnwrapped}/lib:$LD_LIBRARY_PATH" \
      --set WINESERVER "${lib.getExe' wineUnwrapped "wineserver"}" \
      --set WINELOADER "${lib.getExe' wineUnwrapped "wine"}" \
      --set WINEDLLPATH "${wineUnwrapped}/lib/wine" \
      --set WINE "${lib.getExe' wineUnwrapped "wine"}" \
      --set WINEDLLOVERRIDES "winemenubuilder.exe=d" \
      --set PATH "${lib.makeBinPath stdPath}"
  '';
  meta.mainProgram = name;
}
