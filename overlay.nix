{ withSystem, inputs, ... }:
{
  flake.overlays.default =
    _final: prev:
    withSystem prev.stdenv.hostPlatform.system (
      _:
      let
        stdPath = pkgs: [
          pkgs.zenity
          pkgs.curl

          pkgs.zstd
          pkgs.coreutils
          pkgs.gnused
          pkgs.gnugrep
          pkgs.wget

          pkgs.busybox
        ];
      in
      {
        affinity-v3 = prev.callPackage ./packages/affinity-v3/package.nix {
          inherit inputs stdPath;
        };
        affinity-photo = prev.callPackage ./packages/affinity/package.nix {
          name = "Photo";
          inherit inputs stdPath;
        };
        affinity-designer = prev.callPackage ./packages/affinity/package.nix {
          name = "Designer";
          inherit inputs stdPath;
        };
        affinity-publisher = prev.callPackage ./packages/affinity/package.nix {
          name = "Publisher";
          inherit inputs stdPath;
        };
      }
    );
}
