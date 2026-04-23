{ inputs, ... }:
{
  imports = [
    ./wine
    ./affinity
    ./affinity-v3
    ./apl
    ./runner
  ];
  perSystem =
    {
      pkgs,
      lib,
      wine-packages,
      ...
    }:
    {
      # this function builds the prefix right up until the affinity sources
      # are used. this separation exists for build caching, as the affinity sources
      # should never be exposed to a cache
      packages.base-prefix-pre-affinity = pkgs.callPackage ./basePrefix.nix {
        inherit inputs wine-packages;
      };

      _module.args = {
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

        warnUnfree =
          pkg:
          lib.warn "For users of affinity-nix through NixOS, Home Manager, nix-darwin, or similar: please switch to consuming this package through the `affinity-nix.overlays.default` overlay. It will become `unfree` in the future, making it impossible to declaratively consume without an overlay." pkg;
      };
    };
}
