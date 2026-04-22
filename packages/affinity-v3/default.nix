{
  perSystem =
    {
      pkgs,
      self',
      ...
    }:
    {
      packages = {
        default = self'.packages.affinity-v3;
        affinity-v3 = pkgs.callPackage ./package.nix {
          inherit (self'.packages) runner;
        };

        v3 = lib.warn "the `v3` package is deprecated, please use `affinity-v3` instead." self'.packages.affinity-v3;
      };
    };
}
