{
  self,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib) enabled merge stringToPort;

  fqdn = "i.${domain}";
  port = stringToPort "zipline";

  # Workaround: fetchPnpmDeps v2 strips lifecycle scripts from the pnpm store
  # index, so sharp's "install": "node install/check.js" becomes scripts: {}.
  # pnpm install --force sees requiresBuild but runs an empty command and fails.
  # Manually install the prebuilt sharp binary and symlink system libvips.
  sharpBinary = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@img/sharp-linux-x64/-/sharp-linux-x64-0.34.5.tgz";
    hash = "sha256-/hNnmyIpB9lYQhS/g31dkslFa6CID8JGJd0RireRjvk=";
  };

  zipline' = pkgs.zipline.overrideAttrs (old: {
    buildPhase = ''
      runHook preBuild

      pnpm config set nodedir ${pkgs.nodejs_24}
      pnpm install --ignore-scripts --offline --frozen-lockfile

      # Install prebuilt sharp native addon
      sharpDir="node_modules/.pnpm/sharp@0.34.5/node_modules/@img/sharp-linux-x64"
      mkdir -p "$sharpDir"
      tar -xzf ${sharpBinary} -C "$sharpDir" --strip-components=1

      # Symlink system libvips
      libvipsDir="node_modules/.pnpm/sharp@0.34.5/node_modules/@img/sharp-libvips-linux-x64/lib"
      mkdir -p "$libvipsDir"
      for f in ${pkgs.vips.out}/lib/libvips*.so*; do
        ln -sf "$f" "$libvipsDir/$(basename "$f")"
      done

      # Run remaining lifecycle scripts (argon2 etc.) — exclude sharp
      pnpm rebuild --offline || true

      pnpm build

      runHook postBuild
    '';
  });
in
{
  imports = [
    (self + /modules/nginx.nix)
    (self + /modules/postgresql.nix)
  ];

  secrets.ziplineSecret.file = ./zipline/secret.age;

  services.postgresql.ensure = [ "zipline" ];

  services.zipline = enabled {
    package = zipline';
    database.createLocally = false;

    settings = {
      CORE_PORT = port;
      CORE_HOSTNAME = "127.0.0.1";
      DATABASE_URL = "postgresql://zipline@localhost/zipline?host=/run/postgresql";
      DATASOURCE_TYPE = "local";
      DATASOURCE_LOCAL_DIRECTORY = "/var/lib/zipline/uploads";
      FILES_MAX_FILE_SIZE = "10gb";
    };

    environmentFiles = [ config.secrets.ziplineSecret.path ];
  };

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    extraConfig = "client_max_body_size 10G;";
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}";
      proxyWebsockets = true;
    };
  };
}
