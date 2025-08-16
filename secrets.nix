let
  inherit (import ./keys.nix)
    nixbox
    admins
    adminsOvh
    all
    ;
in
{
  # nixbox server
  "hosts/nixbox/id.age".publicKeys = [ nixbox ] ++ admins;
  "hosts/nixbox/password.age".publicKeys = [ nixbox ] ++ admins;

  "hosts/nixbox/forgejo/runner.age".publicKeys = [ nixbox ] ++ admins;

  "hosts/nixbox/matrix/key.age".publicKeys = [ nixbox ] ++ admins;
  "hosts/nixbox/matrix/secret.age".publicKeys = [ nixbox ] ++ admins;

  "hosts/nixbox/github2forgejo/environment.age".publicKeys = [ nixbox ] ++ admins;

  "hosts/nixbox/nextcloud/password.age".publicKeys = [ nixbox ] ++ admins;

  "hosts/nixbox/plausible/key.age".publicKeys = [ nixbox ] ++ admins;

  "hosts/nixbox/vaultwarden/env.age".publicKeys = [ nixbox ] ++ admins;

  "hosts/nixbox/yourspotify/secret.age".publicKeys = [ nixbox ] ++ admins;

  # nixmain desktop
  "hosts/nixmain/id.age".publicKeys = admins;
  "hosts/nixmain/password.age".publicKeys = admins;
  "hosts/nixmain/yubikey/u2f.age".publicKeys = admins;

  # nixovh server
  "hosts/nixovh/forgejo/assets.tar.gz.age".publicKeys = admins ++ adminsOvh;
  "hosts/nixovh/id.age".publicKeys = admins ++ adminsOvh;
  "hosts/nixovh/password.age".publicKeys = admins ++ adminsOvh;

  "hosts/nixovh/grafana/password.age".publicKeys = admins ++ adminsOvh;

  "hosts/nixovh/plausible/key.age".publicKeys = admins ++ adminsOvh;

  # shared
  "modules/common/atuin/key.age".publicKeys = all;
  "modules/common/shell/anthropic-key.age".publicKeys = all;
  "modules/common/shell/openai-key.age".publicKeys = all;
  "modules/common/ssh/config.age".publicKeys = all;
  "modules/acme/environment.age".publicKeys = all;
  "modules/linux/restic/password.age".publicKeys = all;
  "modules/mail/password.hash.age".publicKeys = all;
  "modules/mail/password.plain.age".publicKeys = all;
}
