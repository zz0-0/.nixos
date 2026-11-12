#!/usr/bin/env bash
# Power attribution sampler: reads sysfs/proc only, changes nothing, needs no root.
#
#   ./scripts/power-triage.sh [seconds]     # default 60
#
# Only meaningful on battery: BAT0/power_now reads 0 while on AC. Run it, then
# compare states (e.g. panel at 165 Hz vs 60 Hz, browser open vs closed) to get
# the wattage of one decision instead of guessing.
#
# Deliberately not `set -e`: a missing sysfs file or a division guard should
# degrade to "n/a", not abort a 60 second sample halfway through.
set -uo pipefail

DUR=${1:-60}
BAT=/sys/class/power_supply/BAT0
ADP=/sys/class/power_supply/ADP1
DGPU=/sys/bus/pci/devices/0000:02:00.0
BL=/sys/class/backlight/intel_backlight

[ "$DUR" = "-h" ] || [ "$DUR" = "--help" ] && {
  sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
}

# pid -> utime+stime (jiffies). Strip the "pid (comm) " prefix, then utime is
# the 12th field and stime the 13th. Pure bash: 1200 processes would otherwise
# mean 1200 forks per snapshot.
proc_ticks() {
  local f line pid rest
  for f in /proc/[0-9]*/stat; do
    line=$(< "$f") 2>/dev/null || continue
    pid=${line%% *}
    rest=${line#*) }
    [ "$rest" != "$line" ] || continue
    # shellcheck disable=SC2086
    set -- $rest
    echo "$pid $(( ${12:-0} + ${13:-0} ))"
  done
}

total_cpu() {
  local u n s i w irq sirq st _
  read -r _ u n s i w irq sirq st _ < /proc/stat
  echo "$((u+n+s+i+w+irq+sirq+st)) $i"
}

irq_total() {
  awk '/^[[:space:]]*[0-9]+:/ {for (i=2;i<=NF;i++) if ($i ~ /^[0-9]+$/) s+=$i} END {print s+0}' /proc/interrupts
}

if [ "$(cat "$ADP/online" 2>/dev/null)" != "0" ]; then
  echo "warning: on AC, BAT0/power_now is charge power, not system draw. Run this unplugged." >&2
  on_battery=false
else
  on_battery=true
fi
full=$(< "$BAT/energy_full") ; full=${full:-97650000}

declare -A t0=() t1=()
while read -r pid tk; do t0[$pid]=$tk; done < <(proc_ticks)
read -r cpu_a idle_a < <(total_cpu)
irq_a=$(irq_total)
e_a=$(< "$BAT/energy_now") ; e_a=${e_a:-0}
susp_a=$(< "$DGPU/power/runtime_suspended_time" 2>/dev/null) ; susp_a=${susp_a:-0}
t_a=$(date +%s)

echo "sampling ${DUR}s ..." >&2
sum=0; n=0; max=0
for ((k=0; k<DUR; k+=2)); do
  p=$(< "$BAT/power_now"); p=${p:-0}
  # Only discharging reports system draw; while charging this is charge power.
  if $on_battery && [ "$p" -gt 0 ] 2>/dev/null; then
    sum=$((sum+p)); n=$((n+1)); [ "$p" -gt "$max" ] && max=$p
  fi
  sleep 2
done

read -r cpu_b idle_b < <(total_cpu)
irq_b=$(irq_total)
e_b=$(< "$BAT/energy_now") ; e_b=${e_b:-0}
susp_b=$(< "$DGPU/power/runtime_suspended_time" 2>/dev/null) ; susp_b=${susp_b:-0}
t_b=$(date +%s)
while read -r pid tk; do t1[$pid]=$tk; done < <(proc_ticks)

elapsed=$((t_b - t_a)); [ "$elapsed" -gt 0 ] || elapsed=1
cpu_d=$((cpu_b - cpu_a)); [ "$cpu_d" -gt 0 ] || cpu_d=1
busy=$(( (cpu_d - (idle_b - idle_a)) * 100 / cpu_d ))
nproc=$(nproc)
dwh=$(( e_a - e_b ))

echo
echo "════ power ════"
if [ "$n" -gt 0 ]; then
  awk -v s="$sum" -v n="$n" -v m="$max" 'BEGIN{printf "average draw  %.2f W  (peak %.2f W)\n", s/n/1e6, m/1e6}'
else
  echo "average draw  n/a (on AC, power_now is 0)"
fi
awk -v d="$dwh" -v e="$elapsed" -v f="$full" 'BEGIN{
  wh = d/1e6;
  printf "energy        %.2f Wh", wh;
  if (wh > 0) printf "  -> %.1f h on a full %.1f Wh battery\n", f/1e6/(wh*3600/e), f/1e6;
  else printf "  (no discharge data)\n";
}'
printf "battery       %s %s%%\n" "$(< "$BAT/status")" "$(< "$BAT/capacity")"

echo
echo "════ cpu ════"
awk -v b="$busy" -v n="$nproc" 'BEGIN{printf "busy          %d%% (%d threads, ~%.2f cores saturated)\n", b, n, b*n/100}'

echo
echo "════ top cpu consumers in this window ════"
for pid in "${!t1[@]}"; do
  echo "$(( ${t1[$pid]} - ${t0[$pid]:-0} )) $pid"
done | sort -rn | head -10 | while read -r d pid; do
  [ "${d:-0}" -gt 0 ] || continue
  [ -r "/proc/$pid/comm" ] || continue
  awk -v d="$d" -v c="$cpu_d" -v n="$(cat /proc/$pid/comm)" -v p="$pid" \
    'BEGIN{printf "  %5.1f%%  %-22s %s\n", d*100/c, n, p}'
done

if [ -e "$DGPU/power/runtime_status" ]; then
  echo
  echo "════ dGPU ════"
  printf "state         %s\n" "$(< "$DGPU/power/runtime_status")"
  awk -v a="$susp_a" -v b="$susp_b" 'BEGIN{printf "suspended     %.2f s total (+%.2f s in window)\n", b/1000, (b-a)/1000}'
fi

echo
echo "════ interrupts ════"
awk -v a="$irq_a" -v b="$irq_b" -v e="$elapsed" 'BEGIN{printf "rate          %.0f/s\n", (b-a)/e}'
awk '/^[[:space:]]*[0-9]+:/ {name=$NF; s=0; for(i=2;i<=NF;i++) if ($i ~ /^[0-9]+$/) s+=$i; t[name]+=s} END {for (n in t) printf "%10d %s\n", t[n], n}' /proc/interrupts | sort -rn | head -6

echo
echo "════ display ════"
SOCK=${NIRI_SOCKET:-$(ls /run/user/"$(id -u)"/niri.*.sock 2>/dev/null | head -1)}
NIRI_SOCKET="$SOCK" niri msg outputs 2>/dev/null | grep -E "^Output|Current mode"
echo "backlight     $(< "$BL/brightness" 2>/dev/null)/$(< "$BL/max_brightness" 2>/dev/null)"
echo "profile       $(< /sys/firmware/acpi/platform_profile 2>/dev/null)"
