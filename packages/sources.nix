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
rec {
  v3-url = "https://web.archive.org/web/20260418054031/https://downloads.affinity.studio/Affinity%20x64.exe";
  v3-segment = ".rsrc/2057/BIN/135";

  v3 = mkExtract (pkgs.fetchurl {
    url = v3-url;
    hash = "sha256-h2zK4cEJpD3FPmhpxjf3Rm3MFcWoRaUjSY4saBfUgL4=";
  }) v3-segment;

  photo = mkExtract (pkgs.fetchurl {
    name = "affinity-photo-msi-2.6.5.exe";
    url = "https://web.archive.org/web/20251103235343/https://d1gl0nrskhax8d.cloudfront.net/windows/photo2/2.6.5/affinity-photo-msi-2.6.5.exe?Expires=1762217451&Signature=sQNwe~q1Na-2UVWhAC5ySq8vJrEgQf7uPvv2-Ju5vDm~X34rMiyJTqoy~Lwu47uEcRTPE9FbaZa7lHn5x04aFcDGj-vy~H06P6Y0RZhLY25yL2l-1XcCOfcKew8Dvfo1n-KM9bsKdYG0m5yL4pT4NBXz66PBhg-yMlx0VpVnRTIBPH-HghwiNn4PdXStisrbLDgqbbSexay~Ovy5EOHvCOJshIbKYZFoWQw1Nf3TTKlXSCNEKY43QT0Lj-t0SrBSkJLwgoWPqyCBAmvzQTGDH~OhidxwRR8zhQ9NgqBIopR2ZmKD~U2GeGu1lUA5X~0CD3PByJ5c2Tt8dpiwDCgC7g__&Key-Pair-Id=APKAIMMPYSI7GSVTEAAQ";
    hash = "sha256-waCX33rWVzZ8AYZWmv2EOqS6ikT6p7s9qRJ+8rDo6Wk=";
  }) ".rsrc/2057/BIN/135";

  designer = mkExtract (pkgs.fetchurl {
    name = "affinity-designer-msi-2.6.5.exe";
    url = "https://web.archive.org/web/20251103235412/https://d1gl0nrskhax8d.cloudfront.net/windows/designer2/2.6.5/affinity-designer-msi-2.6.5.exe?Expires=1762217645&Signature=ot75D-h9rqDSXhVk1w8qU2XQfJZPd6KRzOuvJt~PbPtRs45yb1ng7Y85L9krv32-pv7Y~FfvObNnlIo6TOo6xFwIhVHmtCwdciBbifDc9pjXbMr5mVZLlchsmS0IrkiZVUGUOM4e7rNo9LYTgBtQ1pIkb5uItD7wZN8nAb6rS962sxG1VtXXjyx7cWGqMsXiDUDI9DS9XHlQVipJUR1-x91cuLz6vIRjyCWlxA3sos3L8HmthmqDASSuVuzGbFHwCxTPVwGUf-0f9JdGz4JMV4EUUHeMU9QkBRYEBqzd~fGO54nfKwebGvGHVwwzooHwFqN5sdwZIS9pYxzlwgDCiA__&Key-Pair-Id=APKAIMMPYSI7GSVTEAAQ";
    hash = "sha256-b5K1FtsCWCjyn/NC4trB0g9Wv+AfLoDWgaZK2ZGXW0w=";
  }) ".rsrc/2057/BIN/135";

  publisher = mkExtract (pkgs.fetchurl {
    name = "affinity-publisher-msi-2.6.5.exe";
    url = "https://web.archive.org/web/20251108071110/https://d1gl0nrskhax8d.cloudfront.net/windows/publisher2/2.6.5/affinity-publisher-msi-2.6.5.exe?Expires=1762589460&Signature=WumFyCJpH7YV2ZKcRV7HOI70ITEVvkQX0pjuyfDsUmso5OTtdGaQxjSpmzQzZQZlbh6KZkAsxgZiujJQF-ktNA3JtED7~T-7ZTWDUVp0Q1B7cWbvKBDJkbgy1j0fVD2~mwOwK9TbQC6g8r-fmwVEsnWHiypcopR73fINt6PV0Ha4zuriIp3hFec6ho~00MG1hDCQkWRgmI3FHJAaUWQWWlt-C7Z5kM8ObvNHTb08qk~oh8ErDhpucEd3txjMN07jA3KTCKZohQV82mKVa~X0m~l2f5xJbEe0uU~HBv4CQwfnmdzC9zEfvgBJuqyB6VV5LnhMI3lGJAjvongA4KlozQ__&Key-Pair-Id=APKAIMMPYSI7GSVTEAAQ";
    hash = "sha256-76ikkAnbAghaSU5YLYLxXiHfAuqVfoEcQK16rHd6+7A=";
  }) ".rsrc/2057/BIN/135";
}
