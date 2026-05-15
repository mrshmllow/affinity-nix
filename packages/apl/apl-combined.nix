{
  callPackage,
  symlinkJoin,
  src,
  ...
}:
let
  version = "unstable";

  apl = callPackage ./apl.nix {
    inherit version src;
  };

  bootstrap = callPackage ./bootstrap.nix {
    inherit version src;
  };
in
symlinkJoin {
  pname = "apl-combined";
  inherit version;
  paths = [
    apl
    bootstrap
  ];

  postBuild = ''
    mv $out/lib/AffinityPluginLoader/* $out
    rm -rf $out/lib
  '';
}
