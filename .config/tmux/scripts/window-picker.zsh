#!/bin/zsh

source "$HOME/.config/fzf/theme.sh"

current_session=$(tmux display-message -p '#S')
current_window=$(tmux display-message -p '#I')

tmux list-windows -a -F '#{window_activity}:#{session_name}:#{window_index}:#{window_name}#{?#{>:#{window_panes},1}, [#{window_panes}p],}' \
	| sort -rn \
	| cut -d: -f2- \
	| awk -v cs="$current_session" -v cw="$current_window" -F: '
	{
	  display = $1":"$3;
	  value = $1":"$2;
	  if ($1 == cs && $2 == cw)
	    print "\033[1;32m" display "\033[0m\t" value;
	  else
	    print display "\t" value;
	}' \
	| FZF_DEFAULT_OPTS= fzf --ansi --reverse --with-nth=1 --delimiter=$'\t' \
		--border=none \
		--no-scrollbar \
		--prompt="$FZF_THEME_NAME · Select window > " \
		--pointer='▶' \
		--bind 'ctrl-/:toggle-preview' \
		--color="$FZF_THEME_COLOR" \
		--preview 'target=$(echo {2} | sed "s/\x1b\[[0-9;]*m//g"); tmux capture-pane -ep -t "$target"' \
		--preview-window=right:72%:wrap:border-left \
	| awk -F'\t' '{print $2}' \
	| xargs -I {} tmux switch-client -t {}

