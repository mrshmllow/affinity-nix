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
    forAllSystems = function:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
      ] (system: function nixpkgs.legacyPackages.${system});
  in {
    packages = forAllSystems (pkgs: let
      symlink = pkgs.callPackage ./symlink.nix {};
      wineUnstable =
        (pkgs.wineWow64Packages.full.override (old: {
          wineRelease = "unstable";
        }))
        .overrideAttrs {
          src = elemental-wine-source;
          version = "8.14";
        };
      wineUnwrapped = symlink {
        wine = wineUnstable;
      };
      winetricksUnwrapped = pkgs.winetricks.overrideAttrs {
        src = winetricks-source;
      };
      photoSrc = pkgs.fetchurl {
        url = "https://archive.org/download/affinity-photo-msi-2.5.2/affinity-photo-msi-2.5.2.exe";
        sha256 = "0g58px4cx4wam6srvx6ymafj1ngv7igg7cgxzsqhf1gbxl7r1ixj";
        version = "2.5.2";
        name = "affinity-photo-msi-2.5.2.exe";
      };
      designerSrc = pkgs.fetchurl {
        url = "https://archive.org/download/affinity-designer-msi-2.5.2/affinity-designer-msi-2.5.2.exe";
        sha256 = "1955vwl06l6dbzx0dfm5vg2jvqbff7994yp8s9sqjf61a609lqhg";
        version = "2.5.2";
        name = "affinity-designer-msi-2.5.2.exe";
      };
      publisherSrc = pkgs.fetchurl {
        url = "https://archive.org/download/affinity-publisher-msi-2.5.2/affinity-publisher-msi-2.5.2.exe";
        sha256 = "1k30vb1fh106fjvivrq8j2sd3nnq16fspp1g1bid3lf2i5jpw9h6";
        version = "2.5.2";
        name = "affinity-publisher-msi-2.5.2.exe";
      };

      wrapWithPrefix = pkg: name:
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

      winetricks = wrapWithPrefix winetricksUnwrapped "winetricks";
      wine = wrapWithPrefix wineUnwrapped "wine";
      wineboot = wrapWithPrefix wineUnwrapped "wineboot";

      check = pkgs.writeScriptBin "check" ''
        WINEDLLOVERRIDES="mscoree=" ${pkgs.lib.getExe wineboot} --init
        ${pkgs.lib.getExe wine} msiexec /i "${wineUnwrapped}/share/wine/mono/wine-mono-8.1.0-x86.msi"
        ${pkgs.lib.getExe winetricks} -q dotnet48 corefonts vcrun2015
        ${pkgs.lib.getExe wine} winecfg -v win11

        if [ ! -d "~/.local/share/affinity/drive_c/windows/system32/WinMetadata/" ]; then
          echo "------------------------------------------------------"
          echo
          echo "Please copy the WinMetadata folder from a windows installation!"
          echo "Example: cp -r ~/Documents/WinMetadata ~/.local/share/affinity/drive_c/windows/system32/WinMetadata/"
          echo
          echo "Then, restart this application."
          echo
          echo "------------------------------------------------------"
          exit 1
        fi
      '';

      createInstaller = src: name:
        pkgs.writeScriptBin "install-${name}" ''
          ${pkgs.lib.getExe check} || exit 1

          if [ ! -f "~/.local/share/affinity/drive_c/Program Files/Affinity/${name} 2/${name}.exe" ]; then
              ${pkgs.lib.getExe wine} ${src}
          fi
        '';

      createRunner = installer: name:
        pkgs.writeScriptBin "run-${name}" ''
          ${pkgs.lib.getExe installer} || exit 1

          ${pkgs.lib.getExe wine} "~/.local/share/affinity/drive_c/Program Files/Affinity/${name} 2/${name}.exe"
        '';
    in {
      wine = wine;
      _wine_unwrapped = wineUnstable;
      winetricks = winetricks;
      wineboot = wineboot;

      installPhoto = createInstaller photoSrc "Photo";
      photo = createRunner self.packages.${pkgs.system}.installPhoto "Photo";
      installDesigner = createInstaller designerSrc "Designer";
      designer = createRunner self.packages.${pkgs.system}.installDesigner "Designer";
      installPublisher = createInstaller publisherSrc "Publisher";
      publisher = createRunner self.packages.${pkgs.system}.installPublisher "Publisher";
    });
  };
}
