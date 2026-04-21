{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      self',
      ...
    }:
    let
      version = "unstable";
    in
    {
      packages = {
        apl = pkgs.callPackage ./apl.nix {
          src = inputs.plugin-loader-src;
          inherit version;
        };

        bootstrap = pkgs.callPackage ./bootstrap.nix {
          src = inputs.plugin-loader-src;
          inherit version;
        };

        d2d1 = pkgs.callPackage ./d2d1.nix {
          src = inputs.plugin-loader-src;
          inherit version;
        };

        apl-combined = pkgs.callPackage ./apl-combined.nix {
          inherit (self'.packages) apl bootstrap d2d1;
          inherit version;
        };
      };
    };
}
