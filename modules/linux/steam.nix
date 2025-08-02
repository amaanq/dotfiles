{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    enabled
    merge
    mkIf
    ;

  # Override r2modman to version 3.2.1
  r2modman-updated = pkgs.r2modman.overrideAttrs (oldAttrs: {
    version = "3.2.1";
    src = pkgs.fetchFromGitHub {
      owner = "ebkr";
      repo = "r2modmanPlus";
      rev = "v3.2.1";
      hash = "sha256-l1xrp+Gl26kiWqh5pIKp4QiETrzr5mTrUP10T0DhUCw=";
    };
    offlineCache = pkgs.fetchYarnDeps {
      yarnLock = "${
        pkgs.fetchFromGitHub {
          owner = "ebkr";
          repo = "r2modmanPlus";
          rev = "v3.2.1";
          hash = "sha256-l1xrp+Gl26kiWqh5pIKp4QiETrzr5mTrUP10T0DhUCw=";
        }
      }/yarn.lock";
      hash = "sha256-HLVHxjyymi0diurVamETrfwYM2mkUrIOHhbYCrqGkeg=";
    };
  });
in
merge
<| mkIf config.isDesktop {
  unfree.allowedNames = [
    "steam"
    "steam-unwrapped"
  ];

  programs.gamemode = enabled;

  # Steam uses 32-bit drivers for some unholy fucking reason.
  hardware.graphics.enable32Bit = true;
  environment.systemPackages = [
    pkgs.steam
    pkgs.mangohud
    r2modman-updated
  ];
}
