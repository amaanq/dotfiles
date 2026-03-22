{
  config,
  jj-src,
  pkgs,
  ...
}:
let
  tomlFormat = pkgs.formats.toml { };
  graphStyle = if config.theme.cornerRadius > 0 then "curved" else "square";

  settings = {
    user = {
      name = "Amaan Qureshi";
      email = "git@amaanq.com";
    };

    aliases = {
      # navigation
      ".." = [
        "edit"
        "@-"
      ];
      ",," = [
        "edit"
        "@+"
      ];
      e = [ "edit" ];
      n = [ "new" ];

      # info
      d = [ "diff" ];
      ds = [
        "diff"
        "--stat"
      ];
      id = [ "interdiff" ];
      l = [ "log" ];
      la = [
        "log"
        "--revisions"
        "::"
      ];
      lp = [
        "log"
        "--patch"
      ];
      lpa = [
        "log"
        "--patch"
        "--revisions"
        "::"
      ];
      ls = [
        "log"
        "--summary"
      ];
      lsa = [
        "log"
        "--summary"
        "--revisions"
        "::"
      ];
      ol = [
        "op"
        "log"
      ];
      sh = [ "show" ];
      st = [ "status" ];

      # rewriting
      a = [ "abandon" ];
      ab = [ "absorb" ];
      c = [ "commit" ];
      ci = [
        "commit"
        "--interactive"
      ];
      de = [ "describe" ];
      r = [ "rebase" ];
      s = [ "squash" ];
      si = [
        "squash"
        "--interactive"
      ];
      sp = [ "split" ];
      u = [ "undo" ];

      # bookmarks
      bl = [
        "bookmark"
        "list"
      ];
      bs = [
        "bookmark"
        "set"
      ];
      t = [ "tug" ];
      tug = [
        "bookmark"
        "move"
        "--from"
        "closest(@-)"
        "--to"
        "closest_pushable(@)"
      ];

      # conflicts
      res = [ "resolve" ];
      resa = [ "resolve-ast" ];
      resolve-ast = [
        "resolve"
        "--tool"
        "mergiraf"
      ];

      # git
      cl = [
        "git"
        "clone"
      ];
      clone = [
        "git"
        "clone"
      ];
      f = [
        "git"
        "fetch"
      ];
      fa = [
        "git"
        "fetch"
        "--all-remotes"
      ];
      fetch = [
        "git"
        "fetch"
      ];
      i = [
        "git"
        "init"
      ];
      init = [
        "git"
        "init"
      ];
      p = [
        "git"
        "push"
      ];
      push = [
        "git"
        "push"
      ];

      # workspaces
      wa = [
        "workspace"
        "add"
      ];
      wf = [
        "workspace"
        "forget"
      ];
      wl = [
        "workspace"
        "list"
      ];
    };

    revset-aliases = {
      "closest(to)" = "heads(::to & bookmarks())";
      "closest_pushable(to)" = ''heads(::to & ~description(exact:"") & (~empty() | merges()))'';
      "immutable_heads()" = "trunk() & ~mine()";
    };

    revsets = {
      log = "present(@) | present(trunk()) | ancestors(remote_bookmarks().. | @.., 8)";
    };

    ui = {
      default-command = "ls";
      diff-editor = ":builtin";
      diff-formatter = [ "delta" ];
      conflict-marker-style = "snapshot";
      graph = {
        style = graphStyle;
      };
    };

    colors = {
      "diff token" = {
        underline = false;
      };
    };

    templates = {
      draft_commit_description = ''
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
      git_push_bookmark = ''"change-amaanq-" ++ change_id.short()'';
    };

    remotes = {
      "*" = {
        auto-track-bookmarks = "glob:*";
        push-new-bookmarks = true;
      };
    };

    snapshot = {
      auto-update-stale = true;
    };

    git = {
      fetch = [
        "origin"
        "upstream"
        "rad"
      ];
      push = "origin";
    };
  }
  // (
    if config.isDesktop then
      {
        signing = {
          backend = "ssh";
          behavior = "own";
          key = "~/.ssh/id";
        };
      }
    else
      { }
  );
in
{
  environment.systemPackages = [
    pkgs.difftastic
    jj-src.packages.${pkgs.system}.jujutsu
    pkgs.mergiraf
    pkgs.radicle-node
  ];

  environment.variables = {
    JJ_CONFIG = "/etc/jj/config.toml";
    RAD_HOME = "$XDG_DATA_HOME/radicle";
  };

  environment.etc."jj/config.toml".source = tomlFormat.generate "jj-config" settings;
}
