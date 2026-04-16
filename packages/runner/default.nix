{
  perSystem =
    {
      lib,
      craneLib,
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
