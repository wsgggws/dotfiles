#!/bin/zsh

set -uo pipefail

source "$HOME/.config/fzf/theme.sh"

current_window=$(tmux display-message -p '#{session_id}:#{window_id}') || exit 1

# Tabs separate metadata; colons/spaces in window names stay in the label.
# Stable IDs also keep the selection valid if tmux renumbers a window.
selection=$(tmux list-windows -a -F $'#{window_activity}\t#{session_id}:#{window_id}\t#{session_name}:#{window_name}#{?#{>:#{window_panes},1}, [#{window_panes}p],}' \
	| sort -rn \
	| awk -v current="$current_window" -F'\t' '
	{
	  marker = ($2 == current) ? "● " : "  ";
	  print marker $3 "\t" $2;
	}' \
	| FZF_DEFAULT_OPTS= FZF_DEFAULT_OPTS_FILE=/dev/null fzf --reverse --with-nth=1 --delimiter=$'\t' \
		--border=none \
		--no-scrollbar \
		--prompt='Select window > ' \
		--pointer='▶' \
		--bind 'ctrl-/:toggle-preview' \
		--color="$FZF_THEME_COLOR" \
		--preview '"$HOME/.config/tmux/scripts/pane-preview.zsh" {2}' \
		--preview-window=right:68%:nowrap:border-left \
		--preview-label=' Window preview · Ctrl-/ toggle ')
picker_status=$?
(( picker_status == 0 )) || exit 0
[[ -n "$selection" ]] || exit 0
target=${selection##*$'\t'}
tmux switch-client -t "$target"

