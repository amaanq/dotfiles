{
  self,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib) enabled mkConst;
in
{
  imports = [ (self + /modules/acme) ];

  options.services.nginx.sslTemplate = mkConst {
    forceSSL = true;
    quic = true;
    useACMEHost = domain;
  };

  options.services.nginx.headers =
    # nginx
    mkConst ''
      proxy_hide_header Access-Control-Allow-Origin;
      add_header Access-Control-Allow-Origin $allow_origin always;

      proxy_hide_header Access-Control-Allow-Credentials;
      add_header Access-Control-Allow-Credentials true always;

      ${config.services.nginx.headersNoAccessControlOrigin}
    '';

  options.services.nginx.headersNoAccessControlOrigin =
    # nginx
    mkConst ''
      proxy_hide_header Access-Control-Allow-Methods;
      add_header Access-Control-Allow-Methods $allow_methods always;

      proxy_hide_header Strict-Transport-Security;
      add_header Strict-Transport-Security $hsts_header always;

      proxy_hide_header Content-Security-Policy;
      add_header Content-Security-Policy "script-src 'self' 'unsafe-inline' 'unsafe-eval' blob: ${domain} *.${domain} *.libg.so; worker-src 'self' blob:; object-src 'self' ${domain} *.${domain}; base-uri 'self';" always;

      proxy_hide_header Referrer-Policy;
      add_header Referrer-Policy no-referrer always;

      proxy_hide_header X-Frame-Options;
      add_header X-Frame-Options DENY always;
    '';

  config.networking.firewall = {
    allowedTCPPorts = [
      443
      80
    ];
    allowedUDPPorts = [ 443 ];
  };

  config.services.prometheus.exporters.nginx = enabled {
    listenAddress = "[::]";
  };

  config.security.acme.users = [ "nginx" ];

  config.services.nginx = enabled {
    package = pkgs.nginx;

    statusPage = true;

    recommendedBrotliSettings = true;
    recommendedGzipSettings = true;
    experimentalZstdSettings = true;

    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    commonHttpConfig = # nginx
      ''
        map $scheme $hsts_header {
          https "max-age=31536000; includeSubdomains; preload";
        }

        map $http_origin $allow_origin {
          ~^https://(?:.+\.)?${domain}$ $http_origin;
        }

        map $http_origin $allow_methods {
          ~^https://(?:.+\.)?${domain}$ "CONNECT, DELETE, GET, HEAD, OPTIONS, PATCH, POST, PUT, TRACE";
        }

        ${config.services.nginx.headers}

        proxy_cookie_path / "/; secure; HttpOnly; SameSite=strict";

        set_real_ip_from 173.245.48.0/20;
        set_real_ip_from 103.21.244.0/22;
        set_real_ip_from 103.22.200.0/22;
        set_real_ip_from 103.31.4.0/22;
        set_real_ip_from 141.101.64.0/18;
        set_real_ip_from 108.162.192.0/18;
        set_real_ip_from 190.93.240.0/20;
        set_real_ip_from 188.114.96.0/20;
        set_real_ip_from 197.234.240.0/22;
        set_real_ip_from 198.41.128.0/17;
        set_real_ip_from 162.158.0.0/15;
        set_real_ip_from 104.16.0.0/13;
        set_real_ip_from 104.24.0.0/14;
        set_real_ip_from 172.64.0.0/13;
        set_real_ip_from 131.0.72.0/22;
        set_real_ip_from 2400:cb00::/32;
        set_real_ip_from 2606:4700::/32;
        set_real_ip_from 2803:f800::/32;
        set_real_ip_from 2405:b500::/32;
        set_real_ip_from 2405:8100::/32;
        set_real_ip_from 2a06:98c0::/29;
        set_real_ip_from 2c0f:f248::/32;
        real_ip_header CF-Connecting-IP;

        # Static assets
        limit_req_zone $binary_remote_addr zone=forgejo_static:10m rate=200r/s;

        # General requests
        limit_req_zone $binary_remote_addr zone=forgejo_general:100m rate=30r/s;

        # API/Auth
        limit_req_zone $binary_remote_addr zone=forgejo_api:100m rate=10r/s;

        # Connection limits
        limit_conn_zone $binary_remote_addr zone=forgejo_conn:10m;
      '';
  };
}
