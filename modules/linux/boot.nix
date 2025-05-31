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
      };
      efi.canTouchEfiVariables = true;
    };

  };
}
