{
  lib,
  ...
}:
{
  nixpkgs.overlays = [
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
    )
  ];
}
