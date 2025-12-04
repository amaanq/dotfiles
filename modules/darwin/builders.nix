{
  config,
  keys,
  lib,
  ...
}:
let
  authorizedKeys = builtins.concatStringsSep "\n" keys.all;
in
{
  users.users.build = {
    name = "build";
    home = "/Users/build";
  };

  system.activationScripts.postActivation.text = lib.mkAfter ''
    # build user
    if ! dscl . -read /Users/build &>/dev/null; then
      sysadminctl -addUser build -shell /bin/zsh -home /Users/build
    fi

    # SSH
    mkdir -p /Users/build/.ssh
    echo '${authorizedKeys}' > /Users/build/.ssh/authorized_keys
    chown -R build:staff /Users/build/.ssh
    chmod 700 /Users/build/.ssh
    chmod 600 /Users/build/.ssh/authorized_keys

    # for detnix, add build to trusted-users if not present
    if [ -f /etc/nix/nix.conf ] && ! grep -q "trusted-users.*build" /etc/nix/nix.conf; then
      echo "trusted-users = root build" >> /etc/nix/nix.conf
      launchctl kickstart -k system/org.nixos.nix-daemon || true
    fi
  '';

  # only set via nix-darwin if nix is managed by nix-darwin & not detnix
  nix.settings.trusted-users = lib.mkIf config.nix.enable [ "build" ];
}
