{
  self,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib) enabled merge;
  fqdn = "cloud.${domain}";
  packageNextcloud = pkgs.nextcloud33;
in
{
  imports = [
    (self + /modules/nginx.nix)
    (self + /modules/postgresql.nix)
  ];

  secrets.nextcloudPassword = {
    file = ./password.age;
    owner = "nextcloud";
  };
  secrets.nextcloudPasswordExporter = {
    file = ./password.age;
    owner = "nextcloud-exporter";
  };

  services.prometheus.exporters.nextcloud = enabled {
    listenAddress = "[::]";

    username = "admin";
    url = "https://${fqdn}";
    passwordFile = config.secrets.nextcloudPasswordExporter.path;
  };

  services.postgresql.ensure = [ "nextcloud" ];

  systemd.services.nextcloud-setup = {
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
  };

  services.nextcloud = enabled {
    package = packageNextcloud;

    hostName = fqdn;
    https = true;

    configureRedis = true;

    config = {
      adminuser = "admin";
      adminpassFile = config.secrets.nextcloudPassword.path;
      dbhost = "/run/postgresql";
      dbtype = "pgsql";
    };

    settings = {
      default_phone_region = "US";
      maintenance_window_start = 1;
      log_type = "file";
    };

    settings.enabledPreviewProviders = [
      "OC\\Preview\\BMP"
      "OC\\Preview\\GIF"
      "OC\\Preview\\JPEG"
      "OC\\Preview\\Krita"
      "OC\\Preview\\MarkDown"
      "OC\\Preview\\MP3"
      "OC\\Preview\\OpenDocument"
      "OC\\Preview\\PNG"
      "OC\\Preview\\TXT"
      "OC\\Preview\\XBitmap"
      "OC\\Preview\\HEIC"
    ];

    phpOptions = {
      "opcache.interned_strings_buffer" = "16";
      output_buffering = "off";
    };

    extraAppsEnable = true;
    extraApps = {
      inherit (packageNextcloud.packages.apps)
        bookmarks
        calendar
        contacts
        deck
        forms
        impersonate
        mail
        notes
        previewgenerator
        ;
    };
  };

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    extraConfig = ''
      ${config.services.nginx.headers}
    '';
  };
}
