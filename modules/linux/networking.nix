{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Network configuration

  # Enable NetworkManager for easy WiFi/Ethernet management
  networking.networkmanager.enable = true;

  # Add user to networkmanager group (handled in host config)

  # Firewall settings
  networking.firewall = {
    enable = true;
    # allowedTCPPorts = [ ... ];
    # allowedUDPPorts = [ ... ];
  };
}
