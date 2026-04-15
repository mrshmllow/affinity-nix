{
  perSystem = _: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs = {
        nixfmt.enable = true;
        yamlfmt.enable = true;
        shfmt.enable = true;
        rustfmt.enable = true;
        taplo.enable = true;
      };
    };
  };
}
