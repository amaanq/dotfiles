{ lib, ... }:
let
  inherit (lib) enabled;
in
{
  environment.variables = {
    MANPAGER = "bat --plain";
    PAGER = "bat --plain";
  };
  environment.shellAliases = {
    cat = "bat";
    less = "bat --plain";
  };

  home-manager.sharedModules = [
    {
      programs.bat = enabled {
        config.pager = "less -FR";
      };
    }
  ];
}
