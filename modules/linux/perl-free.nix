{ lib, ... }:
{
  # nixos-core replaces:
  #   update-users-groups.pl      (user/group/shadow sync)
  #   setup-etc.pl                (/etc/static atomic update)
  #   stage-1-init.sh             (legacy initrd boot)
  #   stage-2-init.sh             (system activation post-initrd)
  system.nixos-core.enable = true;

  # We use flakes anyway, so get rid of this perl slop.
  system.tools.nixos-generate-config.enable = lib.mkDefault false;

  # I'm never allowing perl on my system again.
  system.forbiddenDependenciesRegexes = [ "perl" ];
}
