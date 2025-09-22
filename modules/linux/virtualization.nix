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
  services.spice-vdagentd = enabled;

  virtualisation = {
    waydroid = enabled;

    libvirtd = enabled {
      qemu = {
        swtpm = enabled;
        ovmf = enabled {
          packages = [ pkgs.OVMFFull.fd ];
        };
      };
    };

    spiceUSBRedirection.enable = true;
  };
}
