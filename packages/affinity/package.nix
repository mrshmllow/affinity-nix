{
  symlinkJoin,
  callPackage,
  lib,
  name,
  runner,
  ...
}:
let
  # last version of affinity v2 released
  lastV2Version = "2.6.5";

  namedRunner = runner.override {
    inherit name;
  };

  desktop = callPackage ./desktopItems.nix {
    ${lib.toLower name} = namedRunner;
  };

  icons = callPackage ./icons.nix { };
  icon-package = icons.mkIconPackageFor name;
in
symlinkJoin {
  name = "affinity-${name}-${lastV2Version}";
  pname = "affinity-${lib.toLower name}";
  paths = [
    namedRunner
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
