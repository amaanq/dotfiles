{ config, lib, ... }:
let
  inherit (lib) enabled;
in
{
  services.hickory-dns = enabled { settings = config.dns.hickorySettings; };

  networking.nameservers = [ config.dns.listenAddress ];

  networking.search = [ config.dns.tailnetDomain ];

  # Order hickory-dns before nss-lookup.target so resolver-dependent units wait.
  systemd.services.hickory-dns = {
    before = [ "nss-lookup.target" ];
    restartTriggers = [ config.services.hickory-dns.configFile ];
    wants = [ "nss-lookup.target" ];
  };

  # Prevent DHCP from overriding DNS settings, because Verizon's DNS
  # is garbage and hangs my matrix homeserver.
  networking.dhcpcd = {
    persistent = true;
    extraConfig = "nohook resolv.conf";
  };
  # systemd-networkd
  systemd.network.networks."99-ethernet-default-dhcp".dhcpV4Config.UseDNS = false;
  systemd.network.networks."99-ethernet-default-dhcp".dhcpV6Config.UseDNS = false;
  systemd.network.networks."99-ethernet-default-dhcp".ipv6AcceptRAConfig.UseDNS = false;
  systemd.network.networks."99-wireless-client-dhcp".dhcpV4Config.UseDNS = false;
  systemd.network.networks."99-wireless-client-dhcp".dhcpV6Config.UseDNS = false;
  systemd.network.networks."99-wireless-client-dhcp".ipv6AcceptRAConfig.UseDNS = false;
}
