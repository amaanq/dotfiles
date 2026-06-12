lib:
lib.nixosSystem' "server" (
  {
    config,
    keys,
    pkgs,
    lib,
    ...
  }:
  let
    inherit (lib) collectNix remove;
  in
  {
    imports = collectNix ./. |> remove ./default.nix;

    type = "server";
    isBuilder = true;
    builderSpeedFactor = 4;
    builderMaxJobs = 16;

    services.openssh.settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = false;
      PrintLastLog = false;
    };

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    secrets.password.rekeyFile = ./password.age;
    users.users = {
      root = {
        openssh.authorizedKeys.keys = keys.admins;
        hashedPasswordFile = config.secrets.password.path;
        shell = pkgs.nushell;
      };

      amaanq = {
        description = "Amaan Qureshi";
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = keys.admins;
        shell = pkgs.nushell;
      };
    };

    networking = {
      hostName = "varve";
      useDHCP = true;
    };

    # systemd's seccomp SystemCallFilter and MemoryDenyWriteExecute break thread
    # creation and Go syscalls on mips64 (chronyd dies in pthread_create,
    # node-exporter takes a SIGSYS register-dump). Both run fine unsandboxed.
    #
    # TODO: VERIFY/FIX
    systemd.services.chronyd.serviceConfig = {
      SystemCallFilter = lib.mkForce [ ];
      MemoryDenyWriteExecute = lib.mkForce false;
    };
    systemd.services.prometheus-node-exporter.serviceConfig = {
      SystemCallFilter = lib.mkForce [ ];
      MemoryDenyWriteExecute = lib.mkForce false;
    };

    system.stateVersion = "26.05";
    time.timeZone = "America/New_York";
  }
)
