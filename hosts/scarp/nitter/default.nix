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
  goAwayPort = stringToPort "go-away";
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
      version = "0-unstable-2026-02-22";
      src = pkgs.fetchFromGitHub {
        owner = "zedeus";
        repo = "nitter";
        rev = "d187b1cc3f61f3046f4c6464a80ad705ea670c29";
        hash = "sha256-W0bx+p7Sr3iuhvg1ZenD0CPI3cHRnE3DpKDjEu2t0aI=";
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
    locations."/".proxyPass = "http://[::1]:${toString goAwayPort}";
  };
}
