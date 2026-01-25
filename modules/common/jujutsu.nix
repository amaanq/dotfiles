{
  config,
  pkgs,
  ...
}:
let
  graphStyle = if config.theme.cornerRadius > 0 then "curved" else "square";
  signingConfig =
    if config.isDesktop then
      ''
        [signing]
        backend = "ssh"
        behavior = "own"
        key = "~/.ssh/id"
      ''
    else
      "";
in
{
  environment.systemPackages = [
    pkgs.difftastic
    pkgs.jjui
    pkgs.jujutsu
    pkgs.mergiraf
    pkgs.radicle-node
  ];

  environment.variables.JJ_CONFIG = "/etc/jj/config.toml";

  environment.etc."jj/config.toml".text = ''
    [user]
    name = "Amaan Qureshi"
    email = "git@amaanq.com"

    [aliases]
    ".." = ["edit", "@-"]
    ",," = ["edit", "@+"]
    fetch = ["git", "fetch"]
    f = ["git", "fetch"]
    push = ["git", "push"]
    p = ["git", "push"]
    clone = ["git", "clone", "--colocate"]
    cl = ["git", "clone", "--colocate"]
    init = ["git", "init", "--colocate"]
    i = ["git", "init", "--colocate"]
    a = ["abandon"]
    c = ["commit"]
    ci = ["commit", "--interactive"]
    d = ["diff"]
    e = ["edit"]
    l = ["log"]
    la = ["log", "--revisions", "::"]
    ls = ["log", "--summary"]
    lsa = ["log", "--summary", "--revisions", "::"]
    lp = ["log", "--patch"]
    lpa = ["log", "--patch", "--revisions", "::"]
    r = ["rebase"]
    res = ["resolve"]
    resolve-ast = ["resolve", "--tool", "mergiraf"]
    resa = ["resolve-ast"]
    s = ["squash"]
    si = ["squash", "--interactive"]
    sh = ["show"]
    tug = ["bookmark", "move", "--from", "closest(@-)", "--to", "closest_pushable(@)"]
    t = ["tug"]
    u = ["undo"]

    [revset-aliases]
    "closest(to)" = "heads(::to & bookmarks())"
    "closest_pushable(to)" = "heads(::to & ~description(exact:\"\") & (~empty() | merges()))"

    [revsets]
    log = "present(@) | present(trunk()) | ancestors(remote_bookmarks().. | @.., 8)"

    [ui]
    default-command = "ls"
    diff-editor = ":builtin"
    diff-formatter = ["difft", "--color", "always", "$left", "$right"]
    conflict-marker-style = "snapshot"

    [ui.graph]
    style = "${graphStyle}"

    [templates]
    draft_commit_description = """
    concat(
      coalesce(description, "\n"),
      surround(
        "\nJJ: This commit contains the following changes:\n", "",
        indent("JJ:     ", diff.stat(72)),
      ),
      "\nJJ: ignore-rest\n",
      diff.git(),
    )
    """
    git_push_bookmark = '"change-amaanq-" ++ change_id.short()'

    [remotes.origin]
    auto-track-bookmarks = "glob:*"

    [git]
    fetch = ["origin", "upstream", "rad"]
    push = "origin"

    ${signingConfig}
  '';
}
