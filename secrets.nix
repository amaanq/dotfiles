let
  inherit (import ./keys.nix)
    nixbox
    nunatak
    admins
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

  # derecho desktop
  "hosts/derecho/id.age".publicKeys = admins;
  "hosts/derecho/password.age".publicKeys = admins;
  "hosts/derecho/yubikey/u2f.age".publicKeys = admins;

  # nunatak server
  "hosts/nunatak/id.age".publicKeys = [ nunatak ] ++ admins;
  "hosts/nunatak/password.age".publicKeys = [ nunatak ] ++ admins;

  "hosts/nunatak/forgejo/assets.tar.gz.age".publicKeys = [ nunatak ] ++ admins;
  "hosts/nunatak/forgejo/runner.age".publicKeys = [ nunatak ] ++ admins;

  "hosts/nunatak/grafana/password.age".publicKeys = [ nunatak ] ++ admins;

  "hosts/nunatak/plausible/key.age".publicKeys = [ nunatak ] ++ admins;

  # nixwsl desktop
  "hosts/nixwsl/password.age".publicKeys = admins;

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
