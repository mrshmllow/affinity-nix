{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      wine-packages,
      ...
    }:
    let
      runner = pkgs.callPackage ./package.nix {
        inherit inputs wine-packages;

        registry-patches = (pkgs.callPackage ../registry-patches.nix { }).combined;
        prefixBase = "/non-functional-runner";
        name = "v3";
      };
    in
    {
      checks = {
        runner = runner.package;

        runner-clippy = runner.package-clippy;
      };

      packages = {
        runner = runner.package;
        runner-artifacts = runner.package-artifacts;
      };
    };
}
