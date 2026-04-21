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

  # BIOS VMware → grub is mandatory → grub's install-grub.sh is perl.
  # Nothing we can do about it short of reimplementing the installer.
  system.forbiddenDependenciesRegexes = lib.mkForce [ ];
}
