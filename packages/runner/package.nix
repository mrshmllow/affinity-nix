{
  pkgs,
  lib,

  toolchain,
  inputs,
  registry-patches,
  wine-packages,
  prefixBase,
  name,
  ...
}:
let
  craneLib = (inputs.crane.mkLib pkgs).overrideToolchain toolchain.toolchain;
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
in
{
  package = craneLib.buildPackage (
    commonArgs
    // {
      inherit cargoArtifacts;

      pname = "affinity-${lib.toLower name}";

      cargoExtraArgs = "-p runner --no-default-features --features ${lib.toLower name}";
      src = fileSetForCrate ../../crates/runner;

      env = {
        LOWER_DIR = prefixBase;
        WINE = lib.getExe wine-packages.wine;
        WINEBOOT = lib.getExe wine-packages.wineboot;
        WINESERVER = lib.getExe wine-packages.wineserver;
        WINETRICKS = lib.getExe wine-packages.winetricks;
        FUSE_OVERLAYFS = lib.getExe pkgs.fuse-overlayfs;
        GNUTAR = lib.getExe pkgs.gnutar;
        ZENITY = lib.getExe pkgs.zenity;
        RSYNC = lib.getExe pkgs.rsync;
        REGISTRY_PATCHES = registry-patches;
        ON_LINUX = inputs.on-linux.outPath;
      };

      meta.mainProgram = "affinity-${lib.toLower name}";

      postInstall = ''
        mv $out/bin/runner $out/bin/affinity-${lib.toLower name}
      '';
    }
  );

  package-clippy = craneLib.cargoClippy (
    commonArgs
    // {
      inherit cargoArtifacts;
      cargoClippyExtraArgs = "--all-targets -- --deny warnings";
    }
  );
}
