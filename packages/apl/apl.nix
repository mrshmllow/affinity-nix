{
  buildDotnetModule,
  src,
  version,
  ...
}:
buildDotnetModule rec {
  pname = "AffinityPluginLoader";

  inherit version src;

  projectFile = "AffinityPluginLoader.sln";

  nugetDeps = ./deps.json;

  postInstall = ''
    pushd $out/lib/${pname}
    rm *.pdb
    rm *.config

    mkdir -p ./apl/plugins
    mv ./WineFix.dll ./apl/plugins
  '';
}
