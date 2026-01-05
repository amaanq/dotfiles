{ lib, ... }:
{
  # Regenerate with: nix run nixpkgs#vivid -- generate tokyonight-moon > modules/common/shell/ls_colors.txt
  environment.variables.LS_COLORS = lib.readFile ./ls_colors.txt;
}
