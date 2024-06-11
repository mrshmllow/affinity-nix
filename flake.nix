{
  description = "An attempt at packging affinity photo for nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    elemental-wine-source = {
      url = "gitlab:ElementalWarrior/wine?host=gitlab.winehq.org&ref=c12ed1469948f764817fa17efd2299533cf3fe1c";
      flake = false;
    };
    winetricks-source = {
      url = "github:winetricks/winetricks?ref=20240105";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    elemental-wine-source,
    winetricks-source,
  }: let
    pkgs = nixpkgs.legacyPackages."x86_64-linux";
    symlink = pkgs.callPackage ./symlink.nix {};
    wineUnstable = pkgs.wineWow64Packages.full.override (old: {
      wineRelease = "unstable";
    });
    wineUnwrapped = symlink {
      wine = wineUnstable.overrideAttrs {
        src = elemental-wine-source;
        version = "8.14";
      };
    };
    winetricksUnwrapped = pkgs.winetricks.overrideAttrs {
      src = winetricks-source;
    };

    wrap = pkg: name:
      pkgs.stdenv.mkDerivation {
        name = name;
        src = ./.;
        nativeBuildInputs = [pkgs.makeWrapper];
        installPhase = ''
          makeWrapper ${pkgs.lib.getExe' pkg name} $out/bin/${name} \
            --set WINEPREFIX "/home/marsh/.local/share/affinity" \
            --set LD_LIBRARY_PATH "${wineUnwrapped}/lib:$LD_LIBRARY_PATH" \
            --set WINESERVER "${pkgs.lib.getExe' wineUnwrapped "wineserver"}" \
            --set WINELOADER "${pkgs.lib.getExe' wineUnwrapped "wine"}" \
            --set WINEDLLPATH "${wineUnwrapped}/lib/wine" \
            --set WINE "${pkgs.lib.getExe' wineUnwrapped "wine"}"
        '';
        meta.mainProgram = name;
      };

    winetricks = wrap winetricksUnwrapped "winetricks";
    wine = wrap wineUnwrapped "wine";
    wineboot = wrap wineUnwrapped "wineboot";

    src = pkgs.fetchurl {
      url = "https://archive.org/download/affinity-photo-msi-2.5.2/affinity-photo-msi-2.5.2.exe";
      sha256 = "0g58px4cx4wam6srvx6ymafj1ngv7igg7cgxzsqhf1gbxl7r1ixj";
      version = "2.5.2";
      name = "affinity-photo-msi-2.5.2.exe";
    };

    photo = pkgs.writeScriptBin "photo" ''
      WINEDLLOVERRIDES="mscoree=" ${pkgs.lib.getExe wineboot} --init
      ${pkgs.lib.getExe wine} msiexec /i "${wineUnwrapped}/share/wine/mono/wine-mono-8.1.0-x86.msi"
      ${pkgs.lib.getExe winetricks} -q dotnet48 corefonts vcrun2015
      ${pkgs.lib.getExe wine} winecfg -v win11

      if [ ! -f "~/.local/share/affinity/drive_c/Program Files/Affinity/Photo 2/Photo.exe" ]; then
          ${pkgs.lib.getExe wine} ${src}
      fi

      ${pkgs.lib.getExe wine} "~/.local/share/affinity/drive_c/Program Files/Affinity/Photo 2/Photo.exe"
    '';
  in {
    packages.x86_64-linux.wine = wine;
    packages.x86_64-linux.winetricks = winetricks;
    packages.x86_64-linux.wineboot = wineboot;
    packages.x86_64-linux.photo = photo;

    packages.x86_64-linux.default = self.packages.x86_64-linux.wine;
  };
}
