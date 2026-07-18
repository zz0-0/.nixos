{ config, pkgs, lib, ... }:

{
  config = {
    systemd.user.services.niri = {
      Unit = {
        Description = "A scrollable-tiling Wayland compositor";
        BindsTo = [ "graphical-session.target" ];
        Before = [ "graphical-session.target" ];
        Wants = [ "graphical-session-pre.target" "xdg-desktop-autostart.target" ];
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Slice = "session.slice";
        Type = "notify";
        ExecStart = "${config.programs.niri.package}/bin/niri --session";
        # Multi-GPU: do not restrict glvnd/Vulkan to Intel-only.
        # Without these overrides, niri auto-discovers both GPUs and creates
        # separate renderers per GPU — Intel for eDP, NVIDIA for HDMI.
        # NVIDIA stays in D3cold when no external monitor is connected.
        Environment = [];
      };
    };

    programs.niri = {
      enable = true;

      settings = {
        screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
        hotkey-overlay.skip-at-startup = true;
        prefer-no-csd = true;

        workspaces = {
          "dev" = {};
          "mail" = {};
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

        spawn-at-startup = [
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
                at-startup = true;
                title = ".*Teams.*";
              }
              {
                at-startup = true;
                app-id = "^teams-for-linux$";
              }
            ];
            open-on-workspace = "mail";
            open-focused = false;
          }
          # {
          #   matches = [
          #     {
          #       at-startup = true;
          #       app-id = "^evolution$";
          #     }
          #     {
          #       at-startup = true;
          #       app-id = "^org\\.gnome\\.Evolution$";
          #     }
          #   ];
          #   open-on-workspace = "mail";
          #   open-focused = false;
          # }
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
          "Mod+Semicolon".action.consume-window-into-column = [ ];
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
          "Mod+B".action.toggle-window-floating = [ ];
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
  };
}
