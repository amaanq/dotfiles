{
  self,
  config,
  lib,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib) enabled merge stringToPort;

  fqdn = "teapot.${domain}";
  port = stringToPort "teapot";
in
{
  imports = [
    (self + /modules/nginx.nix)
  ];

  secrets.teapotSessions = {
    file = ./sessions.age;
    mode = "0444";
  };

  services.teapot = enabled {
    preferences = {
      hlsPlayback = true;
      infiniteScroll = true;
    };
    server = {
      inherit port;
      address = "127.0.0.1";
      hostname = fqdn;
      https = true;
      title = "teapot";
    };
    cache.listMinutes = 240;
    sessionsFile = config.secrets.teapotSessions.path;
  };

  # Force IPv4 only since X.com sometimes returns 403 for IPv6 connections
  systemd.services.teapot.serviceConfig.RestrictAddressFamilies = lib.mkForce [
    "AF_INET"
    "AF_UNIX"
  ];

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    locations."/".proxyPass = "http://127.0.0.1:${toString port}";
  };
}
