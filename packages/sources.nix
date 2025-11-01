let
  version = "2.6.4";
in
{
  photo = {
    name = "affinity-photo-msi-${version}.exe";
    sha256 = "6fd4a0330437194492ac428df1853821a90a56a94a319c56c8096abd1ff7c871";
    url = "https://store.serif.com/en-gb/update/windows/photo/2/";
  };
  designer = {
    name = "affinity-designer-msi-${version}.exe";
    sha256 = "9b64d312846518dd7e7f75ec9a7ca7307b347f5a584af405f4ce75041e435d99";
    url = "https://store.serif.com/en-gb/update/windows/designer/2/";
  };
  publisher = {
    name = "affinity-publisher-msi-${version}.exe";
    sha256 = "9ed8a4402a05f4daee90916bce2724e56bd60dfa249014c51405b55124ac725d";
    url = "https://store.serif.com/en-gb/update/windows/publisher/2/";
  };
  v3 = {
    name = "Affinity x64.exe";
    sha256 = "26194fb7ab0c83754549c99951b2dbbdc0361278172d02bb55eaf6b42a100409";
    # Oct 30th 2025
    url = "https://web.archive.org/web/20251030194823/https://downloads.affinity.studio/Affinity%20x64.exe";
  };

  _version = version;
}
