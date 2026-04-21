{
  apl,
  d2d1,
  bootstrap,
  version,
  symlinkJoin,
  ...
}:
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
