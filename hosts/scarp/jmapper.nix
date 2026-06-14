{
  inputs,
  config,
  lib,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib)
    enabled
    merge
    mkIf
    stringToPort
    ;

  accountsFile = ./jmapper-accounts.age;
  hasAccounts = builtins.pathExists accountsFile;
  fqdn = "jmap.${domain}";
  port = stringToPort "jmap";
  upstream = "http://127.0.0.1:${toString port}";
in
{
  imports = [
    (inputs.self + /modules/nginx.nix)
  ];

  secrets.jmapperAccounts = mkIf hasAccounts {
    rekeyFile = accountsFile;
    owner = "jmapper";
    group = "jmapper";
    mode = "0400";
  };

  services.jmapper = enabled {
    user = "jmapper";
    group = "jmapper";
    accountsFile = if hasAccounts then config.secrets.jmapperAccounts.path else null;
    settings.server = {
      bind = "127.0.0.1:${toString port}";
      session_url = "https://${fqdn}";
      cors_origins = [ "https://inbox.${domain}" ];
      database_url = "host=/run/postgresql dbname=jmapper";
      dav_sync_interval_seconds = 60;
    };
  };

  systemd.services.bulwark.environment.ALLOW_CUSTOM_JMAP_ENDPOINT = "true";

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    locations."/" = {
      proxyPass = upstream;
      extraConfig = "client_max_body_size 50M;";
    };

    locations."= /metrics" = {
      proxyPass = upstream;
      extraConfig = ''
        allow 127.0.0.1;
        allow ::1;
        deny all;
      '';
    };
  };
}
