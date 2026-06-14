{
  homebrew-core,
  homebrew-cask,
  config,
  lib,
  ...
}:
let
  inherit (lib) enabled;
in
{
  homebrew = enabled {
    global.autoUpdate = false;
    onActivation.extraEnv.HOMEBREW_NO_ANALYTICS = "1";
  };

  environment.variables.HOMEBREW_NO_ANALYTICS = "1";

  nix-homebrew = enabled {
    user = config.system.primaryUser;

    taps."homebrew/homebrew-core" = homebrew-core;
    taps."homebrew/homebrew-cask" = homebrew-cask;

    mutableTaps = false;
  };
}
