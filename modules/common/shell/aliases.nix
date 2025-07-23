{
  secrets.openai_api_key = {
    file = ./openai-key.age;
    owner = "amaanq";
  };

  secrets.anthropic_api_key = {
    file = ./anthropic-key.age;
    owner = "amaanq";
  };

  environment.shellAliases = {
    la = "ls --all";
    l = "ls --long";
    lla = "ls --long --all";
    sl = "ls";

    cdtmp = "cd (mktemp --directory)";
    cp = "cp --recursive --verbose --progress";
    mk = "mkdir";
    mv = "mv --verbose";
    rm = "rm --recursive --verbose";

    pstree = "pstree -g 3";
    tree = "eza --tree --git-ignore --group-directories-first";

    c = "clear";
    q = "exit";
  };
}
