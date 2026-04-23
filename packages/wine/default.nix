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
        src = inputs.elemental-wine-source;
        nixpkgs-wine = inputs.nixpkgs-wine;
        inherit stdPath;
      };
    in
    {
      packages.wine = wine-packages.wine;

      _module.args = {
        inherit (wine-packages) wineUnwrapped;

        wine-stuff = wine-packages;
      };
    };
}
