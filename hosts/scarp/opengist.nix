{
  self,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib) merge stringToPort;

  fqdn = "gist.${domain}";
  port = stringToPort "gist";
in
{
  imports = [
    (self + /modules/nginx.nix)
    (self + /modules/postgresql.nix)
  ];

  services.postgresql.ensure = [ "opengist" ];

  systemd.services.opengist = {
    description = "amaanq's gists";
    after = [
      "postgresql.service"
    ];
    requires = [ "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      OG_LOG_LEVEL = "warn";
      OG_DB_URI = "postgres://opengist@127.0.0.1:5432/opengist?sslmode=disable";
      OG_HTTP_PORT = toString port;
      OG_HTTP_GIT_ENABLED = "false";
      OG_EXTERNAL_URL = "https://${fqdn}";
    };

    serviceConfig = {
      Type = "simple";
      User = "opengist";
      Group = "opengist";
      WorkingDirectory = "/var/lib/opengist";
      ExecStart = "${pkgs.opengist}/bin/opengist";
      Restart = "always";
      RestartSec = "10s";
    };

    path = [
      pkgs.git
      pkgs.openssh
    ];
  };

  users.users.opengist = {
    isSystemUser = true;
    group = "opengist";
    home = "/var/lib/opengist";
    createHome = true;
  };

  users.groups.opengist = { };

  systemd.tmpfiles.rules = [
    "d /var/lib/opengist 0755 opengist opengist -"
  ];

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    locations."/".proxyPass = "http://[::1]:${toString port}";
  };
}
