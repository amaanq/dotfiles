{
  config,
  self,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    const
    enabled
    genAttrs
    merge
    mkConst
    ;

  fqdn = "data.libg.so";
  port = 8007;
in
{
  imports = [
    (self + /modules/nginx.nix)
    (self + /modules/postgresql.nix)
  ];

  config.secrets.plausibleKey = {
    file = ./key.age;
    owner = "plausible";
  };

  config.services.postgresql.ensure = [ "plausible" ];

  config.services.plausible = enabled {
    server = {
      disableRegistration = "invite_only";

      secretKeybaseFile = config.secrets.plausibleKey.path;

      baseUrl = "https://${fqdn}";

      listenAddress = "::1";
      inherit port;
    };

    mail = {
      email = "noreply@libg.so";
      smtp = {
        hostAddr = "mail.amaanq.com";
        hostPort = 25;
      };
    };
  };

  options.services.plausible.extraNginxConfigFor = mkConst (
    domain: # nginx
    ''
      proxy_set_header Accept-Encoding ""; # Substitution won't work if it is compressed.
      sub_filter "</head>" '<script defer data-domain="${domain}" src="https://${fqdn}/js/script.js"></script></head>';
      sub_filter_last_modified on;
      sub_filter_once on;
    ''
  );

  config.services.restic.backups =
    genAttrs config.services.restic.hosts
    <| const {
      paths = [ "/var/lib/clickhouse" ];
      exclude = [ "/var/lib/clickhouse/tmp" ];
    };

  config.systemd.services.clickhouse-log-cleanup = {
    description = "Truncate ClickHouse system logs";
    serviceConfig.Type = "oneshot";
    script = ''
      for table in trace_log metric_log query_log asynchronous_metric_log part_log text_log processors_profile_log latency_log; do
        ${pkgs.clickhouse}/bin/clickhouse-client --query "TRUNCATE TABLE IF EXISTS system.$table" 2>/dev/null || true
        for i in $(seq 0 9); do
          ${pkgs.clickhouse}/bin/clickhouse-client --query "TRUNCATE TABLE IF EXISTS system.''${table}_$i" 2>/dev/null || true
        done
      done
    '';
  };
  config.systemd.timers.clickhouse-log-cleanup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };

  config.services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    extraConfig = config.services.plausible.extraNginxConfigFor fqdn;

    locations."/" = {
      proxyPass = "http://[::1]:${toString port}";
      proxyWebsockets = true;
    };
  };
}
