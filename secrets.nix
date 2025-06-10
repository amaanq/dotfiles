let
  inherit (import ./keys.nix) nixbox admins all;
in
{
  # nixbox server
  "hosts/nixbox/id.age".publicKeys = [ nixbox ] ++ admins;
  "hosts/nixbox/password.age".publicKeys = [ nixbox ] ++ admins;
  "hosts/nixbox/nextcloud/password.age".publicKeys = [ nixbox ] ++ admins;
  "hosts/nixbox/vaultwarden/env.age".publicKeys = [ nixbox ] ++ admins;
  "hosts/nixbox/yourspotify/secret.age".publicKeys = [ nixbox ] ++ admins;

  # nixmain desktop
  "hosts/nixmain/id.age".publicKeys = admins;
  "hosts/nixmain/password.age".publicKeys = admins;
  "hosts/nixmain/yubikey/u2f.age".publicKeys = admins;

  # shared
  "modules/common/atuin/key.age".publicKeys = all;
  "modules/common/ssh/config.age".publicKeys = all;
  "modules/acme/environment.age".publicKeys = all;
}
