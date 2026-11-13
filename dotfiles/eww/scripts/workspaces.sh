#!/usr/bin/env bash
# Prints a JSON array for workspaces 1-10 whenever sway's workspace state changes.
# (sway only lists a workspace while it holds windows or is focused, so "listed" means occupied.)
emit() {
  swaymsg -t get_workspaces -r | jq -c '. as $w | [range(1;11) as $i |
    {id: $i, active: any($w[]; .num == $i and .focused), occupied: any($w[]; .num == $i)}]'
}
emit
swaymsg -t subscribe -m '["workspace"]' | while read -r _; do emit; done
