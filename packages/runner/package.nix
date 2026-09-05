{
  pkgs,
  lib,

  inputs,
  registry-patches,
  wine-packages,
  prefixBase,
  name,
  ...
}:
let
  craneLib = inputs.crane.mkLib pkgs;
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

  env = {
    WINE = lib.getExe wine-packages.wine;
    WINESERVER = lib.getExe wine-packages.wineserver;
    WINETRICKS = lib.getExe wine-packages.winetricks;
    FUSE_OVERLAYFS = lib.getExe pkgs.fuse-overlayfs;
    GNUTAR = lib.getExe pkgs.gnutar;
    ZENITY = lib.getExe pkgs.zenity;
    RSYNC = lib.getExe pkgs.rsync;
    REGISTRY_PATCHES = registry-patches;
    ON_LINUX = inputs.on-linux.outPath;
  };

  executableName = "affinity-${lib.toLower name}";

  executable = craneLib.buildPackage (
    commonArgs
    // {
      inherit cargoArtifacts env;

      pname = executableName;

      cargoExtraArgs = "-p runner --no-default-features --features ${lib.toLower name}";
      src = fileSetForCrate ../../crates/runner;

      meta.mainProgram = executableName;

      postInstall = ''
        mv $out/bin/runner $out/bin/affinity-${lib.toLower name}
      '';
    }
  );
in
{
  package =
    pkgs.runCommand executableName
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];

        meta.mainProgram = executableName;
      }
      ''
        mkdir -p $out/bin
        cp ${lib.getExe executable} $out/bin/${executableName}

        wrapProgram $out/bin/${executableName} \
            --set "LOWER_DIR" "${prefixBase}" \
      '';

  package-clippy = craneLib.cargoClippy (
    commonArgs
    // {
      inherit cargoArtifacts env;
      cargoClippyExtraArgs = "--all-targets -- --deny warnings";
    }
  );

  package-artifacts = cargoArtifacts;
}
