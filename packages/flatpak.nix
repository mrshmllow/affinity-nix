{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      craneLib,
      self',
      ...
    }:
    let
      mkTar =
        name: src:
        pkgs.runCommand "${name}.tar.gz" { } ''
          cp -r ${src} ./src-tmp
          chmod -R +w ./src-tmp

          rm -rf "./src-tmp/dosdevices"

          tar --sort=name \
              --format=posix \
              --pax-option='exthdr.name=%d/PaxHeaders/%f' \
              --pax-option='delete=atime,delete=ctime' \
              --numeric-owner \
              --owner=0 \
              --group=0 \
              --mode='go+u,go-w' \
              --verbose \
              -czhf $out -C ./src-tmp .
        '';

      mkDirHash =
        dir:
        builtins.replaceStrings [ "\n" ] [ "" ] (
          builtins.readFile (
            pkgs.runCommand "hash-directory" { } ''
              cat ${dir}/* | sha256sum | cut -d' ' -f1 > $out
            ''
          )
        );

      fileSetForCrate =
        crate:
        lib.fileset.toSource {
          root = ../.;
          fileset = lib.fileset.unions [
            ../Cargo.toml
            ../Cargo.lock
            (craneLib.fileset.commonCargoSources crate)
          ];
        };

      installers = pkgs.callPackage ./sources.nix { };
    in
    {
      packages.flatpak-manifest = pkgs.writers.writeJSON "zone.althaea.Affinity.yaml" {
        id = "zone.althaea.Affinity";
        runtime = "org.freedesktop.Platform";
        runtime-version = "25.08";
        sdk = "org.freedesktop.Sdk";
        command = "/app/bin/runner";

        sdk-extensions = [
          "org.freedesktop.Sdk.Extension.rust-stable"
          "org.freedesktop.Sdk.Extension.vala"
        ];

        build-options = {
          append-path = "/usr/lib/sdk/rust-stable/bin:/usr/lib/sdk/vala/bin";
          build-args = [ "--share=network" ];
        };

        finish-args = [
          "--share=ipc"
          "--socket=x11"
          "--socket=pulseaudio"
          "--device=dri"
        ];

        cleanup-commands = [
          "find /app/bin -mindepth 1 -maxdepth 1  -name 'msi*' ! -name 'msiextract' -delete"
        ];

        cleanup = [
          "/share/applications/wine.desktop"
          "/bin/rsync-ssl"
        ];

        modules = [
          {
            name = "wine";
            buildsystem = "autotools";
            config-opts = [
              "--enable-win64"
              "CC=gcc -std=gnu17"
            ];
            sources = [
              {
                type = "archive";
                path = mkTar "wine-source" inputs.elemental-wine-source;
              }
            ];
          }
          {
            name = "cabextract";
            buildsystem = "autotools";
            sources = [
              {
                type = "archive";
                url = "https://www.cabextract.org.uk/cabextract-1.11.tar.gz";
                sha256 = "b5546db1155e4c718ff3d4b278573604f30dd64c3c5bfd4657cd089b823a3ac6";
              }
            ];
          }
          {
            name = "winetricks";
            buildsystem = "simple";
            build-commands = [
              "install -D -m755 winetricks /app/bin/winetricks"
            ];
            sources = [
              {
                type = "file";
                url = "https://raw.githubusercontent.com/Winetricks/winetricks/14b802e419aff260b9d630e71027d88855e224e7/src/winetricks";
                sha256 = "9e84b4dee3a7f570fde5f3de4029f616b60ac35636c9b76db9a08240ff12d14a";
              }
            ];
          }
          {
            name = "rsync";
            buildsystem = "autotools";
            config-opts = [
              "--disable-md2man"
            ];
            sources = [
              {
                type = "git";
                url = "https://github.com/RsyncProject/rsync.git";
                # v3.4.1
                commit = "3305a7a063ab0167cab5bf7029da53abaa9fdb6e";
              }
            ];
          }
          {
            name = "7zz";
            buildsystem = "simple";
            build-commands = [
              # https://github.com/NixOS/nixpkgs/blob/10e7ad5bbcb421fe07e3a4ad53a634b0cd57ffac/pkgs/by-name/_7/_7zz/package.nix#L45
              "rm -r CPP/7zip/Compress/Rar*"

              "make -C CPP/7zip/Bundles/Alone2 -j $FLATPAK_BUILDER_N_JOBS -f ../../cmpl_gcc.mak DISABLE_RAR_COMPRESS=true"

              "install -Dm755 CPP/7zip/Bundles/Alone2/b/g/7zz /app/bin/7zz"
            ];
            sources = [
              {
                type = "archive";
                url = "https://7-zip.org/a/7z2501-src.tar.xz";
                sha256 = "ed087f83ee789c1ea5f39c464c55a5c9d4008deb0efe900814f2df262b82c36e";
                strip-components = 0;
              }
            ];
          }
          {
            name = "libgsf";
            buildsystem = "autotools";
            sources = [
              {
                type = "archive";
                url = "https://download.gnome.org/sources/libgsf/1.14/libgsf-1.14.56.tar.xz";
                sha256 = "9d21d30df1d12feaf03e181afd6067f65e3048ab69cb6ad174a3c5b72b92d297";
              }
            ];
          }
          {
            name = "msitools";
            buildsystem = "meson";
            sources = [
              {
                type = "git";
                url = "https://github.com/GNOME/msitools.git";
                # v0.106
                commit = "279a1d54ad58a4f5593462ffd607c663f60a32a1";
              }
            ];
          }
          # {
          #   name = "apl";
          #   buildsystem = "simple";
          #   build-options = {
          #     strip = false;
          #     no-debuginfo = true;
          #   };
          #   build-commands = [
          #     "mkdir -p /app/apl"
          #     "cp -r . /app/apl"
          #   ];
          #   sources = [
          #     {
          #       type = "archive";
          #       path = mkTar "apl-dir" self'.packages.apl-combined;
          #     }
          #   ];
          # }
          {
            name = "lower";
            buildsystem = "simple";
            build-options = {
              strip = false;
              no-debuginfo = true;
            };
            build-commands = [
              "mkdir -p /app/lower"
              "cp -r . /app/lower"
              "install -Dm755 apply_extra \${FLATPAK_DEST}/bin/apply_extra"
            ];
            sources = [
              {
                type = "archive";
                path = mkTar "lower-dir" self'.packages.base-prefix-pre-affinity;
              }
              {
                type = "extra-data";
                url = installers.v3-url;
                sha256 = "c55cde2dddbbdbab5c5cacc33229b693fdfccfb4169613bedc3b7a9d84db9aea";
                size = 643911240;
                filename = "Affinity.exe";
              }
              {
                type = "script";
                dest-filename = "apply_extra";
                commands =
                  let
                    file = lib.last (lib.splitString "/" installers.v3-segment);
                  in
                  [
                    "/app/bin/7zz e Affinity.exe -tpe \"${installers.v3-segment}\""
                    "/app/bin/msiextract -C sources ${file}"
                    # "cp -r /app/apl/. sources/Affinity/Affinity/"
                    "rm Affinity.exe ${file}"
                  ];
              }
            ];
          }
          {
            name = "registry-patches-${builtins.hashFile "sha256" ../packages/registry-patches.nix}";
            buildsystem = "simple";
            build-commands = [
              "mkdir -p /app/registry-patches"
              "cp -r . /app/registry-patches"
            ];
            sources = [
              {
                type = "archive";
                path = mkTar "registry-patches" (pkgs.callPackage ../packages/registry-patches.nix { }).combined;
              }
            ];
          }
          {
            name = "runner-${mkDirHash ../crates/runner/src}";
            buildsystem = "simple";
            build-commands = [
              "cargo build --release --features v3,flatpak"
              "install -Dm755 target/release/runner /app/bin/runner"
            ];
            build-options.env = {
              WINE = "/app/bin/wine64";
              WINESERVER = "/app/bin/wineserver";
              WINETRICKS = "/app/bin/winetricks";

              # not required for flatpak mode
              FUSE_OVERLAYFS = "";

              ZENITY = "/usr/bin/zenity";
              GNUTAR = "/usr/bin/tar";

              RSYNC = "/app/bin/rsync";

              REGISTRY_PATCHES = "/app/registry-patches";
              ON_LINUX = inputs.on-linux.outPath;

              LOWER_DIR = "/app/lower";
            };
            sources = [
              {
                type = "archive";
                path = mkTar "runner-source" (fileSetForCrate ../crates/runner);
              }
            ];
          }
        ];
      };
    };
}
