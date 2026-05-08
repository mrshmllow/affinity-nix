build-flatpak:
    rm -f ./zone.althaea.Affinity.yml

    cp $(nix build .#flatpak-manifest --no-link --print-out-paths) ./zone.althaea.Affinity.yml

    flatpak-builder --force-clean \
        --user \
        --ccache \
        --install-deps-from=flathub \
        --repo=repo \
        --install \
        builddir ./zone.althaea.Affinity.yml
