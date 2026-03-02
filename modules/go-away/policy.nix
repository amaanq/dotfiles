# Shared go-away policy definitions.
#
# Usage:
#   let policy = import ./policy.nix; in
#   policy.mkPolicy {
#     staticAssets = [ ... ];           # is-static-asset condition entries
#     serviceRules = [ ... ];           # service-specific rules (inserted between shared early/late)
#     extraChallenges = [ "http-cookie-check" ];  # prepended to challenge lists (optional)
#     extraChallengeDefs = { ... };     # additional challenge definitions (optional)
#     extraConditions = { ... };        # additional condition definitions (optional)
#     wellKnownExtras = [ ... ];        # extra is-well-known-asset entries (optional)
#   }
{
  networks = {
    googlebot = [
      {
        url = "https://developers.google.com/static/search/apis/ipranges/googlebot.json";
        jq-path = ''(.prefixes[] | select(has("ipv4Prefix")) | .ipv4Prefix), (.prefixes[] | select(has("ipv6Prefix")) | .ipv6Prefix)'';
      }
    ];
    bingbot = [
      {
        url = "https://www.bing.com/toolbox/bingbot.json";
        jq-path = ''(.prefixes[] | select(has("ipv4Prefix")) | .ipv4Prefix), (.prefixes[] | select(has("ipv6Prefix")) | .ipv6Prefix)'';
      }
    ];
    duckduckbot = [
      {
        url = "https://duckduckgo.com/duckduckgo-help-pages/results/duckduckbot";
        regex = ''<li><div>(?P<prefix>[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)</div></li>'';
      }
    ];
    kagibot = [
      {
        url = "https://kagi.com/bot";
        regex = ''\n(?P<prefix>[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) '';
      }
    ];
    qwantbot = [
      {
        url = "https://help.qwant.com/wp-content/uploads/sites/latest/qwantbot.json";
        jq-path = ''(.prefixes[] | select(has("ipv4Prefix")) | .ipv4Prefix), (.prefixes[] | select(has("ipv6Prefix")) | .ipv6Prefix)'';
      }
    ];
    yandexbot = [
      {
        prefixes = [
          "5.45.192.0/18"
          "5.255.192.0/18"
          "37.9.64.0/18"
          "37.140.128.0/18"
          "77.88.0.0/18"
          "84.252.160.0/19"
          "87.250.224.0/19"
          "90.156.176.0/22"
          "93.158.128.0/18"
          "95.108.128.0/17"
          "141.8.128.0/18"
          "178.154.128.0/18"
          "185.32.187.0/24"
          "2a02:6b8::/29"
        ];
      }
    ];
    uptimerobot = [
      {
        url = "https://uptimerobot.com/inc/files/ips/IPv4andIPv6.txt";
        regex = ''(?P<prefix>[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?|[0-9a-f:]+:.+)'';
      }
    ];
    betterstack = [
      {
        url = "https://uptime.betterstack.com/ips-by-cluster.json";
        jq-path = ".[] | .[]";
      }
    ];
    huawei-cloud = [ { asn = 136907; } ];
    alibaba-cloud = [ { asn = 45102; } ];
    zenlayer-inc = [ { asn = 21859; } ];
    aws-cloud = [
      {
        url = "https://ip-ranges.amazonaws.com/ip-ranges.json";
        jq-path = ''(.prefixes[] | select(has("ip_prefix")) | .ip_prefix), (.prefixes[] | select(has("ipv6_prefix")) | .ipv6_prefix)'';
      }
    ];
    google-cloud = [
      {
        url = "https://www.gstatic.com/ipranges/cloud.json";
        jq-path = ''(.prefixes[] | select(has("ipv4Prefix")) | .ipv4Prefix), (.prefixes[] | select(has("ipv6Prefix")) | .ipv6Prefix)'';
      }
    ];
  };

  challenges = {
    cookie.runtime = "cookie";
    preload-link = {
      condition = ''"Sec-Fetch-Mode" in headers && headers["Sec-Fetch-Mode"] == "navigate"'';
      runtime = "preload-link";
      parameters.preload-early-hint-deadline = "2s";
    };
    header-refresh = {
      runtime = "refresh";
      parameters.refresh-via = "header";
    };
    meta-refresh = {
      runtime = "refresh";
      parameters.refresh-via = "meta";
    };
    resource-load.runtime = "resource-load";
    js-refresh = {
      runtime = "refresh";
      parameters.refresh-via = "javascript";
    };
    js-pow-sha256 = {
      runtime = "js";
      parameters = {
        path = "js-pow-sha256";
        js-loader = "load.mjs";
        wasm-runtime = "runtime.wasm";
        wasm-runtime-settings.difficulty = 20;
        verify-probability = 0.02;
      };
    };
    dnsbl = {
      runtime = "dnsbl";
      parameters = {
        dnsbl-decay = "1h";
        dnsbl-timeout = "1s";
      };
    };
  };

  conditions = {
    is-bot-googlebot = [
      ''(userAgent.contains("+http://www.google.com/bot.html") || userAgent.contains("Google-PageRenderer") || userAgent.contains("Google-InspectionTool") || userAgent.contains("Googlebot")) && remoteAddress.network("googlebot")''
    ];
    is-bot-bingbot = [
      ''userAgent.contains("+http://www.bing.com/bingbot.htm") && remoteAddress.network("bingbot")''
    ];
    is-bot-duckduckbot = [
      ''userAgent.contains("+http://duckduckgo.com/duckduckbot.html") && remoteAddress.network("duckduckbot")''
    ];
    is-bot-kagibot = [
      ''userAgent.contains("+https://kagi.com/bot") && remoteAddress.network("kagibot")''
    ];
    is-bot-qwantbot = [
      ''userAgent.contains("+https://help.qwant.com/bot/") && remoteAddress.network("qwantbot")''
    ];
    is-bot-yandexbot = [
      ''userAgent.contains("+http://yandex.com/bots") && remoteAddress.network("yandexbot")''
    ];
    is-bot-uptimerobot = [
      ''userAgent.contains("http://www.uptimerobot.com/") && remoteAddress.network("uptimerobot")''
    ];
    is-bot-betterstack = [
      ''((userAgent.startsWith("Better Stack Better Uptime Bot") || userAgent.startsWith("Better Uptime Bot"))) && remoteAddress.network("betterstack")''
    ];
    is-generic-browser = [
      ''userAgent.startsWith("Mozilla/") || userAgent.startsWith("Opera/")''
    ];
    is-generic-robot-ua = [
      ''userAgent.matches("compatible[;)]") && !userAgent.contains("Trident/")''
      ''userAgent.matches("\\+https?://")''
      ''userAgent.contains("@")''
      ''userAgent.matches("[bB]ot/[0-9]")''
    ];
    is-tool-ua = [
      ''userAgent.startsWith("python-requests/")''
      ''userAgent.startsWith("Python-urllib/")''
      ''userAgent.startsWith("python-httpx/")''
      ''userAgent.contains("aoihttp/")''
      ''userAgent.startsWith("http.rb/")''
      ''userAgent.startsWith("curl/")''
      ''userAgent.startsWith("Wget/")''
      ''userAgent.startsWith("libcurl/")''
      ''userAgent.startsWith("okhttp/")''
      ''userAgent.startsWith("Java/")''
      ''userAgent.startsWith("Apache-HttpClient//")''
      ''userAgent.startsWith("Go-http-client/")''
      ''userAgent.startsWith("node-fetch/")''
      ''userAgent.startsWith("reqwest/")''
    ];
    is-headless-chromium = [
      ''userAgent.contains("HeadlessChrome") || userAgent.contains("HeadlessChromium")''
      ''"Sec-Ch-Ua" in headers && (headers["Sec-Ch-Ua"].contains("HeadlessChrome") || headers["Sec-Ch-Ua"].contains("HeadlessChromium"))''
    ];
    is-suspicious-crawler = [
      ''(userAgent.startsWith("Mozilla/") || userAgent.startsWith("Opera/")) && ("ja4" in fp && fp.ja4.matches("^t[0-9a-z]+00_")) && !(userAgent.contains("compatible;") || userAgent.contains("+http") || userAgent.contains("facebookexternalhit/") || userAgent.contains("Twitterbot/"))''
      ''userAgent.contains("Presto/") || userAgent.contains("Trident/")''
      ''userAgent.matches("MSIE ([2-9]|10|11)\\.")''
      ''userAgent.matches("Linux i[63]86") || userAgent.matches("FreeBSD i[63]86")''
      ''userAgent.matches("Windows (3|95|98|CE)") || userAgent.matches("Windows NT [1-5]\\.")''
      ''userAgent.matches("Android [1-5]\\.") || userAgent.matches("(iPad|iPhone) OS [1-9]_")''
      ''userAgent.startsWith("Opera/")''
      ''userAgent.matches("^Mozilla/[1-4]")''
    ];
  };

  # Build a complete policy from shared + service-specific pieces.
  #
  # extraChallenges: list of challenge names prepended to various challenge lists
  #   (e.g. ["http-cookie-check"] for forgejo's session validation)
  # extraChallengeDefs: additional challenge definitions to merge
  # staticAssets: list of CEL conditions for is-static-asset
  # wellKnownExtras: extra entries for is-well-known-asset (appended to defaults)
  # extraConditions: additional condition definitions to merge
  # serviceRules: service-specific rules inserted between shared early/late rules
  mkPolicy =
    {
      extraChallenges ? [ ],
      extraChallengeDefs ? { },
      staticAssets,
      wellKnownExtras ? [ ],
      extraConditions ? { },
      serviceRules ? [ ],
    }:
    let
      self = import ./policy.nix;

      wellKnownBase = [
        ''path == "/robots.txt" || path == "/security.txt"''
        ''path == "/favicon.ico"''
        ''path.startsWith("/.well-known/")''
      ];

      undesiredCrawlerConditions = [
        "($is-headless-chromium)"
        ''userAgent.startsWith("Lightpanda/")''
        ''userAgent.startsWith("masscan/")''
        ''userAgent.matches("^Opera/[0-9.]+\\.\\(")''
        ''userAgent.contains("Bytedance") || userAgent.contains("Bytespider") || userAgent.contains("TikTokSpider")''
        ''userAgent.contains("meta-externalagent/") || userAgent.contains("meta-externalfetcher/") || userAgent.contains("FacebookBot")''
        ''userAgent.contains("ClaudeBot") || userAgent.contains("Claude-User") || userAgent.contains("Claude-SearchBot")''
        ''userAgent.contains("CCBot")''
        ''userAgent.contains("GPTBot") || userAgent.contains("OAI-SearchBot") || userAgent.contains("ChatGPT-User")''
        ''userAgent.contains("Amazonbot") || userAgent.contains("Google-Extended") || userAgent.contains("PanguBot") || userAgent.contains("AI2Bot") || userAgent.contains("Diffbot") || userAgent.contains("cohere-training-data-crawler") || userAgent.contains("Applebot-Extended")''
        ''userAgent.contains("BLEXBot")''
      ];

      earlyRules = [
        {
          name = "allow-well-known-resources";
          conditions = [ "($is-well-known-asset)" ];
          action = "pass";
        }
        {
          name = "allow-static-resources";
          conditions = [ "($is-static-asset)" ];
          action = "pass";
        }
        {
          name = "desired-crawlers";
          conditions = [
            "($is-bot-googlebot)"
            "($is-bot-bingbot)"
            "($is-bot-duckduckbot)"
            "($is-bot-kagibot)"
            "($is-bot-qwantbot)"
            "($is-bot-yandexbot)"
          ];
          action = "pass";
        }
        {
          name = "monitoring-bots";
          conditions = [
            "($is-bot-uptimerobot)"
            "($is-bot-betterstack)"
          ];
          action = "pass";
        }
        {
          name = "undesired-networks";
          conditions = [
            ''remoteAddress.network("huawei-cloud") || remoteAddress.network("alibaba-cloud") || remoteAddress.network("zenlayer-inc") || remoteAddress.network("aws-cloud") || remoteAddress.network("google-cloud")''
          ];
          action = "drop";
        }
        {
          name = "undesired-crawlers";
          conditions = undesiredCrawlerConditions;
          action = "drop";
        }
        {
          name = "unknown-crawlers";
          conditions = [ ''userAgent == ""'' ];
          action = "deny";
        }
        {
          name = "suspicious-crawlers";
          conditions = [ "($is-suspicious-crawler)" ];
          action = "none";
          children = [
            {
              name = "0";
              action = "check";
              settings.challenges = [ "js-refresh" ] ++ extraChallenges;
            }
            {
              name = "1";
              action = "check";
              settings.challenges = [
                "preload-link"
                "resource-load"
              ];
            }
            {
              name = "2";
              action = "check";
              settings.challenges = [ "header-refresh" ];
            }
          ];
        }
      ];

      lateRules = [
        {
          name = "undesired-dnsbl";
          action = "check";
          settings = {
            challenges = [ "dnsbl" ];
            fail = "check";
            fail-settings.challenges = [ "js-refresh" ] ++ extraChallenges;
          };
        }
        {
          name = "non-get-request";
          action = "pass";
          conditions = [ ''!(method == "HEAD" || method == "GET")'' ];
        }
        {
          name = "enable-meta-tags";
          action = "context";
          conditions = [
            ''userAgent.contains("facebookexternalhit/") || userAgent.contains("Facebot/") || userAgent.contains("Twitterbot/")''
            "($is-generic-robot-ua)"
            "!($is-generic-browser)"
          ];
          settings.context-set.proxy-meta-tags = "true";
        }
        {
          name = "plaintext-browser";
          action = "challenge";
          settings.challenges = extraChallenges ++ [
            "meta-refresh"
            "cookie"
          ];
          conditions = [ ''userAgent.startsWith("Lynx/")'' ];
        }
        {
          name = "standard-tools";
          action = "challenge";
          settings.challenges = [ "cookie" ];
          conditions = [
            "($is-tool-ua)"
            "!($is-generic-browser)"
          ];
        }
        {
          name = "standard-browser";
          action = "challenge";
          settings.challenges = extraChallenges ++ [
            "preload-link"
            "meta-refresh"
            "resource-load"
            "js-refresh"
            "js-pow-sha256"
          ];
          conditions = [ "($is-generic-browser)" ];
        }
      ];
    in
    {
      inherit (self) networks;
      challenges = self.challenges // extraChallengeDefs;
      conditions =
        self.conditions
        // {
          is-well-known-asset = wellKnownBase ++ wellKnownExtras;
          is-static-asset = staticAssets;
        }
        // extraConditions;
      rules = earlyRules ++ serviceRules ++ lateRules;
    };
}
