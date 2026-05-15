{ withSystem, inputs, ... }:
{
  flake.overlays.default =
    _final: prev:
    withSystem prev.stdenv.hostPlatform.system (_: {
      affinity-v3 = prev.callPackage ./packages/affinity-v3/package.nix {
        inherit inputs;
      };
      affinity-photo = prev.callPackage ./packages/affinity/package.nix {
        name = "Photo";
        inherit inputs;
      };
      affinity-designer = prev.callPackage ./packages/affinity/package.nix {
        name = "Designer";
        inherit inputs;
      };
      affinity-publisher = prev.callPackage ./packages/affinity/package.nix {
        name = "Publisher";
        inherit inputs;
      };
    });
}
