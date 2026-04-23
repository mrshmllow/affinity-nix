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

  d2d1 = callPackage ./d2d1.nix {
    inherit version src;
  };
in
symlinkJoin {
  pname = "apl-combined";
  inherit version;
  paths = [
    apl
    d2d1
    bootstrap
  ];

  postBuild = ''
    mv $out/lib/AffinityPluginLoader/* $out
    rm -rf $out/lib
  '';
}
