{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    generators
    merge
    mkIf
    ;

  iniFormat = pkgs.formats.gitIni { };

  gitConfig = {
    user = {
      name = "Amaan Qureshi";
      email = "git@amaanq.com";
    };

    init.defaultBranch = "master";

    color.ui = true;
    core = {
      attributesfile = "/etc/git/attributes";
      pager = "delta";
      preloadindex = true;
      untrackedcache = true;
    };
    credential.helper = "cache";

    delta = {
      navigate = true;
      light = false;
      side-by-side = false;
      line-numbers = true;
      # https://github.com/folke/tokyonight.nvim/blob/main/extras/delta/tokyonight_moon.gitconfig
      minus-style = "syntax \"#3a273a\"";
      minus-non-emph-style = "syntax \"#3a273a\"";
      minus-emph-style = "syntax \"#6b2e43\"";
      minus-empty-line-marker-style = "syntax \"#3a273a\"";
      line-numbers-minus-style = "\"#e26a75\"";
      plus-style = "syntax \"#273849\"";
      plus-non-emph-style = "syntax \"#273849\"";
      plus-emph-style = "syntax \"#305f6f\"";
      plus-empty-line-marker-style = "syntax \"#273849\"";
      line-numbers-plus-style = "\"#b8db87\"";
      line-numbers-zero-style = "\"#3b4261\"";
    };

    diff = {
      colorMoved = "default";
      context = 5;
    };

    github.user = "amaanq";

    interactive.diffFilter = "delta --color-only";

    log.showSignature = true;

    merge = {
      conflictStyle = "diff3";
      mergiraf = {
        name = "mergiraf";
        driver = "mergiraf merge --git %O %A %B -s %S -x %X -y %Y -p %P -l %L";
      };
    };

    pull.rebase = true;
    push.autoSetupRemote = true;

    rebase = {
      autoSquash = true;
      autoStash = true;
      preserveMerges = true;
      updateRefs = true;
    };
    rerere.enabled = true;

    fetch.fsckObjects = true;
    fetch.prune = true;
    receive.fsckObjects = true;
    transfer.fsckobjects = true;

    alias = {
      st = "status -sb";
      co = "checkout";
      c = "commit --short";
      ci = "commit --short";
      p = "push";
      l = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --decorate --date=short";
    };
  };

  desktopGitConfig = {
    core.sshCommand = "ssh -i ~/.ssh/id";
    url."ssh://git@github.com/".insteadOf = "https://github.com/";

    commit.gpgSign = true;
    tag.gpgSign = true;

    gpg = {
      format = "ssh";
      program = toString (pkgs.writeShellScript "no-gpg" "exit 1");
      ssh.allowedSignersFile = "/etc/git/allowed_signers";
    };
    user.signingKey = "~/.ssh/id";
  };

  ghConfig = {
    git_protocol = "ssh";
  };
in
merge {
  environment.systemPackages = [
    pkgs.delta
    pkgs.difftastic
    pkgs.git
    pkgs.lazygit
    pkgs.mergiraf
  ];

  environment.etc."git/config".source = iniFormat.generate "gitconfig" gitConfig;
  environment.etc."git/attributes".text = "* merge=mergiraf\n";
  environment.etc."git/allowed_signers".text = ''
    git@amaanq.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID+36H8eD4p4waEpgPejhPCNGymi+OSN9fZ5LRUBcOnP
    will.lillis24@gmail.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIYWWRfOsSpi7M6ejCEWHGTtsvOA8v7FiUOBR2If1nVa
  '';

  environment.variables.GIT_CONFIG_GLOBAL = "/etc/git/config";
}
<| mkIf config.isDesktop {
  environment.etc."git/config-desktop".source =
    iniFormat.generate "gitconfig-desktop" desktopGitConfig;

  # Include desktop config in main config
  environment.etc."git/config".source = lib.mkForce (
    iniFormat.generate "gitconfig" (
      gitConfig
      // {
        include.path = "/etc/git/config-desktop";
      }
    )
  );

  environment.systemPackages = [
    pkgs.gh
    pkgs.gh-dash
    pkgs.gh-notify
  ];

  environment.etc."gh/config.yml".text = generators.toYAML { } ghConfig;
  environment.variables.GH_CONFIG_DIR = "/etc/gh";
}
