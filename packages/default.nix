{ inputs, ... }:
{
  imports = [
    ./wine
    ./affinity
    ./affinity-v3
    ./apl
    ./runner
  ];
  perSystem =
    {
      pkgs,
      wine-packages,
      ...
    }:
    {
      # this function builds the prefix right up until the affinity sources
      # are used. this separation exists for build caching, as the affinity sources
      # should never be exposed to a cache
      packages.base-prefix-pre-affinity = pkgs.callPackage ./basePrefix.nix {
        inherit inputs wine-packages;
      };

      _module.args = {
        
      };
    };
}
