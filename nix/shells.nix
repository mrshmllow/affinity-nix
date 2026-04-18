{
  perSystem =
    {
      config,
      lib,
      craneLib,
      pkgs,
      runnerEnv,
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
        ];

        env = runnerEnv;

        shellHook = builtins.concatStringsSep "\n" [
          cfg.installationScript
        ];
      };
    };
}
