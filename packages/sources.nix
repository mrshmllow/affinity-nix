let
  version = "2.6.5";
in
{
  # last version of v2 ever released
  photo = {
    name = "affinity-photo-msi-${version}.exe";
    sha256 = "c1a097df7ad657367c0186569afd843aa4ba8a44faa7bb3da9127ef2b0e8e969";
    url = "https://web.archive.org/web/20251103235343/https://d1gl0nrskhax8d.cloudfront.net/windows/photo2/2.6.5/affinity-photo-msi-2.6.5.exe?Expires=1762217451&Signature=sQNwe~q1Na-2UVWhAC5ySq8vJrEgQf7uPvv2-Ju5vDm~X34rMiyJTqoy~Lwu47uEcRTPE9FbaZa7lHn5x04aFcDGj-vy~H06P6Y0RZhLY25yL2l-1XcCOfcKew8Dvfo1n-KM9bsKdYG0m5yL4pT4NBXz66PBhg-yMlx0VpVnRTIBPH-HghwiNn4PdXStisrbLDgqbbSexay~Ovy5EOHvCOJshIbKYZFoWQw1Nf3TTKlXSCNEKY43QT0Lj-t0SrBSkJLwgoWPqyCBAmvzQTGDH~OhidxwRR8zhQ9NgqBIopR2ZmKD~U2GeGu1lUA5X~0CD3PByJ5c2Tt8dpiwDCgC7g__&Key-Pair-Id=APKAIMMPYSI7GSVTEAAQ";
  };
  designer = {
    name = "affinity-designer-msi-${version}.exe";
    sha256 = "6f92b516db025828f29ff342e2dac1d20f56bfe01f2e80d681a64ad991975b4c";
    url = "https://web.archive.org/web/20251103235412/https://d1gl0nrskhax8d.cloudfront.net/windows/designer2/2.6.5/affinity-designer-msi-2.6.5.exe?Expires=1762217645&Signature=ot75D-h9rqDSXhVk1w8qU2XQfJZPd6KRzOuvJt~PbPtRs45yb1ng7Y85L9krv32-pv7Y~FfvObNnlIo6TOo6xFwIhVHmtCwdciBbifDc9pjXbMr5mVZLlchsmS0IrkiZVUGUOM4e7rNo9LYTgBtQ1pIkb5uItD7wZN8nAb6rS962sxG1VtXXjyx7cWGqMsXiDUDI9DS9XHlQVipJUR1-x91cuLz6vIRjyCWlxA3sos3L8HmthmqDASSuVuzGbFHwCxTPVwGUf-0f9JdGz4JMV4EUUHeMU9QkBRYEBqzd~fGO54nfKwebGvGHVwwzooHwFqN5sdwZIS9pYxzlwgDCiA__&Key-Pair-Id=APKAIMMPYSI7GSVTEAAQ";
  };
  publisher = {
    name = "affinity-publisher-msi-${version}.exe";
    sha256 = "efa8a49009db02085a494e582d82f15e21df02ea957e811c40ad7aac777afbb0";
    url = "https://web.archive.org/web/20251103235402/https://d1gl0nrskhax8d.cloudfront.net/windows/publisher2/2.6.5/affinity-publisher-msi-2.6.5.exe?Expires=1762217633&Signature=a66~IMXMQ0CVfuT284IDwZTSvQepehSumTq7kQl5-tv-bxjjFh4a4Eb1N2ecHGCeqQH~mHirG4d7Lzki56tEHr-HFw3YHGANm4CK8Ol6BM1WMlgsfxr7YoR7Use1c~3IsxMhw6dXDhLtoV9HcV-wlI-PijQ565NMp8NGD9tZAVEwy~t--5EdKC3KY~n-cHXykKh3lomAYbj1APF~IZd-OpiM0kEFdtvOGosMqqc6Hd1g~J878mrKfu7CpC66fSkOdL0MFOyvs1PaHoaWKjsYZnAk8tFRyfwIY7CPLUsRM6fw5KIeXiXhins5BLas~GEd9GPoQOW1WLDYseU14nh-rg__&Key-Pair-Id=APKAIMMPYSI7GSVTEAAQ";
  };

  v3 = {
    name = "Affinity x64.exe";
    sha256 = "26194fb7ab0c83754549c99951b2dbbdc0361278172d02bb55eaf6b42a100409";
    # Oct 30th 2025
    url = "https://web.archive.org/web/20251030194823/https://downloads.affinity.studio/Affinity%20x64.exe";
  };

  _version = version;
}
