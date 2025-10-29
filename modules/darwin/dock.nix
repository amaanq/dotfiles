{
  system.defaults.dock = {
    autohide = true;
    showhidden = true; # Translucent.

    mouse-over-hilite-stack = true;

    show-recents = false;
    mru-spaces = false;

    tilesize = 48;
    magnification = false;

    enable-spring-load-actions-on-all-items = true;

    persistent-apps = [
      { app = "/Applications/Ghostty.app"; }
      { app = "/Applications/Nix Apps/Thorium.app"; }
      { app = "/Applications/Orion.app"; }
      { app = "~/Applications/Home Manager Apps/Discord.app"; }
      { app = "/Applications/Nix Apps/Spotify.app"; }
      { app = "/Applications/Nix Apps/IINA.app"; }
      { app = "/Applications/Nix Apps/qbittorrent.app"; }
      { app = "/Applications/OrbStack.app"; }
    ];
  };

  system.defaults.CustomSystemPreferences."com.apple.dock" = {
    autohide-time-modifier = 0.0;
    autohide-delay = 0.0;
    expose-animation-duration = 0.0;
    springboard-show-duration = 0.0;
    springboard-hide-duration = 0.0;
    springboard-page-duration = 0.0;

    # Disable hot corners.
    wvous-tl-corner = 0;
    wvous-tr-corner = 0;
    wvous-bl-corner = 0;
    wvous-br-corner = 0;

    launchanim = 0;
  };
}
