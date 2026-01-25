{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrNames
    attrValues
    const
    enabled
    filterAttrs
    flatten
    listToAttrs
    mapAttrs
    mapAttrsToList
    readFile
    replaceStrings
    theme
    ;

  colors = theme.withHashtag;
  package = pkgs.nushell;
in
{
  home-manager.sharedModules = [
    (
      homeArgs:
      let
        config' = homeArgs.config;

        baseVariablesMap = {
          HOME = config'.home.homeDirectory;
          USER = config'.home.username;
          XDG_CACHE_HOME = config'.xdg.cacheHome;
          XDG_CONFIG_HOME = config'.xdg.configHome;
          XDG_DATA_HOME = config'.xdg.dataHome;
          XDG_STATE_HOME = config'.xdg.stateHome;
        };

        environmentVariables =
          let
            variablesMap =
              baseVariablesMap
              |> mapAttrsToList (
                name: value: [
                  {
                    name = "\$${name}";
                    inherit value;
                  }
                  {
                    name = "\${${name}}";
                    inherit value;
                  }
                ]
              )
              |> flatten
              |> listToAttrs;
          in
          config.environment.variables
          |> mapAttrs (const <| replaceStrings (attrNames variablesMap) (attrValues variablesMap))
          |> filterAttrs (name: const <| name != "TERM" && name != "XDG_DATA_DIRS");
      in
      {
        home.shell.enableNushellIntegration = true;

        programs.nushell = enabled {
          inherit package;

          inherit environmentVariables;

          shellAliases = config.environment.shellAliases |> filterAttrs (_: value: value != null);

          configFile.text =
            let
              completions =
                let
                  completion = name: ''
                    source ${pkgs.nu_scripts}/share/nu_scripts/custom-completions/${name}/${name}-completions.nu
                  '';
                in
                names: builtins.foldl' (prev: str: "${prev}\n${str}") "" (map completion names);

              nuScriptsPath = "${pkgs.nu_scripts}/share/nu_scripts";
            in
            # nu
            ''
              # Add nu_scripts to library paths
              $env.NU_LIB_DIRS = (
                $env.NU_LIB_DIRS | append "${nuScriptsPath}"
              )

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
              ${readFile ./nushell.nu}

              use ${pkgs.nu_scripts}/share/nu_scripts/modules/capture-foreign-env
              source ${pkgs.nu_scripts}/share/nu_scripts/modules/formats/from-env.nu

              # zoxide
              source ${
                pkgs.runCommand "zoxide.nu" { } ''${pkgs.zoxide}/bin/zoxide init nushell --cmd cd >> "$out"''
              }

              # carapace
              source ${
                pkgs.runCommand "carapace.nu" { }
                  ''${pkgs.carapace}/bin/carapace _carapace nushell | sed 's|"/homeless-shelter|$"($env.HOME)|g' >> "$out"''
              }

              # direnv
              $env.config = ($env.config? | default {})
              $env.config.hooks = ($env.config.hooks? | default {})
              $env.config.hooks.pre_prompt = (
                  $env.config.hooks.pre_prompt?
                  | default []
                  | append {||
                      ${pkgs.direnv}/bin/direnv export json
                      | from json --strict
                      | default {}
                      | items {|key, value|
                          let value = do (
                              {
                                "PATH": {
                                  from_string: {|s| $s | split row (char esep) | path expand --no-symlink }
                                  to_string: {|v| $v | path expand --no-symlink | str join (char esep) }
                                }
                              }
                              | merge ($env.ENV_CONVERSIONS? | default {})
                              | get ([[value, optional, insensitive]; [$key, true, true] [from_string, true, false]] | into cell-path)
                              | if ($in | is-empty) { {|x| $x} } else { $in }
                          ) $value
                          return [ $key $value ]
                      }
                      | into record
                      | load-env
                  }
              )

              # atuin
              source ${
                pkgs.runCommand "atuin.nu" {
                  nativeBuildInputs = [ pkgs.writableTmpDirAsHomeHook ];
                } ''${pkgs.atuin}/bin/atuin init nu --disable-up-arrow >> "$out"''
              }

              if ($env.USER == "amaanq") {
                if ("${config.secrets.openai_api_key.path}" | path exists) {
                  $env.OPENAI_API_KEY = (open ${config.secrets.openai_api_key.path} | str trim)
                }
              }

              # Rose Pine theme
              $env.config.color_config = {
                separator: "${colors.base03}"
                leading_trailing_space_bg: "${colors.base04}"
                header: "${colors.base0B}"
                date: "${colors.base0E}"
                filesize: "${colors.base0D}"
                row_index: "${colors.base0C}"
                bool: "${colors.base08}"
                int: "${colors.base0B}"
                duration: "${colors.base08}"
                range: "${colors.base08}"
                float: "${colors.base08}"
                string: "${colors.base04}"
                nothing: "${colors.base08}"
                binary: "${colors.base08}"
                cellpath: "${colors.base08}"
                hints: dark_gray

                shape_garbage: { fg: "${colors.base07}" bg: "${colors.base08}" }
                shape_bool: "${colors.base0D}"
                shape_int: { fg: "${colors.base0E}" attr: b }
                shape_float: { fg: "${colors.base0E}" attr: b }
                shape_range: { fg: "${colors.base0A}" attr: b }
                shape_internalcall: { fg: "${colors.base0C}" attr: b }
                shape_external: "${colors.base0C}"
                shape_externalarg: { fg: "${colors.base0B}" attr: b }
                shape_literal: "${colors.base0D}"
                shape_operator: "${colors.base0A}"
                shape_signature: { fg: "${colors.base0B}" attr: b }
                shape_string: "${colors.base0B}"
                shape_filepath: "${colors.base0D}"
                shape_globpattern: { fg: "${colors.base0D}" attr: b }
                shape_variable: "${colors.base0E}"
                shape_flag: { fg: "${colors.base0D}" attr: b }
                shape_custom: { attr: b }
              }
            '';
        };
      }
    )
  ];
}
