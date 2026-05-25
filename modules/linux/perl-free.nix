{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) enabled;
in
{
  # nixos-core replaces:
  #   update-users-groups.pl      (user/group/shadow sync)
  #   setup-etc.pl                (/etc/static atomic update)
  #   stage-1-init.sh             (legacy initrd boot)
  #   stage-2-init.sh             (system activation post-initrd)
  system.nixos-core = enabled {
    package = pkgs.callPackage (inputs.nixos-core + "/nix/package.nix") { };
  };

  # We use flakes anyway, so get rid of this perl or perl-dependent slop.
  system.tools.nixos-generate-config.enable = lib.mkDefault false;
  system.tools.nixos-option.enable = lib.mkDefault false;
  system.tools.nixos-rebuild.enable = lib.mkDefault false;

  # I'm never allowing perl on my system again.
  system.forbiddenDependenciesRegexes = [ "[^[:alpha:]][Pp]erl" ];

  # For some reason, this is in Perl.
  programs.command-not-found.enable = false;

  # nixpkgs, sob
  system.systemBuilderArgs.perl = lib.mkForce "";
}
