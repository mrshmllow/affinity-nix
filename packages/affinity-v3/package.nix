{
  symlinkJoin,
  callPackage,
  stdenv,
  inputs,
  stdPath,
  lib,
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
  };

  runner = callPackage ../runner/package.nix {
    inherit prefixBase inputs wine-packages;
    registry-patches = (callPackage ../registry-patches.nix { }).combined;
    toolchain = inputs.fenix.packages.${stdenv.hostPlatform.system}.complete;
    name = "v3";
  };

  desktop = callPackage ./desktopItems.nix {
    affinity-v3 = runner.package;
  };

  icons = callPackage ./icons.nix { };
  icon-package = icons.iconPackage;
in
symlinkJoin {
  name = "Affinity v3";
  pname = "affinity-v3";
  paths = [
    runner.package
    desktop.affinity-v3
    icon-package
  ];
  meta = {
    mainProgram = "affinity-v3";

    description = "Affinity v3";
    license = lib.licenses.unfree;
    homepage = "https://affinity.serif.com/";
    platforms = [ "x86_64-linux" ];
  };
}
