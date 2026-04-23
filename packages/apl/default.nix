{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      self',
      ...
    }:
    {
      packages.apl-combined = pkgs.callPackage ./apl-combined.nix {
        src = inputs.plugin-loader-src;
      };
    };
}
