{requireFile}: let
  version = "2.5.6";
in {
  photo = requireFile {
    name = "affinity-photo-msi-${version}.exe";
    sha256 = "0a0mhlm38pvpkkq9xbgqc94yg9y8hnwdvkmjn4hmk5pi44hwk545";
    url = "https://store.serif.com/en-gb/update/windows/photo/2/";
  };
  designer = requireFile {
    name = "affinity-designer-msi-${version}.exe";
    sha256 = "0v73yq2jxgdnk5n5npr495p52535sr5z2bzk78kl7hgq0n3wbn58";
    url = "https://store.serif.com/en-gb/update/windows/designer/2/";
  };
  publisher = requireFile {
    name = "affinity-publisher-msi-${version}.exe";
    sha256 = "0kvixkjgh0r68f5vz6s78j7qssf8749157gidarlf6ych5ipvfmy";
    url = "https://store.serif.com/en-gb/update/windows/designer/2/";
  };

  _version = version;
}
