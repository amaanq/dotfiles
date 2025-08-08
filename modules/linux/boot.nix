{
  lib,
  ...
}:
let
  inherit (lib) enabled;
in
{
  boot = {
    loader = {
      systemd-boot = enabled {
        editor = false;
        configurationLimit = 20;
      };
      efi.canTouchEfiVariables = true;
    };
  };
}
