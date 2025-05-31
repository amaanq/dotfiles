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
    getExe
    mkIf
    optionalAttrs
    readFile
    ;
in
{
  environment =
    optionalAttrs config.isLinux {
      sessionVariables.SHELLS = getExe pkgs.nushell;
    }
    // {
      shells = mkIf config.isDarwin [ pkgs.nushell ];

      shellAliases = {
        la = "ls --all";
        ll = "ls --long";
        lla = "ls --long --all";
        sl = "ls";

        cdtmp = "cd (mktemp --directory)";
        cp = "cp --recursive --verbose --progress";
        mk = "mkdir";
        mv = "mv --verbose";
        rm = "rm --recursive --verbose";

        pstree = "pstree -g 2";
        tree = "eza --tree --git-ignore --group-directories-first";

        c = "clear";
        q = "exit";
      };

      systemPackages = attrValues {
        inherit (pkgs)
          fish # For completions.
          nu_scripts # Nushell scripts and completions.
          zoxide # For completions and better cd.
          ;
      };

    };

  home-manager.sharedModules = [
    (
      homeArgs:
      let
        homeConfig = homeArgs.config;
        # Creds: Aylur's conf
        completions =
          let
            completion = name: ''
              source ${pkgs.nu_scripts}/share/nu_scripts/custom-completions/${name}/${name}-completions.nu
            '';
          in
          names: builtins.foldl' (prev: str: "${prev}\n${str}") "" (map completion names);
      in
      {
        xdg.configFile = {
          # TODO(amaanq): *sigh*, figure this out
          # "nushell/atuin.nu".source = pkgs.runCommand "atuin.nu" { } ''
          #   ${getExe pkgs.atuin} init nu --disable-up-arrow > $out
          # '';

          "nushell/zoxide.nu".source = pkgs.runCommand "zoxide.nu" { } ''
            ${getExe pkgs.zoxide} init nushell --cmd cd > $out
          '';

          "nushell/ls_colors.txt".source = pkgs.runCommand "ls_colors.txt" { } ''
            ${getExe pkgs.vivid} generate tokyonight-moon > $out
          '';
        };

        programs.nushell = enabled {
          configFile.text =
            # nu
            ''
              ${completions [
                "bat"
                "cargo"
                "curl"
                "docker"
                "gh"
                "git"
                "just"
                "less"
                "make"
                "man"
                "nix"
                "npm"
                # "rg" - breaks with the alias
                "rustup"
                "ssh"
                "tar"
                "typst"
                "uv"
                "virsh"
              ]}
              ${readFile ./config.nu}

              source ${pkgs.nu_scripts}/share/nu_scripts/modules/formats/from-env.nu
            '';
          envFile.text =
            let
              nuScriptsPath = "${pkgs.nu_scripts}/share/nu_scripts";
              baseEnv = readFile ./env.nu;
            in
            # nu
            ''
              ${baseEnv}

              # Add nu_scripts to library paths
              $env.NU_LIB_DIRS = (
                $env.NU_LIB_DIRS | append "${nuScriptsPath}"
              )
            '';

          environmentVariables =
            let
              environmentVariables = config.environment.variables;

              homeVariables = homeConfig.home.sessionVariables;
              homeVariablesExtra = { };
            in
            environmentVariables
            // homeVariables
            // homeVariablesExtra
            // {
              PROMPT_INDICATOR = " ";
              PROMPT_INDICATOR_VI_INSERT = "❯ ";
              PROMPT_INDICATOR_VI_NORMAL = ": ";
              PROMPT_MULTILINE_INDICATOR = "::: ";
            };

          shellAliases = removeAttrs config.environment.shellAliases [
            "ls"
            "l"
          ];
        };
      }
    )
  ];
}
