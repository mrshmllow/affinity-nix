{
  stdenv,
  version,
  wine64,
  src,
  ...
}:
let
  TARGET = "x86_64-unix";
in
stdenv.mkDerivation {
  src = "${src}/WineFix/lib/d2d1";
  pname = "d2d1";
  inherit version TARGET;

  nativeBuildInputs = [ wine64 ];

  env.NIX_CFLAGS_COMPILE = toString [
    "-Wno-error=incompatible-pointer-types"
    "-Wno-error=discarded-qualifiers"
  ];

  installPhase = ''
    mkdir -p $out/lib/AffinityPluginLoader
    cp build/${TARGET}/d2d1.dll.so $out/lib/AffinityPluginLoader/d2d1.dll
  '';
}
