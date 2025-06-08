{ lib, pkgs, ... }:
let
  inherit (lib) attrValues;
in
{
  environment.variables = {
    # LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib";
    # LD_LIBRARY_PATH = "${pkgs.openssl.out}/lib:${pkgs.stdenv.cc.cc.lib}/lib";
    # PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig:${pkgs.pkg-config}/lib/pkgconfig";
  };

  environment.systemPackages = attrValues {
    inherit (pkgs)
      clang
      clang-tools
      cmake
      gnumake
      meson
      ninja
      lldb
      llvm
      pkg-config
      ;
    inherit (pkgs.stdenv.cc.cc) lib;
  };

  # "Root" clang-format and clang-tidy configuration files
  home-manager.sharedModules = [
    {
      home.file.".clang-format".text = ''
        AlignArrayOfStructures: Left
        BasedOnStyle: LLVM
        IndentCaseLabels: true
        IndentGotoLabels: true
        IndentPPDirectives: None
        IndentWidth: 4
        InsertNewlineAtEOF: true
        KeepEmptyLinesAtTheStartOfBlocks: false
        SeparateDefinitionBlocks: Always
        SortIncludes: CaseInsensitive
        SortUsingDeclarations: true
        SpaceAfterCStyleCast: false
        SpaceAfterLogicalNot: false
        SpaceBeforeCaseColon: false
        BinPackParameters: true
        BinPackArguments: true
        ColumnLimit: 120
      '';

      home.file.".clang-tidy".text = ''
        Checks: "*,clang-analyzer-optin-performance.Padding,-modernize-use-trailing-return-type,-altera-*,-google-readability-todo,-cppcoreguidelines-avoid-magic-numbers,-llvmlibc-*,-readability-magic-numbers,-hicpp-signed-bitwise,-readability-function-cognitive-complexity,-google-objc-*,-hicpp-avoid-c-arrays,-hicpp-no-array-decay,-fuchsia-*,-cppcoreguidelines-owning-memory,-google-build-using-namespace,-modernize-avoid-c-arrays,-cppcoreguidelines-pro-bounds-array-to-pointer-decay,-cppcoreguidelines-avoid-c-arrays,-cppcoreguidelines-avoid-non-const-global-variables,-performance-no-int-to-ptr,-cert-dc*,-bugprone-reserved-identifier,-hicpp-no-assembler,-readability-isolate-declaration,-cppcoreguidelines-init-variables,-readability-identifier-length,-bugprone-easily-swappable-parameters,-cert-err33-c,-misc-non-private-member-variables-in-classes"
        HeaderFilterRegex: ""
      '';
    }
  ];
}
