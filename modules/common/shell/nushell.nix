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
    concatStringsSep
    const
    enabled
    filter
    filterAttrs
    flatten
    foldl'
    head
    last
    listToAttrs
    mapAttrs
    mapAttrsToList
    match
    nameValuePair
    readFile
    removeAttrs
    replaceStrings
    splitString
    ;

  package = pkgs.nushell;
in
{
  shells."0" = package;

  home-manager.sharedModules = [
    (
      homeArgs:
      let
        config' = homeArgs.config;
        completions =
          let
            completion = name: ''
              source ${pkgs.nu_scripts}/share/nu_scripts/custom-completions/${name}/${name}-completions.nu
            '';
          in
          names: builtins.foldl' (prev: str: "${prev}\n${str}") "" (map completion names);

        environmentVariables =
          let
            variablesMap =
              {
                HOME = config'.home.homeDirectory;
                USER = config'.home.username;

                XDG_CACHE_HOME = config'.xdg.cacheHome;
                XDG_CONFIG_HOME = config'.xdg.configHome;
                XDG_DATA_HOME = config'.xdg.dataHome;
                XDG_STATE_HOME = config'.xdg.stateHome;
              }
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

            environmentVariables = config.environment.variables;

            homeVariables = config'.home.sessionVariables;

            homeVariablesExtra =
              pkgs.runCommand "home-variables-extra.env" { } ''
                bash -ic '
                  ${
                    variablesMap |> mapAttrsToList (name: value: "export ${name}='${value}'") |> concatStringsSep "\n"
                  }

                  alias export=echo
                  source ${config'.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh
                ' > $out
              ''
              |> readFile
              |> splitString "\n"
              |> filter (s: s != "")
              |> map (match "([^=]+)=(.*)")
              |> map (keyAndValue: nameValuePair (head keyAndValue) (last keyAndValue))
              |> foldl' (x: y: x // y) { };

            homeSearchVariables =
              config'.home.sessionSearchVariables |> mapAttrs (const <| concatStringsSep ":");
          in
          environmentVariables // homeVariables // homeVariablesExtra // homeSearchVariables
          |> mapAttrs (name: value: toString value) # Convert ALL values to strings first
          |> mapAttrs (const <| replaceStrings (attrNames variablesMap) (attrValues variablesMap))
          |> filterAttrs (name: const <| name != "TERM");

      in
      {
        home.shell.enableNushellIntegration = true;

        programs.nushell = enabled {
          inherit package;

          shellAliases = removeAttrs config.environment.shellAliases [
            "ls"
            "l"
          ];
          inherit environmentVariables;

          configFile.text =
            let
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

              source ${pkgs.nu_scripts}/share/nu_scripts/modules/formats/from-env.nu

              $env.OPENAI_API_KEY = (open ${config.secrets.openai_api_key.path} | str trim)
              $env.ANTHROPIC_API_KEY = (open ${config.secrets.anthropic_api_key.path} | str trim)
            '';
        };
      }
    )
  ];
}
