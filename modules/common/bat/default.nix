{ pkgs, ... }:
let
  batCache = pkgs.runCommand "bat-cache" { } ''
    mkdir -p $out/themes
    cp ${./rose-pine.tmTheme} $out/themes/rose-pine.tmTheme
    mkdir -p $out/cache
    XDG_CACHE_HOME=$out/cache ${pkgs.bat}/bin/bat cache --build --source $out
    mv $out/cache/bat $out/bat-cache
  '';
in
{
  wrappers.bat = {
    basePackage = pkgs.bat;
    systemWide = true;
    executables.bat.environment = {
      BAT_CACHE_PATH.value = "${batCache}/bat-cache";
      BAT_THEME.value = "rose-pine";
    };
  };

  environment.variables = {
    MANPAGER = "bat -plman";
    PAGER = "bat --plain";
    BAT_PAGER = "less -RFK";
  };

  environment.shellAliases = {
    cat = "bat";
    less = "bat --plain";
  };
}
