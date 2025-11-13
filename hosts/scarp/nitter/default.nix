{
  self,
  config,
  lib,
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
    owner = "nitter";
  };

  services.nitter = enabled {
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

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    locations."/".proxyPass = "http://127.0.0.1:${toString port}";
  };
}
