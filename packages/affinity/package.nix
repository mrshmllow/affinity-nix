{
  symlinkJoin,
  callPackage,
  lib,
  name,
  stdenv,
  inputs,
  stdPath,
  ...
}:
let
  wine-packages = callPackage ../wine/packages.nix {
    inherit inputs stdPath;
  };

  apl-combined = callPackage ../apl/apl-combined.nix {
    src = inputs.plugin-loader-src;
  };

  prefixBase = callPackage ../prefixWithAffinity.nix {
    inherit inputs wine-packages apl-combined;
    v3 = false;
  };

  runner = callPackage ../runner/package.nix {
    inherit
      prefixBase
      inputs
      wine-packages
      name
      ;
    registry-patches = (callPackage ../registry-patches.nix { }).combined;
    toolchain = inputs.fenix.packages.${stdenv.hostPlatform.system}.complete;
  };

  desktop = callPackage ./desktopItems.nix {
    ${lib.toLower name} = runner.package;
  };

  icons = callPackage ./icons.nix { };
  icon-package = icons.mkIconPackageFor name;

  # last version of affinity v2 released
  lastV2Version = "2.6.5";
in
symlinkJoin {
  name = "affinity-${lib.toLower name}-${lastV2Version}";
  pname = "affinity-${lib.toLower name}";
  paths = [
    runner.package
    desktop.${lib.toLower name}
    icon-package
  ];
  meta = {
    mainProgram = "affinity-${lib.toLower name}";

    description = "Affinity ${name} ${lastV2Version}";
    license = lib.licenses.unfree;
    homepage = "https://affinity.serif.com/";
    platforms = [ "x86_64-linux" ];
  };
}
