{ self, config, ... }:

let
  inherit (config.networking) domain;
  fqdn = "mail.${domain}";
in
{
  imports = [ (self + /modules/mail) ];

  secrets.hkMailPassword.file = ./hk-password.hash.age;

  services.stalwart-mail.settings = {
    server.hostname = fqdn;

    server.lookup.default.hostname = fqdn;
  };
}