{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      stdPath,
      self',
      ...
    }:
    {
      packages = {
        affinity-v3 = pkgs.callPackage ./package.nix {
          inherit inputs stdPath;
        };

        default = self'.packages.affinity-v3;

        v3 = lib.warn "the `v3` package is deprecated, please use `affinity-v3` instead." self'.packages.affinity-v3;
      };
    };
}
