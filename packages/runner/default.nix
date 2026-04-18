{
  perSystem =
    {
      lib,
      pkgs,
      craneLib,
      wine-stuff,
      runnerEnv,
      ...
    }:
    let
      src = craneLib.cleanCargoSource ../..;

      commonArgs = {
        inherit src;
        strictDeps = true;

        env = runnerEnv;
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

      runner = craneLib.buildPackage (
        commonArgs
        // {
          inherit cargoArtifacts;
          pname = "runner";
          cargoExtraArgs = "-p runner";
          src = fileSetForCrate ../../crates/runner;
          meta.mainProgram = "runner";
        }
      );
    in
    {
      _module.args = {
        runnerEnv = {
          WINEBOOT = lib.getExe wine-stuff.wineboot;
          WINESERVER = lib.getExe wine-stuff.wineserver;
          FUSE_OVERLAYFS = lib.getExe pkgs.fuse-overlayfs;
          GNUTAR = lib.getExe pkgs.gnutar;
          ZENITY = lib.getExe pkgs.zenity;
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
