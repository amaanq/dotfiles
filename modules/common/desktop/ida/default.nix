{
  config,
  ...
}:
{
  secrets.nixNetrc = {
    rekeyFile = ./netrc.age;
    owner = "amaanq";
    mode = "0400";
  };

  nix.settings."netrc-file" = config.secrets.nixNetrc.path;
}
