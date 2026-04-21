{ lib, pkgs, ... }:
{
  environment.systemPackages = [ pkgs.keepassxc ];

  services.gnome.gnome-keyring.enable = lib.mkForce false;
}
