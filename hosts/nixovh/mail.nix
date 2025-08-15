{ self, config, ... }:

let
  inherit (config.networking) domain;
  fqdn = "mail.${domain}";
in
{
  imports = [ (self + /modules/mail) ];

  mailserver = {
    inherit fqdn;

    loginAccounts."gulag@libg.so" = {
      hashedPasswordFile = config.secrets.mailPassword.path;
    };
  };
}
