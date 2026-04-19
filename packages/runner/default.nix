{
  perSystem =
    {
      lib,
      pkgs,
      craneLib,
      wine-stuff,
      runnerEnv,
      mkPrefixBase,
      mkGraphicalCheck,
      self',
      ...
    }:
    let
      src = craneLib.cleanCargoSource ../..;

      commonArgs = {
        inherit src;
        strictDeps = true;
      };

      cargoArtifacts = craneLib.buildDepsOnly commonArgs;

      fileSetForCrate =
        crate:
        lib.fileset.toSource {
          root = ../..;
          fileset = lib.fileset.unions [
            ../../Cargo.toml
            ../../Cargo.lock
            (craneLib.fileset.commonCargoSources crate)
          ];
        };

      runner =
        lib.makeOverridable
          (
            {
              name,
            }:
            craneLib.buildPackage (
              commonArgs
              // rec {
                inherit cargoArtifacts;

                pname = "affinity-${lib.toLower name}";
                meta.mainProgram = pname;

                cargoExtraArgs = "-p runner --no-default-features --features ${lib.toLower name}";
                src = fileSetForCrate ../../crates/runner;

                env = runnerEnv // {
                  LOWER_DIR = mkPrefixBase (name == "v3");
                  CHECK_SCRIPT = lib.getExe (mkGraphicalCheck (name == "v3"));
                };

                postInstall = ''
                  mv $out/bin/runner $out/bin/affinity-${lib.toLower name}
                '';
              }
            )
          )
          {
            name = "v3";
          };
    in
    {
      _module.args = {
        runnerEnv = {
          WINE = lib.getExe self'.packages.wine;
          WINEBOOT = lib.getExe wine-stuff.wineboot;
          WINESERVER = lib.getExe wine-stuff.wineserver;
          WINETRICKS = lib.getExe wine-stuff.winetricks;
          FUSE_OVERLAYFS = lib.getExe pkgs.fuse-overlayfs;
          GNUTAR = lib.getExe pkgs.gnutar;
          ZENITY = lib.getExe pkgs.zenity;

          LOWER_DIR = "";
          CHECK_SCRIPT = "";
        };
      };

      checks = {
        inherit runner;

        runner-clippy = craneLib.cargoClippy (
          commonArgs
          // {
            inherit cargoArtifacts;
            cargoClippyExtraArgs = "--all-targets -- --deny warnings";
          }
        );
      };

      packages = {
        inherit runner;
      };
    };
}
