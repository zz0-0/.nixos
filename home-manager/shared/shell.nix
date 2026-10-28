{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Resolve the family through fontconfig at runtime instead of pinning one
  # here, so WezTerm follows the system's configured monospace font.
  # Falls back to WezTerm's built-in JetBrains Mono if fc-match fails.
  systemMonospace = lib.generators.mkLuaInline ''
    wezterm.font((function()
      local ok, family = wezterm.run_child_process({
        "${pkgs.fontconfig}/bin/fc-match", "--format=%{family[0]}", "monospace",
      })
      if ok and family ~= "" then
        return family
      end
      return "JetBrains Mono"
    end)())
  '';
in
{
  programs.wezterm = {
    enable = true;
    settings = {
      font = systemMonospace;

      # DMS regenerates this file whenever the desktop theme changes, so the
      # terminal follows the system theme. The name is the file stem under
      # ~/.config/wezterm/colors/.
      color_scheme = "dank-theme";

      window_padding = {
        left = 8;
        right = 8;
        top = 8;
        bottom = 8;
      };
      hide_tab_bar_if_only_one_tab = true;
    };
  };

  programs.fish = {
    enable = true;
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Exec fish for interactive login shells (keep the original behavior)
  home.file.".bash_profile".text = ''
    # Exec fish for interactive sessions only; do not exec in non-interactive shells.
    if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z "$BASH_EXECUTION_STRING" ]]
    then
      shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
      exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
    fi
  '';
}
