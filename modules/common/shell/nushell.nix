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
    ;

  package = pkgs.nushell;
in
{
  home-manager.sharedModules = [
    (
      homeArgs:
      let
        config' = homeArgs.config;

        environmentVariables =
          let
            variablesMap =
              config'.variablesMap
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

        shells."0" = package;

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

              source ${pkgs.nu_scripts}/share/nu_scripts/modules/formats/from-env.nu

              if ($env.USER == "amaanq") {
                if ("${config.secrets.openai_api_key.path}" | path exists) {
                  $env.OPENAI_API_KEY = (open ${config.secrets.openai_api_key.path} | str trim)
                }
              }
            '';
        };
      }
    )
  ];
}
