{ lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs.kdePackages; [
    kwallet
    kwalletmanager
  ];

  security.pam.services.login.enableKwallet = true;

  services.gnome.gnome-keyring.enable = lib.mkForce false;
}
