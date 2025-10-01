{ requireFile }:
let
  version = "2.6.4";
in
{
  photo = requireFile {
    name = "affinity-photo-msi-${version}.exe";
    sha256 = "0wf8ywgvssh9r1b9qcaam5b0ma91722z33a2mj94869p0hrs1m3g";
    url = "https://store.serif.com/en-gb/update/windows/photo/2/";
  };
  designer = requireFile {
    name = "affinity-designer-msi-${version}.exe";
    sha256 = "16ax8cg08xffyh2z8jjqb9zk8yrhlxy9mv3mgxzds635hh9d6r4v";
    url = "https://store.serif.com/en-gb/update/windows/designer/2/";
  };
  publisher = requireFile {
    name = "affinity-publisher-msi-${version}.exe";
    sha256 = "0pbjmhj53d852k2i9414z86xcsz54hkwwswij3pdmx05590a9n4y";
    url = "https://store.serif.com/en-gb/update/windows/publisher/2/";
  };

  _version = version;
}
