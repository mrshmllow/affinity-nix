{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      ...
    }:
    let
      wine-packages = pkgs.callPackage ./packages.nix {
        inherit inputs;
      };
    in
    {
      packages.wine = wine-packages.wine;

      _module.args = {
        inherit (wine-packages) wineUnwrapped;

        wine-packages = wine-packages;
      };
    };
}
