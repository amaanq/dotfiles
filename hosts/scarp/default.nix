lib:
lib.nixosSystem' "server" (
  {
    config,
    keys,
    lib,
    pkgs,
    ...
  }:
  let
    inherit (lib) collectNix remove;
  in
  {
    imports = collectNix ./. |> remove ./default.nix;

    type = "server";
    isBuilder = true;
    builderMaxJobs = 12;

    networking = {
      domain = "amaanq.com";
      hostName = "scarp";
    };
    nixpkgs.config.allowUnfree = true;

    secrets.id.rekeyFile = ./id.age;
    services.openssh.hostKeys = [
      {
        type = "ed25519";
        path = config.secrets.id.path;
      }
    ];

    secrets.password.rekeyFile = ./password.age;
    users.users = {
      root = {
        openssh.authorizedKeys.keys = keys.admins;
        hashedPasswordFile = config.secrets.password.path;
      };

      amaanq = {
        description = "Amaan Qureshi";
        extraGroups = [ "wheel" ];
        isNormalUser = true;
        hashedPasswordFile = config.secrets.password.path;
        openssh.authorizedKeys.keys = keys.admins;
        shell = pkgs.nushell;
      };

      backup = {
        description = "Backup";
        openssh.authorizedKeys.keys = keys.all;
        hashedPasswordFile = config.secrets.password.path;
        isNormalUser = true;
      };
    };

    boot.tmp.cleanOnBoot = true;

    # Immich's exiftool-vendored is fundamentally perl (Image::ExifTool plus
    # ~hundreds of perl modules) and there is no equivalent for HEIF gainmaps,
    # video metadata, or RAW manufacturer tags. Until immich is containerized
    # or moved off scarp, scarp is the one host that legitimately requires
    # perl in its closure.
    system.forbiddenDependenciesRegexes = lib.mkForce [ ];

    system.stateVersion = "25.11";

    time.timeZone = "America/New_York";
  }
)
