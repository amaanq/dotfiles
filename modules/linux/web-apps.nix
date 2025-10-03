{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  webAppLauncherScript = pkgs.writeShellScript "web-app-launcher" ''
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

    url="$1"
    app_name="''${2:-$(basename "$0")}"
    shift

    exec setsid "$browser_exec" \
      --app="$url" \
      --user-data-dir="$HOME/.local/share/web-apps/$app_name" \
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
      pkgName = "${lib.toLower name}-web-app";
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
          makeWrapper ${webAppLauncherScript} $out/bin/${pkgName} \
            --add-flags "${url}" \
            --add-flags "${pkgName}"
          runHook postInstall
        '';

        desktopItems = [
          (pkgs.makeDesktopItem {
            name = pkgName;
            exec = "${pkgName} %U";
            icon = icon;
            desktopName = name;
            comment = description;
            categories = categories;
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
        icon = "cinny";
        description = "Cinny, a Matrix client";
      }
      {
        name = "Discord";
        url = "https://discord.com/app";
        icon = "discord";
        description = "Discord Web";
      }
      {
        name = "Element";
        url = "https://app.element.io";
        icon = "element-desktop";
        description = "Element, a Matrix client";
      }
      {
        name = "Telegram";
        url = "https://web.telegram.org/a";
        icon = "telegram";
        description = "Telegram Web";
      }
      {
        name = "Twitter";
        url = "https://twitter.com";
        icon = "twitter";
        description = "Twitter Web";
        categories = [
          "Network"
          "News"
        ];
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
