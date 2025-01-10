{requireFile}: let
  version = "2.5.7";
in {
  photo = requireFile {
    name = "affinity-photo-msi-${version}.exe";
    sha256 = "0765m6ci844kkw2wf2c8x9drizbi0h0m5kjd1z3csvhq4fiqqxys";
    url = "https://store.serif.com/en-gb/update/windows/photo/2/";
  };
  designer = requireFile {
    name = "affinity-designer-msi-${version}.exe";
    sha256 = "0w56kgl359qjrbrhqhwcpsdfz314cpkbmiawpps49ksb0k83ivqz";
    url = "https://store.serif.com/en-gb/update/windows/designer/2/";
  };
  publisher = requireFile {
    name = "affinity-publisher-msi-${version}.exe";
    sha256 = "1p3sifs58w86zkq1hd38p3hrnf0rj858qf0rg38l6ywv03yr2axv";
    url = "https://store.serif.com/en-gb/update/windows/publisher/2/";
  };

  _version = version;
}
