{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  webAppLauncher = pkgs.writeShellScript "web-app-launcher" ''
    #!/bin/bash
    browser="thorium"

    browser_exec=""
    for path in ~/.local ~/.nix-profile /usr; do
      if [ -f "$path/share/applications/$browser.desktop" ]; then
        browser_exec=$(sed -n 's/^Exec=\([^ ]*\).*/\1/p' "$path/share/applications/$browser.desktop" 2>/dev/null | head -1)
        break
      fi
    done

    if [ -z "$browser_exec" ]; then
      browser_exec="thorium"
    fi

    extensions="$HOME/.config/thorium-extensions/adnauseam.chromium/"

    case "$1" in
      *discord.com*)
        extensions="$extensions,$HOME/.config/thorium-extensions/vencord/"
        ;;
      *twitter.com*)
        extensions="$extensions,$HOME/.config/thorium-extensions/control-panel-for-twitter/"
        ;;
    esac

    exec setsid "$browser_exec" \
      --app="$1" \
      --user-data-dir="$HOME/.local/share/web-apps/$(echo "$1" | sed 's|https\?://||' | sed 's|[^a-zA-Z0-9]|-|g')" \
      --class="WebApp-$(basename "$1")" \
      --no-first-run \
      --no-default-browser-check \
      --disable-background-timer-throttling \
      --disable-backgrounding-occluded-windows \
      --disable-renderer-backgrounding \
      --use-angle=vulkan \
      --enable-quic \
      --quic-version=h3-29 \
      --enable-features=UseOzonePlatform,WaylandWindowDecorations,WaylandPerWindowScaling,WaylandTextInputV3 \
      --ozone-platform=wayland \
      --gtk-version=4 \
      --enable-experimental-web-platform-features \
      --load-extension="$extensions" \
      ''${@:2}
  '';

  # Create desktop entries for web apps
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
    {
      name = "web-app-${name}";
      value = pkgs.makeDesktopItem {
        name = "web-app-${name}";
        desktopName = name;
        exec = "${webAppLauncher} ${url}";
        icon = icon;
        comment = description;
        categories = categories;
        mimeTypes = [ ];
        startupNotify = true;
        startupWMClass = "WebApp-${url}";
      };
    };

  webApps = builtins.listToAttrs [
    (createWebApp {
      name = "Cinny";
      url = "https://cinny.amaanq.com";
      icon = "cinny";
      description = "Cinny, a Matrix client";
    })
    (createWebApp {
      name = "Discord";
      url = "https://discord.com/app";
      icon = "discord";
      description = "Discord Web";
    })
    (createWebApp {
      name = "Element";
      url = "https://app.element.io";
      icon = "element-desktop";
      description = "Element, a Matrix client";
    })
    (createWebApp {
      name = "Telegram";
      url = "https://web.telegram.org/a";
      icon = "telegram";
      description = "Telegram Web";
    })
    (createWebApp {
      name = "Twitter";
      url = "https://twitter.com";
      icon = "twitter";
      description = "Twitter Web";
      categories = [
        "Network"
        "News"
      ];
    })
  ];
in
{
  config = mkIf config.isDesktop {
    environment.systemPackages = builtins.attrValues webApps;

    xdg.mime.defaultApplications = {
      "x-scheme-handler/matrix" = "web-app-Element.desktop";
      "x-scheme-handler/tg" = "web-app-Telegram.desktop";
      "x-scheme-handler/tonsite" = "web-app-Telegram.desktop";
    };

    environment.etc."web-apps-setup".text = ''
      mkdir -p /home/*/.local/share/web-apps
    '';
  };
}
