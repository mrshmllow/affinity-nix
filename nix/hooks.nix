{
  perSystem =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      pre-commit = {
        settings = {
          hooks = {
            statix.enable = true;
            zizmor.enable = true;
            typos.enable = true;
            deadnix = {
              enable = true;
              settings.edit = true;
            };
            fmt = {
              enable = true;
              name = "nix fmt";
              entry = "${lib.getExe config.formatter} --no-cache";
            };
            ty = {
              enable = true;
              name = "ty check";
              files = "\\.py$";
              entry = lib.getExe (
                pkgs.writeShellScriptBin "ty-check" ''
                  cd tests/
                  ${lib.getExe pkgs.uv} run ty check
                ''
              );
            };
          };
        };
      };
    };
}
