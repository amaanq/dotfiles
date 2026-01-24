{ pkgs, ... }:
let
  # Bat with rose-pine theme baked in
  batWithTheme = pkgs.symlinkJoin {
    name = "bat-with-theme";
    paths = [ pkgs.bat ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm $out/bin/bat
      mkdir -p $out/share/bat/themes
      cp ${./rose-pine.tmTheme} $out/share/bat/themes/rose-pine.tmTheme

      # Build cache with theme
      mkdir -p $out/cache
      XDG_CACHE_HOME=$out/cache ${pkgs.bat}/bin/bat cache --build --source $out/share/bat

      makeWrapper ${pkgs.bat}/bin/bat $out/bin/bat \
        --set BAT_CACHE_PATH $out/cache/bat \
        --set BAT_THEME rose-pine
    '';
    inherit (pkgs.bat) meta;
  };
in
{
  environment.systemPackages = [ batWithTheme ];

  environment.variables = {
    MANPAGER = "bat --plain";
    PAGER = "bat --plain";
  };

  environment.shellAliases = {
    cat = "bat";
    less = "bat --plain";
  };
}
