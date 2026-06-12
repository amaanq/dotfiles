{
  self,
  config,
  tilera-docs,
  ...
}:
let
  zone = "endangered.systems";
  fqdn = "tilera.${zone}";
in
{
  imports = [ (self + /modules/nginx.nix) ];

  security.acme.certs.${zone} = {
    extraDomainNames = [ "*.${zone}" ];
    group = "acme";
  };

  services.nginx.virtualHosts.${fqdn} = config.services.nginx.sslTemplate // {
    useACMEHost = zone;

    locations."/docs/" = {
      alias = "${tilera-docs}/";
      extraConfig = ''
        index index.html;
        autoindex off;
      '';
    };

    locations."/".return = "302 /docs/";
  };
}
