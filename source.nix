{ requireFile }:
let
  version = "2.6.3";
in
{
  photo = requireFile {
    name = "affinity-photo-msi-${version}.exe";
    sha256 = "1vqnhhz10hs22drpzbzq2dfz95aq2vf0lvnjxk1z6qyn7yf2g7ij";
    url = "https://store.serif.com/en-gb/update/windows/photo/2/";
  };
  designer = requireFile {
    name = "affinity-designer-msi-${version}.exe";
    sha256 = "0m5a679hw207451kv7rh6xf134pl71zxsr6xfwia28c7gnvx13cp";
    url = "https://store.serif.com/en-gb/update/windows/designer/2/";
  };
  publisher = requireFile {
    name = "affinity-publisher-msi-${version}.exe";
    sha256 = "0frs665y5rqc8lkcr9drn50xh2wssx5nf8v4ajrvpma8mvnhhlbg";
    url = "https://store.serif.com/en-gb/update/windows/publisher/2/";
  };

  _version = version;
}
