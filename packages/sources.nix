{
  pkgs,
  lib,
  ...
}:
let

  mkExtract =
    source: segment:
    pkgs.runCommand "affinity-extracted-sources"
      {
        nativeBuildInputs = [
          pkgs._7zz
          pkgs.msitools
        ];

        meta.license = lib.licenses.unfree;
      }
      ''
        7zz e ${source} -tpe "${segment}"
        msiextract -C $out ./*
      '';
in
{
  v3 = mkExtract (pkgs.fetchurl {
    url = "https://web.archive.org/web/20260418054031/https://downloads.affinity.studio/Affinity%20x64.exe";
    hash = "sha256-h2zK4cEJpD3FPmhpxjf3Rm3MFcWoRaUjSY4saBfUgL4=";
  }) ".rsrc/2057/BIN/135";

  photo = mkExtract (pkgs.fetchurl {
    name = "affinity-photo-msi-2.6.5.exe";
    url = "https://archive.org/download/affinity_20251030/affinity-photo-msi-2.6.5.exe";
    hash = "sha256-waCX33rWVzZ8AYZWmv2EOqS6ikT6p7s9qRJ+8rDo6Wk=";
  }) ".rsrc/2057/BIN/135";

  designer = mkExtract (pkgs.fetchurl {
    name = "affinity-designer-msi-2.6.5.exe";
    url = "https://archive.org/download/affinity_20251030/affinity-designer-msi-2.6.5.exe";
    hash = "sha256-b5K1FtsCWCjyn/NC4trB0g9Wv+AfLoDWgaZK2ZGXW0w=";
  }) ".rsrc/2057/BIN/135";

  publisher = mkExtract (pkgs.fetchurl {
    name = "affinity-publisher-msi-2.6.5.exe";
    url = "https://archive.org/download/affinity_20251030/affinity-publisher-msi-2.6.5.exe";
    hash = "sha256-76ikkAnbAghaSU5YLYLxXiHfAuqVfoEcQK16rHd6+7A=";
  }) ".rsrc/2057/BIN/135";
}
