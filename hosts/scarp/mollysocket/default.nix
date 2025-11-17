{
  self,
  config,
  lib,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib)
    enabled
    merge
    stringToPort
    ;

  fqdn = "molly.${domain}";
  port = stringToPort "molly";
in
{
  imports = [
    (self + /modules/nginx.nix)
  ];

  services.mollysocket = enabled {
    settings = {
      host = "::1";
      inherit port;
    };
  };

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    locations."/" = {
      proxyPass = "http://[::1]:${toString port}";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
      '';
    };
  };
}
