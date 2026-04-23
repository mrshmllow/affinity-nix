{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      self',
      ...
    }:
    let
      version = "unstable";
    in
    {
      packages = {
        apl = pkgs.buildDotnetModule rec {
          pname = "AffinityPluginLoader";

          inherit version;

          src = inputs.plugin-loader-src;

          projectFile = "AffinityPluginLoader.sln";

          patches = [
            ./no-login.patch
          ];

          nugetDeps = ./deps.json;

          postInstall = ''
            pushd $out/lib/${pname}
            rm *.pdb
            rm *.config

            mkdir -p ./apl/plugins
            mv ./WineFix.dll ./apl/plugins
          '';
        };

        bootstrap = pkgs.pkgsCross.mingwW64.stdenv.mkDerivation {
          pname = "affinity-bootstrap";

          inherit version;

          src = "${inputs.plugin-loader-src}/AffinityBootstrap";

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
        };

        apl-combined = pkgs.symlinkJoin {
          pname = "apl-combined";
          inherit version;
          paths = [
            self'.packages.apl
            self'.packages.bootstrap
          ];

          postBuild = ''
            mv $out/lib/AffinityPluginLoader/* $out
            rm -rf $out/lib
          '';
        };
      };
    };
}
