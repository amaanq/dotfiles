{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.bat ];

  environment.variables = {
    MANPAGER = "bat --plain";
    PAGER = "bat --plain";
  };

  environment.shellAliases = {
    cat = "bat";
    less = "bat --plain";
  };
}
