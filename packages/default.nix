{
  imports = [
    ./wine
    ./affinity
  ];
  perSystem =
    { sources, ... }:
    {
      _module.args = {
        sources = import ./sources.nix;
        version = sources._version;
      };
    };
}
