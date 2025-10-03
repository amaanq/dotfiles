{
  pkgs,
  nvim-config,
  ...
}:
{
  environment.variables = {
    EDITOR = "nvim";
  };

  environment.systemPackages = [
    nvim-config.packages.${pkgs.system}.nvim
  ];
}
