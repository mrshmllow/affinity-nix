{
  symlinkJoin,
  callPackage,
  runner,
  lib,
  ...
}:
let
  desktop = callPackage ./desktopItems.nix {
    affinity-v3 = runner;
  };

  icons = callPackage ./icons.nix { };
  icon-package = icons.iconPackage;
in
symlinkJoin {
  name = "Affinity v3";
  pname = "affinity-v3";
  paths = [
    runner
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
