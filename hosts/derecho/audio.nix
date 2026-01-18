{ pkgs, ... }:
{
  services.pipewire.wireplumber.extraConfig."90-game-audio-routing" = {
    "monitor.alsa.rules" = [
      {
        matches = [ { "application.name" = "SDL Application"; } ];
        actions.update-props = {
          "target.object" = "Game-Output-Proxy";
        };
      }
    ];
  };

  services.pipewire.extraConfig.pipewire = {
    # Virtual sink for streaming game audio to Discord
    "91-null-sinks" = {
      "context.objects" = [
        {
          factory = "adapter";
          args = {
            "factory.name" = "support.null-audio-sink";
            "node.name" = "Game-Output-Proxy";
            "node.description" = "Game Output (for streaming)";
            "media.class" = "Audio/Sink";
            "audio.position" = "FL,FR";
            "audio.rate" = 48000;
            # Loopback to default sink so you still hear it
            "monitor.channel-volumes" = true;
            "monitor.passthrough" = true;
          };
        }
      ];
    };

    # RNNoise virtual mic for noise cancellation
    "92-rnnoise" = {
      "context.modules" = [
        {
          name = "libpipewire-module-filter-chain";
          args = {
            "node.description" = "Noise Canceling source";
            "media.name" = "Noise Canceling source";
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  name = "rnnoise";
                  plugin = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                  label = "noise_suppressor_mono";
                  control = {
                    "VAD Threshold (%)" = 50.0;
                    "VAD Grace Period (ms)" = 200;
                    "Retroactive VAD Grace (ms)" = 0;
                  };
                }
              ];
            };
            "capture.props" = {
              "node.name" = "capture.rnnoise_source";
              "node.passive" = true;
              "audio.rate" = 48000;
            };
            "playback.props" = {
              "node.name" = "rnnoise_source";
              "media.class" = "Audio/Source";
              "audio.rate" = 48000;
            };
          };
        }
      ];
    };

    "93-game-loopback" = {
      "context.modules" = [
        {
          name = "libpipewire-module-loopback";
          args = {
            "node.description" = "Game Audio Loopback";
            "capture.props" = {
              "node.name" = "game-loopback-capture";
              "audio.position" = "FL,FR";
              "stream.dont-remix" = true;
              "node.passive" = true;
              "node.target" = "Game-Output-Proxy";
            };
            "playback.props" = {
              "node.name" = "game-loopback-playback";
              "audio.position" = "FL,FR";
              "stream.dont-remix" = true;
              "node.passive" = true;
            };
          };
        }
      ];
    };
  };
}
