{
  config,
  fleet,
  lib,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    filterAttrs
    attrNames
    mapAttrsToList
    head
    map
    remove
    optionalString
    ;

  controlPath = "~/.ssh/control";

  # GCC Compile Farm hosts — data in cfarm.json to avoid nixfmt mangling
  # https://portal.cfarm.net/machines/list/
  cfarmHosts = builtins.fromJSON (builtins.readFile ./cfarm.json);

  cfarmConfig =
    cfarmHosts
    |> map (h: ''
      # @desc ${h.desc}
      Host ${h.host}${optionalString (h ? port) "\n    Port ${toString h.port}"}${
        optionalString (h ? extra) "\n    ${h.extra}"
      }
    '')
    |> concatStringsSep "\n";

  # Host blocks from the fleet registry (fleet.nix)
  hosts =
    fleet
    |> filterAttrs (_: h: h.ssh)
    |> mapAttrsToList (
      name: h: ''
        Host ${name}
          User ${h.user}${optionalString (h.port != 22) "\n    Port ${toString h.port}"}
          StrictHostKeyChecking accept-new
      ''
    );

  sshConfig = ''
    # Include secrets
    Include ${config.secrets.sshConfig.path}

    Host github.com
      User git

    Host gitlab.com
      User git

    # Hosts from nixosConfigurations
    ${concatStringsSep "\n" hosts}

    # GCC Compile Farm
    Host cfarm*
      CanonicalizeHostname yes
      CanonicalDomains cfarm.net
      User amaanq
      IdentityFile ~/.ssh/id_rsaslop
      IdentityFile ~/.ssh/id

    ${cfarmConfig}

    # Default settings for all hosts
    Host *
      ControlMaster auto
      ControlPath ${controlPath}/%r@%n:%p
      ControlPersist 60m
      ServerAliveCountMax 2
      ServerAliveInterval 60
      SetEnv COLORTERM="truecolor" TERM="xterm-256color"
      IdentityFile ~/.ssh/id
  '';
in
{
  secrets.sshConfig = {
    rekeyFile = ./config.age;
    mode = "0400";
    owner = "amaanq";
  };

  # Drift check
  assertions =
    let
      entry = fleet.${config.networking.hostName};
      user =
        config.users.users
        |> filterAttrs (_: u: u.isNormalUser or false)
        |> attrNames
        |> remove "backup"
        |> remove "build"
        |> remove "root"
        |> head;
      port = config.services.openssh.ports or [ 22 ] |> head;
    in
    [
      {
        assertion = entry.ssh -> (config.services.openssh.enable or false);
        message = "fleet.nix: ${config.networking.hostName}.ssh = true but openssh is disabled";
      }
      {
        assertion = entry.ssh -> entry.user == user;
        message = "fleet.nix: ${config.networking.hostName}.user = ${entry.user} but config derives ${user}";
      }
      {
        assertion = entry.ssh -> entry.port == port;
        message = "fleet.nix: ${config.networking.hostName}.port = ${toString entry.port} but config has ${toString port}";
      }
    ];

  programs.ssh.extraConfig = sshConfig;
}
