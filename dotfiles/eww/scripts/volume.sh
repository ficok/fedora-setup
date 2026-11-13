#!/usr/bin/env bash
# volume.sh get | up | down     (eww passes "up"/"down" on scroll)
sink='@DEFAULT_AUDIO_SINK@'
case "${1:-get}" in
  up)   wpctl set-volume -l 1.0 "$sink" 5%+ ;;
  down) wpctl set-volume "$sink" 5%- ;;
esac
out="$(wpctl get-volume "$sink")"
if grep -q MUTED <<<"$out"; then echo "muted"; else awk '{printf "%d%%", $2 * 100}' <<<"$out"; fi
