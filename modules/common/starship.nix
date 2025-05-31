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
    ;
in
{
  environment = {
    variables.STARSHIP_LOG = "error";
  };

  home-manager.sharedModules = [
    {
      xdg.configFile = {
        "nushell/starship.nu".source = pkgs.runCommand "starship.nu" { } ''
          ${getExe pkgs.starship} init nu > $out
        '';
      };

      programs.starship = enabled {
        # No because we are doing it at build time instead of the way
        # this retarded module does it. Why the hell do you generate
        # the config every time the shell is launched?
        enableNushellIntegration = false;

        settings = {
          vcs.disabled = false;

          command_timeout = 100;
          scan_timeout = 20;

          package.disabled = config.isServer;

          character.error_symbol = "";
          character.success_symbol = "";

          format = "$all$fill$time$line_break";

          aws.symbol = "  ";

          battery = {
            full_symbol = "🔋";
            charging_symbol = "🔌";
            discharging_symbol = "⚡";
            display = [
              {
                threshold = 20;
                style = "bold red";
              }
            ];
          };

          buf.symbol = " ";

          c = {
            symbol = " ";
            format = "[$symbol$version]($style) ";
            commands = [
              [
                "clang"
                "--version"
              ]
            ];
          };

          conda.symbol = " ";

          dart.symbol = " ";

          directory = {
            read_only = " ";
            read_only_style = "red";
            truncation_length = 5;
            truncate_to_repo = false;
            format = "[$path]($style)[$lock_symbol]($lock_style) ";
          };

          docker_context.symbol = " ";

          dotnet = {
            symbol = " ";
            format = "[$symbol$version]($style) ";
          };

          elixir.symbol = " ";

          elm.symbol = " ";

          git_branch = {
            symbol = " ";
            style = "bold green";
          };

          git_commit = {
            commit_hash_length = 7;
            style = "bold white";
          };

          git_state.format = ''[\($state( $progress_current of $progress_total)\)]($style) '';

          git_status = {
            conflicted = "⚔️ \${count} ";
            ahead = "⇡\${count} ";
            behind = "⇣\${count} ";
            diverged = "⇕ ⇡\${ahead_count} ⇣\${behind_count} ";
            untracked = "?\${count} ";
            stashed = "\\$\${count} ";
            modified = "!\${count} ";
            staged = "+\${count} ";
            renamed = "»\${count} ";
            deleted = "✘\${count} ";
            format = ''([$all_status$ahead_behind]($style))'';
          };

          golang = {
            symbol = " ";
            format = "[$symbol$version]($style) ";
          };

          gradle = {
            symbol = " ";
            format = "[$symbol$version]($style) ";
          };

          haskell = {
            symbol = " ";
            format = "[$symbol$version]($style) ";
          };

          hostname.disabled = true;

          hg_branch.symbol = " ";

          java = {
            symbol = " ";
            format = "[$symbol$version]($style) ";
          };

          julia = {
            symbol = " ";
            format = "[$symbol$version]($style) ";
          };

          kotlin = {
            symbol = "󱈙 ";
            format = "[$symbol$version]($style) ";
          };

          lua = {
            symbol = " ";
            format = "[$symbol$version]($style) ";
          };

          memory_usage = {
            disabled = false;
            symbol = " ";
            format = "$symbol[\${ram}( | \${swap})]($style) ";
            threshold = 70;
          };

          nim.symbol = " ";

          nodejs = {
            symbol = " ";
            format = "[$symbol$version]($style) ";
          };

          php = {
            symbol = " ";
            format = "[$symbol$version]($style) ";
          };

          python = {
            symbol = " ";
            format = "[$symbol$version]($style) ";
          };

          rlang.symbol = "ﳒ ";

          ruby.symbol = " ";

          rust = {
            symbol = " ";
            format = "[$symbol$version]($style) ";
          };

          spack.symbol = "🅢 ";

          swift = {
            symbol = "󰛥 ";
            format = "[$symbol$version]($style) ";
          };

          time = {
            disabled = false;
            use_12hr = true;
            style = "bold bright-black";
            format = "$time($style) ";
          };

          username.style_user = "bold dimmed blue";

          fill.symbol = " ";
        };
      };
    }
  ];
}
