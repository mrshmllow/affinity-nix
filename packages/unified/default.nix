{
  perSystem =
    {
      pkgs,
      self',
      stdShellArgs,
      wine-stuff,
      directPhoto,
      directDesigner,
      directPublisher,
      mkOverlayfsRunner,
      directV3,
      ...
    }:
    let
      scripts = pkgs.callPackage ./scripts.nix {
        inherit stdShellArgs wine-stuff mkOverlayfsRunner;
        inherit (self'.packages) wine;
        apps = {
          photo = directPhoto;
          designer = directDesigner;
          publisher = directPublisher;
          v3 = directV3;
        };
      };
    in
    {
      packages = {
        default = self'.packages.v3;

        photo = scripts.createUnifiedPackage "Photo";
        designer = scripts.createUnifiedPackage "Designer";
        publisher = scripts.createUnifiedPackage "Publisher";

        v3 = scripts.createUnifiedPackage "v3";
      };
    };
}
