{
  stdenv,
  lib,
  pkgs,
  affinityPath,
  wineUnwrapped,
}: pkg: pname:
stdenv.mkDerivation rec {
  name = "affinity-${pname}";
  src = ./.;
  nativeBuildInputs = [pkgs.makeWrapper];
  installPhase = ''
    makeWrapper ${lib.getExe' pkg pname} $out/bin/${name} \
      --run 'export WINEPREFIX="${affinityPath}"' \
      --set LD_LIBRARY_PATH "${wineUnwrapped}/lib:$LD_LIBRARY_PATH" \
      --set WINESERVER "${lib.getExe' wineUnwrapped "wineserver"}" \
      --set WINELOADER "${lib.getExe' wineUnwrapped "wine"}" \
      --set WINEDLLPATH "${wineUnwrapped}/lib/wine" \
      --set WINE "${lib.getExe' wineUnwrapped "wine"}"
  '';
  meta.mainProgram = name;
}
