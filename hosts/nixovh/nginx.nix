{
  self,
  config,
  ...
}:
let
  domain = "git.xeondev.com";
in
{
  imports = [
    (self + /modules/nginx.nix)
  ];

  services.nginx.appendHttpConfig = ''
    map $http_origin $allow_origin {
      ~^https://(?:.+\.)?${domain}$ $http_origin;
    }

    map $http_origin $allow_methods {
      ~^https://(?:.+\.)?${domain}$ "CONNECT, DELETE, GET, HEAD, OPTIONS, PATCH, POST, PUT, TRACE";
    }
  '';

  services.nginx.virtualHosts.${domain} =
    (removeAttrs config.services.nginx.sslTemplate [ "useACMEHost" ])
    // {
      enableACME = true;
      locations."/" = {
        proxyPass = "http://[::1]:3000";
        extraConfig = # nginx
          ''
            client_max_body_size 100M;
          '';
      };
    };
}
