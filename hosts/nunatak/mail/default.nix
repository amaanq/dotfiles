{
  self,
  config,
  lib,
  ...
}:

let
  inherit (config.networking) domain;
  inherit (lib) enabled;

  domains = [
    "amaanq.com"
    "ameerq.com"
    "libg.so"
    "hkpoolservices.com"
  ];

  mkDkimSignature = domain: {
    name = "rsa-${domain}";
    value = {
      inherit domain;
      private-key = "%{file:/run/credentials/stalwart-mail.service/dkim_key}%";
      selector = "stalwart";
      algorithm = "rsa-sha256";
      canonicalization = "relaxed/relaxed";
    };
  };

  mkDkimSignRule = domain: {
    "if" = "sender_domain == '${domain}'";
    "then" = "['rsa-${domain}']";
  };
in
{
  imports = [ (self + /modules/acme) ];

  secrets.stalwartPassword.file = ./password.plain.age;
  secrets.stalwartAmeerqPassword.file = ./ameerq-password.plain.age;
  secrets.stalwartHkPassword.file = ./hk-password.plain.age;
  secrets.stalwartDkimKey.file = ./dkim-stalwart.key.age;

  users.users.stalwart-mail.extraGroups = [ "acme" ];

  security.acme.certs.${domain}.reloadServices = [ "stalwart-mail.service" ];

  services.nginx.virtualHosts =
    lib.genAttrs
      [
        "mail.${domain}"
        domain
        "ameerq.com"
        "libg.so"
        "hkpoolservices.com"
      ]
      (
        _:
        config.services.nginx.sslTemplate
        // {
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
        }
      );

  services.stalwart-mail = enabled {
    dataDir = "/var/lib/stalwart-mail";

    openFirewall = true;

    credentials = {
      password = config.secrets.stalwartPassword.path;
      ameerq_password = config.secrets.stalwartAmeerqPassword.path;
      hk_password = config.secrets.stalwartHkPassword.path;
      dkim_key = config.secrets.stalwartDkimKey.path;
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
            bind = [ "[::1]:8080" ];
            protocol = "http";
          };

          "admin" = {
            bind = [ "[::1]:9080" ];
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
            name = "info";
            secret = "%{file:/run/credentials/stalwart-mail.service/ameerq_password}%";
            email = [
              "info@ameerq.com"
              "@ameerq.com"
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
            name = "reese";
            secret = "%{file:/run/credentials/stalwart-mail.service/hk_password}%";
            email = [
              "reese@hkpoolservices.com"
              "@hkpoolservices.com"
            ];
          }
        ];
      };

      signature = lib.listToAttrs (map mkDkimSignature domains);

      auth.dkim.sign = (map mkDkimSignRule domains) ++ [
        {
          "else" = false;
        }
      ];

      server.virtual = map (domain: { inherit domain; }) domains;
    };
  };
}
