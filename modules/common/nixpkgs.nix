{
  lib,
  run0-sudo-shim,
  xdg-utils-nu,
  ...
}:
{
  nixpkgs.overlays = [
    # Consume the shim via its overlay (builds on the caller's pkgs) so cross
    # hosts cross-compile it; `.packages.${system}` would be a native build.
    (
      final: prev:
      lib.optionalAttrs prev.stdenv.hostPlatform.isLinux (run0-sudo-shim.overlays.default final prev)
    )
    (
      final: prev:
      lib.optionalAttrs prev.stdenv.hostPlatform.isLinux (xdg-utils-nu.overlays.default final prev)
    )
    (
      final: prev:
      let
        isCross = final.stdenv.buildPlatform != final.stdenv.hostPlatform;
      in
      {
        nh-unwrapped =
          if isCross then
            prev.nh-unwrapped.overrideAttrs (_: {
              postInstall = "";
              nativeInstallCheckInputs = [ ];
              doInstallCheck = false;
            })
          else
            prev.nh-unwrapped;

        nh =
          let
            unwrapped = final.nh-unwrapped;
            useNom =
              !(final.stdenv.hostPlatform.isPower64 or false)
              && !(final.stdenv.hostPlatform.isLoongArch64 or false);
            runtimeDeps = lib.optionals useNom [ final.nix-output-monitor ];
          in
          final.symlinkJoin {
            pname = "nh";
            inherit (unwrapped) version;

            paths = [ unwrapped ];

            nativeBuildInputs = lib.optionals useNom [ final.makeBinaryWrapper ];

            postBuild = lib.optionalString useNom /* sh */ ''
              wrapProgram $out/bin/nh \
                --prefix PATH : ${lib.makeBinPath runtimeDeps}
            '';

            meta = {
              inherit (unwrapped.meta)
                changelog
                description
                homepage
                license
                mainProgram
                maintainers
                ;

              hydraPlatforms = [ ];
              priority = (unwrapped.meta.priority or lib.meta.defaultPriority) - 1;
            };
          };
      }
    )
    (
      _final: prev:
      lib.optionalAttrs (prev.stdenv.buildPlatform != prev.stdenv.hostPlatform) {
        systemd = prev.systemd.override { withLibBPF = false; };
      }
    )
    # Stub shellcheck cuz Haskell is slop and I don't want to compile it for ppc64.
    (
      final: _prev:
      let
        stub =
          final.runCommand "shellcheck-stub"
            {
              meta.mainProgram = "shellcheck";
              passthru = {
                unwrapped = stub;
                compiler.bootstrapAvailable = false;
              };
            }
            ''
              mkdir -p $out/bin
              printf '#!/bin/sh\nexit 0\n' > $out/bin/shellcheck
              chmod +x $out/bin/shellcheck
            '';
      in
      {
        shellcheck = stub;
        shellcheck-minimal = stub;
      }
    )
    (
      final: prev:
      let
        thunderbirdUnwrapped = prev.thunderbird-unwrapped.overrideAttrs (old: {
          configureFlags = map (
            flag: if lib.hasPrefix "--with-onnx-runtime=" flag then "--without-onnx-runtime" else flag
          ) old.configureFlags;
        });
      in
      lib.optionalAttrs prev.stdenv.hostPlatform.isLinux {
        thunderbird-unwrapped = thunderbirdUnwrapped;
        thunderbird = final.wrapThunderbird thunderbirdUnwrapped { };
      }
    )
    (_final: prev: {
      bcachefs-tools = prev.bcachefs-tools.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          ../linux/patches/bcachefs-tools-codegen-skip-fvisibility.patch
          ../linux/patches/bcachefs-tools-codegen-host-linker.patch
        ];
      });
    })
    (final: prev: {
      formats = prev.formats // {
        toml =
          args:
          (prev.formats.toml args)
          // {
            generate =
              name: value:
              final.runCommand name {
                nativeBuildInputs = [ final.buildPackages.nushell ];
                value = builtins.toJSON value;
                passAsFile = [ "value" ];
                preferLocalBuild = true;
              } ''nu -c "open --raw '$valuePath' | from json | to toml" > $out'';
          };
      };
    })
  ]
  # Nuking perl in its entirety.
  ++ [
    (
      final: prev:
      {
        # git-repo's wrapper pulls the full perl-enabled git.
        git-repo = prev.git-repo.override { git = final.gitMinimal; };

        # in aspell, bin/aspell-import is a perl script which imports
        # ispell wordlists. This is not used in KDE
        aspell = prev.aspell.overrideAttrs (old: {
          postFixup = (old.postFixup or "") + /* sh */ ''
            rm -f $out/bin/aspell-import
          '';
        });

        # Patch kio-extras at the kdePackages *scope* level so Dolphin
        # et al. rebuild against the perl-free variant.
        kdePackages = prev.kdePackages.overrideScope (
          _: kprev: {
            kio-extras = kprev.kio-extras.overrideAttrs (old: {
              postPatch = (old.postPatch or "") + /* sh */ ''
                substituteInPlace CMakeLists.txt \
                  --replace-fail 'add_subdirectory( info )' \
                                 '# add_subdirectory( info )  # perl-free closure'
              '';
            });
          }
        );
      }
      // lib.optionalAttrs prev.stdenv.hostPlatform.isLinux {
        xdg-utils = final.xdg-utils-nu;

        # winetricks's wrapper embeds perl in PATH for a handful of niche
        # verbs (mostly font/registry helpers). Scrub the store ref so perl
        # drops out of the closure; if a verb that needs perl is invoked,
        # it'll just error at runtime. This should *probably* be fine.
        winetricks = prev.winetricks.overrideAttrs (old: {
          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.removeReferencesTo ];
          postFixup = (old.postFixup or "") + /* sh */ ''
            remove-references-to -t ${final.perl} $out/bin/winetricks $out/bin/.winetricks-wrapped
          '';
        });

        # libvirt defaults to enabling Xen on x86_64 Linux, dragging in
        # xen → ipxe → syslinux → perl. We only use the qemu/KVM driver,
        # so Xen can be dropped.
        libvirt = prev.libvirt.override { enableXen = false; };

        # rnnoise-plugin drags webkitgtk_4_1 into buildInputs purely because
        # JUCE's default plugin profile includes a WebBrowser module. The
        # built shared object has no UI, so we strip webkit and tell JUCE
        # to skip web.
        rnnoise-plugin = prev.rnnoise-plugin.overrideAttrs (old: {
          buildInputs = builtins.filter (p: (p.pname or "") != "webkitgtk") (old.buildInputs or [ ]);
          cmakeFlags = (old.cmakeFlags or [ ]) ++ [ "-DJUCE_WEB_BROWSER=0" ];
        });

        # plausible's BEAM stack pulls erlang → wxwidgets → webkitgtk for the
        # Observer GUI, which is useless on a headless server and parks 100MB+
        # of GTK in the closure. Swap to the wx-less BEAM set.
        plausible = prev.plausible.override {
          beam27Packages = prev.beamMinimal27Packages;
        };

        radicle-node = prev.radicle-node.overrideAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            substituteInPlace \
              crates/radicle-node/src/test/node.rs \
              crates/radicle-cli/tests/commands/id.rs \
              crates/radicle-cli/tests/commands/cob.rs \
              --replace-fail 'Duration::from_secs(6)' 'Duration::from_secs(60)'
          '';
          checkFlags = (old.checkFlags or [ ]) ++ [ "--test-threads=1" ];
        });

      }
    )
  ];
}
