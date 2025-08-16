{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib)
    merge
    mkIf
    optional
    listToAttrs
    nameValuePair
    ;

  # Helper function to create extension configs for any chromium-based browser
  mkBrowserExtensions =
    browser: extensions:
    listToAttrs (
      map (
        ext:
        nameValuePair ".config/${browser}/External Extensions/${ext.id}.json" {
          text = builtins.toJSON (
            if ext ? crxPath then
              {
                external_crx = ext.crxPath;
                external_version = ext.version;
              }
            else
              {
                external_update_url = ext.updateUrl or "https://clients2.google.com/service/update2/crx";
              }
          );
          force = false;
        }
      ) extensions
    );

  thoriumExtensions = [
    { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden Password Manager
    { id = "lckanjgmijmafbedllaakclkaicjfmnk"; } # ClearURLs
    { id = "jjicbefpemnphinccgikpdaagjebbnhg"; } # CSFloat Market Checker
    { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
    { id = "camiehngogdpflplmapknnjkeeofhfop"; } # Extenssr
    { id = "ghbmnnjooekpmoecnnnilnnbdlolhkhi"; } # Google Docs Offline
    { id = "cdglnehniifkbagbbombnjghhcihifij"; } # Kagi Search
    { id = "nkbihfbeogaeaoehlefnkodbefgpgknn"; } # MetaMask
    { id = "dneaehbmnbhcippjikoajpoabadpodje"; } # Old Reddit Redirect
    { id = "hlepfoohegkhhmjieoechaddaejaokhf"; } # Refined GitHub
    { id = "gebbhagfogifgggkldgodflihgfeippi"; } # Return YouTube Dislike
    { id = "abpdnfjocnmdomablahdcfnoggeeiedb"; } # Save All Resources
    { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; } # SponsorBlock for YouTube
    { id = "jinjaccalgkegednnccohejagnlnfdag"; } # Violentmonkey
    { id = "hkligngkgcpcolhcnkgccglchdafcnao"; } # Web Archives
    {
      id = "dkoaabhijcomjinndlgbmfnmnjnmdeeb"; # AdNauseam
      updateUrl = "https://rednoise.org/adnauseam/updates.xml";
    }
    {
      id = "lkbebcjgcmobigpeffafkodonchffocl"; # Bypass Paywalls Clean
      updateUrl = "https://gitlab.com/magnolia1234/bypass-paywalls-chrome-clean/-/raw/master/updates.xml";
    }
  ];
in
merge
<| mkIf config.isDesktop {
  environment.variables = {
    BROWSER = "thorium";
  };

  environment.systemPackages =
    optional config.isLinux (
      pkgs.symlinkJoin {
        name = "thorium";
        paths = [ inputs.thorium.packages.${pkgs.system}.thorium-avx2 ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/thorium \
            --add-flags "--use-angle=vulkan --enable-quic --quic-version=h3-29 --disable-extensions-file-access-check --disable-extensions-http-throttling --extensions-on-chrome-urls"
        '';
      }
    )
    ++ optional config.isDarwin inputs.thorium.packages.${pkgs.system}.thorium-arm;

  home-manager.sharedModules = [
    {
      home.file = mkBrowserExtensions "thorium" thoriumExtensions;
    }
  ];
}
