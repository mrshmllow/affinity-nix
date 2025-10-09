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
          export PATH=${
            lib.makeSearchPathOutput "dev" "bin" [
              pkgs.toybox
              pkgs.zenity
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
