{
  self,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    const
    enabled
    genAttrs
    merge
    ;
  inherit (lib.strings) toJSON;

  domain = "libg.so";
  fqdn = "chat.${domain}";
  port = 8004;

  wellKnownResponse =
    data: # nginx
    ''
      ${config.services.nginx.headersNoAccessControlOrigin}
      add_header Access-Control-Allow-Origin * always;

      default_type application/json;
      return 200 '${toJSON data}';
    '';

  configWellKnownResponse.locations = {
    "= /.well-known/matrix/client".extraConfig = wellKnownResponse {
      "m.homeserver".base_url = "https://${fqdn}";
    };

    "= /.well-known/matrix/server".extraConfig = wellKnownResponse {
      "m.server" = "${fqdn}:443";
    };
  };
in
{
  imports = [
    (self + /modules/nginx.nix)
  ];

  secrets.tuwunelToken = {
    file = ./tuwunel-token.age;
    owner = "tuwunel";
  };

  services.restic.backups =
    genAttrs config.services.restic.hosts
    <| const {
      paths = [ "/var/lib/tuwunel" ];
    };

  services.matrix-tuwunel = enabled {
    settings = {
      global = {
        server_name = domain;

        port = [ port ];

        allow_registration = true;

        registration_token_file = config.secrets.tuwunelToken.path;
      };
    };
  };

  services.nginx.virtualHosts.${domain} = configWellKnownResponse;

  services.nginx.virtualHosts.${fqdn} =
    merge config.services.nginx.sslTemplate configWellKnownResponse
      {
        extraConfig = # nginx
          ''
            client_max_body_size ${toString config.services.matrix-tuwunel.settings.global.max_request_size};
          '';

        locations."/".return = "301 https://${domain}/404";

        locations."/_matrix" = {
          proxyPass = "http://[::1]:${toString port}";
          extraConfig = config.services.nginx.headers;
        };
      };
}
