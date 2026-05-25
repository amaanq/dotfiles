{
  self,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled mkIf;

  # Shorter is better for networking interfaces IMO.
  interface = "ts0";

  port = toString config.services.tailscale.port;
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

  # tailscaled hardcodes socket mode 0666, so gate CLI access via the runtime dir.
  systemd.services.tailscaled.serviceConfig.RuntimeDirectoryMode = lib.mkForce "0750";
  systemd.services.tailscaled.postStart = ''
    ${pkgs.coreutils}/bin/chgrp wheel /run/tailscale
  '';

  networking.firewall = {
    trustedInterfaces = [ interface ];

    # OSUOSL's openpower fabric drops large UDP, but tiny disco probes
    # pass, so tailscale prefers the starved direct path forever.
    # Drop wireguard's UDP so it relays over DERP (plain TCP) instead.
    extraCommands = mkIf pkgs.stdenv.hostPlatform.isPower64 ''
      ip46tables -I INPUT -p udp --dport ${port} -j DROP
      ip46tables -I OUTPUT -p udp --sport ${port} -j DROP
    '';
    extraStopCommands = mkIf pkgs.stdenv.hostPlatform.isPower64 ''
      ip46tables -D INPUT -p udp --dport ${port} -j DROP 2>/dev/null || true
      ip46tables -D OUTPUT -p udp --sport ${port} -j DROP 2>/dev/null || true
    '';
  };
}
