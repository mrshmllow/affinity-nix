{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      stdPath,
      ...
    }:
    let
      wine-packages = pkgs.callPackage ./packages.nix {
        inherit stdPath inputs;
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
