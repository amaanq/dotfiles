{ lib, ... }:
let
  inherit (lib) enabled;
in
{
  environment.shellAliases = {
    todo = "rg \"todo|fixme\" --colors match:fg:yellow --colors match:style:bold";
    rg = "rg --line-number --smart-case";
  };

  home-manager.sharedModules = [
    {
      programs.ripgrep = enabled {
        arguments = [
          "--line-number"
          "--smart-case"
          "--colors=line:style:bold"
          "--colors=path:fg:cyan"
          "--colors=match:fg:yellow"
          "--colors=match:style:bold"
        ];
      };
    }
  ];
}
