{
  self,
  config,
  lib,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib)
    const
    enabled
    genAttrs
    head
    mkDefault
    ;
in
{
  imports = [ (self + /modules/acme) ];

  secrets.mailPassword.file = ./password.hash.age;

  services.prometheus.exporters.postfix = enabled {
    listenAddress = "[::]";
  };

  security.acme.users = [ "mail" ];

  mailserver = enabled {
    domains = mkDefault [ domain ];
    certificateScheme = "acme";

    # We use systemd-resolved instead of Knot Resolver.
    localDnsResolver = false;

    hierarchySeparator = "/";
    useFsLayout = true;

    dkimKeyDirectory = "/var/lib/dkim";
    mailDirectory = "/var/lib/mail";
    sieveDirectory = "/var/lib/sieve";

    vmailUserName = "mail";
    vmailGroupName = "mail";

    fullTextSearch = enabled;

    loginAccounts."contact@${head config.mailserver.domains}" = {
      aliases = [ "@${head config.mailserver.domains}" ];

      hashedPasswordFile = config.secrets.mailPassword.path;
    };

    stateVersion = 3;
  };
}
