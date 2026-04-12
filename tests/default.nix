{
  perSystem =
    {
      pkgs,
      self',
      ...
    }:
    let
      stripTyping =
        value:
        let
          split = builtins.split "(from typing import TYPE_CHECKING|# typing-end)" value;
        in
        (builtins.elemAt split 0) + (builtins.elemAt split 4);
    in
    {
      checks.test-affinity-v3 = pkgs.testers.nixosTest {
        name = "test-affinity-v3";

        enableOCR = true;

        nodes.machine = {
          environment.systemPackages = [ self'.packages.v3 ];

          virtualisation.memorySize = 4096;

          imports = [ "${pkgs.path}/nixos/tests/common/x11.nix" ];
        };

        testScript = stripTyping (builtins.readFile ./v3.py);
      };
    };
}
