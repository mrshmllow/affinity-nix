{requireFile}: let
  version = "2.6.0";
in {
  photo = requireFile {
    name = "affinity-photo-msi-${version}.exe";
    sha256 = "0xdyi6gwshdn7xh742faawwvc0nnwp8xsaxwsirh8hwf7s34rgm4";
    url = "https://store.serif.com/en-gb/update/windows/photo/2/";
  };
  designer = requireFile {
    name = "affinity-designer-msi-${version}.exe";
    sha256 = "0wrhk3jid4ffa43y2rkpx6ddilk8pqlk5himr22hj14prwm6ibgg";
    url = "https://store.serif.com/en-gb/update/windows/designer/2/";
  };
  publisher = requireFile {
    name = "affinity-publisher-msi-${version}.exe";
    sha256 = "0b6snfs3fz5d5ifh9vmcaydplqilpxyll4c5x7rxxjprfa3y977j";
    url = "https://store.serif.com/en-gb/update/windows/publisher/2/";
  };

  _version = version;
}
