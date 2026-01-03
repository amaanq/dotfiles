{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.environment.memoryAllocator;

  # The set of alternative malloc(3) providers.
  providers = {
    graphene-hardened = {
      libPath = "${pkgs.graphene-hardened-malloc}/lib/libhardened_malloc.so";
      description = ''
        Hardened memory allocator coming from GrapheneOS project.
        The default configuration template has all normal optional security
        features enabled and is quite aggressive in terms of sacrificing
        performance and memory usage for security.
      '';
    };

    graphene-hardened-light = {
      libPath = "${pkgs.graphene-hardened-malloc}/lib/libhardened_malloc-light.so";
      description = ''
        Hardened memory allocator coming from GrapheneOS project.
        The light configuration template disables the slab quarantines,
        write after free check, slot randomization and raises the guard
        slab interval from 1 to 8 but leaves zero-on-free and slab canaries enabled.
        The light configuration has solid performance and memory usage while still
        being far more secure than mainstream allocators with much better security
        properties.
      '';
    };

    jemalloc = {
      libPath = "${pkgs.jemalloc}/lib/libjemalloc.so";
      description = ''
        A general purpose allocator that emphasizes fragmentation avoidance
        and scalable concurrency support.
      '';
    };

    scudo =
      let
        platformMap = {
          aarch64-linux = "aarch64";
          x86_64-linux = "x86_64";
        };

        systemPlatform =
          platformMap.${pkgs.stdenv.hostPlatform.system}
            or (throw "scudo not supported on ${pkgs.stdenv.hostPlatform.system}");
      in
      {
        libPath = "${pkgs.llvmPackages.compiler-rt}/lib/linux/libclang_rt.scudo_standalone-${systemPlatform}.so";
        description = ''
          A user-mode allocator based on LLVM Sanitizer’s CombinedAllocator,
          which aims at providing additional mitigations against heap based
          vulnerabilities, while maintaining good performance.
        '';
      };

    mimalloc = {
      libPath = "${pkgs.mimalloc}/lib/libmimalloc.so";
      description = ''
        A compact and fast general purpose allocator, which may
        optionally be built with mitigations against various heap
        vulnerabilities.
      '';
    };
  };

  providerConf = providers.${cfg.provider};

  # An output that contains only the shared library, to avoid
  # needlessly bloating the system closure
  mallocLib =
    pkgs.runCommand "malloc-provider-${cfg.provider}"
      rec {
        preferLocalBuild = true;
        allowSubstitutes = false;
        origLibPath = providerConf.libPath;
        libName = baseNameOf origLibPath;
      }
      ''
        mkdir -p $out/lib
        cp -L $origLibPath $out/lib/$libName
      '';

  # The full path to the selected provider shlib.
  providerLibPath = "${mallocLib}/lib/${mallocLib.libName}";

  needsMozillaFix =
    cfg.mozillaPackages != [ ]
    && lib.elem cfg.provider [
      "graphene-hardened"
      "graphene-hardened-light"
    ];

  # Create wrapper package for Mozilla apps that sets MOZ_REPLACE_MALLOC_LIB
  wrappedMozillaPackages =
    pkgs.runCommand "malloc-mozilla-wrappers"
      {
        preferLocalBuild = true;
        allowSubstitutes = false;
        nativeBuildInputs = [ pkgs.makeWrapper ];
        # Take precedence over non-wrapped versions
        meta.priority = -1;
      }
      ''
        mkdir -p $out/bin
        ${lib.concatMapStringsSep "\n" (pkg: ''
          for exe in ${lib.getBin pkg}/bin/*; do
            if [ -x "$exe" ] && [ -f "$exe" ]; then
              exeName=$(basename "$exe")
              makeWrapper "$exe" "$out/bin/$exeName" \
                --unset LD_PRELOAD \
                --set MOZ_REPLACE_MALLOC_LIB "${providerLibPath}"
            fi
          done
        '') cfg.mozillaPackages}
      '';

  # Create wrapper package for excluded packages that unsets LD_PRELOAD
  wrappedExcludedPackages =
    pkgs.runCommand "malloc-excluded-wrappers"
      {
        preferLocalBuild = true;
        allowSubstitutes = false;
        nativeBuildInputs = [ pkgs.makeWrapper ];
        # Take precedence over non-wrapped versions
        meta.priority = -1;
      }
      ''
        mkdir -p $out/bin
        ${lib.concatMapStringsSep "\n" (pkg: ''
          for exe in ${lib.getBin pkg}/bin/*; do
            if [ -x "$exe" ] && [ -f "$exe" ]; then
              exeName=$(basename "$exe")
              makeWrapper "$exe" "$out/bin/$exeName" --unset LD_PRELOAD
            fi
          done
        '') cfg.excludedPackages}
      '';

  # Create wrapper scripts for excluded commands (non-NixOS binaries)
  # These find the real binary in PATH and exec without LD_PRELOAD
  wrappedExcludedCommands =
    pkgs.runCommand "malloc-excluded-commands"
      {
        preferLocalBuild = true;
        allowSubstitutes = false;
        # Take precedence over non-wrapped versions
        meta.priority = -1;
      }
      ''
        mkdir -p $out/bin
        ${lib.concatMapStringsSep "\n" (cmd: ''
          cat > "$out/bin/${cmd}" <<'EOF'
        #!${pkgs.runtimeShell}
        unset LD_PRELOAD
        # Find the real binary, skipping this wrapper
        for dir in $(echo "$PATH" | tr ':' '\n'); do
          if [ -x "$dir/${cmd}" ] && [ "$dir/${cmd}" != "$0" ]; then
            exec "$dir/${cmd}" "$@"
          fi
        done
        echo "${cmd}: command not found" >&2
        exit 127
        EOF
          chmod +x "$out/bin/${cmd}"
        '') cfg.excludedCommands}
      '';
in

{
  meta = {
    maintainers = [ lib.maintainers.joachifm ];
  };

  options = {
    environment.memoryAllocator.provider = lib.mkOption {
      type = lib.types.enum ([ "libc" ] ++ lib.attrNames providers);
      default = "libc";
      description = ''
        The system-wide memory allocator.

        Briefly, the system-wide memory allocator providers are:

        - `libc`: the standard allocator provided by libc
        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (
            name: value: "- `${name}`: ${lib.replaceStrings [ "\n" ] [ " " ] value.description}"
          ) providers
        )}

        ::: {.warning}
        Selecting an alternative allocator (i.e., anything other than
        `libc`) may result in instability, data loss,
        and/or service failure.
        :::
      '';
    };

    environment.memoryAllocator.mozillaPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      example = lib.literalExpression "[ pkgs.firefox pkgs.thunderbird ]";
      description = ''
        Mozilla packages to integrate with the hardened allocator via
        `MOZ_REPLACE_MALLOC_LIB`. This prevents crashes caused by mixing
        jemalloc with the system allocator while still providing hardened
        memory allocation.

        Only applies when using `graphene-hardened` or `graphene-hardened-light`.
      '';
    };

    environment.memoryAllocator.excludedPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      example = lib.literalExpression "[ pkgs.signal-desktop ]";
      description = ''
        Packages to completely exclude from the system-wide memory allocator.
        These packages will be wrapped to unset `LD_PRELOAD` before execution,
        causing them to use libc's default allocator instead.
      '';
    };

    environment.memoryAllocator.excludedCommands = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "ckati" "ninja" ];
      description = ''
        Command names to exclude from the system-wide memory allocator.
        Use this for non-NixOS binaries (e.g., prebuilt tools in external projects).
        Wrapper scripts will be created that unset `LD_PRELOAD` before executing
        the real binary found in PATH.
      '';
    };
  };

  config = lib.mkIf (cfg.provider != "libc") {
    environment.sessionVariables.LD_PRELOAD = providerLibPath;

    environment.systemPackages =
      lib.optional needsMozillaFix wrappedMozillaPackages
      ++ lib.optional (cfg.excludedPackages != [ ]) wrappedExcludedPackages
      ++ lib.optional (cfg.excludedCommands != [ ]) wrappedExcludedCommands;

    security.apparmor.includes = {
      "abstractions/base" = ''
        include "${
          pkgs.apparmorRulesFromClosure {
            name = "mallocLib";
            baseRules = [ "mr $path/lib/**.so*" ];
          } [ mallocLib ]
        }"
      '';
    };
  };
}
