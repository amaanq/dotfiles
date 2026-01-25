{
  self,
  config,
  lib,
  hkpoolservices,
  ...
}:
let
  domain = "hkpoolservices.com";
  user = "poolservice";
  group = user;
  stateDir = "/var/lib/${user}";

  hkpspkg = hkpoolservices.packages.${config.hostSystem}.default;
in
{
  imports = [
    (self + /modules/nginx.nix)
  ];

  users.users.${user} = {
    inherit group;
    isSystemUser = true;
    home = stateDir;
    createHome = true;
  };

  users.groups.${group} = { };

  systemd.services.poolservice-deploy = {
    description = "Deploy HK Pool Services website";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = ''
      rm -rf ${stateDir}/*

      cp -r ${hkpspkg}/* ${stateDir}/

      chown -R ${user}:${group} ${stateDir}
      chmod 755 ${stateDir}
      find ${stateDir} -type f -exec chmod 644 {} \;
      find ${stateDir} -type d -exec chmod 755 {} \;
    '';
    before = [ "nginx.service" ];
    wantedBy = [ "multi-user.target" ];
  };

  services.nginx.virtualHosts.${domain} = lib.recursiveUpdate config.services.nginx.sslTemplate {
    root = stateDir;

    locations."/" = {
      tryFiles = "$uri $uri.html $uri/ /index.html";
    };

    extraConfig = ''
      ${config.services.plausible.extraNginxConfigFor domain}

      error_page 404 /404.html;

      location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        more_set_headers "Cache-Control: public, immutable";
      }
    '';
  };

  services.nginx.virtualHosts."www.${domain}" = {
    globalRedirect = domain;
  };
}
