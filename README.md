# affinity-nix

An attempt at packaging affinity applications with nix.

Based on https://github.com/lf-/affinity-crimes and https://codeberg.org/wanesty/affinity-wine-docs

## Usage Instructions

**Cached with garnix. Read https://garnix.io/docs/caching for instructions to add it as a subsitutor.**

Perform the first time setup which will manipluate `~/.local/share/affinity/`.

```bash
nix run github:mrshmllow/affinity-nix#setup
```

Copy `C:\Windows\System32\WinMetadata` from a windows computer to `~/.local/share/affinity/drive_c/windows/system32/`.

```bash
cp -r ~/Documents/WinMetadata ~/.local/share/affinity/drive_c/windows/system32/
```

Download the .exe installer for Affinity [Photo](https://store.serif.com/en-gb/update/windows/photo/2/), [Designer](https://store.serif.com/en-gb/update/windows/designer/2/), or [Publisher](https://store.serif.com/en-gb/update/windows/publisher/2/).

Install the application.

```bash
nix run github:mrshmllow/affinity-nix#wine ~/Downloads/affinity-photo-msi-2.3.1.exe
```

Run the application. For example:

```bash
nix run github:mrshmllow/affinity-nix#wine ~/.local/share/affinity/drive_c/Program\ Files/Affinity/Photo\ 2/Photo.exe
```
