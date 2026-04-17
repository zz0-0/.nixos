{ config, pkgs, ... }:

let
  # Script to configure niri outputs based on connected monitors
  configureNiriOutputsScript = pkgs.writeShellScriptBin "configure-niri-outputs" ''
    set -euo pipefail

    # Wait a bit for niri to be ready
    echo "Waiting for niri to be ready..."
    sleep 3

    # Get list of connected outputs from niri
    connected_outputs=$("${pkgs.niri}/bin/niri" msg outputs 2>/dev/null || true)

    # Parse outputs to identify monitors by serial number
    edp1_found=false
    monitor_11601000458_connector=""
    monitor_11709001774_connector=""

    echo "Detecting monitors..."

    while IFS= read -r line; do
      # Extract connector name (text in parentheses)
      connector=$(echo "$line" | sed -n 's/.*(\([^)]*\)).*/\1/p')
      if [[ -n "$connector" ]]; then

        # Check for eDP-1 (laptop display)
        if [[ "$connector" == "eDP-1" ]]; then
          edp1_found=true
          echo "Found laptop display: $connector"
          continue
        fi

        # Check if this line contains monitor serial numbers
        if [[ "$line" == *"AU11601000458"* ]]; then
          monitor_11601000458_connector="$connector"
          echo "Found AU11601000458 on connector: $connector"
        elif [[ "$line" == *"AU11709001774"* ]]; then
          monitor_11709001774_connector="$connector"
          echo "Found AU11709001774 on connector: $connector"
        elif [[ "$connector" == "DP-2" || "$connector" == "DP-3" ]]; then
          # These might be the Philips monitors but we couldn't identify by serial
          echo "Found external monitor on connector: $connector (serial unknown)"
        fi
      fi
    done <<< "$connected_outputs"

    # Position monitors contiguously
    x_position=0

    # Get the width of eDP-1 for positioning calculations
    edp1_width=1920  # Default

    # Always position AU11601000458 first (leftmost)
    if [[ -n "$monitor_11601000458_connector" ]]; then
      echo "Positioning AU11601000458 ($monitor_11601000458_connector) at $x_position,0"
      "${pkgs.niri}/bin/niri" msg output "$monitor_11601000458_connector" position set $x_position 0 || true
      x_position=$((x_position + 1920))
    fi

    # Always position AU11709001774 second (middle)
    if [[ -n "$monitor_11709001774_connector" ]]; then
      echo "Positioning AU11709001774 ($monitor_11709001774_connector) at $x_position,0"
      "${pkgs.niri}/bin/niri" msg output "$monitor_11709001774_connector" position set $x_position 0 || true
      x_position=$((x_position + 1920))
    fi

    # Position eDP-1 last (rightmost)
    if [[ "$edp1_found" == true ]]; then
      echo "Positioning eDP-1 (laptop display) at $x_position,0"
      "${pkgs.niri}/bin/niri" msg output "eDP-1" position set $x_position 0 || true
    else
      echo "Warning: eDP-1 not found, using default position 0,0"
      "${pkgs.niri}/bin/niri" msg output "eDP-1" position set 0 0 || true
    fi

    # Wait for configuration to take effect
    echo "Waiting for configuration to settle..."
    sleep 2

    # Verify configuration - ensure monitors are positioned contiguously
    echo "Verifying monitor positions..."
    "${pkgs.niri}/bin/niri" msg outputs 2>/dev/null | grep -A1 "Output " || true

    # Additional verification: check for gaps
    echo "Checking for gaps in monitor layout..."
    positions=$("${pkgs.niri}/bin/niri" msg outputs 2>/dev/null | grep "Logical position:" | sed 's/.*Logical position: \([0-9]\+\),.*/\1/' | sort -n || true)

    if [[ -n "$positions" ]]; then
      prev_pos=""
      for pos in $positions; do
        if [[ -n "$prev_pos" ]]; then
          gap=$((pos - prev_pos))
          if [[ $gap -gt 1920 ]]; then
            echo "WARNING: Large gap detected between monitors: $prev_pos to $pos (gap: $gap pixels)"
            echo "This may cause mouse confinement issues in games!"
          elif [[ $gap -lt 1920 ]]; then
            echo "WARNING: Monitors may be overlapping or too close: $prev_pos to $pos (gap: $gap pixels)"
          fi
        fi
        prev_pos=$pos
      done
    fi

    echo "Output configuration complete - ensure monitors are contiguous for proper mouse movement"

    # Assign workspaces based on connected monitors
    echo "Configuring workspace assignments..."
    if [[ -n "$monitor_11601000458_connector" ]]; then
        echo "Moving workspace 'mail' to monitor $monitor_11601000458_connector"
        "${pkgs.niri}/bin/niri" msg action focus-workspace "mail" || true
        "${pkgs.niri}/bin/niri" msg action move-workspace-to-monitor "$monitor_11601000458_connector" || true
    else
        echo "No external monitor found, keeping workspace 'mail' on eDP-1"
        "${pkgs.niri}/bin/niri" msg action focus-workspace "mail" || true
        "${pkgs.niri}/bin/niri" msg action move-workspace-to-monitor "eDP-1" || true
    fi

    # Refocus dev workspace
    echo "Refocusing workspace 'dev'"
    "${pkgs.niri}/bin/niri" msg action focus-workspace "dev" || true

    echo "Workspace configuration complete"
  '';
in
{
  config = {
    programs.niri = {
      enable = true;
      settings = {
        # zz-specific outputs
        outputs = {
          # eDP-1: 1920x1080 @ 144Hz
          "eDP-1" = {
            mode = {
              width = 1920;
              height = 1080;
              refresh = 143.999;
            };
            position = {
              x = 0;
              y = 0;
            };
          };
        };

        screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
        hotkey-overlay.skip-at-startup = true;
        prefer-no-csd = true;

        workspaces = {
          "dev" = {
            open-on-output = "eDP-1";
          };
          "mail" = {
            open-on-output = "eDP-1";
          };
        };

        environment = {
          ELECTRON_OZONE_PLATFORM_HINT = "auto";
        };

        input.keyboard.numlock = true;
        input.touchpad = {
          enable = true;
          tap = true;
          natural-scroll = true;
          dwt = true;
          dwtp = false;
          disabled-on-external-mouse = false;
          drag = true;
          drag-lock = false;
          accel-profile = "adaptive";
          middle-emulation = false;
          left-handed = false;
        };
        input.focus-follows-mouse.enable = true;
        input.focus-follows-mouse.max-scroll-amount = "0%";

        gestures.hot-corners.enable = false;

        layout.gaps = 16;
        layout.center-focused-column = "never";
        layout.default-column-width = {
          proportion = 0.5;
        };
        layout.preset-column-widths = [
          { proportion = 0.33333; }
          { proportion = 0.5; }
          { proportion = 0.66667; }
        ];
        layout.focus-ring.enable = true;
        layout.focus-ring.width = 4;
        layout.focus-ring.active.color = "#7fc8ff";
        layout.focus-ring.inactive.color = "#505050";
        layout.border.enable = false;

        spawn-at-startup = pkgs.lib.mkForce [
          {
            command = [
              "${configureNiriOutputsScript}/bin/configure-niri-outputs"
            ];
          }
          {
            command = [
              "wl-clip-persist"
              "--clipboard"
              "regular"
            ];
          }
        ];

        animations.enable = true;

        window-rules = [
          {
            open-maximized = true;
          }
          {
            matches = [
              {
                app-id = "^teams-for-linux$";
                at-startup = true;
              }
              {
                app-id = "^teamsforlinux$";
                at-startup = true;
              }
              {
                app-id = "^Microsoft Teams$";
                at-startup = true;
              }
              {
                app-id = "electron";
                title = ".*Microsoft Teams.*";
              }
              {
                title = ".*Microsoft Teams.*";
              }
            ];
            open-on-workspace = "mail";
            open-focused = false;
          }
          {
            matches = [
              {
                at-startup = true;
                app-id = "^evolution$";
              }
              {
                at-startup = true;
                app-id = "^org\\.gnome\\.Evolution$";
              }
            ];
            open-on-workspace = "mail";
            open-focused = false;
          }
        ];

        layer-rules = [
          {
            matches = [ { namespace = "dms:blurwallpaper"; } ];
            place-within-backdrop = true;
          }
        ];

        debug = {
          wait-for-frame-completion-before-queueing = [ ];
        };

        binds = {
          # System
          "Mod+Shift+Slash".action.show-hotkey-overlay = [ ];
          "Mod+Escape" = {
            action.toggle-keyboard-shortcuts-inhibit = [ ];
            allow-inhibiting = false;
          };
          "Mod+Shift+E".action.quit = { };
          "Mod+Shift+P".action.power-off-monitors = [ ];

          # Applications
          "Mod+Return" = {
            action.spawn = "wezterm";
            hotkey-overlay.title = "Terminal";
          };

          # Media
          "XF86AudioPlay" = {
            action.spawn = [
              "playerctl"
              "play-pause"
            ];
            allow-when-locked = true;
          };
          "XF86AudioStop" = {
            action.spawn = [
              "playerctl"
              "stop"
            ];
            allow-when-locked = true;
          };
          "XF86AudioPrev" = {
            action.spawn = [
              "playerctl"
              "previous"
            ];
            allow-when-locked = true;
          };
          "XF86AudioNext" = {
            action.spawn = [
              "playerctl"
              "next"
            ];
            allow-when-locked = true;
          };

          # Window management
          "Mod+O" = {
            action.toggle-overview = [ ];
            repeat = false;
          };
          "Mod+Q" = {
            action.close-window = [ ];
            repeat = false;
          };
          "Mod+Left".action.focus-column-left = [ ];
          "Mod+Down".action.focus-workspace-down = [ ];
          "Mod+Up".action.focus-workspace-up = [ ];
          "Mod+Right".action.focus-column-right = [ ];
          "Mod+H".action.focus-column-left = [ ];
          "Mod+J".action.focus-workspace-down = [ ];
          "Mod+K".action.focus-workspace-up = [ ];
          "Mod+L".action.focus-column-right = [ ];

          # Move windows
          "Mod+Ctrl+Left".action.move-column-left = [ ];
          "Mod+Ctrl+Down".action.move-column-to-workspace-down = [ ];
          "Mod+Ctrl+Up".action.move-column-to-workspace-up = [ ];
          "Mod+Ctrl+Right".action.move-column-right = [ ];
          "Mod+Ctrl+H".action.move-column-left = [ ];
          "Mod+Ctrl+J".action.move-column-to-workspace-down = [ ];
          "Mod+Ctrl+K".action.move-column-to-workspace-up = [ ];
          "Mod+Ctrl+L".action.move-column-right = [ ];
          "Mod+Home".action.focus-column-first = [ ];
          "Mod+End".action.focus-column-last = [ ];
          "Mod+Ctrl+Home".action.move-column-to-first = [ ];
          "Mod+Ctrl+End".action.move-column-to-last = [ ];

          # Monitors
          "Mod+Shift+Left".action.focus-monitor-left = [ ];
          "Mod+Shift+Down".action.focus-monitor-down = [ ];
          "Mod+Shift+Up".action.focus-monitor-up = [ ];
          "Mod+Shift+Right".action.focus-monitor-right = [ ];
          "Mod+Shift+H".action.focus-monitor-left = [ ];
          "Mod+Shift+J".action.focus-monitor-down = [ ];
          "Mod+Shift+K".action.focus-monitor-up = [ ];
          "Mod+Shift+L".action.focus-monitor-right = [ ];
          "Mod+Shift+Ctrl+Left".action.move-column-to-monitor-left = [ ];
          "Mod+Shift+Ctrl+Down".action.move-column-to-monitor-down = [ ];
          "Mod+Shift+Ctrl+Up".action.move-column-to-monitor-up = [ ];
          "Mod+Shift+Ctrl+Right".action.move-column-to-monitor-right = [ ];
          "Mod+Shift+Ctrl+H".action.move-column-to-monitor-left = [ ];
          "Mod+Shift+Ctrl+J".action.move-column-to-monitor-down = [ ];
          "Mod+Shift+Ctrl+K".action.move-column-to-monitor-up = [ ];
          "Mod+Shift+Ctrl+L".action.move-column-to-monitor-right = [ ];

          # Workspaces
          "Mod+Page_Down".action.focus-workspace-down = [ ];
          "Mod+Page_Up".action.focus-workspace-up = [ ];
          "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = [ ];
          "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = [ ];
          "Mod+Ctrl+U".action.move-column-to-workspace-down = [ ];
          "Mod+Ctrl+I".action.move-column-to-workspace-up = [ ];
          "Mod+Shift+Page_Down".action.move-workspace-down = [ ];
          "Mod+Shift+Page_Up".action.move-workspace-up = [ ];
          "Mod+Shift+U".action.move-workspace-down = [ ];
          "Mod+Shift+I".action.move-workspace-up = [ ];

          # Workspace numbers
          "Mod+1".action.focus-workspace = 1;
          "Mod+2".action.focus-workspace = 2;
          "Mod+3".action.focus-workspace = 3;
          "Mod+4".action.focus-workspace = 4;
          "Mod+5".action.focus-workspace = 5;
          "Mod+6".action.focus-workspace = 6;
          "Mod+7".action.focus-workspace = 7;
          "Mod+8".action.focus-workspace = 8;
          "Mod+9".action.focus-workspace = 9;
          "Mod+Ctrl+1".action.move-column-to-workspace = 1;
          "Mod+Ctrl+2".action.move-column-to-workspace = 2;
          "Mod+Ctrl+3".action.move-column-to-workspace = 3;
          "Mod+Ctrl+4".action.move-column-to-workspace = 4;
          "Mod+Ctrl+5".action.move-column-to-workspace = 5;
          "Mod+Ctrl+6".action.move-column-to-workspace = 6;
          "Mod+Ctrl+7".action.move-column-to-workspace = 7;
          "Mod+Ctrl+8".action.move-column-to-workspace = 8;
          "Mod+Ctrl+9".action.move-column-to-workspace = 9;

          # Mouse wheel
          "Mod+WheelScrollDown" = {
            action.focus-workspace-down = [ ];
            cooldown-ms = 150;
          };
          "Mod+WheelScrollUp" = {
            action.focus-workspace-up = [ ];
            cooldown-ms = 150;
          };
          "Mod+Ctrl+WheelScrollDown" = {
            action.move-column-to-workspace-down = [ ];
            cooldown-ms = 150;
          };
          "Mod+Ctrl+WheelScrollUp" = {
            action.move-column-to-workspace-up = [ ];
            cooldown-ms = 150;
          };
          "Mod+WheelScrollRight".action.focus-column-right = [ ];
          "Mod+WheelScrollLeft".action.focus-column-left = [ ];
          "Mod+Ctrl+WheelScrollRight".action.move-column-right = [ ];
          "Mod+Ctrl+WheelScrollLeft".action.move-column-left = [ ];
          "Mod+Shift+WheelScrollDown".action.focus-column-right = [ ];
          "Mod+Shift+WheelScrollUp".action.focus-column-left = [ ];
          "Mod+Ctrl+Shift+WheelScrollDown".action.move-column-right = [ ];
          "Mod+Ctrl+Shift+WheelScrollUp".action.move-column-left = [ ];

          # Window sizing
          "Mod+BracketLeft".action.consume-or-expel-window-left = [ ];
          "Mod+BracketRight".action.consume-or-expel-window-right = [ ];
          "Mod+Semicolon".action.consume-window-into-column = [ ]; # Mod+Comma conflicts with DMS
          "Mod+Period".action.expel-window-from-column = [ ];
          "Mod+R".action.switch-preset-column-width = [ ];
          "Mod+Shift+R".action.switch-preset-window-height = [ ];
          "Mod+Ctrl+R".action.reset-window-height = [ ];
          "Mod+F".action.maximize-column = [ ];
          "Mod+Shift+F".action.fullscreen-window = [ ];
          "Mod+Ctrl+F".action.expand-column-to-available-width = [ ];
          "Mod+C".action.center-column = [ ];
          "Mod+Ctrl+C".action.center-visible-columns = [ ];
          "Mod+Minus".action.set-column-width = "-10%";
          "Mod+Equal".action.set-column-width = "+10%";
          "Mod+Shift+Minus".action.set-window-height = "-10%";
          "Mod+Shift+Equal".action.set-window-height = "+10%";

          # Window modes
          "Mod+B".action.toggle-window-floating = [ ]; # Mod+V conflicts with DMS
          "Mod+Shift+B".action.switch-focus-between-floating-and-tiling = [ ];
          "Mod+W".action.toggle-column-tabbed-display = [ ];

          # Screenshots
          "Print".action.screenshot = [ ];
          "Ctrl+Print".action.screenshot-screen = [ ];
          "Alt+Print".action.screenshot-window = [ ];

          # DMS Keybinds
          "Mod+Space" = {
            action.spawn = [
              "dms"
              "ipc"
              "call"
              "spotlight"
              "toggle"
            ];
            hotkey-overlay.title = "Launcher";
          };
          "Mod+V" = {
            action.spawn = [
              "dms"
              "ipc"
              "call"
              "clipboard"
              "toggle"
            ];
            hotkey-overlay.title = "Clipboard";
          };
          "Mod+M" = {
            action.spawn = [
              "dms"
              "ipc"
              "call"
              "processlist"
              "toggle"
            ];
            hotkey-overlay.title = "Task Manager";
          };
          "Mod+Comma" = {
            action.spawn = [
              "dms"
              "ipc"
              "call"
              "settings"
              "toggle"
            ];
            hotkey-overlay.title = "Settings";
          };
          "Mod+N" = {
            action.spawn = [
              "dms"
              "ipc"
              "call"
              "notifications"
              "toggle"
            ];
            hotkey-overlay.title = "Notifications";
          };
          "Mod+Y" = {
            action.spawn = [
              "dms"
              "ipc"
              "call"
              "dankdash"
              "wallpaper"
            ];
            hotkey-overlay.title = "Wallpapers";
          };
          "Mod+Shift+N" = {
            action.spawn = [
              "dms"
              "ipc"
              "call"
              "notepad"
              "toggle"
            ];
            hotkey-overlay.title = "Notepad";
          };
          "Mod+Alt+L" = {
            action.spawn = [
              "dms"
              "ipc"
              "call"
              "lock"
              "lock"
            ];
            hotkey-overlay.title = "Lock";
          };
          "Ctrl+Alt+Delete" = {
            action.spawn = [
              "dms"
              "ipc"
              "call"
              "processlist"
              "toggle"
            ];
            hotkey-overlay.title = "Task Manager";
          };
          "XF86AudioRaiseVolume" = {
            action.spawn = [
              "dms"
              "ipc"
              "call"
              "audio"
              "increment"
              "3"
            ];
            allow-when-locked = true;
          };
          "XF86AudioLowerVolume" = {
            action.spawn = [
              "dms"
              "ipc"
              "call"
              "audio"
              "decrement"
              "3"
            ];
            allow-when-locked = true;
          };
          "XF86AudioMute" = {
            action.spawn = [
              "dms"
              "ipc"
              "call"
              "audio"
              "mute"
            ];
            allow-when-locked = true;
          };
          "XF86AudioMicMute" = {
            action.spawn = [
              "dms"
              "ipc"
              "call"
              "audio"
              "micmute"
            ];
            allow-when-locked = true;
          };
          "XF86MonBrightnessUp" = {
            action.spawn = [
              "dms"
              "ipc"
              "call"
              "brightness"
              "increment"
              "5"
              ""
            ];
            allow-when-locked = true;
          };
          "XF86MonBrightnessDown" = {
            action.spawn = [
              "dms"
              "ipc"
              "call"
              "brightness"
              "decrement"
              "5"
              ""
            ];
            allow-when-locked = true;
          };
        };
      };
    };

    home.packages = [ configureNiriOutputsScript ];
  };
}
