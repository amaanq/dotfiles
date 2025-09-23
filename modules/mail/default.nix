{
  self,
  config,
  lib,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib)
    const
    enabled
    genAttrs
    mkDefault
    stringToPort
    ;

  fqdn = "mail.${domain}";
  port = stringToPort "mail";
in
{
  imports = [ (self + /modules/acme) ];

  secrets.mailPassword.file = ./password.hash.age;
  secrets.stalwartAdminPassword = {
    file = ./stalwart-admin-password.age;
    owner = "stalwart-mail";
  };
  secrets.stalwartPostgresPassword = {
    file = ./stalwart-postgres-password.age;
    owner = "stalwart-mail";
  };

  services.restic.backups =
    genAttrs config.services.restic.hosts
    <| const {
      paths = [ "/var/lib/stalwart-mail" ];
    };

  networking.firewall.allowedTCPPorts = [
    25 # SMTP
    465 # SMTPS
    587 # SMTP submission
    993 # IMAPS
  ];

  security.acme.users = [ "stalwart-mail" ];

  services.postgresql.ensure = [ "stalwart-mail" ];

  services.stalwart-mail = enabled {
    openFirewall = true;

    dataDir = "/var/lib/stalwart-mail";

    settings = {
      tracer.stdout = enabled {
        type = "stdout";
        level = "trace";
        ansi = false;
      };

      lookup.default.hostname = domain;

      email.encryption = enabled;

      server = {
        hostname = mkDefault fqdn;

        tls = enabled {
          implicit = true;
        };

        listener = {
          smtp = {
            protocol = "smtp";
            bind = [ "[::]:25" ];
            tls.implicit = false;
          };
          submission = {
            bind = [ "[::]:587" ];
            protocol = "smtp";
          };
          submissions = {
            bind = [ "[::]:465" ];
            protocol = "smtp";
            tls.implicit = true;
          };
          imaptls = {
            bind = [ "[::]:993" ];
            protocol = "imap";
            tls.implicit = true;
          };
          management = {
            bind = [ "[::1]:${toString port}" ];
            protocol = "http";
          };
          jmap = {
            bind = [ "[::1]:${toString (port + 1)}" ];
            protocol = "http";
          };
        };

        lookup.default = {
          inherit domain;

          hostname = mkDefault fqdn;
        };
      };

      storage = {
        blob = "db";
        data = "db";
        fts = "db";
        lookup = "db";
        directory = "internal";
      };

      store.db = {
        type = "postgresql";
        host = "localhost";
        port = 5432;
        database = "stalwart-mail";
        user = "stalwart-mail";
        password = "%{file:${config.secrets.stalwartPostgresPassword.path}}%";
        tls.enable = false;
      };

      authentication.fallback-admin = {
        user = "admin";
        secret = "%{file:${config.secrets.stalwartAdminPassword.path}}%";
      };
    };
  };

  services.nginx.virtualHosts.${fqdn} =
    (removeAttrs config.services.nginx.sslTemplate [ "useACMEHost" ])
    // {
      enableACME = true;
      locations."/" = {
        proxyPass = "http://[::1]:${toString port}";
      };
    };
}
