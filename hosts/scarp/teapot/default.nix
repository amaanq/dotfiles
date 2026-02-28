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
    preferences.infiniteScroll = true;
    server = {
      inherit port;
      address = "::1";
      hostname = fqdn;
      https = true;
      title = "teapot";
    };
    config = {
      paidEmoji = "✡️";
      aiEmoji = "🦼";
    };
    cache.listMinutes = 240;
    sessionsFile = config.secrets.teapotSessions.path;
  };

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    locations."/".proxyPass = "http://[::1]:${toString port}";
  };

  services.nginx.virtualHosts."nitter.${domain}" = merge config.services.nginx.sslTemplate {
    locations."/".proxyPass = "http://[::1]:${toString port}";
  };

  services.nginx.virtualHosts."tpot.${domain}" = merge config.services.nginx.sslTemplate {
    locations."/".proxyPass = "http://[::1]:${toString port}";
  };
}
