{
  self,
  config,
  lib,
  pkgs,
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
    merge
    mkIf
    remove
    ;

  controlPath = "~/.ssh/control";

  # GCC Compile Farm hosts — data in cfarm.json to avoid nixfmt mangling
  # https://portal.cfarm.net/machines/list/
  cfarmHosts = builtins.fromJSON (builtins.readFile ./cfarm.json);

  cfarmConfig =
    cfarmHosts
    |> map (
      h: ''
        # @desc ${h.desc}
        Host ${h.host}${lib.optionalString (h ? port) "\n    Port ${toString h.port}"}${lib.optionalString (h ? extra) "\n    ${h.extra}"}
      ''
    )
    |> concatStringsSep "\n";

  # Generate host blocks from nixosConfigurations
  hosts =
    self.nixosConfigurations
    |> filterAttrs (_: value: value.config.services.openssh.enable)
    |> mapAttrsToList (
      name: value:
      let
        user =
          value.config.users.users
          |> filterAttrs (_: u: u.isNormalUser)
          |> attrNames
          |> remove "backup"
          |> remove "build"
          |> remove "root"
          |> head;
        port = value.config.services.openssh.ports or [ 22 ] |> builtins.head;
      in
      ''
        Host ${name}
          User ${user}${lib.optionalString (port != 22) "\n    Port ${toString port}"}
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
merge {
  secrets.sshConfig = {
    rekeyFile = ./config.age;
    mode = "0400";
    owner = "amaanq";
  };

  programs.ssh.extraConfig = sshConfig;
}
<| mkIf config.isDesktop {
  environment.systemPackages = [ pkgs.mosh ];
  environment.shellAliases.mosh = "mosh --no-init --no-ssh-pty";
}
