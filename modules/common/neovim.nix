{
  config,
  nvim-config,
  ...
}:
{
  environment.variables = {
    EDITOR = "nvim";
  };

  environment.systemPackages = [
    nvim-config.packages.${config.hostSystem}.nvim
  ];
}
