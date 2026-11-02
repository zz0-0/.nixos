{
  pkgs,
  ...
}:

# Helpers for cheating in Phantom Blade Zero (Steam app 4115450) on Linux.
#
# The game runs through Proton, so every Windows trainer has to run inside the
# *same* Proton prefix. Both scripts below do exactly that.
#
#   pbz-trainer  — run an .exe (FLiNG / Cheat Engine / WeMod-style trainer) in
#                  the game's prefix.
#   pbz-ue4ss    — install/remove UE4SS, which the Nexus in-game trainer mod
#                  ("PHANTOM BLADE ZERO TRAINER AND ITEM GIVER") depends on.
let
  appId = "4115450";
  # Pinned build the Nexus trainer was tested against (game build 26266538).
  ue4ssUrl = "https://github.com/KintaroModding/ue4ss/releases/download/v3.0.1-1195-g1ceefac8/phantombladezero_ue4ss_v3.0.1-1195-g1ceefac8.zip";

  pbz-trainer = pkgs.writeShellApplication {
    name = "pbz-trainer";
    runtimeInputs = with pkgs; [
      coreutils
      procps
      protontricks
    ];
    text = ''
      usage() {
        cat <<'EOF'
      Usage: pbz-trainer /path/to/Trainer.exe [args...]

      Runs a Windows trainer (FLiNG, Cheat Engine, ...) inside the Proton
      prefix of Phantom Blade Zero, so it can see the running game.

      Start the game first and leave it at the main menu / in game, then run
      this. Keep the trainer window open while you play.

      Examples:
        pbz-trainer ~/Downloads/PBZ.Trainer.v1.0.exe
        pbz-trainer ~/Downloads/cheatengine-x86_64.exe
      EOF
      }

      if [ "$#" -lt 1 ]; then
        usage
        exit 2
      fi

      exe=$1
      shift

      if [ ! -f "$exe" ]; then
        echo "error: no such file: $exe" >&2
        exit 1
      fi
      exe=$(realpath "$exe")

      steam_root="''${STEAM_ROOT:-$HOME/.local/share/Steam}"
      compat="$steam_root/steamapps/compatdata/${appId}"

      if [ ! -d "$compat" ]; then
        echo "error: no Proton prefix at $compat" >&2
        echo "       launch Phantom Blade Zero through Steam at least once." >&2
        exit 1
      fi

      if ! pgrep -f 'PBZ\.exe' >/dev/null 2>&1; then
        echo "warning: PBZ.exe does not look like it is running." >&2
        echo "         start the game first, the trainer needs it in memory." >&2
      fi

      exec protontricks-launch --appid '${appId}' "$exe" "$@"
    '';
  };

  pbz-ue4ss = pkgs.writeShellApplication {
    name = "pbz-ue4ss";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      findutils
      procps
      unzip
      protontricks
    ];
    text = ''
      appid='${appId}'
      steam_root="''${STEAM_ROOT:-$HOME/.local/share/Steam}"
      compat="$steam_root/steamapps/compatdata/$appid"
      game_dir="$steam_root/steamapps/common/PBZ/platform/steam"
      reg_exe="$compat/pfx/drive_c/windows/system32/reg.exe"
      ue4ss_url='${ue4ssUrl}'

      die() { echo "error: $*" >&2; exit 1; }

      ensure_closed() {
        if pgrep -f 'PBZ\.exe' >/dev/null 2>&1; then
          die "close Phantom Blade Zero before doing this."
        fi
      }

      # Proton only loads a proxy DLL when the prefix does not treat it as
      # builtin-only. Doing it in the registry is the same as
      # WINEDLLOVERRIDES="dwmapi=n,b" but survives without Steam launch options.
      set_override() {
        protontricks-launch --appid "$appid" "$reg_exe" \
          add 'HKCU\Software\Wine\DllOverrides' /v dwmapi /t REG_SZ \
          /d native,builtin /f >/dev/null
      }

      installed() {
        [ -f "$game_dir/dwmapi.dll" ] && [ -d "$game_dir/ue4ss" ]
      }

      do_install() {
        ensure_closed
        [ -d "$game_dir" ] || die "game folder not found: $game_dir"

        local zip=''${1:-}
        local tmp
        tmp=$(mktemp -d)
        # shellcheck disable=SC2064
        trap "rm -rf '$tmp'" EXIT

        if [ -z "$zip" ]; then
          echo "downloading UE4SS (pinned build 1195)..."
          zip="$tmp/ue4ss.zip"
          curl --fail --location --progress-bar --output "$zip" "$ue4ss_url" \
            || die "download failed; pass a local ZIP as the second argument"
        elif [ ! -f "$zip" ]; then
          die "no such file: $zip"
        fi

        echo "extracting..."
        unzip -q "$zip" -d "$tmp/extract" || die "not a valid ZIP: $zip"

        local src
        src=$(find "$tmp/extract" -type f -name dwmapi.dll -printf '%h\n' | head -n1)
        [ -n "$src" ] || die "dwmapi.dll not found inside the archive"
        [ -d "$src/ue4ss" ] || die "ue4ss/ folder not found inside the archive"

        if [ -f "$game_dir/dwmapi.dll" ] && [ ! -f "$game_dir/dwmapi.dll.pbzbak" ]; then
          cp -a "$game_dir/dwmapi.dll" "$game_dir/dwmapi.dll.pbzbak"
        fi

        # Merge instead of nesting a second ue4ss/ on updates.
        mkdir -p "$game_dir/ue4ss"
        cp -a "$src/dwmapi.dll" "$game_dir/dwmapi.dll"
        cp -a "$src/ue4ss/." "$game_dir/ue4ss/"
        set_override

        echo
        echo "UE4SS installed in $game_dir"
        echo
        echo "Next step (the trainer itself is a Nexus download, login required):"
        echo "  1. Download 'PHANTOM BLADE ZERO TRAINER AND ITEM GIVER'"
        echo "     https://www.nexusmods.com/phantombladezero/mods/185"
        echo "  2. Extract its ZIP so that this file exists:"
        echo "     $game_dir/ue4ss/Mods/PBZTrainer/Scripts/main.lua"
        echo "  3. Start the game, load a save, press F10 (or click both sticks)."
        echo
        echo "Check it loaded:  pbz-ue4ss status"
      }

      case "''${1:-}" in
        install|update)
          do_install "''${2:-}"
          ;;
        on)
          ensure_closed
          if [ -f "$game_dir/dwmapi.dll.off" ]; then
            mv "$game_dir/dwmapi.dll.off" "$game_dir/dwmapi.dll"
            echo "UE4SS enabled."
          elif [ -f "$game_dir/dwmapi.dll" ]; then
            echo "UE4SS already enabled."
          else
            die "UE4SS is not installed; run: pbz-ue4ss install"
          fi
          ;;
        off)
          ensure_closed
          if [ -f "$game_dir/dwmapi.dll" ]; then
            mv "$game_dir/dwmapi.dll" "$game_dir/dwmapi.dll.off"
            echo "UE4SS disabled (dwmapi.dll renamed to dwmapi.dll.off)."
          else
            echo "UE4SS already disabled or not installed."
          fi
          ;;
        status)
          echo "game:    $game_dir"
          echo "prefix:  $compat"
          if installed; then
            echo "ue4ss:   installed"
          elif [ -d "$game_dir/ue4ss" ]; then
            echo "ue4ss:   installed but disabled (dwmapi.dll missing or .off)"
          else
            echo "ue4ss:   not installed"
          fi
          if [ -f "$game_dir/ue4ss/Mods/PBZTrainer/Scripts/main.lua" ] \
            || [ -f "$game_dir/ue4ss/Mods/PBZTrainer/main.lua" ]; then
            echo "trainer: PBZTrainer mod present"
          else
            echo "trainer: PBZTrainer mod NOT present (extract it into ue4ss/Mods)"
          fi
          if [ -f "$game_dir/ue4ss/UE4SS.log" ]; then
            echo
            echo "last UE4SS.log lines:"
            tail -n 15 "$game_dir/ue4ss/UE4SS.log"
          fi
          ;;
        remove)
          ensure_closed
          echo "This deletes ue4ss/ (including the trainer mod) and dwmapi.dll."
          printf "Type 'yes' to continue: "
          read -r answer || true
          if [ "$answer" = "yes" ]; then
            rm -rf "$game_dir/ue4ss" "$game_dir/dwmapi.dll" "$game_dir/dwmapi.dll.pbzbak" \
              "$game_dir/dwmapi.dll.off"
            echo "removed."
          else
            echo "aborted."
          fi
          ;;
        *)
          cat <<'EOF'
      Usage: pbz-ue4ss <command> [local.zip]

        install [zip]  download + install the pinned UE4SS build (or a local zip)
        update         same as install, keeps your Mods folder
        on | off       toggle UE4SS without deleting anything
        status         show what is installed and tail UE4SS.log
        remove         delete UE4SS and the trainer mod
      EOF
          exit 2
          ;;
      esac
    '';
  };
in
{
  home.packages = [
    pkgs.protontricks
    pbz-trainer
    pbz-ue4ss
  ];
}
