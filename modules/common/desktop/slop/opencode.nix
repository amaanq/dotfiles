{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # Bun override: fork's packageManager is bun@1.3.13, nixpkgs is on 1.3.11.
  # Drop once nixpkgs catches up (and pass `{}` to callPackage below).
  bunVersion = "1.3.13";
  bunSources = {
    x86_64-linux = {
      file = "bun-linux-x64.zip";
      hash = "sha256-ecB3H6i5LDOq5B4VoODTB+qZ0OLwAxfHHGxTI3p44lo=";
    };
    aarch64-linux = {
      file = "bun-linux-aarch64.zip";
      hash = "sha256-cLrkGzkIsKEg4eWMXIrzDnSvrjuNEbDT/djnh937SyI=";
    };
    x86_64-darwin = {
      file = "bun-darwin-x64.zip";
      hash = "sha256-5abItk9BmSUjLREeyxPiXwq/VeVPeSNB+YdiP9B3gAk=";
    };
    aarch64-darwin = {
      file = "bun-darwin-aarch64.zip";
      hash = "sha256-VGfj9l26Umuf6pjwzOBO+vwMY+Fpcz7Ce4dqOtMtoZA=";
    };
  };

  bunSrc = bunSources.${pkgs.stdenv.hostPlatform.system};

  bun' = pkgs.bun.overrideAttrs (_: {
    version = bunVersion;
    src = pkgs.fetchurl {
      url = "https://github.com/oven-sh/bun/releases/download/bun-v${bunVersion}/${bunSrc.file}";
      inherit (bunSrc) hash;
    };
  });

  # Vendor prettier into packages/opencode/node_modules. The fork's
  # node_modules.nix runs `bun install --filter '!./' --filter './packages/opencode' ...`
  # which skips the root workspace, but prettier (used at compile time by
  # generate.ts via dynamic import) is declared in the ROOT package.json.
  # Without this, bun --compile fails with "Could not resolve 'prettier'".
  # Upstream fix belongs in the fork's filter list.
  prettier = pkgs.fetchzip {
    url = "https://registry.npmjs.org/prettier/-/prettier-3.6.2.tgz";
    hash = "sha256-1ECWebLdPoOsVcq8TsLMPcZE1iu/GvZYfdf6tikBBlc=";
  };

  opencode =
    (pkgs.callPackage "${inputs.opencode-anomalyco}/nix/opencode.nix" {
      bun = bun';
      node_modules = pkgs.callPackage "${inputs.opencode-anomalyco}/nix/node_modules.nix" {
        bun = bun';
      };
    }).overrideAttrs
      (prev: {
        postConfigure = (prev.postConfigure or "") + ''
          chmod -R u+w packages/opencode/node_modules
          mkdir -p packages/opencode/node_modules/prettier
          cp -R --no-preserve=mode,ownership ${prettier}/. packages/opencode/node_modules/prettier/
        '';
      });

  # Vendored from rtk's repo (hooks/opencode/rtk.ts). Opencode's
  # `tool.execute.before` hook lets us mutate args.command before exec; the
  # plugin shells out to `rtk rewrite` and replaces the command if rtk has
  # a registered filter for it.
  rtkOpencodePlugin = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/rtk-ai/rtk/80a6fe606f73b19e52b0b330d242e62a6c07be42/hooks/opencode/rtk.ts";
    hash = "sha256-ZTDBMZRshIkvlSKr1o1OUT4eZY2N260fWTiMhuu8trs=";
  };

  opencodeConfig = pkgs.writeText "opencode.json" (
    lib.strings.toJSON {
      "$schema" = "https://opencode.ai/config.json";
      autoupdate = false;
      share = "disabled";
      instructions = [ "~/.config/claude/CLAUDE.md" ];
      permission."*" = "allow";
      compaction.auto = false;
      plugin = [ "/etc/opencode/plugins/rtk.ts" ];
    }
  );
in
{
  environment.systemPackages = [ opencode ];

  environment.shellAliases.oc = "opencode";

  environment.etc."opencode/opencode.json".source = opencodeConfig;
  environment.etc."opencode/plugins/rtk.ts".source = rtkOpencodePlugin;

  environment.variables.OPENCODE_CONFIG = "/etc/opencode/opencode.json";
}
