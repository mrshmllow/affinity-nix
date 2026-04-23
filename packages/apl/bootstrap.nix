{
  pkgs,
  version,
  src,
  ...
}:
pkgs.pkgsCross.mingwW64.stdenv.mkDerivation {
  pname = "affinity-bootstrap";

  inherit version;

  src = "${src}/AffinityBootstrap";

  nativeBuildInputs = [ pkgs.wine64 ];

  buildPhase = ''
    mkdir -p build

    cat << 'EOF' > mscoree.def
    LIBRARY mscoree.dll
    EXPORTS
    CLRCreateInstance
    EOF

    x86_64-w64-mingw32-dlltool -d mscoree.def -l build/libmscoree.a

    $CC -shared -o build/AffinityBootstrap.dll bootstrap.c \
      -I${pkgs.wine64}/include/wine/windows \
      -Lbuild \
      -lole32 -loleaut32 -luuid -lmscoree
  '';

  installPhase = ''
    mkdir -p $out/lib/AffinityPluginLoader
    cp build/AffinityBootstrap.dll $out/lib/AffinityPluginLoader
  '';
}
