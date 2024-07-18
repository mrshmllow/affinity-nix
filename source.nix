{requireFile}: let
  version = "2.5.3";
in {
  photo = requireFile {
    name = "affinity-photo-msi-${version}.exe";
    sha256 = "0lly8jr6w0i8ifxphqpclisr3zrcfn2snnilwcs4q2h2jpvfgbiv";
    url = "https://store.serif.com/en-gb/update/windows/photo/2/";
  };
  designer = requireFile {
    name = "affinity-designer-msi-${version}.exe";
    sha256 = "1pj9adxh6d77b7sikqbd798gbf2hbn2yxwcld62bvfwrbqkyq6v7";
    url = "https://store.serif.com/en-gb/update/windows/designer/2/";
  };
  publisher = requireFile {
    name = "affinity-publisher-msi-${version}.exe";
    sha256 = "1rd6ma5idaa88i49mz2d9gl3k1svvpa6sna333p34dbjqdc5y7yq";
    url = "https://store.serif.com/en-gb/update/windows/designer/2/";
  };

  _version = version;
}
