{
  pkgs,
}:
rec {
  # vkd3d was added in revision 10
  one-vkd3d =
    (pkgs.writeText "vkd3d-regedit-changes.reg" ''
      Windows Registry Editor Version 5.00

      [HKEY_CURRENT_USER\Software\Wine\DllOverrides]
      "d3d12"="native"
      "d3d12core"="native"
    '').outPath;

  combined = pkgs.linkFarm "registry-patches-combined" [
    {
      name = "one.reg";
      path = one-vkd3d;
    }
  ];
}
