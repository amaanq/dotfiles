{
  self,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib) merge;

  fqdn = "fdroid.${domain}";
  fdroidDir = "/var/lib/fdroid";

  androidSdk = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [ "34" ];
    buildToolsVersions = [ "34.0.0" ];
    platformToolsVersion = "35.0.2";
    includeNDK = false;
    includeEmulator = false;
    includeSources = false;
  };

  fdroidWithSdk = pkgs.writeShellScriptBin "fdroid" ''
    export ANDROID_HOME="${androidSdk.androidsdk}/libexec/android-sdk"
    exec -a "$0" ${pkgs.fdroidserver}/bin/fdroid "$@"
  '';

  generateConfig = pkgs.writeShellScript "generate-fdroid-config" ''
        PASSWORD=$(cat ${config.secrets.fdroid-keystore-password.path})
        cat > ${fdroidDir}/config.yml << EOF
    repo_url: https://${fqdn}/repo
    repo_name: Amaan's F-Droid Repository
    repo_description: My personal F-Droid repository for custom Android app builds
    archive_url: https://${fqdn}/archive
    archive_name: Amaan's F-Droid Archive
    keystore: keystore.p12
    repo_keyalias: fdroid
    keystorepass: $PASSWORD
    keypass: $PASSWORD
    EOF
        chmod 0600 ${fdroidDir}/config.yml
        chown fdroid:fdroid ${fdroidDir}/config.yml
  '';
in
{
  imports = [
    (self + /modules/nginx.nix)
  ];

  nixpkgs.config.android_sdk.accept_license = true;

  users.users.fdroid = {
    description = "F-Droid Repository Manager";
    isSystemUser = true;
    group = "fdroid";
    home = fdroidDir;
    createHome = true;
    homeMode = "755";
    useDefaultShell = true;
    openssh.authorizedKeys.keys = config.users.users.amaanq.openssh.authorizedKeys.keys;
    packages = [
      fdroidWithSdk
      pkgs.openjdk17
    ];
  };

  users.groups.fdroid = { };

  secrets.upload-token = {
    file = ./upload-token.age;
    mode = "0440";
    group = "fdroid";
  };

  secrets.fdroid-keystore = {
    file = ./keystore.p12.age;
    path = "${fdroidDir}/keystore.p12";
    mode = "0400";
    owner = "fdroid";
    group = "fdroid";
  };

  secrets.fdroid-keystore-password = {
    file = ./keystore-password.age;
    mode = "0400";
    owner = "fdroid";
    group = "fdroid";
  };

  systemd.tmpfiles.rules = [
    "d ${fdroidDir} 0755 fdroid fdroid -"
    "d ${fdroidDir}/repo 0755 fdroid fdroid -"
    "d ${fdroidDir}/archive 0755 fdroid fdroid -"
  ];

  system.activationScripts.fdroid-config = lib.stringAfter [ "agenix" ] ''
    ${generateConfig}
  '';

  systemd.services.fdroid-upload =
    let
      uploadServer = pkgs.rustPlatform.buildRustPackage {
        pname = "fdroid-upload-server";
        version = "0.1.0";
        src = ./.;
        cargoLock.lockFile = ./Cargo.lock;
      };
    in
    {
      description = "F-Droid APK Upload Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        AUTH_TOKEN_FILE = config.secrets.upload-token.path;
        REPO_DIR = fdroidDir;
      };

      path = [
        pkgs.bash
        pkgs.curl
        fdroidWithSdk
        pkgs.openjdk17
      ];

      serviceConfig = {
        Type = "simple";
        User = "fdroid";
        Group = "fdroid";
        WorkingDirectory = fdroidDir;
        ExecStart = "${uploadServer}/bin/fdroid-upload-server";
        Restart = "always";
      };
    };

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    extraConfig = ''
      client_max_body_size 500M;
    '';

    locations."= /" = {
      return = "301 https://${fqdn}/repo/";
    };

    locations."/repo/" = {
      alias = "${fdroidDir}/repo/";
    };

    locations."/archive/" = {
      alias = "${fdroidDir}/archive/";
    };

    locations."/upload" = {
      proxyPass = "http://127.0.0.1:9876";
    };

    locations."/download" = {
      proxyPass = "http://127.0.0.1:9876";
    };
  };
}
