{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) merge;
  inherit (lib.strings) toJSON;

  fqdn = "cinny.amaanq.com";
  root = pkgs.cinny;

  cinnyConfig = {
    allowCustomHomeservers = false;
    homeserverList = [ "amaanq.com" ];
    defaultHomeserver = 0;

    hashRouter = {
      enabled = false;
      basename = "/";
    };

    featuredCommunities = {
      openAsDefault = false;

      servers = [
        "amaanq.com"
        "matrix.org"
      ];

      spaces = [
        "#space:nixos.org"
      ];

      rooms = [
        "#probe-rs:matrix.org"
        "#rust-embedded:matrix.org"
        "#stm32-rs:matrix.org"
      ];
    };
  };
in
{
  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    inherit root;

    locations."= /config.json".extraConfig = # nginx
      ''
        default_type application/json;
        return 200 '${toJSON cinnyConfig}';
      '';

    extraConfig = # nginx
      ''
        rewrite ^/config.json$ /config.json break;
        rewrite ^/manifest.json$ /manifest.json break;

        rewrite ^/sw.js$ /sw.js break;
        rewrite ^/pdf.worker.min.js$ /pdf.worker.min.js break;

        rewrite ^/public/(.*)$ /public/$1 break;
        rewrite ^/assets/(.*)$ /assets/$1 break;

        rewrite ^(.+)$ /index.html break;
      '';
  };
}
