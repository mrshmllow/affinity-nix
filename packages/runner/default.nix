{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      toolchain,
      wine-packages,
      self',
      ...
    }:
    let
      runner = pkgs.callPackage ./package.nix {
        inherit toolchain inputs wine-packages;

        registry-patches = (pkgs.callPackage ../registry-patches.nix { }).combined;
        prefixBase = (
          pkgs.callPackage ../prefixWithAffinity.nix {
            inherit inputs wine-packages;
            apl-combined = self'.packages.apl-combined;
            v3 = true;
          }
        );
        name = "v3";
      };
    in
    {
      checks = {
        runner = runner.package;

        runner-clippy = runner.package-clippy;
      };

      packages.runner = runner.package;
    };
}
