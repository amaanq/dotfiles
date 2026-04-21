{ lib, ... }:
let
  inherit (lib) enabled;
in
{
  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    efi.canTouchEfiVariables = lib.mkForce false;
    # Sigh
    grub = enabled { efiSupport = false; };
  };
}
