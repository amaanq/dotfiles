{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    const
    filter
    foldl'
    getExe
    head
    last
    mapAttrs
    mapAttrsToList
    match
    mkConst
    mkIf
    nameValuePair
    readFile
    splitString
    ;
in
{
  environment.shells = [ pkgs.nushell ];

  environment.systemPackages = [
    pkgs.nu_scripts # Nushell scripts and completions.
  ];

  home-manager.sharedModules = [
    (
      homeArgs:
      let
        config' = homeArgs.config;
      in
      {
        options.variablesMap = mkConst {
          HOME = config'.home.homeDirectory;
          USER = config'.home.username;

          XDG_CACHE_HOME = config'.xdg.cacheHome;
          XDG_CONFIG_HOME = config'.xdg.configHome;
          XDG_DATA_HOME = config'.xdg.dataHome;
          XDG_STATE_HOME = config'.xdg.stateHome;
        };
      }
    )

    (mkIf config.isDarwin (
      homeArgs:
      let
        config' = homeArgs.config;

        homeSessionVariables =
          let
            homeSessionVariables = config'.home.sessionVariables;

            homeSessionVariablesExtra =
              pkgs.runCommand "home-variables-extra.env" { } ''
                bash -ic '
                  ${
                    config'.variablesMap
                    |> mapAttrsToList (name: value: "export ${name}='${value}'")
                    |> concatStringsSep "\n"
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

            homeSessionSearchVariables =
              config'.home.sessionSearchVariables |> mapAttrs (const <| concatStringsSep ":");
          in
          homeSessionVariables // homeSessionVariablesExtra // homeSessionSearchVariables;
      in
      {
        home.file.".zshrc".text =
          mkIf config.isDarwin # zsh
            ''
              ${
                homeSessionVariables
                |> mapAttrsToList (name: value: "export ${name}='${value}'")
                |> concatStringsSep "\n"
              }
              SHELL='${getExe pkgs.nushell}' exec "$SHELL"
            '';
      }
    ))
  ];
}
