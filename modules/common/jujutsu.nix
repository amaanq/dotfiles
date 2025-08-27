{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled mkIf;
in
{
  environment.systemPackages = [
    pkgs.difftastic
    pkgs.jjui
    pkgs.mergiraf
    pkgs.radicle-node
  ];

  home-manager.sharedModules = [
    {
      programs.jujutsu = enabled {
        settings = {
          user.name = "Amaan Qureshi";
          user.email = "contact@amaanq.com";

          aliases.".." = [
            "edit"
            "@-"
          ];
          aliases.",," = [
            "edit"
            "@+"
          ];

          aliases.fetch = [
            "git"
            "fetch"
          ];
          aliases.f = [
            "git"
            "fetch"
          ];

          aliases.push = [
            "git"
            "push"
          ];
          aliases.p = [
            "git"
            "push"
          ];

          aliases.clone = [
            "git"
            "clone"
            "--colocate"
          ];
          aliases.cl = [
            "git"
            "clone"
            "--colocate"
          ];

          aliases.init = [
            "git"
            "init"
            "--colocate"
          ];
          aliases.i = [
            "git"
            "init"
            "--colocate"
          ];

          aliases.a = [ "abandon" ];

          aliases.c = [ "commit" ];
          aliases.ci = [
            "commit"
            "--interactive"
          ];

          aliases.d = [ "diff" ];

          aliases.e = [ "edit" ];

          aliases.l = [ "log" ];
          aliases.la = [
            "log"
            "--revisions"
            "::"
          ];
          aliases.ls = [
            "log"
            "--summary"
          ];
          aliases.lsa = [
            "log"
            "--summary"
            "--revisions"
            "::"
          ];
          aliases.lp = [
            "log"
            "--patch"
          ];
          aliases.lpa = [
            "log"
            "--patch"
            "--revisions"
            "::"
          ];

          aliases.r = [ "rebase" ];

          aliases.res = [ "resolve" ];

          aliases.resolve-ast = [
            "resolve"
            "--tool"
            "mergiraf"
          ];
          aliases.resa = [ "resolve-ast" ];

          aliases.s = [ "squash" ];
          aliases.si = [
            "squash"
            "--interactive"
          ];

          aliases.sh = [ "show" ];

          aliases.tug = [
            "bookmark"
            "move"
            "--from"
            "closest(@-)"
            "--to"
            "closest_pushable(@)"
          ];
          aliases.t = [ "tug" ];

          aliases.u = [ "undo" ];

          revset-aliases."closest(to)" = "heads(::to & bookmarks())";
          revset-aliases."closest_pushable(to)" =
            "heads(::to & ~description(exact:\"\") & (~empty() | merges()))";

          revsets.log = "present(@) | present(trunk()) | ancestors(remote_bookmarks().. | @.., 8)";

          ui.default-command = "ls";

          ui.diff-editor = ":builtin";
          ui.diff-formatter = [
            "difft"
            "--color"
            "always"
            "$left"
            "$right"
          ];

          ui.conflict-marker-style = "snapshot";
          ui.graph.style = if config.theme.cornerRadius > 0 then "curved" else "square";

          templates.draft_commit_description = # python
            ''
              concat(
                coalesce(description, "\n"),
                surround(
                  "\nJJ: This commit contains the following changes:\n", "",
                  indent("JJ:     ", diff.stat(72)),
                ),
                "\nJJ: ignore-rest\n",
                diff.git(),
              )
            '';

          templates.git_push_bookmark = # python
            ''
              "change-amaanq-" ++ change_id.short()
            '';

          git.auto-local-bookmark = true;

          git.fetch = [
            "origin"
            "upstream"
            "rad"
          ];
          git.push = "origin";

          signing.backend = mkIf config.isDesktop "ssh";
          signing.behavior = mkIf config.isDesktop "own";
          signing.key = mkIf config.isDesktop "~/.ssh/id";
        };
      };
    }
  ];
}
