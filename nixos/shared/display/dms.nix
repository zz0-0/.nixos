{
  config,
  lib,
  pkgs,
  username,
  ...
}:

{
  services = {
    displayManager = {
      dms-greeter = {
        enable = true;
        compositor = {
          name = "niri";
          customConfig = ''
            hotkey-overlay {
                skip-at-startup
            }

            environment {
                DMS_RUN_GREETER "1"
            }

            gestures {
               hot-corners {
                 off
               }
            }

            layout {
              background-color "#000000"
            }
          '';
        };
        configHome = "/home/${username}";
        logs = {
          save = true;
          path = "/tmp/dms-greeter.log";
        };
      };
    };
  };
}
