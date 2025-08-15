{
  config,
  pkgs,
  inputs,
  ...
}:
{
  environment.variables = {
    EDITOR = "nvim";
  };

  environment.systemPackages = [
    (
      if config.isConstrained then
        inputs.nvim-config.packages.${pkgs.system}.server
      else
        inputs.nvim-config.packages.${pkgs.system}.nvim
    )
  ];
}
