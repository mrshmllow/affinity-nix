{
  makeDesktopItem,
  lib,
  affinity-v3 ? null,
}:
{
  affinity-v3 = makeDesktopItem rec {
    desktopName = "Affinity";
    name = "affinity-v3";
    exec = "${lib.getExe affinity-v3} %U";
    icon = name;
    type = "Application";
    categories = [ "Graphics" ];
    keywords = [
      "Graphics"
      "2DGraphics"
      "RasterGraphics"
      "VectorGraphics"
      "image"
      "editor"
      "vector"
      "drawing"
    ];
    mimeTypes = [
      "application/afphoto"
      "application/afdesign"
    ];
    startupWMClass = "affinity.exe";
  };
}
