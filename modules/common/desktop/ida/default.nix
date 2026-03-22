{
  config,
  ...
}:
{
  secrets.nixNetrc = {
    rekeyFile = ./netrc.age;
    mode = "0444";
  };

  nix.settings."netrc-file" = config.secrets.nixNetrc.path;
}
