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

  fqdn = "ntfy.${domain}";
  port = stringToPort "ntfy";
in
{
  imports = [
    (self + /modules/nginx.nix)
  ];

  services.ntfy-sh = enabled {
    settings = {
      base-url = "https://${fqdn}";
      listen-http = "[::1]:${toString port}";

      auth-default-access = "deny-all";
      auth-file = "/var/lib/ntfy-sh/auth.db";
      enable-login = true;

      auth-users = [
        "amaanq:\$2a\$10\$aRFXfLWphg1JTf0wFYto5erczu7d3FyuuSt9Wam/Vm4VXw0m6.aZm:user"
        "rgbcube:\$2a\$10\$wUFBVas5nm3dp64a26j1muCtXNGjLY.kWLCIlWG/UoHtmTmHOgYo2:user"
      ];

      auth-access = [
        "amaanq:*:read-write"
        "rgbcube:*:read-write"
      ];

      cache-file = "/var/lib/ntfy-sh/cache.db";
      cache-duration = "12h";

      attachment-cache-dir = "/var/lib/ntfy-sh/attachments";
      attachment-total-size-limit = "5G";
      attachment-file-size-limit = "15M";

      behind-proxy = true;

      visitor-request-limit-burst = 60;
      visitor-request-limit-replenish = "10s";
    };
  };

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    locations."/" = {
      proxyPass = "http://[::1]:${toString port}";
      proxyWebsockets = true;
    };
  };
}
