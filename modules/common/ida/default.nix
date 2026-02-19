{
  config,
  lib,
  ...
}:
lib.merge
<| lib.mkIf config.isDesktop {
  secrets.nixNetrc = {
    file = ./netrc.age;
    mode = "0444";
  };

  nix.settings."netrc-file" = config.secrets.nixNetrc.path;
}
