{
  self,
  config,
  lib,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib) enabled merge stringToPort;

  fqdn = "xitter.${domain}";
  port = stringToPort "xitter";
in
{
  imports = [ (self + /modules/nginx.nix) ];

  services.xitter-notify-server = enabled {
    listenAddr = "[::1]:${toString port}";
  };

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    locations."/".proxyPass = "http://[::1]:${toString port}";
  };
}
