{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.ripgrep ];

  environment.variables.RIPGREP_CONFIG_PATH = "/etc/ripgreprc";

  environment.etc."ripgreprc".text = ''
    --line-number
    --smart-case
    --colors=line:style:bold
    --colors=path:fg:cyan
    --colors=match:fg:yellow
    --colors=match:style:bold
  '';

  environment.shellAliases.todo = "rg \"todo|fixme\"";
}
