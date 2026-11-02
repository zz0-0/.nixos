{ pkgs, ... }:

let
  # dsh generates a new launch token on every boot. The token only has to be
  # opened once per browser; dsh then keeps a signed cookie across restarts.
  # This helper finds the current boot's URL again if a browser loses it.
  dsh-web-url = pkgs.writeShellApplication {
    name = "dsh-web-url";
    runtimeInputs = with pkgs; [
      systemd
      gnugrep
      coreutils
      wl-clipboard
      xdg-utils
    ];
    text = ''
      url=""
      for _ in 1 2 3 4 5 6 7 8 9 10; do
        url="$(journalctl --user -u dsh-web -b --no-pager -o cat 2>/dev/null \
          | grep -o 'http://127\.0\.0\.1:3080/[^ ]*' \
          | tail -n 1 || true)"
        [ -n "$url" ] && break
        sleep 0.5
      done

      if [ -z "$url" ]; then
        echo "dsh-web has not printed a launch URL this boot." >&2
        echo "Try: systemctl --user restart dsh-web" >&2
        exit 1
      fi

      case "''${1:-}" in
        --open) exec xdg-open "$url" ;;
        --copy) printf '%s' "$url" | wl-copy; echo "URL copied to clipboard" ;;
        *) printf '%s\n' "$url" ;;
      esac
    '';
  };
in
{
  home.packages = [ dsh-web-url ];

  # App launcher: always opens the current boot's token URL.
  xdg.desktopEntries.dsh-web = {
    name = "DeepSeek Harness";
    comment = "Open the DeepSeek Harness web UI";
    exec = "${dsh-web-url}/bin/dsh-web-url --open";
    terminal = false;
    categories = [ "Development" ];
    icon = "utilities-terminal";
  };

  # DeepSeek Harness web UI as a user service. Linger is enabled for this
  # user, so the service starts at boot without waiting for a graphical login.
  systemd.user.services.dsh-web = {
    Unit = {
      Description = "DeepSeek Harness web UI (dsh)";
      Documentation = [ "https://github.com/deepseek-ai/deepseek-harness" ];
    };

    Service = {
      ExecStart = "${pkgs.deepseek-harness}/bin/dsh web --no-open --host 127.0.0.1 --port 3080";
      WorkingDirectory = "%h";
      Restart = "on-failure";
      RestartSec = 5;
      Environment = [
        "DSH_TELEMETRY_DISABLED=1"
      ];
    };

    Install.WantedBy = [ "default.target" ];
  };
}
