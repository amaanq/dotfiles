{
  pkgs,
  inputs,
  ...
}:
{
  environment.variables = {
    EDITOR = "nvim";
  };

  environment.systemPackages = [
    inputs.nvim-config.packages.${pkgs.system}.nvim
  ];
}
