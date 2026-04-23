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

      defaults = {
        virtualisation.memorySize = 4096;

        imports = [ "${pkgs.path}/nixos/tests/common/x11.nix" ];
      };
    in
    {
      checks = {
        test-affinity-v3 = pkgs.testers.runNixOSTest {
          name = "test-affinity-v3";
          enableOCR = true;
          inherit defaults;

          nodes.machine.environment.systemPackages = [ self'.packages.affinity-v3 ];

          testScript = stripTyping (builtins.readFile ./v3.py);
        };

        test-affinity-v2 = pkgs.testers.runNixOSTest {
          name = "test-affinity-v2";
          enableOCR = true;
          inherit defaults;

          nodes = {
            photo.environment.systemPackages = [ self'.packages.affinity-photo ];
            publisher.environment.systemPackages = [ self'.packages.affinity-publisher ];
            designer.environment.systemPackages = [ self'.packages.affinity-designer ];
          };

          testScript = ''
            start_all()
            ${stripTyping (builtins.readFile ./v2.py)}
          '';
        };
      };
    };
}
