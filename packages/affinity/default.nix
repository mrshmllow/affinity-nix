{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      ...
    }:
    let
      makeV2Package =
        name:
        (pkgs.callPackage ./package.nix {
          inherit inputs name;
        });
    in
    {
      packages = {
        affinity-photo = makeV2Package "Photo";
        affinity-designer = makeV2Package "Designer";
        affinity-publisher = makeV2Package "Publisher";
      };
    };
}
