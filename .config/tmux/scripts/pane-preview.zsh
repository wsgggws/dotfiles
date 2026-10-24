#!/bin/zsh

pane_id=$1
[[ -n "$pane_id" ]] || exit 0

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

