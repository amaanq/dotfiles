{ config, lib, ... }:
let
  inherit (lib) enabled concatStringsSep;
in
{
  services.resolved = enabled {
    dnssec = "true";
    dnsovertls = "true";

    extraConfig = config.dns.servers |> map (server: "DNS=${server}") |> concatStringsSep "\n";

    fallbackDns = config.dns.serversFallback;
  };

  systemd.network.networks."99-ethernet-default-dhcp".dhcpV4Config.UseDNS = false;
  systemd.network.networks."99-ethernet-default-dhcp".dhcpV6Config.UseDNS = false;
  systemd.network.networks."99-ethernet-default-dhcp".ipv6AcceptRAConfig.UseDNS = false;
  systemd.network.networks."99-wireless-client-dhcp".dhcpV4Config.UseDNS = false;
  systemd.network.networks."99-wireless-client-dhcp".dhcpV6Config.UseDNS = false;
  systemd.network.networks."99-wireless-client-dhcp".ipv6AcceptRAConfig.UseDNS = false;
}
