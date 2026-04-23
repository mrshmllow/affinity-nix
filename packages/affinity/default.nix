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
          inherit inputs stdPath;
        };
        affinity-designer = pkgs.callPackage ./package.nix {
          name = "Designer";
          inherit inputs stdPath;
        };
        affinity-publisher = pkgs.callPackage ./package.nix {
          name = "Publisher";
          inherit inputs stdPath;
        };

        photo = makeDeprecated "photo";
        designer = makeDeprecated "designer";
        publisher = makeDeprecated "publisher";
      };
    };
}
