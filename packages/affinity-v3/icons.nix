{
  fetchurl,
  pkgs,
  lib,
}:
rec {
  icon = fetchurl {
    url = "https://static.canva.com/domain-assets/affinity/static/images/apple-touch-180x180-1.png";
    sha256 = "sha256-KLT9loFiD2y8uNXNzc27DZ4A73yEs6Ntr4h3WULG5HM=";
  };

  iconPackage = pkgs.runCommand "affinity-v3-icons" { } ''
    mkdir -p $out/share/icons/hicolor/256x256/apps

    ${lib.getExe pkgs.imagemagick} \
        ${icon} \
        -resize 256x256 \
        $out/share/icons/hicolor/256x256/apps/affinity-v3.png
  '';
}
