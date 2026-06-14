let
  default = {
    class = "nixos";
    user = "amaanq";
    port = 2001;
    ssh = true;
    builder = true;
    speedFactor = 1;
    emulatedSystems = [ ];
  };

  desktopEmulatedSystems = [
    "aarch64-linux"
    "armv7l-linux"
    "i686-linux"
    "loongarch64-linux"
    "mips-linux"
    "mips64-linux"
    "mips64el-linux"
    "mipsel-linux"
    "powerpc-linux"
    "powerpc64-linux"
    "powerpc64le-linux"
    "riscv32-linux"
    "riscv64-linux"
    "s390x-linux"
  ];
in
builtins.mapAttrs (_: entry: default // entry) {
  barchan = {
    system = "loongarch64-linux";
    maxJobs = 24;
  };
  derecho = {
    system = "x86_64-linux";
    maxJobs = 32;
    emulatedSystems = desktopEmulatedSystems;
  };
  esker = {
    system = "x86_64-linux";
    maxJobs = 8;
    builder = false;
    emulatedSystems = desktopEmulatedSystems;
  };
  flysch = {
    system = "mips64-linux";
    maxJobs = 12;
  };
  guyot = {
    system = "x86_64-linux";
    maxJobs = 96;
  };
  karst = {
    system = "aarch64-linux";
    maxJobs = 16;
  };
  lahar = {
    system = "x86_64-linux";
    maxJobs = 8;
    builder = false;
    emulatedSystems = desktopEmulatedSystems;
  };
  loess = {
    system = "aarch64-linux";
    maxJobs = 16;
  };
  moraine = {
    system = "powerpc64-linux";
    maxJobs = 16;
  };
  nunatak = {
    system = "aarch64-linux";
    maxJobs = 12;
  };
  scarp = {
    system = "x86_64-linux";
    maxJobs = 32;
    speedFactor = 4;
  };
  simoom = {
    class = "darwin";
    system = "aarch64-darwin";
    maxJobs = 16;
    port = 22;
    ssh = false;
  };
  squall = {
    class = "darwin";
    system = "aarch64-darwin";
    maxJobs = 8;
    port = 22;
    ssh = false;
  };
  tarn = {
    system = "powerpc64-linux";
    maxJobs = 16;
  };
  varve = {
    system = "mips64-linux";
    maxJobs = 16;
    speedFactor = 4;
  };
  yardang = {
    system = "x86_64-linux";
    maxJobs = 8;
  };
}
