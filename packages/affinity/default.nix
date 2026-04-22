{
  perSystem =
    {
      pkgs,
      self',
      ...
    }:
    let
      makeDeprecated =
        name:
        lib.warn "the `${name}` package is deprecated, please use `affinity-${name}` instead."
          self'.packages."affinity-${name}";
    in
    {
      packages = {
        affinity-photo = pkgs.callPackage ./package.nix {
          name = "Photo";
          runner = self'.packages.runner;
        };
        affinity-designer = pkgs.callPackage ./package.nix {
          name = "Designer";
          runner = self'.packages.runner;
        };
        affinity-publisher = pkgs.callPackage ./package.nix {
          name = "Publisher";
          runner = self'.packages.runner;
        };

        photo = makeDeprecated "photo";
        designer = makeDeprecated "designer";
        publisher = makeDeprecated "publisher";
      };
    };
}
