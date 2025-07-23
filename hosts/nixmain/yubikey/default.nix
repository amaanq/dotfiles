{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrNames
    enabled
    head
    ;
  user = head (attrNames config.users.users);
in
{
  environment.systemPackages = [
    pkgs.yubikey-manager
    pkgs.yubikey-personalization
    pkgs.yubioath-flutter
    pkgs.pam_u2f
  ];

  secrets.u2f = {
    file = ./u2f.age;
    owner = user;
  };
  security.pam = {
    u2f = enabled {
      settings = {
        authfile = config.secrets.u2f.path;
        cue = true;
        cue_prompt = "🔐 Touch your YubiKey to authenticate";
      };
    };

    services = {
      sudo.u2fAuth = true;
      login.u2fAuth = true;
    };
  };

  services.udev = {
    packages = [ pkgs.yubikey-personalization ];
    extraRules = ''
      ACTION=="remove",\
       ENV{ID_BUS}=="usb",\
       ENV{ID_MODEL_ID}=="0407",\
       ENV{ID_VENDOR_ID}=="1050",\
       ENV{ID_VENDOR}=="Yubico",\
       RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
    '';
  };
}
