{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.meta) getExe;

  # Bun override: fork's packageManager is bun@1.3.13, nixpkgs is still on
  # 1.3.11 as of this commit. Drop the override (and pass `{}` to callPackage
  # in build.nix) once nixpkgs catches up.
  bunVersion = "1.3.13";
  bunSources = {
    x86_64-linux = {
      arch = "x64";
      hash = "sha256-ecB3H6i5LDOq5B4VoODTB+qZ0OLwAxfHHGxTI3p44lo=";
    };
    aarch64-linux = {
      arch = "aarch64";
      hash = "sha256-cLrkGzkIsKEg4eWMXIrzDnSvrjuNEbDT/djnh937SyI=";
    };
  };

  # Build recipe handed to `nix-build --argstr src ...`. Wraps the fork's
  # callPackage chain, bumps bun (binary swap, not a compile), and vendors
  # prettier into packages/opencode/node_modules so generate.ts's
  # `await import("prettier")` resolves at bun --compile time. Prettier is
  # declared in the root package.json but the fork's node_modules.nix
  # filters skip the root workspace (`--filter '!./'`), so it never lands
  # in the FOD output. Upstream fix belongs in the fork.
  buildExpr = pkgs.writeText "opencode-build.nix" ''
    { src }:
    let
      pkgs = import ${pkgs.path} { };
      bunSources = ${lib.generators.toPretty { } bunSources};
      bunSrc = bunSources.''${pkgs.stdenv.hostPlatform.system};
      bun' = pkgs.bun.overrideAttrs (_: {
        version = "${bunVersion}";
        src = pkgs.fetchurl {
          url = "https://github.com/oven-sh/bun/releases/download/bun-v${bunVersion}/bun-linux-''${bunSrc.arch}.zip";
          inherit (bunSrc) hash;
        };
      });
      prettier = pkgs.fetchzip {
        url = "https://registry.npmjs.org/prettier/-/prettier-3.6.2.tgz";
        hash = "sha256-1ECWebLdPoOsVcq8TsLMPcZE1iu/GvZYfdf6tikBBlc=";
      };
      srcPath = src + "";
      opencode = pkgs.callPackage (srcPath + "/nix/opencode.nix") {
        bun = bun';
        node_modules = pkgs.callPackage (srcPath + "/nix/node_modules.nix") {
          bun = bun';
        };
      };
    in
    opencode.overrideAttrs (prev: {
      postConfigure = (prev.postConfigure or "") + '''
        chmod -R u+w packages/opencode/node_modules
        mkdir -p packages/opencode/node_modules/prettier
        cp -R --no-preserve=mode,ownership ''${prettier}/. packages/opencode/node_modules/prettier/
      ''';
    })
  '';

  # Self-updating launcher — mirrors the claude-code flow: check GitHub once
  # per 6h for the latest anomalyco/opencode tag, fetch source on demand,
  # nix-build via build.nix, cache the gcroot per version, exec.
  opencode = pkgs.writeScriptBin "opencode" /* nu */ ''
    #!${getExe pkgs.nushell} --no-config-file

    def fetch-latest-tag []: nothing -> string {
       try {
          http get --max-time 5sec https://api.github.com/repos/anomalyco/opencode/releases/latest
             | get tag_name
             | str trim --left --char v
       } catch {
          print --stderr $"(ansi yellow_bold)warn:(ansi reset) can't fetch latest tag"
          ""
       }
    }

    def resolve-version [cache: directory, --rebuild]: nothing -> string {
       let tag_file = $cache | path join "latest-tag"
       let stale = try { (date now) - (ls $tag_file | get 0.modified) > 6hr } catch { true }

       if $rebuild or $stale {
          let v = fetch-latest-tag
          if ($v | is-not-empty) {
             try { $v | save --force $tag_file }
             return $v
          }
       }

       try { open $tag_file } catch { "" }
    }

    def fetch-source [version: string, src_dir: string] {
       let tgz = $"($src_dir).tgz"
       print --stderr $"(ansi cyan)fetch:(ansi reset) opencode v($version) source"
       http get --raw $"https://github.com/anomalyco/opencode/archive/refs/tags/v($version).tar.gz"
          | save --force --raw $tgz

       let parent = $src_dir | path dirname
       ^${getExe pkgs.gnutar} -xzf $tgz -C $parent
       rm $tgz
       mv ($parent | path join $"opencode-($version)") $src_dir
    }

    def build-from-src [version: string, gcroot: string, cache: string] {
       let src_dir = $cache | path join "src" $version
       if not ($src_dir | path exists) {
          mkdir ($cache | path join "src")
          fetch-source $version $src_dir
       }

       print --stderr $"(ansi cyan)build:(ansi reset) nix-build opencode v($version)"
       mkdir ($gcroot | path dirname)
       ^${pkgs.nix}/bin/nix-build --out-link $gcroot --argstr src $src_dir ${buildExpr}
    }

    def run-latest [cache: directory, ...arguments] {
       print --stderr $"(ansi yellow_bold)warn:(ansi reset) falling back to latest cached build"
       try {
          let latest = glob ($cache | path join "gcroots" "v*")
             | sort
             | last
          exec ($latest | path join "bin" "opencode") ...$arguments
       } catch {
          print --stderr $"(ansi red_bold)error:(ansi reset) no cached opencode build"
          exit 67
       }
    }

    def --wrapped main [--rebuild, ...args] {
       let cache = $env
          | get --optional "XDG_CACHE_HOME"
          | default ($env.HOME | path join ".cache")
          | path join "opencode"
       mkdir $cache

       let version = resolve-version $cache --rebuild=($rebuild)
       if ($version | is-empty) { run-latest $cache ...$args }

       let gcroot = $cache | path join "gcroots" $"v($version)"
       if not ($gcroot | path exists) or $rebuild {
          build-from-src $version $gcroot $cache
       }

       exec ($gcroot | path join "bin" "opencode") ...$args
    }
  '';
in
{
  environment.systemPackages = [ opencode ];
  environment.shellAliases.oc = "opencode";
}
