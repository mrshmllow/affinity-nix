{
  fetchurl,
  pkgs,
  lib,
}:
rec {
  icon = fetchurl {
    url = "https://cdn.serif.com/store/img/logos/affinity-photo-2-020520191502.svg";
    sha256 = "04bnf12znp9dgkwpk46c01381cw298gq14ga7j7dwccyl3m556d7";
  };

  mkIconPackageFor = pkgs.runCommand "affinity-v3-icons" { } ''
    mkdir -p $out/share/icons/hicolor/{256x256,scalable}/apps

    cp ${icon} \
        $out/share/icons/hicolor/scalable/apps/affinity-v3.svg

    ${lib.getExe pkgs.inkscape} \
        -w 256 -h 256 \
        ${icon} \
        -o - > $out/share/icons/hicolor/256x256/apps/affinity-v3.png
  '';
}
