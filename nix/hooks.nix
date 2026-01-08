{
  perSystem =
    {
      config,
      lib,
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
          };
        };
      };
    };
}
