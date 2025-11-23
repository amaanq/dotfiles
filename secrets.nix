let
  inherit (import ./keys.nix)
    scarp
    nunatak
    admins
    all
    ;
in
{
  # scarp server
  "hosts/scarp/id.age".publicKeys = [ scarp ] ++ admins;
  "hosts/scarp/password.age".publicKeys = [ scarp ] ++ admins;

  "hosts/scarp/fdroid/upload-token.age".publicKeys = [ scarp ] ++ admins;
  "hosts/scarp/fdroid/keystore.p12.age".publicKeys = [ scarp ] ++ admins;
  "hosts/scarp/fdroid/keystore-password.age".publicKeys = [ scarp ] ++ admins;

  "hosts/scarp/forgejo/runner.age".publicKeys = [ scarp ] ++ admins;

  "hosts/scarp/matrix/key.age".publicKeys = [ scarp ] ++ admins;
  "hosts/scarp/matrix/secret.age".publicKeys = [ scarp ] ++ admins;

  "hosts/scarp/github2forgejo/environment.age".publicKeys = [ scarp ] ++ admins;

  "hosts/scarp/mollysocket/vapid-key.age".publicKeys = [ scarp ] ++ admins;

  "hosts/scarp/nextcloud/password.age".publicKeys = [ scarp ] ++ admins;

  "hosts/scarp/nitter/sessions.age".publicKeys = [ scarp ] ++ admins;

  "hosts/scarp/plausible/key.age".publicKeys = [ scarp ] ++ admins;

  "hosts/scarp/vaultwarden/env.age".publicKeys = [ scarp ] ++ admins;

  "hosts/scarp/yourspotify/secret.age".publicKeys = [ scarp ] ++ admins;

  # derecho desktop
  "hosts/derecho/id.age".publicKeys = admins;
  "hosts/derecho/password.age".publicKeys = admins;
  "hosts/derecho/yubikey/u2f.age".publicKeys = admins;

  # nunatak server
  "hosts/nunatak/id.age".publicKeys = [ nunatak ] ++ admins;
  "hosts/nunatak/password.age".publicKeys = [ nunatak ] ++ admins;

  "hosts/nunatak/forgejo/assets.tar.gz.age".publicKeys = [ nunatak ] ++ admins;
  "hosts/nunatak/forgejo/runner.age".publicKeys = [ nunatak ] ++ admins;

  "hosts/nunatak/mail/dkim-stalwart.key.age".publicKeys = [ nunatak ] ++ admins;
  "hosts/nunatak/mail/password.plain.age".publicKeys = [ nunatak ] ++ admins;
  "hosts/nunatak/mail/ameerq-password.plain.age".publicKeys = [ nunatak ] ++ admins;
  "hosts/nunatak/mail/hk-password.plain.age".publicKeys = [ nunatak ] ++ admins;

  "hosts/nunatak/matrix/tuwunel-token.age".publicKeys = [ nunatak ] ++ admins;

  "hosts/nunatak/grafana/password.age".publicKeys = [ nunatak ] ++ admins;

  "hosts/nunatak/plausible/key.age".publicKeys = [ nunatak ] ++ admins;

  # gyre desktop
  "hosts/gyre/password.age".publicKeys = admins;

  # shared
  "modules/common/atuin/key.age".publicKeys = all;
  "modules/common/shell/anthropic-key.age".publicKeys = all;
  "modules/common/shell/openai-key.age".publicKeys = all;
  "modules/common/ssh/config.age".publicKeys = all;
  "modules/acme/environment.age".publicKeys = all;
  "modules/linux/tailscale/authkey.age".publicKeys = all;
  "modules/linux/restic/password.age".publicKeys = all;
}
