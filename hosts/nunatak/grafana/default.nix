{
  self,
  config,
  lib,
  ...
}:
let
  inherit (self.nunatak.services.stalwart-mail.settings.server) hostname;
  inherit (lib)
    const
    enabled
    genAttrs
    merge
    stringToPort
    ;

  domain = "libg.so";
  fqdn = "metrics.${domain}";
  port = stringToPort "grafana";
in
{
  imports = [
    (self + /modules/nginx.nix)
    (self + /modules/postgresql.nix)
  ];

  secrets.grafanaPassword = {
    file = ./password.age;
    owner = "grafana";
  };
  secrets.grafanaPasswordMail = {
    file = self + /modules/mail/password.plain.age;
    owner = "grafana";
  };

  services.postgresql.ensure = [ "grafana" ];

  services.restic.backups =
    genAttrs config.services.restic.hosts
    <| const {
      paths = [ "/var/lib/grafana" ];
    };

  systemd.services.grafana = {
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
  };

  services.grafana = enabled {
    provision = enabled;

    settings = {
      analytics.reporting_enabled = false;

      database.host = "/run/postgresql";
      database.type = "postgres";
      database.user = "grafana";

      server.domain = fqdn;
      server.http_addr = "::1";
      server.http_port = port;

      users.default_theme = "system";
    };

    settings.security = {
      admin_email = "metrics@${domain}";
      admin_password = "$__file{${config.secrets.grafanaPassword.path}}";
      admin_user = "admin";

      cookie_secure = true;
      disable_gravatar = true;

      disable_initial_admin_creation = false;
    };

    settings.smtp = {
      enabled = true;

      password = "$__file{${config.secrets.grafanaPasswordMail.path}}";
      startTLS_policy = "MandatoryStartTLS";

      ehlo_identity = "metrics@${domain}";
      from_address = "metrics@${domain}";
      from_name = "Metrics";
      host = "${hostname}:587";
    };
  };

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    locations."/" = {
      extraConfig = # nginx
        ''
          # Grafana sets `nosniff` while not setting the content type properly,
          # so everything breaks with it. Unset the header.
          proxy_hide_header X-Content-Type-Options;

          ${config.services.plausible.extraNginxConfigFor fqdn}
        '';

      proxyPass = "http://[::1]:${toString port}";
      proxyWebsockets = true;
    };
  };
}
