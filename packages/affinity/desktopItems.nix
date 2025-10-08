{
  makeDesktopItem,
  lib,
  photo ? null,
  publisher ? null,
  designer ? null,
}:
{
  photo = makeDesktopItem rec {
    desktopName = "Affinity Photo 2";
    name = "affinity-photo";
    exec = "${lib.getExe photo} %U";
    icon = name;
    type = "Application";
    categories = [ "Graphics" ];
    keywords = [
      "Graphics"
      "2DGraphics"
      "RasterGraphics"
      "image"
      "editor"
      "vector"
      "drawing"
    ];
    mimeTypes = [ "application/afphoto" ];
    startupWMClass = "photo.exe";
  };
  designer = makeDesktopItem rec {
    desktopName = "Affinity Designer 2";
    name = "affinity-designer";
    exec = "${lib.getExe designer} %U";
    icon = name;
    type = "Application";
    categories = [ "Graphics" ];
    keywords = [
      "Graphics"
      "2DGraphics"
      "VectorGraphics"
      "image"
      "editor"
      "vector"
      "drawing"
    ];
    mimeTypes = [ "application/afdesign" ];
    startupWMClass = "designer.exe";
  };
  publisher = makeDesktopItem rec {
    desktopName = "Affinity Publisher 2";
    name = "affinity-publisher";
    exec = "${lib.getExe publisher} %U";
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
      "application/afdesign"
      "application/afphoto"
      # Note that there is no mime type for a `.afpub` file
    ];
    startupWMClass = "publisher.exe";
  };
}
