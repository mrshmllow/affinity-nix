{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      stdPath,
      self',
      warnUnfree,
      ...
    }:
    let
      makeDeprecated =
        name:
        lib.warn "the `${name}` package is deprecated, please use `affinity-${name}` instead."
          self'.packages."affinity-${name}";

      makeV2Package =
        name:
        warnUnfree (
          pkgs.callPackage ./package.nix {
            inherit inputs stdPath name;
          }
        );
    in
    {
      packages = {
        affinity-photo = makeV2Package "Photo";
        affinity-designer = makeV2Package "Designer";
        affinity-publisher = makeV2Package "Publisher";

        photo = makeDeprecated "photo";
        designer = makeDeprecated "designer";
        publisher = makeDeprecated "publisher";
      };
    };
}
