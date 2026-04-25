{ inputs, ... }:
{
  perSystem =
    {
      config,
      lib,
      craneLib,
      pkgs,
      self',
      wine-packages,
      ...
    }:
    let
      cfg = config.pre-commit;
    in
    {
      # Adapted from
      # https://github.com/cachix/git-hooks.nix/blob/dcf5072734cb576d2b0c59b2ac44f5050b5eac82/flake-module.nix#L66-L78
      devShells.default = craneLib.devShell {
        packages = lib.flatten [
          cfg.settings.enabledPackages
          cfg.settings.package

          pkgs.uv
          pkgs.flatpak-builder
          pkgs.just
        ];

        env = {
          WINE = lib.getExe self'.packages.wine;
          WINESERVER = lib.getExe wine-packages.wineserver;
          WINETRICKS = lib.getExe wine-packages.winetricks;
          FUSE_OVERLAYFS = lib.getExe pkgs.fuse-overlayfs;
          GNUTAR = lib.getExe pkgs.gnutar;
          ZENITY = lib.getExe pkgs.zenity;
          RSYNC = lib.getExe pkgs.rsync;
          REGISTRY_PATCHES = (pkgs.callPackage ../packages/registry-patches.nix { }).combined;
          ON_LINUX = inputs.on-linux.outPath;

          LOWER_DIR = "";
        };

        shellHook = builtins.concatStringsSep "\n" [
          cfg.installationScript
        ];
      };
    };
}
