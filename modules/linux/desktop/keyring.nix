{ pkgs, ... }:
{
  environment.systemPackages = with pkgs.kdePackages; [
    kwallet
    kwalletmanager
  ];

  security.pam.services.login.enableKwallet = true;
}
