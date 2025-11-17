{
  self,
  config,
  lib,
  ...
}:

let
  inherit (config.networking) domain;
  inherit (lib) enabled;
in
{
  imports = [ (self + /modules/acme) ];

  secrets.stalwartPassword.file = ../../modules/mail/password.plain.age;
  secrets.stalwartHkPassword.file = ./mail/hk-password.plain.age;

  users.users.stalwart-mail.extraGroups = [ "acme" ];

  security.acme.certs.${domain}.reloadServices = [ "stalwart-mail.service" ];

  services.nginx.virtualHosts = lib.genAttrs [
    "mail.${domain}"
    domain
    "ameerq.com"
    "libg.so"
    "hkpoolservices.com"
  ] (_: config.services.nginx.sslTemplate // {
    locations."/.well-known/jmap" = {
      proxyPass = "http://[::1]:8080/.well-known/jmap";
      extraConfig = ''
        proxy_set_header Host mail.${domain};
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
      '';
    };

    locations."/jmap" = {
      proxyPass = "http://[::1]:8080/jmap";
      extraConfig = ''
        proxy_set_header Host mail.${domain};
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        client_max_body_size 50M;
      '';
    };
  });

  services.stalwart-mail = enabled {
    dataDir = "/var/lib/stalwart-mail";

    openFirewall = true;

    credentials = {
      password = config.secrets.stalwartPassword.path;
      hk_password = config.secrets.stalwartHkPassword.path;
    };

    settings = {
      server = {
        hostname = "mail.${domain}";

        listener = {
          "smtp" = {
            bind = [ "[::]:25" ];
            protocol = "smtp";
          };

          "submission" = {
            bind = [ "[::]:587" ];
            protocol = "smtp";
            auth.require = true;
          };

          "submissions" = {
            bind = [ "[::]:465" ];
            protocol = "smtp";
            auth.require = true;
            tls.implicit = true;
          };

          "imap" = {
            bind = [ "[::]:143" ];
            protocol = "imap";
          };

          "imaps" = {
            bind = [ "[::]:993" ];
            protocol = "imap";
            tls.implicit = true;
          };

          "jmap" = {
            bind = [ "127.0.0.1:8080" "[::1]:8080" ];
            protocol = "http";
          };

          "admin" = {
            bind = [ "127.0.0.1:9080" ];
            protocol = "http";
          };
        };
      };

      certificate."default" = {
        cert = "%{file:/var/lib/acme/${domain}/fullchain.pem}%";
        private-key = "%{file:/var/lib/acme/${domain}/key.pem}%";
      };

      server.tls = {
        enable = true;
        implicit = false;
        certificate = "default";
      };

      session.auth = {
        mechanisms = "[plain, login]";
        directory = "'internal'";
      };

      directory."internal" = {
        type = "memory";

        principals = [
          {
            class = "admin";
            name = "admin";
            secret = "%{file:/run/credentials/stalwart-mail.service/password}%";
            email = [ "admin@${domain}" ];
          }

          {
            class = "individual";
            name = "contact";
            secret = "%{file:/run/credentials/stalwart-mail.service/password}%";
            email = [
              "contact@amaanq.com"
              "@amaanq.com"
            ];
          }

          {
            class = "individual";
            name = "contact-libg";
            secret = "%{file:/run/credentials/stalwart-mail.service/password}%";
            email = [
              "contact@libg.so"
              "@libg.so"
              "noreply@libg.so"
              "admin@libg.so"
              "support@libg.so"
              "info@libg.so"
            ];
          }

          {
            class = "individual";
            name = "gulag";
            secret = "%{file:/run/credentials/stalwart-mail.service/password}%";
            email = [ "gulag@libg.so" ];
          }

          {
            class = "individual";
            name = "reese";
            secret = "%{file:/run/credentials/stalwart-mail.service/hk_password}%";
            email = [
              "reese@hkpoolservices.com"
              "@hkpoolservices.com"
            ];
          }
        ];
      };

      signature."dkim" = {
        enable = true;
        selector = "stalwart";
        domains = [
          "amaanq.com"
          "libg.so"
          "hkpoolservices.com"
        ];
      };

      server.virtual = [
        { domain = "amaanq.com"; }
        { domain = "libg.so"; }
        { domain = "hkpoolservices.com"; }
      ];
    };
  };
}
