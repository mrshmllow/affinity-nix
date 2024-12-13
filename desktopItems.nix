{
  makeDesktopItem,
  lib,
  fetchurl,
  photo ? null,
  publisher ? null,
  designer ? null,
}: {
  photo = makeDesktopItem {
    desktopName = "Affinity Photo 2";
    name = "affinity-photo";
    exec = "${lib.getExe photo} %U";
    icon = fetchurl {
      url = "https://cdn.serif.com/store/img/logos/affinity-photo-2-020520191502.svg";
      sha256 = "04bnf12znp9dgkwpk46c01381cw298gq14ga7j7dwccyl3m556d7";
    };
    type = "Application";
    categories = ["Graphics"];
    keywords = ["Graphics" "2DGraphics" "RasterGraphics" "image" "editor" "vector" "drawing"];
    mimeTypes = ["application/x-affinity"];
    startupWMClass = "photo.exe";
  };
  designer = makeDesktopItem {
    desktopName = "Affinity Designer 2";
    name = "affinity-designer";
    exec = "${lib.getExe designer} %U";
    icon = fetchurl {
      url = "https://cdn.serif.com/store/img/logos/affinity-designer-2-020520191502.svg";
      sha256 = "025j4aq8py2a5r34hx39nlhdmps06z6506h7wxchyxbbz6xz3d11";
    };
    type = "Application";
    categories = ["Graphics"];
    keywords = ["Graphics" "2DGraphics" "VectorGraphics" "image" "editor" "vector" "drawing"];
    mimeTypes = ["application/x-affinity"];
    startupWMClass = "designer.exe";
  };
  publisher = makeDesktopItem {
    desktopName = "Affinity Publisher 2";
    name = "affinity-publisher";
    exec = "${lib.getExe publisher} %U";
    icon = fetchurl {
      url = "https://cdn.serif.com/store/img/logos/affinity-publisher-2-020520191502.svg";
      sha256 = "16ghh3mc2vjhvphbyy9zgan066ccp3xj1ilb6z5lmvsb94dp37aj";
    };
    type = "Application";
    categories = ["Graphics"];
    keywords = ["Graphics" "2DGraphics" "RasterGraphics" "VectorGraphics" "image" "editor" "vector" "drawing"];
    mimeTypes = ["application/x-affinity"];
    startupWMClass = "publisher.exe";
  };
}
