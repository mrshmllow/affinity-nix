{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      self',
      warnUnfree,
      ...
    }:
    {
      packages = {
        affinity-v3 = warnUnfree (
          pkgs.callPackage ./package.nix {
            inherit inputs;
          }
        );

        default = self'.packages.affinity-v3;

        v3 = lib.warn "the `v3` package is deprecated, please use `affinity-v3` instead." self'.packages.affinity-v3;
      };
    };
}
