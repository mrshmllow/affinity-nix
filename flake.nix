{
  description = "An attempt at packging affinity photo for nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    elemental-wine-source = {
      url = "gitlab:ElementalWarrior/wine?host=gitlab.winehq.org&ref=master";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    elemental-wine-source,
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

    script = pkgs.writeScriptBin "affinity" ''
      export WINEPREFIX="${WINEPREFIX:-$HOME/.local/share/wineAffinity}"
      export PATH="$winepath/bin:$PATH"
      export LD_LIBRARY_PATH="${wineWrapped}/lib$\{LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      export WINEDLLOVERRIDES="winemenubuilder.exe=d"
      export WINESERVER="${wineWrapped}/bin/wineserver"
      export WINELOADER="${wineWrapped}/bin/wine"
      export WINEDLLPATH="${wineWrapped}/lib/wine"

      exec "$@"
    '';

    wine = pkgs.stdenv.mkDerivation {
      name = "wine";

      src = ./.;

      installPhase = ''
        wrapProgram ${pkgs.lib.getExe wineWrapped} \
            --set WINEPREFIX "$HOME/.local/share/affinity" \
            --set WINEDLLOVERRIDES "winemenubuilder.exe=d" \
            --set WINESERVER "${wineWrapped}/bin/wineserver" \
            --set WINELOADER "${wineWrapped}/bin/wine" \
            --set WINEDLLPATH "${wineWrapped}/lib/wine"
      '';
    };
  in {
    packages.x86_64-linux.wine = wineWrapped;
    packages.x86_64-linux.script = script;

    packages.x86_64-linux.default = self.packages.x86_64-linux.wine;
  };
}
