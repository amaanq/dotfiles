{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    enabled
    getExe
    mkIf
    ;
in
{
  environment.systemPackages = [
    pkgs.jujutsu
    pkgs.difftastic
  ];

  home-manager.sharedModules = [
    {
      programs.jujutsu = enabled {
        settings = {
          user.name = "amaanq";
          user.email = "amaanq12@gmail.com";

          aliases.".." = [
            "edit"
            "@-"
          ];
          aliases.",," = [
            "edit"
            "@+"
          ];

          aliases.f = [
            "git"
            "fetch"
          ];
          aliases.p = [
            "git"
            "push"
          ];

          aliases.cl = [
            "git"
            "clone"
            "--colocate"
          ];
          aliases.i = [
            "git"
            "init"
            "--colocate"
          ];

          aliases.c = [ "commit" ];
          aliases.e = [ "edit" ];
          aliases.d = [ "diff" ];
          aliases.l = [ "log" ];
          aliases.s = [ "squash" ];

          ui.default-command = "log";
          ui.diff-editor = ":builtin";
          ui.diff-formatter = [
            "${getExe pkgs.difftastic}"
            "--color"
            "always"
            "$left"
            "$right"
          ];

          git.auto-local-bookmark = true;
          git.push-bookmark-prefix = "change-amaanq-";

          signing.backend = mkIf config.isDesktop "ssh";
          signing.behavior = mkIf config.isDesktop "own";
          signing.key = mkIf config.isDesktop "~/.ssh/id";
        };
      };
    }
  ];
}
