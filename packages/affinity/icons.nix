{
  fetchurl,
  pkgs,
  lib,
}:
rec {
  icons = {
    photo = fetchurl {
      url = "https://cdn.serif.com/store/img/logos/affinity-photo-2-020520191502.svg";
      sha256 = "04bnf12znp9dgkwpk46c01381cw298gq14ga7j7dwccyl3m556d7";
    };
    designer = fetchurl {
      url = "https://cdn.serif.com/store/img/logos/affinity-designer-2-020520191502.svg";
      sha256 = "025j4aq8py2a5r34hx39nlhdmps06z6506h7wxchyxbbz6xz3d11";
    };
    publisher = fetchurl {
      url = "https://cdn.serif.com/store/img/logos/affinity-publisher-2-020520191502.svg";
      sha256 = "16ghh3mc2vjhvphbyy9zgan066ccp3xj1ilb6z5lmvsb94dp37aj";
    };
  };

  mkIconPackageFor =
    name:
    pkgs.runCommand "${name}-icons" { } ''
      mkdir -p $out/share/icons/hicolor/{256x256,scalable}/apps

      cp ${icons.${lib.toLower name}} \
          $out/share/icons/hicolor/scalable/apps/affinity-${lib.toLower name}.svg

      # https://docs.appimage.org/reference/appdir.html
      ${lib.getExe pkgs.inkscape} \
          -w 256 -h 256 \
          ${icons.${lib.toLower name}} \
          -o - > $out/share/icons/hicolor/256x256/apps/affinity-${lib.toLower name}.png
    '';
}
