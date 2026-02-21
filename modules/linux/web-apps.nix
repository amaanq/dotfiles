{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  papirusIcon =
    name: sha256:
    builtins.fetchurl {
      url = "https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-icon-theme/master/Papirus/64x64/apps/${name}.svg";
      inherit sha256;
    };

  icons = {
    cinny = builtins.fetchurl {
      name = "cinny.svg";
      url = "https://raw.githubusercontent.com/cinnyapp/cinny/dev/public/res/svg/cinny.svg";
      sha256 = "07q417kinfccmcy5y8sal1w9g2c8p9azw1zl6r7qd68sq90a1ygx";
    };
    discord = papirusIcon "discord" "01b789880cnscbwfddkz5b89wjcj7zmm06dpbpblj5dv7sx9lskd";
    element = builtins.fetchurl {
      name = "element.png";
      url = "https://raw.githubusercontent.com/element-hq/element-web/master/res/vector-icons/1024.png";
      sha256 = "0945rxmjzrk510c9swi3qnp69cabarlb7ij52p2wi5mq6icaxabz";
    };
    telegram = builtins.fetchurl {
      name = "telegram.svg";
      url = "https://web.telegram.org/a/favicon.svg";
      sha256 = "0430x3k06i7j5kz9yjvvhjb3m8fhs77r6i056n1v85iy6g2z2qm4";
    };
    twitter = builtins.fetchurl {
      name = "twitter.svg";
      url = "https://upload.wikimedia.org/wikipedia/commons/6/6f/Logo_of_Twitter.svg";
      sha256 = "0571s6chrwc1a3ffyffklq9b6i3fdscbwzygnc1ndnpixwcda1ab";
    };
    slack = papirusIcon "slack" "05dy0l6lhb7dqlfpc3kj4wfka23s8kcdgadz99iaylja46k371j9";
    gather-town =
      let
        src = builtins.fetchurl {
          name = "gather-town-src.png";
          url = "https://framerusercontent.com/images/TgqHPNGUSL5hxRZ63TBh09Rn4.png";
          sha256 = "02azxsv8yb3qhwni3cdykryhxiyya7s5rbffb8iyicnjzdkni15b";
        };
      in
      pkgs.runCommand "gather-town.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
        magick ${src} \( +clone -alpha extract \
          -draw "fill black polygon 0,0 0,64 64,0 fill white circle 64,64 64,0" \
          -draw "fill black polygon 448,0 512,0 512,64 fill white circle 448,64 448,0" \
          -draw "fill black polygon 0,448 0,512 64,512 fill white circle 64,448 64,512" \
          -draw "fill black polygon 448,512 512,512 512,448 fill white circle 448,448 448,512" \
        \) -alpha off -compose CopyOpacity -composite $out
      '';
  };

  webAppLauncher = pkgs.writeShellScript "web-app-launcher" ''
    browser="helium"

    browser_exec=""
    for path in ~/.local ~/.nix-profile /usr; do
      if [ -f "$path/share/applications/$browser.desktop" ]; then
        browser_exec=$(sed -n 's/^Exec=\([^ ]*\).*/\1/p' "$path/share/applications/$browser.desktop" 2>/dev/null | head -1)
        break
      fi
    done

    if [ -z "$browser_exec" ]; then
      browser_exec="helium"
    fi

    url="$1"
    app_name="''${2:-$(basename "$0")}"
    shift 2

    exec setsid "$browser_exec" \
      --app="$url" \
      --user-data-dir="$HOME/.local/share/web-apps/$app_name" \
      --no-first-run \
      --no-default-browser-check \
      --disable-background-timer-throttling \
      --disable-backgrounding-occluded-windows \
      --disable-renderer-backgrounding \
      --enable-quic \
      --quic-version=h3-29 \
      --enable-features=UseOzonePlatform,WaylandWindowDecorations,WaylandPerWindowScaling,WaylandTextInputV3,WebRTCPipeWireCapturer \
      --disable-features=WebRtcAllowInputVolumeAdjustment \
      --ozone-platform=wayland \
      --gtk-version=4 \
      --enable-experimental-web-platform-features \
      "$@"
  '';

  # Create web app package
  createWebApp =
    {
      name,
      url,
      icon,
      description ? "",
      categories ? [
        "Network"
        "Chat"
        "InstantMessaging"
      ],
    }:
    let
      pkgName = "${lib.replaceStrings [ " " ] [ "-" ] (lib.toLower name)}-web-app";
    in
    {
      name = pkgName;
      value = pkgs.stdenv.mkDerivation {
        pname = pkgName;
        version = "1.0";
        dontUnpack = true;

        nativeBuildInputs = [
          pkgs.copyDesktopItems
          pkgs.makeWrapper
        ];

        installPhase = ''
          runHook preInstall
          makeWrapper ${webAppLauncher} $out/bin/${pkgName} \
            --add-flags "${url}" \
            --add-flags "${pkgName}"
          runHook postInstall
        '';

        desktopItems = [
          (pkgs.makeDesktopItem {
            inherit icon categories;
            name = pkgName;
            exec = "${pkgName} %U";
            desktopName = name;
            comment = description;
            startupNotify = true;
            startupWMClass = pkgName;
          })
        ];
      };
    };

  apps = builtins.listToAttrs (
    map createWebApp [
      {
        name = "Cinny";
        url = "https://cinny.amaanq.com";
        icon = icons.cinny;
        description = "Cinny, a Matrix client";
      }
      {
        name = "Discord";
        url = "https://discord.com/app";
        icon = icons.discord;
        description = "Discord Web";
      }
      {
        name = "Element";
        url = "https://app.element.io";
        icon = icons.element;
        description = "Element, a Matrix client";
      }
      {
        name = "Telegram";
        url = "https://web.telegram.org/a";
        icon = icons.telegram;
        description = "Telegram Web";
      }
      {
        name = "Twitter";
        url = "https://twitter.com";
        icon = icons.twitter;
        description = "Twitter Web";
        categories = [
          "Network"
          "News"
        ];
      }
      {
        name = "Gather Town";
        url = "https://app.v2.gather.town";
        icon = icons.gather-town;
        description = "Gather Town virtual office";
      }
      {
        name = "Slack";
        url = "https://app.slack.com";
        icon = icons.slack;
        description = "Slack Web";
      }
    ]
  );
in
{
  config = mkIf config.isDesktop {
    environment.systemPackages = builtins.attrValues apps;

    xdg.mime.defaultApplications = {
      "x-scheme-handler/matrix" = "element-web-app.desktop";
      "x-scheme-handler/tg" = "telegram-web-app.desktop";
      "x-scheme-handler/tonsite" = "telegram-web-app.desktop";
    };

    environment.etc."web-apps-setup".text = ''
      mkdir -p /home/*/.local/share/web-apps
    '';
  };
}
