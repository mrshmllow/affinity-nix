{
  imports = [
    ./wine
    ./affinity
    ./affinity-v3
    ./unified
    ./common.nix
  ];
  perSystem =
    {
      sources,
      lib,
      pkgs,
      stdPath,
      ...
    }:
    {
      _module.args = {
        sources = import ./sources.nix;
        version = sources._version;
        stdPath = [
          pkgs.zenity
          pkgs.curl

          pkgs.coreutils
          pkgs.gnused
          pkgs.gnugrep
          pkgs.wget

          pkgs.busybox
        ];

        stdShellArgs = ''
          export LC_ALL="C"
          export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
          export PATH=${lib.makeBinPath stdPath}
        '';
      };
    };

  flake =
    let
      sources = import ./sources.nix;
      version = sources._version;
    in
    {
      inherit version;
    };
}
