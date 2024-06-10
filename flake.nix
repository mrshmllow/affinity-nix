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
    wrap = pkgs.callPackage ./wrap.nix {};
    wineUnstable = pkgs.wineWow64Packages.full.override (old: {
      wineRelease = "unstable";
    });
    wineUnwrapped = wineUnstable.overrideAttrs {
      src = elemental-wine-source;
      version = "8.14";
    };
    wineWrapped = wrap {wine = wineUnwrapped;};
    winetricksCustom = pkgs.winetricks.overrideAttrs {
      src = winetricks-source;
    };

    wine = pkgs.stdenv.mkDerivation {
      name = "wine";
      src = ./.;

      nativeBuildInputs = [pkgs.makeWrapper];

      installPhase = ''
        makeWrapper ${pkgs.lib.getExe' wineWrapped "wine"} $out/bin/wine \
            --set WINEPREFIX "/home/marsh/.local/share/affinity" \
            --set LD_LIBRARY_PATH "${wineWrapped}/lib:$LD_LIBRARY_PATH" \
            --set WINESERVER "${pkgs.lib.getExe' wineWrapped "wineserver"}" \
            --set WINELOADER "${pkgs.lib.getExe' wineWrapped "wine"}" \
            --set WINEDLLPATH "${wineWrapped}/lib/wine"
      '';
    };

    winetricks = pkgs.stdenv.mkDerivation {
      name = "winetricks";
      src = ./.;

      nativeBuildInputs = [pkgs.makeWrapper];

      installPhase = ''
        makeWrapper ${pkgs.lib.getExe winetricksCustom} $out/bin/winetricks \
            --set WINEPREFIX "/home/marsh/.local/share/affinity" \
            --set LD_LIBRARY_PATH "${wineWrapped}/lib:$LD_LIBRARY_PATH" \
            --set WINESERVER "${pkgs.lib.getExe' wineWrapped "wineserver"}" \
            --set WINELOADER "${pkgs.lib.getExe' wineWrapped "wine"}" \
            --set WINEDLLPATH "${wineWrapped}/lib/wine" \
            --set WINE "${pkgs.lib.getExe' wineWrapped "wine"}"
      '';
    };

    setup = pkgs.writeScriptBin "setup" ''
      export WINEPREFIX="$HOME/.local/share/affinity"
      export LD_LIBRARY_PATH="${wineWrapped}/lib:$LD_LIBRARY_PATH"
      export WINEDLLOVERRIDES="winemenubuilder.exe=d"
      export WINESERVER="${pkgs.lib.getExe' wineWrapped "wineserver"}"
      export WINELOADER="${pkgs.lib.getExe' wineWrapped "wine"}"
      export WINEDLLPATH="${wineWrapped}/lib/wine"
      export WINE="${pkgs.lib.getExe' wineWrapped "wine"}"

      WINEDLLOVERRIDES="mscoree=" ${pkgs.lib.getExe' wineWrapped "wineboot"} --init
      ${pkgs.lib.getExe' wineWrapped "wine"} msiexec /i "${wineWrapped}/share/wine/mono/wine-mono-8.1.0-x86.msi"
      ${pkgs.lib.getExe winetricksCustom} -q dotnet48 corefonts vcrun2015
      ${pkgs.lib.getExe' wineWrapped "wine"} winecfg -v win11
    '';
  in {
    packages.x86_64-linux.wine = wine;
    packages.x86_64-linux.winetricks = winetricks;
    packages.x86_64-linux.setup = setup;

    packages.x86_64-linux.default = self.packages.x86_64-linux.wine;
  };
}
