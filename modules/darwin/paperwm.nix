{
  pkgs,
  ...
}:
let
  paperWMSpoon = pkgs.fetchFromGitHub {
    owner = "mogenson";
    repo = "PaperWM.spoon";
    rev = "88aa02ad9002d1b5697aeaf9fb27cdb5cedc4964";
    hash = "sha256-c6ltYZKLjZXXin8UaURY0xIrdFvA06aKxC5oty2FCdY=";
  };

  swipeSpoon = pkgs.fetchFromGitHub {
    owner = "mogenson";
    repo = "Swipe.spoon";
    rev = "c56520507d98e663ae0e1228e41cac690557d4aa";
    hash = "sha256-G0kuCrG6lz4R+LdAqNWiMXneF09pLI+xKCiagryBb5k=";
  };

  initLua = /* lua */ ''
    ---@type table
    _G.hs = _G.hs

    PaperWM = hs.loadSpoon("PaperWM")
    Swipe = hs.loadSpoon("Swipe")

    local windowResize = function(offsetWidth, offsetHeight)
      local window = hs.window.focusedWindow()
      if not window then return end

      local window_frame = window:frame()
      local screen_frame = window:screen():frame()

      -- Adjust width
      window_frame.w = window_frame.w + offsetWidth
      window_frame.w = math.max(100, math.min(window_frame.w, screen_frame.w - window_frame.x))

      -- Adjust height
      window_frame.h = window_frame.h + offsetHeight
      window_frame.h = math.max(100, math.min(window_frame.h, screen_frame.h - window_frame.y))

      window:setFrame(window_frame)
    end

    local windowClose = function()
      local window = hs.window.focusedWindow()

      if not window then return end

      window:close()
    end

    local toggleFullscreen = function()
      local window = hs.window.focusedWindow()
      if not window then return end

      window:toggleFullScreen()
    end

    local currentSpaceIndex = function()
      local current_space = hs.spaces.activeSpaceOnScreen()
      local spaces = hs.spaces.allSpaces()[hs.screen.mainScreen():getUUID()]

      local current_index = nil
      for space_index, space in ipairs(spaces) do
        if space == current_space then
          current_index = space_index
          break
        end
      end

      return current_index
    end

    local changeSpaceBy = function(offset)
      -- Use native fast workspace switching
      hs.spaces.gotoSpaceFast(offset)
    end

    local gotoSpace = function(index)
      local current_index = currentSpaceIndex()
      local change_by = index - current_index

      changeSpaceBy(change_by)
    end

    do -- HOTKEYS (niri-style keybinds)
      local mod = { "alt" }
      local mod_shift = { "alt", "shift" }
      local mod_alt = { "alt", "cmd" }
      local mod_ctrl = { "alt", "ctrl" }

      -- FOCUS -- MOD + H/J/K/L (matching niri)
      hs.hotkey.bind(mod, "h", PaperWM.actions.focus_left)
      hs.hotkey.bind(mod, "j", PaperWM.actions.focus_down)
      hs.hotkey.bind(mod, "k", PaperWM.actions.focus_up)
      hs.hotkey.bind(mod, "l", PaperWM.actions.focus_right)

      -- SWAP/MOVE WINDOW -- MOD + SHIFT + H/J/K/L (matching niri)
      hs.hotkey.bind(mod_shift, "h", PaperWM.actions.swap_left)
      hs.hotkey.bind(mod_shift, "j", PaperWM.actions.swap_down)
      hs.hotkey.bind(mod_shift, "k", PaperWM.actions.swap_up)
      hs.hotkey.bind(mod_shift, "l", PaperWM.actions.swap_right)

      -- RESIZE WINDOW -- MOD + ALT + H/J/K/L
      hs.hotkey.bind(mod_alt, "h", function() windowResize(-40, 0) end, nil, function() windowResize(-40, 0) end)
      hs.hotkey.bind(mod_alt, "j", function() windowResize(0, 40) end, nil, function() windowResize(0, 40) end)
      hs.hotkey.bind(mod_alt, "k", function() windowResize(0, -40) end, nil, function() windowResize(0, -40) end)
      hs.hotkey.bind(mod_alt, "l", function() windowResize(40, 0) end, nil, function() windowResize(40, 0) end)

      -- WORKSPACE NAVIGATION -- MOD + U/I (matching niri, using fast gesture-based switching)
      hs.hotkey.bind(mod, "u", function() hs.spaces.gotoSpaceFast(-1) end) -- previous space
      hs.hotkey.bind(mod, "i", function() hs.spaces.gotoSpaceFast(1) end)  -- next space

      -- MOVE WINDOW TO WORKSPACE -- MOD + CTRL + U/I (matching niri)
      local moveWindowToSpace = function(offset)
        local window = hs.window.focusedWindow()
        if not window then return end

        local current_index = currentSpaceIndex()
        local spaces = hs.spaces.allSpaces()[hs.screen.mainScreen():getUUID()]
        local next_index = current_index + offset

        if next_index > #spaces then
          next_index = 1
        elseif next_index <= 0 then
          next_index = #spaces
        end

        local next_space = spaces[next_index]
        hs.spaces.moveWindowToSpace(window, next_space)
        hs.spaces.gotoSpace(next_space)
      end

      hs.hotkey.bind(mod_ctrl, "u", function() moveWindowToSpace(-1) end)
      hs.hotkey.bind(mod_ctrl, "i", function() moveWindowToSpace(1) end)

      -- WORKSPACE NUMBERS -- MOD + 1-9 (matching niri)
      for index = 1, 9 do
        hs.hotkey.bind(mod, tostring(index), function() gotoSpace(index) end)
        hs.hotkey.bind(mod_shift, tostring(index), PaperWM.actions["move_window_" .. index])
      end

      -- WINDOW MANAGEMENT (matching niri)
      hs.hotkey.bind(mod, "c", windowClose)                      -- Mod+C: close window
      hs.hotkey.bind(mod, "v", PaperWM.actions.toggle_floating)  -- Mod+V: toggle floating
      hs.hotkey.bind(mod, "f", toggleFullscreen)                 -- Mod+F: fullscreen window
      hs.hotkey.bind(mod, "d", PaperWM.actions.full_width)       -- Mod+D: maximize width (doesn't toggle back, but won't break PaperWM)
      hs.hotkey.bind(mod_ctrl, "c", PaperWM.actions.center_window) -- Mod+Ctrl+C: center window

      -- SLURP & BARF WINDOW -- MOD + COMMA/PERIOD (matching niri's comma/period)
      hs.hotkey.bind(mod, ",", PaperWM.actions.slurp_in)
      hs.hotkey.bind(mod, ".", PaperWM.actions.barf_out)

      -- APPLICATIONS
      hs.hotkey.bind(mod, "return", function() hs.application.launchOrFocus("Ghostty") end) -- Mod+Return: terminal
      hs.hotkey.bind(mod, "e", function() hs.application.launchOrFocus("Finder") end)       -- Mod+E: file manager
      hs.hotkey.bind(mod, "w", function() hs.application.launchOrFocus("Zen") end)

      PaperWM.swipe_fingers = 3
      PaperWM.swipe_gain = 1.7

      PaperWM:start()
    end

    do -- 3 FINGER VERTICAL SWIPE TO CHANGE SPACES
      local current_id, threshold

      Swipe:start(3, function(direction, distance, id)
        if id ~= current_id then
          current_id = id
          threshold = 0.2 -- 20% of trackpad
          return
        end

        if distance > threshold then
          threshold = math.huge -- only trigger once per swipe

          if direction == "up" then
            changeSpaceBy(1)
          elseif direction == "down" then
            changeSpaceBy(-1)
          end
        end
      end)
    end

    do -- SPACE BUTTONS
      local space_buttons = {}

      local updateSpaceButtons = function()
        for _, button in pairs(space_buttons) do
          button:delete()
        end
        space_buttons = {}

        local current_space = hs.spaces.activeSpaceOnScreen()
        local spaces = hs.spaces.allSpaces()[hs.screen.mainScreen():getUUID()]

        for index = #spaces, 1, -1 do
          local space = spaces[index]

          local title = tostring(index)

          local attributes = space == current_space and {
            color = { red = 1 }
          } or {}

          local button = hs.menubar.new()
          button:setTitle(hs.styledtext.new(title, attributes))
          button:setClickCallback(function()
            gotoSpace(index)
          end)

          table.insert(space_buttons, button)
        end
      end

      hs.spaces.watcher.new(updateSpaceButtons):start()

      updateSpaceButtons()
    end
  '';
in
{
  system.defaults.NSGlobalDomain = {
    _HIHideMenuBar = false; # Only hide menubar on fullscreen.

    AppleInterfaceStyle = "Dark";

    AppleScrollerPagingBehavior = true; # Jump to the spot that was pressed in the scrollbar.
    AppleShowScrollBars = "WhenScrolling";

    NSWindowShouldDragOnGesture = true; # CMD+CTRL click to drag window.
    AppleEnableMouseSwipeNavigateWithScrolls = false;
    AppleEnableSwipeNavigateWithScrolls = false;

    AppleWindowTabbingMode = "always"; # Always prefer tabs for new windows.
    AppleKeyboardUIMode = 3; # Full keyboard access.
    ApplePressAndHoldEnabled = false; # No ligatures when you press and hold a key, just repeat it.

    NSScrollAnimationEnabled = true;
    NSWindowResizeTime = 0.003;

    "com.apple.keyboard.fnState" = false; # Don't invert Fn.
    "com.apple.trackpad.scaling" = 1.5; # Faster mouse speed.

    InitialKeyRepeat = 10; # N * 15ms to start repeating, so about 150ms to start repeating.
    KeyRepeat = 1; # N * 15ms, so 15ms between each keypress, about 66 presses per second. Very slow but it doesn't go faster than this.

    NSAutomaticCapitalizationEnabled = false;
    NSAutomaticDashSubstitutionEnabled = false;
    NSAutomaticInlinePredictionEnabled = false;
    NSAutomaticPeriodSubstitutionEnabled = false;
    NSAutomaticQuoteSubstitutionEnabled = false;

    NSNavPanelExpandedStateForSaveMode = true; # Expand save panel by default.
    PMPrintingExpandedStateForPrint = true; # Expand print panel by default.

    AppleSpacesSwitchOnActivate = false; # Do not switch workspaces implicitly.
  };

  system.defaults.CustomSystemPreferences."com.apple.dock".workspaces-auto-swoosh = false; # Read `AppleSpacesSwitchOnActivate`.

  system.defaults.CustomSystemPreferences."com.apple.CoreBrightness" = {
    "Keyboard Dim Time" = 60;
    KeyboardBacklight.KeyboardBacklightIdleDimTime = 60;
  };

  system.defaults.CustomSystemPreferences."com.apple.AppleMultitouchTrackpad" = {
    TrackpadThreeFingerVertSwipeGesture = 0; # Four finger swipe up for mission control.

    # Disable 3 finger horizontal stuff.
    TrackpadFourFingerHorizSwipeGesture = 0;
    TrackpadThreeFingerHorizSwipeGesture = 0;

    # Smooth clicking.
    FirstClickThreshold = 0;
    SecondClickThreshold = 0;
  };

  system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = true;

  system.defaults.CustomSystemPreferences."com.apple.Accessibility".ReduceMotionEnabled = 1;
  system.defaults.universalaccess.reduceMotion = true;

  system.defaults.WindowManager = {
    AppWindowGroupingBehavior = false; # Show them one at a a time.
  };

  # Hammerspoon reads directly from /etc/hammerspoon (MJConfigFile set in hammerspoon.nix)
  environment.etc."hammerspoon/init.lua".text = initLua;
  environment.etc."hammerspoon/Spoons/PaperWM.spoon".source = paperWMSpoon;
  environment.etc."hammerspoon/Spoons/Swipe.spoon".source = swipeSpoon;
}
