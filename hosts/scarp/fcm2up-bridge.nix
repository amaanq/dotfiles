{
  self,
  config,
  lib,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib) enabled merge stringToPort;

  fqdn = "fcm.${domain}";
  port = stringToPort "fcm";
in
{
  imports = [ (self + /modules/nginx.nix) ];

  services.fcm2up-bridge = enabled {
    inherit port;
  };

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    locations."/".proxyPass = "http://[::1]:${toString port}";
  };
}
