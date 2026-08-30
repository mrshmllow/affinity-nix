{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      self',
      ...
    }:
    {
      packages = {
        affinity-v3 = pkgs.callPackage ./package.nix {
          inherit inputs;
        };

        default = self'.packages.affinity-v3;
      };
    };
}
