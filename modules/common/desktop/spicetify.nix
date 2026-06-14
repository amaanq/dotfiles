{
  config,
  spicetify,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    enabled
    mkForce
    optionalAttrs
    theme
    ;

  colors = theme;

  # nixpkgs PR #540416
  spicetifyCli = pkgs.spicetify-cli.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
      pkgs.nodejs
      pkgs.esbuild
    ];
    postBuild = (old.postBuild or "") + ''
      esbuild $src/src/jsHelper/spicetifyWrapper/index.js \
        --bundle --minify --target=chrome108 --format=iife \
        --outfile=spicetifyWrapper.js
    '';
    postInstall = (old.postInstall or "") + ''
      chmod -R u+w $out/share/spicetify/jsHelper
      cp spicetifyWrapper.js $out/share/spicetify/jsHelper/spicetifyWrapper.js
    '';
  });

  spicetifyTheme = pkgs.writeTextFile {
    name = "color.ini";
    destination = "/color.ini";
    text = ''
      [base]
      text               = ${colors.text}
      subtext            = ${colors.text}
      main               = ${colors.base}
      main-elevated      = ${colors.overlay}
      highlight          = ${colors.overlay}
      highlight-elevated = ${colors.muted}
      sidebar            = ${colors.surface}
      player             = ${colors.subtle}
      card               = ${colors.muted}
      shadow             = ${colors.base}
      selected-row       = ${colors.subtle}
      button             = ${colors.subtle}
      button-active      = ${colors.subtle}
      button-disabled    = ${colors.muted}
      tab-active         = ${colors.overlay}
      notification       = ${colors.overlay}
      notification-error = ${colors.love}
      equalizer          = ${colors.pine}
      misc               = ${colors.overlay}
    '';
  };

  spotifyNoPreload =
    pkgs.runCommandLocal "spotify-no-preload"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
        meta.priority = -1;
      }
      ''
        mkdir -p $out/bin
        makeWrapper ${config.programs.spicetify.spicedSpotify}/bin/spotify \
          $out/bin/spotify --unset LD_PRELOAD
      '';
in
{
  programs.spicetify =
    enabled {
      spicetifyPackage = spicetifyCli;
      experimentalFeatures = true;
      enabledExtensions = with spicetify.legacyPackages.${config.hostSystem}.extensions; [
        copyLyrics
      ];
      theme = mkForce {
        name = "rose-pine";
        src = spicetifyTheme;
        sidebarConfig = false;
      };
      colorScheme = mkForce "base";
    }
    // optionalAttrs config.isLinux {
      wayland = true;
    };

  environment.systemPackages = lib.mkIf config.isLinux [ spotifyNoPreload ];
}
