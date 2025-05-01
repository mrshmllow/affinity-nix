{requireFile}: let
  version = "2.6.2";
in {
  photo = requireFile {
    name = "affinity-photo-msi-${version}.exe";
    sha256 = "0wlg6v6qxxbkrz856nchh77kg7k8jhlmdga3fd58a8sqh3xnx9cc";
    url = "https://store.serif.com/en-gb/update/windows/photo/2/";
  };
  designer = requireFile {
    name = "affinity-designer-msi-${version}.exe";
    sha256 = "0906w23g2csa52rwncv53ys0bq04ainbxlr60cp5rd8zcglkqas2";
    url = "https://store.serif.com/en-gb/update/windows/designer/2/";
  };
  publisher = requireFile {
    name = "affinity-publisher-msi-${version}.exe";
    sha256 = "14sqkbjg2yy7lnfx27wfp6gsabkhxkyg76rs8zphyk4wca6w0w3d";
    url = "https://store.serif.com/en-gb/update/windows/publisher/2/";
  };

  _version = version;
}
