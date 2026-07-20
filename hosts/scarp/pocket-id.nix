{
  self,
  config,
  lib,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib) enabled merge stringToPort;

  fqdn = "auth.${domain}";
  port = stringToPort "pocket-id";
in
{
  imports = [ (self + /modules/nginx.nix) ];

  secrets.pocketIdEncryptionKey.rekeyFile = ./pocket-id-encryption-key.age;

  services.pocket-id = enabled {
    credentials.ENCRYPTION_KEY = config.secrets.pocketIdEncryptionKey.path;

    settings = {
      APP_URL = "https://${fqdn}";
      TRUST_PROXY = true;
      HOST = "127.0.0.1";
      PORT = port;

      ALLOW_INSECURE_CALLBACK_URLS = false;
      ANALYTICS_DISABLED = true;
      VERSION_CHECK_DISABLED = true;
    };
  };

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_cookie_path off;
        proxy_busy_buffers_size 512k;
        proxy_buffers 4 512k;
        proxy_buffer_size 256k;
      '';
    };
  };
}
