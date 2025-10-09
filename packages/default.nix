{
  imports = [
    ./wine
    ./affinity
    ./unified
  ];
  perSystem =
    {
      sources,
      lib,
      pkgs,
      ...
    }:
    {
      _module.args = {
        sources = import ./sources.nix;
        version = sources._version;

        stdShellArgs = ''
          export LC_ALL="C"
          export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
          export PATH=${
            lib.makeSearchPath "bin" [
              pkgs.zenity
              pkgs.curl

              pkgs.coreutils
              pkgs.gnused
              pkgs.gnugrep
            ]
          }
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
