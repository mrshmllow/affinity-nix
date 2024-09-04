{requireFile}: let
  version = "2.5.5";
in {
  photo = requireFile {
    name = "affinity-photo-msi-${version}.exe";
    sha256 = "1x41zgsmg6blkklpsj8qlk41lbzrv101w5187jc183rnabccjq0j";
    url = "https://store.serif.com/en-gb/update/windows/photo/2/";
  };
  designer = requireFile {
    name = "affinity-designer-msi-${version}.exe";
    sha256 = "0r24r0ljkmyjmys34a3k0dk7ylcrg8kv8ivxwj4allfq5arjb03m";
    url = "https://store.serif.com/en-gb/update/windows/designer/2/";
  };
  publisher = requireFile {
    name = "affinity-publisher-msi-${version}.exe";
    sha256 = "1c49svih8azk5cfxk8x42w6y1xr0bvf8vir8nn1ksf04xvip7kqc";
    url = "https://store.serif.com/en-gb/update/windows/designer/2/";
  };

  _version = version;
}
