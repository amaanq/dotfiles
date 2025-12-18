{ config, ... }:
{
  boot.tmp =
    if config.isDesktop && !config.isLaptop then
      {
        useTmpfs = true;
        tmpfsSize = "16G";
      }
    else
      {
        cleanOnBoot = true;
      };
}
