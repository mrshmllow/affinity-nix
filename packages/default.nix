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
      lib,
      pkgs,
      stdPath,
      wine-stuff,
      self',
      ...
    }:
    {
      # this function builds the prefix right up until the affinity sources
      # are used. this separation exists for build caching, as the affinity sources
      # should never be exposed to a cache
      packages.base-prefix-pre-affinity = pkgs.callPackage ./basePrefix.nix {
        inherit inputs;
        wine-packages = wine-stuff;
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

        stdShellArgs = ''
          export LC_ALL="C"
          export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
          export PATH=${lib.makeBinPath (stdPath pkgs)}
        '';

        mkPrefixBase =
          v3:
          (pkgs.callPackage ./prefixWithAffinity.nix {
            inherit inputs v3;
            wine-packages = wine-stuff;
            apl-combined = self'.packages.apl-combined;
          });
      };
    };
}
