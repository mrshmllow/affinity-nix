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

          nugetDeps = ./deps.json;

          postInstall = ''
            pushd $out/lib/${pname}
            rm *.pdb

            mkdir -p ./apl/plugins
            mv ./WineFix.dll ./apl/plugins
          '';
        };

        d2d1 = pkgs.stdenv.mkDerivation rec {
          src = "${inputs.plugin-loader-src}/WineFix/lib/d2d1";
          pname = "d2d1";
          inherit version;

          nativeBuildInputs = with pkgs; [
            wine64
          ];

          TARGET = "x86_64-unix";

          env.NIX_CFLAGS_COMPILE = toString [
            "-Wno-error=incompatible-pointer-types"
            "-Wno-error=discarded-qualifiers"
          ];

          installPhase = ''
            mkdir -p $out/lib/AffinityPluginLoader
            cp build/${TARGET}/d2d1.dll.so $out/lib/AffinityPluginLoader/d2d1.dll
          '';
        };

        apl-combined = pkgs.symlinkJoin {
          pname = "apl-combined";
          inherit version;
          paths = [
            self'.packages.apl
            self'.packages.d2d1
          ];

          postBuild = ''
            mv $out/lib/AffinityPluginLoader/* $out
            rm -rf $out/lib
          '';
        };
      };
    };
}
