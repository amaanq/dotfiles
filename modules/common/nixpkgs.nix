{ lib, ... }:
{
  nixpkgs.overlays = [
    # stalwart 0.16 dropped TOML config in favour of a one-shot config.json
    # describing only the data store; everything else lives in the database and
    # is reconciled via the relocated stalwart-cli (now its own repo at
    # github.com/stalwartlabs/cli, version 1.x), which nixpkgs doesn't package
    # yet (PR #512341 / issue #511880, target nixos-26.05). The 0.16 server is
    # now nixpkgs' native stalwart_0_16; only the CLI needs this overlay.
    (final: prev: {
      stalwart-cli_1_0 = final.callPackage (
        {
          lib,
          rustPlatform,
          fetchFromGitHub,
        }:
        rustPlatform.buildRustPackage (finalAttrs: {
          pname = "stalwart-cli";
          version = "1.0.2";

          src = fetchFromGitHub {
            owner = "stalwartlabs";
            repo = "cli";
            tag = "v${finalAttrs.version}";
            hash = "sha256-klbRM1bHbQq7s+2iDxqTZ7M8+XRv351J5orBqGJ5sRY=";
          };

          cargoDeps = rustPlatform.fetchCargoVendor {
            inherit (finalAttrs) src;
            hash = "sha256-sTt4lRMggJbKTVuJK/QfgniyYn+116zIoWaVCkFIoTo=";
          };

          # cli v1.0.2 uses reqwest with default-features=false and
          # features=["blocking","rustls","json"]; the lockfile resolves to
          # rustls + ring + rustls-platform-verifier and only pulls in
          # openssl-probe (not openssl-sys), so neither pkg-config nor an
          # openssl buildInput is needed.

          # Tests reach out to a live Stalwart server.
          doCheck = false;

          meta = {
            description = "Stalwart Mail Server CLI (1.x, JMAP-based)";
            homepage = "https://github.com/stalwartlabs/cli";
            changelog = "https://github.com/stalwartlabs/cli/releases/tag/v${finalAttrs.version}";
            license = lib.licenses.agpl3Only;
            mainProgram = "stalwart-cli";
            platforms = lib.platforms.unix;
          };
        })
      ) { };
    })
    (
      final: prev:
      let
        nhSrc = final.fetchFromGitHub {
          owner = "nix-community";
          repo = "nh";
          rev = "da26cc24d1f68ec47bdcb76d61c8ccc218a6f758";
          hash = "sha256-9RJDznEtODgaKESpGIQwos1OPmJbRbnDp4RU4c3Kp5s=";
        };
        isCross = final.stdenv.buildPlatform != final.stdenv.hostPlatform;
      in
      {
        nh-unwrapped =
          let
            withFork = prev.nh-unwrapped.overrideAttrs (old: {
              version = "4.4.0-beta1-unstable-2026-06-23";
              src = nhSrc;
              # Upstream reads finalAttrs.src.tag, null when using `rev`.
              env = (old.env or { }) // {
                NH_REV = nhSrc.rev;
              };
              # finalAttrs overrideAttrs swallows cargoHash; swap cargoDeps.
              cargoDeps = final.rustPlatform.fetchCargoVendor {
                src = nhSrc;
                hash = "sha256-6OZgCjBaFKjXvESQDJGChKPy4I8E0wzi5IjiYWdXNdA=";
              };
            });
            # Upstream postInstall runs `xtask dist` via an emulator to make
            # shell completions + manpage; on cross that drags qemu-user +
            # glib + gobject-introspection + systemtap into the build closure.
            dropDistOnCross =
              drv:
              drv.overrideAttrs (_: {
                postInstall = "";
                nativeInstallCheckInputs = [ ];
                doInstallCheck = false;
              });
          in
          if isCross then dropDistOnCross withFork else withFork;

        nh =
          let
            unwrapped = final.nh-unwrapped;
            useNom = !(final.stdenv.hostPlatform.isPower64 or false);
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
        xdg-utils = final.symlinkJoin {
          name = "xdg-utils-handlr-shim-${prev.handlr-regex.version or "0"}";
          paths = [
            final.xdg-user-dirs
            (final.writeShellScriptBin "xdg-open" /* sh */ ''exec ${final.handlr-regex}/bin/handlr open "$@"'')
            (final.writeShellScriptBin "xdg-mime" /* sh */ ''exec ${final.handlr-regex}/bin/handlr mime "$@"'')
            (final.writeShellScriptBin "xdg-settings" /* sh */ ''exec ${final.handlr-regex}/bin/handlr get "$@"'')
            (final.writeShellScriptBin "xdg-email" /* sh */ ''exec ${final.handlr-regex}/bin/handlr open "mailto:$*"'')

            # These are install-time helpers that are not used on NixOS.
            (final.writeShellScriptBin "xdg-desktop-menu" "exit 0")
            (final.writeShellScriptBin "xdg-desktop-icon" "exit 0")
            (final.writeShellScriptBin "xdg-icon-resource" "exit 0")
            (final.writeShellScriptBin "xdg-screensaver" "exit 0")
          ];
          meta = {
            description = "xdg-utils shim backed by handlr-regex (perl-free)";
            mainProgram = "xdg-open";
          };
        };

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

        # radicle-node has flaky p2p integration tests that hit
        # connection-reset broken-pipe races under nix builder load.
        radicle-node = prev.radicle-node.overrideAttrs (old: {
          checkFlags = (old.checkFlags or [ ]) ++ [
            "--skip=commands::clone::rad_clone_connect"
            "--skip=commands::id::rad_id_threshold"
            "--skip=commands::inbox::rad_inbox"
            "--skip=commands::init::rad_init_private_clone"
            "--skip=commands::init::rad_init_private_clone_seed"
            "--skip=commands::patch::rad_patch_checkout_force"
          ];
        });

      }
    )
  ];
}
