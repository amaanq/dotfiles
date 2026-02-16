{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) merge;
  inherit (lib.strings) toJSON;

  fqdn = "cinny.xeondev.com";
  root = (pkgs.cinny-unwrapped.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./fix-zwj-sequence-rendering.patch ];
  }));

  cinnyConfig = {
    allowCustomHomeservers = false;
    homeserverList = [
      "xeondev.com"
      "libg.so"
    ];
    defaultHomeserver = 0;

    hashRouter = {
      enabled = false;
      basename = "/";
    };

    featuredCommunities = {
      openAsDefault = false;

      servers = [
        "xeondev.com"
        "matrix.org"
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
