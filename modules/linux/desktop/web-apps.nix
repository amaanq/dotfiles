{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    mkAliasOptionModule
    types
    mapAttrsToList
    attrNames
    filterAttrs
    replaceStrings
    toLower
    ;
  inherit (types)
    str
    strMatching
    package
    path
    nullOr
    listOf
    attrsOf
    submodule
    either
    ;

  papirusIcon =
    name: sha256:
    builtins.fetchurl {
      url = "https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-icon-theme/master/Papirus/64x64/apps/${name}.svg";
      inherit sha256;
    };

  icons = {
    bulwark = builtins.fetchurl {
      name = "bulwark.svg";
      url = "https://raw.githubusercontent.com/bulwarkmail/webmail/main/public/branding/Bulwark_Icon_App.svg";
      sha256 = "0w54484d77s30znp9pshh8gqh5g58yiw3i5qq3wip6wbr3jvg07n";
    };
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

  # Shared flags every PWA inherits. Values are literal strings expanded at
  # build time; $HOME is escaped so it expands at run time.
  commonFlags = [
    "--password-store=gnome-libsecret"
    "--no-first-run"
    "--no-default-browser-check"
    "--disable-background-timer-throttling"
    "--disable-backgrounding-occluded-windows"
    "--disable-renderer-backgrounding"
    "--enable-quic"
    "--quic-version=h3-29"
    "--enable-features=UseOzonePlatform,WaylandWindowDecorations,WaylandPerWindowScaling,WaylandTextInputV3,WebRTCPipeWireCapturer"
    "--disable-features=WebRtcAllowInputVolumeAdjustment"
    "--ozone-platform=wayland"
    "--gtk-version=4"
    "--enable-experimental-web-platform-features"
  ];

  mkWebApp =
    {
      name,
      url,
      icon,
      description,
      categories,
    }:
    let
      cleanName = replaceStrings [ " " "\n" "\t" ] [ "-" "-" "-" ] name |> toLower;
      pname = "${cleanName}-web-app";
      heliumBin = "${config.wrappers.helium.finalPackage}/bin/helium";
      flags = [
        "--app=${url}"
        "--user-data-dir=$HOME/.local/share/web-apps/${pname}"
      ]
      ++ commonFlags;
      flagArgs = lib.concatStringsSep " " (map (f: "--add-flags ${lib.escapeShellArg f}") flags);
    in
    pkgs.stdenv.mkDerivation {
      inherit pname;
      version = "1.0";
      dontUnpack = true;

      nativeBuildInputs = [
        pkgs.copyDesktopItems
        pkgs.makeWrapper
      ];

      installPhase = ''
        runHook preInstall
        makeWrapper ${heliumBin} $out/bin/${pname} ${flagArgs}
        runHook postInstall
      '';

      desktopItems = [
        (pkgs.makeDesktopItem (
          {
            name = pname;
            exec = "${pname} %U";
            desktopName = name;
            startupNotify = true;
            startupWMClass = pname;
          }
          // filterAttrs (_: v: v != null) {
            inherit icon categories;
            comment = description;
          }
        ))
      ];

      meta.mainProgram = pname;
    };

  innerOpts = {
    options = {
      name = mkOption {
        type = str;
      };
      url = mkOption {
        type = strMatching "[hH][tT][tT][pP][sS]?://[^\n\r[:space:]]+";
      };
      icon = mkOption {
        type = nullOr (either str path);
        default = null;
      };
      description = mkOption {
        type = nullOr str;
        default = null;
      };
      categories = mkOption {
        type = nullOr (listOf str);
        default = null;
      };
    };
  };

  pwaModule = submodule (
    { config, ... }:
    {
      imports =
        let
          names = innerOpts.options |> attrNames;
        in
        map (optName: mkAliasOptionModule [ optName ] [ "settings" optName ]) names;
      options = {
        settings = mkOption {
          type = submodule innerOpts;
          default = { };
        };
        package = mkOption {
          type = package;
          readOnly = true;
          default = mkWebApp config.settings;
        };
      };
    }
  );
in
{
  options = {
    programs.pwas = mkOption {
      description = "PWA Applications";
      type = attrsOf pwaModule;
      default = { };
    };
  };

  config = {
    programs.pwas = {
      bulwark = {
        name = "Bulwark";
        url = "https://inbox.amaanq.com";
        icon = icons.bulwark;
        description = "Bulwark webmail";
      };
      cinny = {
        name = "Cinny";
        url = "https://cinny.amaanq.com";
        icon = icons.cinny;
        description = "Cinny, a Matrix client";
      };
      discord = {
        name = "Discord";
        url = "https://discord.com/app";
        icon = icons.discord;
        description = "Discord Web";
      };
      element = {
        name = "Element";
        url = "https://app.element.io";
        icon = icons.element;
        description = "Element, a Matrix client";
      };
      telegram = {
        name = "Telegram";
        url = "https://web.telegram.org/a";
        icon = icons.telegram;
        description = "Telegram Web";
      };
      twitter = {
        name = "Twitter";
        url = "https://twitter.com";
        icon = icons.twitter;
        description = "Twitter Web";
        categories = [
          "Network"
          "News"
        ];
      };
      gather-town = {
        name = "Gather Town";
        url = "https://app.v2.gather.town";
        icon = icons.gather-town;
        description = "Gather Town virtual office";
      };
      slack = {
        name = "Slack";
        url = "https://app.slack.com";
        icon = icons.slack;
        description = "Slack Web";
      };
    };

    environment.systemPackages = mapAttrsToList (_: v: v.package) config.programs.pwas;

    xdg.mime.defaultApplications = {
      "x-scheme-handler/matrix" = "element-web-app.desktop";
      "x-scheme-handler/tg" = "telegram-web-app.desktop";
      "x-scheme-handler/tonsite" = "telegram-web-app.desktop";
    };
  };
}
