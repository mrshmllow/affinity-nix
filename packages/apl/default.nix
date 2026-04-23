{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      packages.apl-combined = pkgs.callPackage ./apl-combined.nix {
        src = inputs.plugin-loader-src;
      };
    };
}
