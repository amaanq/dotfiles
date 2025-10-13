{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    disabled
    enabled
    merge
    mkIf
    ;
in
merge
<| mkIf config.isDesktop {
  environment.systemPackages =
    let
      krisp-patcher =
        pkgs.writers.writePython3Bin "krisp-patcher"
          {
            libraries = [
              pkgs.python3Packages.capstone
              pkgs.python3Packages.pyelftools
            ];
            flakeIgnore = [
              "E501" # line too long (82 > 79 characters)
              "F403" # 'from module import *' used; unable to detect undefined names
              "F405" # name may be undefined, or defined from star imports: module
            ];
          }
          (
            builtins.readFile (
              pkgs.fetchurl {
                url = "https://raw.githubusercontent.com/sersorrel/sys/afc85e6b249e5cd86a7bcf001b544019091b928c/hm/discord/krisp-patcher.py";
                sha256 = "sha256-h8Jjd9ZQBjtO3xbnYuxUsDctGEMFUB5hzR/QOQ71j/E=";
              }
            )
          );
    in
    [
      krisp-patcher
    ];

  unfree.allowedNames = [
    "discord"
  ];

  home-manager.sharedModules = [
    {
      programs.nixcord = disabled {
        config = {
          useQuickCss = true;
          themeLinks = [ ];

          plugins = {
            alwaysTrust = enabled;
            anonymiseFileNames = enabled {
              anonymiseByDefault = true;
            };
            betterFolders = enabled;
            betterGifAltText = enabled;
            betterRoleContext = enabled;
            betterSessions = enabled;
            betterSettings = enabled;
            betterUploadButton = enabled;
            biggerStreamPreview = enabled;
            callTimer = enabled;
            clearURLs = enabled;
            colorSighted = enabled;
            consoleJanitor = enabled;
            consoleShortcuts = enabled;
            copyFileContents = enabled;
            copyStickerLinks = enabled;
            crashHandler = enabled;
            dearrow = enabled;
            disableCallIdle = enabled;
            experiments = enabled {
              toolbarDevMenu = false;
            };
            expressionCloner = enabled;
            f8Break = enabled;
            fakeNitro = enabled;
            favoriteEmojiFirst = enabled;
            fixCodeblockGap = enabled;
            fixImagesQuality = enabled;
            fixSpotifyEmbeds = enabled;
            fixYoutubeEmbeds = enabled;
            forceOwnerCrown = enabled;
            friendsSince = enabled;
            fullSearchContext = enabled;
            gifPaste = enabled;
            greetStickerPicker = enabled;
            imageFilename = enabled;
            imageZoom = enabled;
            keepCurrentChannel = enabled;
            memberCount = enabled;
            messageLatency = enabled;
            messageLinkEmbeds = enabled;
            messageLogger = enabled;
            mutualGroupDMs = enabled;
            newGuildSettings = enabled;
            noDevtoolsWarning = enabled;
            noF1 = enabled;
            noOnboardingDelay = enabled;
            noPendingCount = enabled {
              hideFriendRequestsCount = false;
              hideMessageRequestCount = false;
            };
            noProfileThemes = enabled;
            noTrack = enabled;
            normalizeMessageLinks = enabled;
            noTypingAnimation = enabled;
            noUnblockToJump = enabled;
            onePingPerDM = enabled;
            openInApp = enabled;
            permissionFreeWill = enabled;
            permissionsViewer = enabled;
            pinDMs = enabled;
            platformIndicators = enabled;
            reactErrorDecoder = enabled;
            relationshipNotifier = enabled;
            replaceGoogleSearch = enabled {
              customEngineName = "Kagi";
              customEngineURL = "https://kagi.com/search?q";
            };
            replyTimestamp = enabled;
            reverseImageSearch = enabled;
            sendTimestamps = enabled;
            serverInfo = enabled;
            serverListIndicators = enabled {
              mode = "onlyServerCount";
            };
            showConnections = enabled;
            showHiddenChannels = enabled;
            showHiddenThings = enabled;
            showTimeoutDuration = enabled;
            silentTyping = enabled;
            sortFriendRequests = enabled {
              showDates = true;
            };
            spotifyControls = enabled;
            spotifyCrack = enabled;
            startupTimings = enabled;
            translate = enabled;
            typingIndicator = enabled;
            typingTweaks = enabled;
            unindent = enabled;
            unlockedAvatarZoom = enabled;
            validUser = enabled;
            voiceDownload = enabled;
            voiceMessages = enabled;
            volumeBooster = enabled;
            youtubeAdblock = enabled;
          };

          # Performance settings
          frameless = false;
          transparent = false;
          disableMinSize = false;
        };
      };
    }
  ];
}
