{
  self,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled;

  # Shorter is better for networking interfaces IMO.
  interface = "ts0";
in
{
  secrets.tailscaleAuthKey.rekeyFile = ./authkey.age;

  services.tailscale = enabled {
    interfaceName = interface;
    useRoutingFeatures = "both";
    authKeyFile = config.secrets.tailscaleAuthKey.path;
    extraUpFlags = [
      "--login-server=https://headscale.${self.scarp.networking.domain}"
      "--accept-dns=false" # hickory-dns handles DNS
      "--operator=amaanq"
    ];
  };

  # tailscaled hardcodes socket mode 0666; gate CLI access via the runtime dir.
  systemd.services.tailscaled.serviceConfig.RuntimeDirectoryMode = lib.mkForce "0750";
  systemd.services.tailscaled.postStart = ''
    ${pkgs.coreutils}/bin/chgrp wheel /run/tailscale
  '';

  networking.firewall.trustedInterfaces = [ interface ];
}
