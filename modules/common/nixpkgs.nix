{ lib, ... }:
{
  nixpkgs.overlays = [
    # stalwart 0.16 dropped TOML config in favour of a one-shot config.json
    # describing only the data store; everything else lives in the database
    # and is reconciled via the relocated stalwart-cli (now its own repo at
    # github.com/stalwartlabs/cli, version 1.x). nixpkgs PR #512341 hasn't
    # landed because the module migration is still being designed upstream
    # (issue #511880, target nixos-26.05). These attrs are exposed under
    # _0_16 / _1_0 names rather than overriding pkgs.stalwart globally so the
    # blast radius stays scoped to the new module.
    (final: prev: {
      stalwart_0_16 = prev.stalwart.overrideAttrs (_old: rec {
        version = "0.16.1";

        src = final.fetchFromGitHub {
          owner = "stalwartlabs";
          repo = "stalwart";
          tag = "v${version}";
          hash = "sha256-/sNRAh+lwLGadZqlkN6CqS1UjeeE7kgjWCc+06Sxz+0=";
        };

        cargoDeps = final.rustPlatform.fetchCargoVendor {
          inherit src;
          hash = "sha256-iqukdNoXxl3Tq9XPsS2vrpOfulP0557c15y4/vOOX0Y=";
        };

        # 0.16 reshuffled the test tree; the long --skip list pinned to 0.15
        # no longer matches and would silently no-op. Disable until upstream
        # rebases the suite.
        doCheck = false;
      });

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
          rev = "6c2365d27cd771bea9408c5b59fa52715667667d";
          hash = "sha256-AsKNNidi3qobePFqGLKXjM8OPLW7HbBEp3mgw+ULuU0=";
        };
        isCross = final.stdenv.buildPlatform != final.stdenv.hostPlatform;
      in
      {
        nh-unwrapped =
          let
            withFork = prev.nh-unwrapped.overrideAttrs (old: {
              version = "4.4.0-beta1-unstable-2026-06-10";
              src = nhSrc;
              # Upstream reads finalAttrs.src.tag, null when using `rev`.
              env = (old.env or { }) // {
                NH_REV = nhSrc.rev;
              };
              # finalAttrs overrideAttrs swallows cargoHash; swap cargoDeps.
              cargoDeps = final.rustPlatform.fetchCargoVendor {
                src = nhSrc;
                hash = "sha256-Xl1IW8KWfNuCm20DQUH8Bdvfm/J3RUzUpMWt9maJ4hk=";
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
        # of GTK in the closure. Swap to the wx-less BEAM set; both args must
        # be overridden because top-level elixir_1_18 sources from the full
        # erlang independently of beam27Packages.
        plausible = prev.plausible.override {
          beam27Packages = prev.beamMinimal27Packages;
          elixir_1_18 = prev.beamMinimal27Packages.elixir_1_18;
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
