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
    merge
    mkIf
    remove
    ;

  controlPath = "~/.ssh/control";

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
      in
      ''
        Host ${name}
          User ${user}
      ''
    );

  sshConfig = ''
    # Include secrets
    Include ${config.secrets.sshConfig.path}

    # Hosts from nixosConfigurations
    ${concatStringsSep "\n" hosts}

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
    file = ./config.age;
    mode = "444";
  };

  programs.ssh.extraConfig = sshConfig;
}
<| mkIf config.isDesktop {
  environment.systemPackages = [ pkgs.mosh ];
  environment.shellAliases.mosh = "mosh --no-init --no-ssh-pty";
}
