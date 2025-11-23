{
  self,
  config,
  lib,
  pkgs,
  headplane,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib)
    enabled
    merge
    stringToPort
    ;

  fqdn = "headplane.${domain}";
  port = stringToPort "headplane";

  format = pkgs.formats.yaml { };

  settings = lib.recursiveUpdate config.services.headscale.settings {
    tls_cert_path = "/dev/null";
    tls_key_path = "/dev/null";
    policy.path = "/dev/null";
    oidc.client_secret_path = "/dev/null";
  };

  headscaleConfig = format.generate "headscale.yml" settings;
in
{
  imports = [
    (self + /modules/nginx.nix)
    headplane.nixosModules.headplane
  ];

  secrets.headplaneCookieSecret = {
    file = ./cookie_secret.age;
    owner = "headscale";
  };

  secrets.headplaneAuthKey = {
    file = self + /modules/linux/tailscale/authkey.age;
    owner = "headscale";
  };

  services.headplane = enabled {
    settings = {
      server = {
        host = "127.0.0.1";
        inherit port;
        cookie_secret_path = config.secrets.headplaneCookieSecret.path;
      };

      headscale = {
        url = "http://[::1]:${toString config.services.headscale.port}";
        config_path = "${headscaleConfig}";
      };

      integration = {
        agent = {
          enabled = true;
          pre_authkey_path = config.secrets.headplaneAuthKey.path;
        };
      };
    };
  };

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}";
      proxyWebsockets = true;
    };
    locations."= /" = {
      return = "301 https://${fqdn}/admin";
    };
  };
}
