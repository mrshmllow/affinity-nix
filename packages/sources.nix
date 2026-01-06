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
    url = "https://web.archive.org/web/20251108071110/https://d1gl0nrskhax8d.cloudfront.net/windows/publisher2/2.6.5/affinity-publisher-msi-2.6.5.exe?Expires=1762589460&Signature=WumFyCJpH7YV2ZKcRV7HOI70ITEVvkQX0pjuyfDsUmso5OTtdGaQxjSpmzQzZQZlbh6KZkAsxgZiujJQF-ktNA3JtED7~T-7ZTWDUVp0Q1B7cWbvKBDJkbgy1j0fVD2~mwOwK9TbQC6g8r-fmwVEsnWHiypcopR73fINt6PV0Ha4zuriIp3hFec6ho~00MG1hDCQkWRgmI3FHJAaUWQWWlt-C7Z5kM8ObvNHTb08qk~oh8ErDhpucEd3txjMN07jA3KTCKZohQV82mKVa~X0m~l2f5xJbEe0uU~HBv4CQwfnmdzC9zEfvgBJuqyB6VV5LnhMI3lGJAjvongA4KlozQ__&Key-Pair-Id=APKAIMMPYSI7GSVTEAAQ";
  };

  v3 = {
    name = "Affinity x64.exe";
    sha256 = "53f44bcdbbe7923ade322ac5c713905cbc40447b1b9bcfc704219d66b56bc1dc";
    url = "https://web.archive.org/web/20260106232536/https://downloads.affinity.studio/Affinity%20x64.exe";
  };

  _version = version;
}
