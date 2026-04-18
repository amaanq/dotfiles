{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled merge mkIf;
in
merge
<| mkIf config.isDesktop {
  users.users.amaanq = {
    extraGroups = [
      "libvirtd"
      "kvm"
    ];
  };

  virtualisation.libvirtd = enabled {
    qemu = {
      package = pkgs.qemu;
      swtpm = enabled;
      vhostUserPackages = [ pkgs.virtiofsd ];
    };
    onBoot = "ignore";
    onShutdown = "shutdown";
  };
}
