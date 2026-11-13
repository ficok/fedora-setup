#!/usr/bin/env bash
# Prints the focused window's title whenever focus or title changes.
emit() {
  swaymsg -t get_tree | jq -r '[.. | objects | select(.focused == true and (.type == "con" or .type == "floating_con"))] | first | .name // ""'
}
emit
swaymsg -t subscribe -m '["window","workspace"]' | while read -r _; do emit; done
