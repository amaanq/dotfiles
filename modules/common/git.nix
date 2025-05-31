{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrValues
    enabled
    mkIf
    optionalAttrs
    ;
in
{
  environment.systemPackages =
    attrValues
    <| optionalAttrs config.isDesktop {
      inherit (pkgs)
        delta
        lazygit
        mergiraf
        ;
    };

  home-manager.sharedModules = [
    {
      programs.git = enabled {
        userName = "Amaan Qureshi";
        userEmail = "amaanq12@gmail.com";

        signing = {
          key = "FCC13F47A6900D64239FF13BE67890ADC4227273";
          signByDefault = true;
        };

        lfs.enable = true;

        extraConfig = {
          init.defaultBranch = "master";

          color.ui = true;
          commit.gpgsign = true;
          core = {
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

          merge.conflictstyle = "zdiff3";

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
    }

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
