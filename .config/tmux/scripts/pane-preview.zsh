#!/bin/zsh

set -uo pipefail

target=${1:-}
[[ -n "$target" ]] || exit 0

# Resolve the window's active pane at preview time (also accepts a pane ID).
pane_id=$(tmux display-message -p -t "$target" '#{pane_id}' 2>/dev/null) || exit 0

# -p prints the captured screen to stdout. Keep each terminal line intact and
# remove only trailing spaces and trailing blank rows.
tmux capture-pane -p -t "$pane_id" 2>/dev/null | awk '
{
  line = $0
  sub(/[[:space:]]+$/, "", line)
  lines[NR] = line
  if (length(line) > 0)
    last = NR
}
END {
  for (i = 1; i <= last; i++)
    print lines[i]
}'

