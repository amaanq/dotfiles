{
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
    tree = "tree --gitignore --dirsfirst -C";

    c = "clear";
    q = "exit";

    clod = "claude";
  };
}
