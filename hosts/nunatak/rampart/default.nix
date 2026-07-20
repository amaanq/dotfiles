{
  self,
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib) disabled enabled;

  inherit (config.mail.rampart) zone;

  rampartHost = "bunker.${zone}";
in
{
  imports = [
    inputs.rampart.nixosModules.rampart
    (self + /modules/nginx.nix)
  ];

  # TODO: move rampart-notifier-password and verp-key to agenix-rekey.
  services.rampart = enabled {
    publicOrigin = "https://${rampartHost}";
    # Alias domains are managed in the rampart DB (admin UI / API). Bootstrap
    # reads them from postgres at startup and reconciles stalwart, so this
    # list is left empty — the DB is the source of truth.
    aliasDomains = [ ];

    # Bind to loopback; nginx terminates TLS in front.
    listen = "[::1]:8090";

    smtp = {
      host = "localhost";
      port = 465;
      user = "rampart-notifier@${domain}";
      passwordFile = "/var/lib/rampart/rampart-notifier-password";
      # AUTH stays on amaanq (internal credential, never visible);
      # From: header is rampart-side so transactional mail recipients
      # never see amaanq.com.
      notifierFrom = "\"rampart\" <noreply@${zone}>";
    };

    stalwart = {
      jmapBaseUrl = "http://[::1]:8080";
      adminUsername = "admin";
      adminPasswordFile = config.secrets.stalwartAdminPassword.path;
      # HMAC key for bounce VERP signing (Codex P1.1). Currently a host-
      # local file generated once via tmpfiles below; same shape as
      # rampart-notifier-password. TODO: agenix-rekey both in a single sweep.
      verpKeyFile = "/var/lib/rampart/verp-key";
      authservId = config.mail.rampart.mx;
    };

    sieve = {
      outputPath = "/var/lib/stalwart-mail/scripts/rampart_rcpt.sieve";
      stalwartUnit = "stalwart.service";
    };

    backups = enabled {
      destination = "/var/lib/rampart/backups";
      schedule = "daily";
      retainDays = 30;
    };

    # nginx submodule binds nothing here — we use the dotfiles' shared
    # nginx + sslTemplate below for HTTPS termination and HTTP/3.
    nginx = disabled { hostName = rampartHost; };
  };

  # Generate the bounce-VERP HMAC key + notifier password on first activation.
  systemd.tmpfiles.rules = [
    "d /var/lib/rampart 0750 rampart rampart - -"
  ];
  system.activationScripts.rampartSecrets = /* sh */ ''
    set -eu
    umask 077
    mkdir -p /var/lib/rampart
    chmod 0750 /var/lib/rampart
    for f in /var/lib/rampart/verp-key /var/lib/rampart/rampart-notifier-password; do
      if [ ! -s "$f" ]; then
        ${pkgs.openssl}/bin/openssl rand -base64 32 > "$f"
      fi
      chown rampart:rampart "$f"
      chmod 0600 "$f"
    done
    chown rampart:rampart /var/lib/rampart
  '';

  # rampart hosts need a same-origin Referer for form POSTs. The
  # Referrer-Policy override lives at server scope so the location can stay
  # add_header-free, as any add_header in a child drops parent inheritance.
  services.nginx.virtualHosts.${rampartHost} = config.services.nginx.sslTemplate // {
    useACMEHost = zone;
    extraConfig = config.services.nginx.mkHeaders {
      referrerPolicy = "strict-origin-when-cross-origin";
    };
    locations."/" = {
      proxyPass = "http://[::1]:8090";
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        client_max_body_size 5M;
      '';
    };
  };

  # Placeholder landing for the rampart apex.
  services.nginx.virtualHosts.${zone} = config.services.nginx.sslTemplate // {
    useACMEHost = zone;
    extraConfig = config.services.nginx.mkHeaders {
      referrerPolicy = "strict-origin-when-cross-origin";
    };
    locations."/".return = ''200 "${zone} - coming soon\n"'';
    locations."/".extraConfig = ''
      default_type "text/plain; charset=utf-8";
    '';
  };
}
