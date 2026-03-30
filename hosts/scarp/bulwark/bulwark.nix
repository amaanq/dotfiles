{
  self,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib) enabled merge;

  fqdn = "inbox.${domain}";
  port = 3000;
  stalwartUrl = "https://mail.${domain}";

  bulwark = pkgs.buildNpmPackage (finalAttrs: {
    pname = "bulwark";
    version = "1.4.13";

    src = pkgs.fetchFromGitHub {
      owner = "bulwarkmail";
      repo = "webmail";
      tag = finalAttrs.version;
      hash = "sha256-8xR7PDfBuwvDUvIYTQ8y3MCWrTTDq58tF02ZLgwVj48=";
    };

    npmDepsHash = "sha256-ooNJYXfk1ELa+I/+5ZUgvevNCGp/dZSP3VUEwIJc1Ow=";

    patches = [ ./bulwark-localfont.patch ];

    configurePhase = ''
      runHook preConfigure

      mkdir -p app/fonts
      cp "${
        pkgs.google-fonts.override { fonts = [ "Geist" ]; }
      }/share/fonts/truetype/Geist[wght].ttf" app/fonts/Geist.ttf
      cp "${
        pkgs.google-fonts.override { fonts = [ "GeistMono" ]; }
      }/share/fonts/truetype/GeistMono[wght].ttf" app/fonts/GeistMono.ttf

      runHook postConfigure
    '';

    buildPhase = ''
      runHook preBuild
      NEXT_TELEMETRY_DISABLED=1 node_modules/.bin/next build --webpack
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir $out
      cp -R .next/standalone/. $out/
      cp -R public $out/public
      cp -R .next/static $out/.next/static

      makeWrapper ${pkgs.nodejs}/bin/node $out/bin/bulwark \
        --add-flags "$out/server.js" \
        --set NODE_ENV production \
        --set NEXT_TELEMETRY_DISABLED 1

      runHook postInstall
    '';

    meta = {
      description = "Modern webmail client for Stalwart Mail Server";
      homepage = "https://bulwarkmail.org";
      license = lib.licenses.agpl3Plus;
      mainProgram = "bulwark";
    };
  });
in
{
  imports = [ (self + /modules/bulwark.nix) ];

  secrets.bulwarkSecret.rekeyFile = ./bulwark-secret.age;

  services.bulwark = enabled {
    package = bulwark;
    jmapServerUrl = "https://${fqdn}";
    inherit port;
    sessionSecretFile = config.secrets.bulwarkSecret.path;
  };

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    locations =
      let
        stalwartProxy = {
          recommendedProxySettings = false;
          extraConfig = ''
            proxy_set_header Host mail.${domain};
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      in
      {
        "/.well-known/jmap" = stalwartProxy // {
          proxyPass = "${stalwartUrl}/.well-known/jmap";
        };

        "/jmap" = stalwartProxy // {
          proxyPass = "${stalwartUrl}/jmap";
          extraConfig = stalwartProxy.extraConfig + ''
            client_max_body_size 50M;
          '';
        };

        "/.well-known/caldav" = stalwartProxy // {
          proxyPass = "${stalwartUrl}/.well-known/caldav";
        };

        "/.well-known/carddav" = stalwartProxy // {
          proxyPass = "${stalwartUrl}/.well-known/carddav";
        };

        "/dav/" = stalwartProxy // {
          proxyPass = "${stalwartUrl}/dav/";
          extraConfig = stalwartProxy.extraConfig + ''
            client_max_body_size 10G;
          '';
        };

        "/" = {
          proxyPass = "http://127.0.0.1:${toString port}";
          proxyWebsockets = true;
        };
      };
  };
}
