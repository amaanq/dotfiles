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
    filterAttrs
    flatten
    getExe
    listToAttrs
    mapAttrs
    mapAttrsToList
    optionals
    readFile
    replaceStrings
    theme
    ;

  colors = theme.withHashtag;

  baseVariablesMap = {
    HOME = "($env.HOME)";
    USER = "($env.USER)";
    XDG_CACHE_HOME = "($env.XDG_CACHE_HOME)";
    XDG_CONFIG_HOME = "($env.XDG_CONFIG_HOME)";
    XDG_DATA_HOME = "($env.XDG_DATA_HOME)";
    XDG_STATE_HOME = "($env.XDG_STATE_HOME)";
  };

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

  environmentVariables =
    config.environment.variables
    |> mapAttrs (const <| replaceStrings (attrNames variablesMap) (attrValues variablesMap))
    |> filterAttrs (name: const <| name != "TERM" && name != "XDG_DATA_DIRS");

  shellAliases = config.environment.shellAliases |> filterAttrs (_: value: value != null);

  # cade's own nushell hook
  cadeHook =
    pkgs.runCommand "cade-hook.nu" { }
      ''${getExe config.programs.cade.package} --config ${
        (pkgs.formats.toml { }).generate "cade-config.toml" { verbosity = "normal"; }
      } hook nushell >> "$out"'';

  configNu =
    pkgs.writeText "config.nu" # nu
      ''
        # Base variables first (XDG dirs, HOME, USER) so that subsequent
        # variables can reference them over SSH where /etc/profile isn't sourced
        ${
          environmentVariables
          |> filterAttrs (name: const <| baseVariablesMap ? ${name})
          |> mapAttrsToList (name: value: "$env.${name} = $\"${value}\"")
          |> concatStringsSep "\n"
        }

        # Remaining environment variables
        ${
          environmentVariables
          |> filterAttrs (name: const <| !(baseVariablesMap ? ${name}))
          |> mapAttrsToList (name: value: "$env.${name} = $\"${value}\"")
          |> concatStringsSep "\n"
        }

        ${lib.optionalString (config.environment.sessionVariables ? LD_PRELOAD) ''
          # nu's wrapper preloads mimalloc; hand the system allocator back to
          # everything nu spawns. Nested nu re-enters the wrapper → mimalloc.
          $env.LD_PRELOAD = "${config.environment.sessionVariables.LD_PRELOAD}"
        ''}

        # Shell aliases
        ${shellAliases |> mapAttrsToList (name: value: "alias ${name} = ${value}") |> concatStringsSep "\n"}

        $env.LS_COLORS = (open ${
          pkgs.runCommand "ls_colors" { } ''
            ${pkgs.buildPackages.vivid}/bin/vivid generate tokyonight-moon > "$out"
          ''
        } | str trim)

        ${readFile ./nushell.nu}

        source ${./ssh-completions.nu}

        use ${./terminfo-autogen.nu}

        # zoxide
        source ${
          pkgs.runCommand "zoxide.nu" { }
            ''${pkgs.buildPackages.zoxide}/bin/zoxide init nushell --cmd cd >> "$out"''
        }

        # Cade appends a pre_prompt closure that reloads only on PWD change.
        source ${cadeHook}

        if ($env.USER == "amaanq") {
          source ${
            pkgs.runCommand "atuin.nu" {
              nativeBuildInputs = [ pkgs.writableTmpDirAsHomeHook ];
            } ''${pkgs.buildPackages.atuin}/bin/atuin init nu --disable-up-arrow >> "$out"''
          }
        }

        if ($env.USER == "amaanq") {
          if ("${config.secrets.openai_api_key.path}" | path exists) {
            $env.OPENAI_API_KEY = (open ${config.secrets.openai_api_key.path} | str trim)
          }
          if ("${config.secrets.githubToken.path}" | path exists) {
            $env.GH_TOKEN = (open ${config.secrets.githubToken.path} | parse "access-tokens = github.com={token}" | get token.0)
          }
          if ("${config.secrets.glm_api_key.path}" | path exists) {
            $env.GLM_API_KEY = (open ${config.secrets.glm_api_key.path} | str trim)
          }
          if ("${config.secrets.kagi_session_token.path}" | path exists) {
            $env.KAGI_SESSION_TOKEN = (open ${config.secrets.kagi_session_token.path} | str trim)
          }
        }

        # OSUOSL OpenStack
        def --env os-load [auth_url: string, project_id: string, password_path: string] {
          $env.OS_AUTH_URL = $auth_url
          $env.OS_PROJECT_ID = $project_id
          $env.OS_PROJECT_NAME = "Nix/NixOS Tree-sitter"
          $env.OS_USER_DOMAIN_NAME = "Default"
          $env.OS_PROJECT_DOMAIN_ID = "default"
          $env.OS_USERNAME = "amaanq"
          $env.OS_REGION_NAME = "RegionOne"
          $env.OS_INTERFACE = "public"
          $env.OS_IDENTITY_API_VERSION = "3"
          $env.OS_PASSWORD = (open $password_path | str trim)
          hide-env -i OS_TENANT_ID
          hide-env -i OS_TENANT_NAME
        }

        def --env os-arm [] {
          os-load "https://arm-openstack.osuosl.org:5000/v3/" "06f88dbf8ad94705aaa966ad43540501" "${config.secrets.openstack_aarch64_password.path}"
        }

        def --env os-ppc64 [] {
          os-load "https://openpower-openstack.osuosl.org:5000/v3/" "aab72902cacf4645a458036486a6b072" "${config.secrets.openstack_powerpc64_password.path}"
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
in
{
  secrets.kagi_session_token = {
    rekeyFile = ./kagi-session-token.age;
    owner = "amaanq";
  };

  secrets.openstack_aarch64_password = {
    rekeyFile = ./openstack-aarch64-password.age;
    owner = "amaanq";
  };

  secrets.openstack_powerpc64_password = {
    rekeyFile = ./openstack-powerpc64-password.age;
    owner = "amaanq";
  };

  environment.systemPackages = optionals config.isDesktop [
    pkgs.openstackclient
  ];

  environment.etc."nushell/config.nu".source = configNu;

  environment.etc."nufmt/nufmt.nuon".text = ''
    {
        indent: 4
        line_length: 100
        margin: 1
    }
  '';

}
