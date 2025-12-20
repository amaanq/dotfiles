{
  self,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib) enabled merge stringToPort;

  fqdn = "nitter.${domain}";
  port = stringToPort "nitter";
in
{
  imports = [
    (self + /modules/nginx.nix)
  ];

  secrets.nitterSessions = {
    file = ./sessions.age;
    mode = "0444";
  };

  services.nitter = enabled {
    package = pkgs.nitter.overrideAttrs {
      version = "0-unstable-2025-12-05";
      src = pkgs.fetchFromGitHub {
        owner = "zedeus";
        repo = "nitter";
        rev = "17fc2628f91f70b9bfda1915c76e94708a5197bf";
        hash = "sha256-yl1ge/Vm5+gkbEl73B7n3Ooh3Rpn4f1lyq0RU4VQRRI=";
      };
    };
    preferences = {
      hlsPlayback = true;
      infiniteScroll = true;
    };
    server = {
      inherit port;
      address = "127.0.0.1";
      hostname = fqdn;
      https = true;
      title = "Dykwabi";
    };
    cache.listMinutes = 240;
    sessionsFile = config.secrets.nitterSessions.path;
  };

  # Force IPv4 only since X.com sometimes returns 403 for IPv6 connections
  systemd.services.nitter.serviceConfig.RestrictAddressFamilies = lib.mkForce [
    "AF_INET"
    "AF_UNIX"
  ];

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    locations."/".proxyPass = "http://127.0.0.1:${toString port}";
  };
}
