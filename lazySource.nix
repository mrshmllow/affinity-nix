{fetchurl}: {
  photo = fetchurl {
    url = "https://archive.org/download/affinity-photo-msi-2.5.2/affinity-photo-msi-2.5.2.exe";
    sha256 = "0g58px4cx4wam6srvx6ymafj1ngv7igg7cgxzsqhf1gbxl7r1ixj";
    version = "2.5.2";
    name = "affinity-photo-msi-2.5.2.exe";
  };
  designer = fetchurl {
    url = "https://archive.org/download/affinity-designer-msi-2.5.2/affinity-designer-msi-2.5.2.exe";
    sha256 = "1955vwl06l6dbzx0dfm5vg2jvqbff7994yp8s9sqjf61a609lqhg";
    version = "2.5.2";
    name = "affinity-designer-msi-2.5.2.exe";
  };
  publisher = fetchurl {
    url = "https://archive.org/download/affinity-publisher-msi-2.5.2/affinity-publisher-msi-2.5.2.exe";
    sha256 = "1k30vb1fh106fjvivrq8j2sd3nnq16fspp1g1bid3lf2i5jpw9h6";
    version = "2.5.2";
    name = "affinity-publisher-msi-2.5.2.exe";
  };
}
