{ self, config, ... }:

let
  inherit (config.networking) domain;
  fqdn = "mail.${domain}";
in
{
  imports = [ (self + /modules/mail) ];

  # secrets.hkMailPassword.file = ./hk-password.hash.age;
  #
  # mailserver = {
  #   inherit fqdn;
  #
  #   loginAccounts."gulag@libg.so" = {
  #     hashedPasswordFile = config.secrets.mailPassword.path;
  #   };
  #
  #   loginAccounts."contact@libg.so" = {
  #     aliases = [
  #       "@libg.so"
  #       "noreply@libg.so"
  #       "admin@libg.so"
  #       "support@libg.so"
  #       "info@libg.so"
  #     ];
  #     hashedPasswordFile = config.secrets.mailPassword.path;
  #   };
  #
  #   loginAccounts."reese@hkpoolservices.com" = {
  #     aliases = [ "@hkpoolservices.com" ];
  #     hashedPasswordFile = config.secrets.hkMailPassword.path;
  #   };
  # };
}
