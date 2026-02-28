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

  "hosts/scarp/bazel-remote/token.age".publicKeys = [ scarp ] ++ admins;

  "hosts/scarp/cache/key.age".publicKeys = [ scarp ] ++ admins;

  "hosts/scarp/miniflux/credentials.age".publicKeys = [ scarp ] ++ admins;

  "hosts/scarp/mollysocket/vapid-key.age".publicKeys = [ scarp ] ++ admins;

  "hosts/scarp/nextcloud/password.age".publicKeys = [ scarp ] ++ admins;

  "hosts/scarp/nitter/sessions.age".publicKeys = [ scarp ] ++ admins;

  "hosts/scarp/teapot/sessions.age".publicKeys = [ scarp ] ++ admins;

  "hosts/scarp/plausible/key.age".publicKeys = [ scarp ] ++ admins;

  "hosts/scarp/vaultwarden/env.age".publicKeys = [ scarp ] ++ admins;

  "hosts/scarp/yourspotify/secret.age".publicKeys = [ scarp ] ++ admins;

  "hosts/scarp/zipline/secret.age".publicKeys = [ scarp ] ++ admins;

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

  # lahar laptop
  "hosts/lahar/password.age".publicKeys = admins;

  # esker laptop
  "hosts/esker/password.age".publicKeys = admins;

  # gyre desktop
  "hosts/gyre/password.age".publicKeys = admins;

  # grapheneos keys
  "modules/common/graphene/komodo/keys.tar.gz.age".publicKeys = admins;

  # shared
  "modules/linux/niri/zipline-token.age".publicKeys = admins;
  "modules/common/atuin/key.age".publicKeys = all;
  "modules/common/builder-key.age".publicKeys = all;
  "modules/common/git-identity.age".publicKeys = all;
  "modules/common/git-private.age".publicKeys = all;
  "modules/common/github-token.age".publicKeys = all;
  "modules/common/shell/anthropic-key.age".publicKeys = all;
  "modules/common/shell/glm-key.age".publicKeys = all;
  "modules/common/shell/openai-key.age".publicKeys = all;
  "modules/common/ida/netrc.age".publicKeys = all;
  "modules/common/ssh/config.age".publicKeys = all;
  "modules/acme/environment.age".publicKeys = all;
  "modules/linux/tailscale/authkey.age".publicKeys = all;
  "modules/linux/restic/password.age".publicKeys = all;
}
