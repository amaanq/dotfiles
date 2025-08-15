{ config, lib, ... }:
let
  inherit (lib) optionals remove;
in
{
  boot.binfmt.emulatedSystems =
    optionals (!config.isConstrained)
    <| remove config.nixpkgs.hostPlatform.system [
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
      "x86_64-linux"
    ];
}
