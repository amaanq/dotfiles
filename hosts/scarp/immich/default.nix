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
  fqdn = "images.${domain}";
  port = stringToPort "immich";

  # Patch immich for Sharp 0.35 + vips 8.18 (Apple HDR/gainmap support)
  # Fetch sharp linux-x64 prebuilt binary and its bundled libvips (pnpm skips optional deps)
  sharpBinary = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@img/sharp-linux-x64/-/sharp-linux-x64-0.35.0-rc.0.tgz";
    hash = "sha256-QAWZlCn3qqiXPTx6fb2CjWcUrqb6POyL0srh0cBNLE4=";
  };
  sharpLibvips = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@img/sharp-libvips-linux-x64/-/sharp-libvips-linux-x64-1.3.0-rc.2.tgz";
    hash = "sha256-/IhN6fRXLHk4RXSFwXiHW1REis9TFIFJ1ogQFcsacx0=";
  };

  immich' = pkgs.immich.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./sharp-0.35.patch ];
    buildInputs = map (d: if d.pname or "" == "vips" then pkgs.vips else d) old.buildInputs;
    pnpmDeps = pkgs.fetchPnpmDeps {
      inherit (old) pname version src;
      patches = (old.patches or [ ]) ++ [ ./sharp-0.35.patch ];
      pnpm = pkgs.pnpm_10;
      fetcherVersion = 2;
      hash = "sha256-4cLUsHGylD7deYBpIB4gdE32lTvqY4yNtspE665/OWI=";
    };
    # Install sharp prebuilt binary with symlinks to system libvips (has libultrahdr)
    postInstall = (old.postInstall or "") + ''
      sharpDir="$out/lib/node_modules/immich/node_modules/.pnpm/sharp@0.35.0-rc.0/node_modules/@img/sharp-linux-x64"
      mkdir -p "$sharpDir"
      tar -xzf ${sharpBinary} -C "$sharpDir" --strip-components=1

      # Create fake libvips dir with symlinks to system libvips 8.18 (with libultrahdr)
      libvipsDir="$out/lib/node_modules/immich/node_modules/.pnpm/sharp@0.35.0-rc.0/node_modules/@img/sharp-libvips-linux-x64/lib"
      mkdir -p "$libvipsDir"
      ln -s ${pkgs.vips.out}/lib/libvips.so.42.20.0 "$libvipsDir/libvips.so.8.18.0"
      ln -s ${pkgs.vips.out}/lib/libvips-cpp.so.42.20.0 "$libvipsDir/libvips-cpp.so.8.18.0"
    '';
    passthru = old.passthru // {
      web = old.passthru.web.overrideAttrs (w: { patches = (w.patches or [ ]) ++ [ ./sharp-0.35.patch ]; });
      plugins = old.passthru.plugins.overrideAttrs (p: { patches = (p.patches or [ ]) ++ [ ./sharp-0.35.patch ]; });
    };
  });
in
{
  imports = [
    (self + /modules/nginx.nix)
    (self + /modules/postgresql.nix)
  ];

  services.postgresql.ensure = [ "immich" ];

  services.immich = enabled {
    host = "::1";
    inherit port;
    package = immich';

    settings.server.externalDomain = "https://${fqdn}";

    database = enabled {
      host = "/run/postgresql";
    };
  };

  systemd.services.immich-server = {
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
  };

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    locations."/" = {
      proxyPass = "http://[::1]:${toString port}";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_cookie_path / /;
      '';
    };

    extraConfig = ''
      client_max_body_size 50000M;
    '';
  };
}
