{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    enabled
    merge
    mkIf
    ;
  systemConfig = config;
in
{
  environment.systemPackages = [
    pkgs.delta
    pkgs.lazygit
    pkgs.mergiraf
  ];

  home-manager.sharedModules = [
    (
      {
        config,
        ...
      }:
      {
        programs.git = enabled {
          userName = "Amaan Qureshi";
          userEmail = "contact@amaanq.com";

          lfs = enabled;

          extraConfig =
            merge {
              init.defaultBranch = "master";

              color.ui = true;
              core = {
                attributesfile = "${config.xdg.configHome}/git/attributes";
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
            }
            <| mkIf systemConfig.isDesktop {
              # This might need to reference system config
              core.sshCommand = "ssh -i ~/.ssh/id";
              url."ssh://git@github.com/".insteadOf = "https://github.com/";

              commit.gpgSign = true;
              tag.gpgSign = true;

              gpg = {
                format = "ssh";
                ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
              };
              user.signingKey = "~/.ssh/id";
            };

          aliases = {
            st = "status -sb";
            co = "checkout";
            c = "commit --short";
            ci = "commit --short";
            p = "push";
            l = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --decorate --date=short";
          };
        };

        xdg.configFile."git/attributes".text = ''
          * merge=mergiraf
        '';

        xdg.configFile."git/allowed_signers".text = ''
          contact@amaanq.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID+36H8eD4p4waEpgPejhPCNGymi+OSN9fZ5LRUBcOnP
          will.lillis24@gmail.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIYWWRfOsSpi7M6ejCEWHGTtsvOA8v7FiUOBR2If1nVa
        '';
      }
    )

    (mkIf config.isDesktop {
      programs.gh = enabled {
        extensions = [
          pkgs.gh-dash
          pkgs.gh-notify
        ];
        settings.git_protocol = "ssh";
      };
    })
  ];
}
