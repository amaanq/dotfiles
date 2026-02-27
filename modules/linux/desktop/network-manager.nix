{ config, lib, ... }:
let
  inherit (lib)
    attrNames
    const
    enabled
    filterAttrs
    getAttr
    mkForce
    ;
in
{
  networking.networkmanager = enabled {
    dns = "none";
    settings.main.rc-manager = "unmanaged";

    connectionConfig = {
      # Use a random MAC address for each connection.
      "ethernet.cloned-mac-address" = mkForce "random";
      "wifi.cloned-mac-address" = mkForce "random";
      # Use temporary addresses.
      "ipv6.ip6-privacy" = mkForce 2;
    };
  };

  users.extraGroups.networkmanager.members =
    config.users.users |> filterAttrs (const <| getAttr "isNormalUser") |> attrNames;

  environment.shellAliases.wifi = "nmcli dev wifi show-password";
}
