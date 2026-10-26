#!/bin/zsh

set -uo pipefail

source "${ALLTHEME_HOME:-$HOME}/.config/fzf/theme.sh"

# One private state directory per popup; simultaneous pickers remain independent.
TMUX_PICKER_STATE=$(mktemp -d "${TMPDIR:-/tmp}/tmux-picker.XXXXXXXX") || exit 1
export TMUX_PICKER_STATE
export TMUX_PICKER_PREVIEW="${0:A:h}/pane-preview.zsh"
trap 'rm -rf -- "$TMUX_PICKER_STATE"' EXIT

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
		--ansi \
		--border=rounded \
		--border-label=" $FZF_THEME_NAME · windows " \
		--prompt='Select window > ' \
		--pointer='▶' \
		--bind 'ctrl-/:toggle-preview' \
		--bind 'shift-up:execute-silent("$TMUX_PICKER_PREVIEW" {2} "$TMUX_PICKER_STATE" --move up)+refresh-preview' \
		--bind 'shift-down:execute-silent("$TMUX_PICKER_PREVIEW" {2} "$TMUX_PICKER_STATE" --move down)+refresh-preview' \
		--bind 'preview-scroll-up:execute-silent("$TMUX_PICKER_PREVIEW" {2} "$TMUX_PICKER_STATE" --move up)+refresh-preview' \
		--bind 'preview-scroll-down:execute-silent("$TMUX_PICKER_PREVIEW" {2} "$TMUX_PICKER_STATE" --move down)+refresh-preview' \
		--bind 'pgup:execute-silent("$TMUX_PICKER_PREVIEW" {2} "$TMUX_PICKER_STATE" --move page-up)+refresh-preview' \
		--bind 'pgdn:execute-silent("$TMUX_PICKER_PREVIEW" {2} "$TMUX_PICKER_STATE" --move page-down)+refresh-preview' \
		--bind 'ctrl-home:execute-silent("$TMUX_PICKER_PREVIEW" {2} "$TMUX_PICKER_STATE" --move top)+refresh-preview' \
		--bind 'ctrl-end:execute-silent("$TMUX_PICKER_PREVIEW" {2} "$TMUX_PICKER_STATE" --move bottom)+refresh-preview' \
		--bind 'left:execute-silent("$TMUX_PICKER_PREVIEW" {2} "$TMUX_PICKER_STATE" --move left)+refresh-preview' \
		--bind 'right:execute-silent("$TMUX_PICKER_PREVIEW" {2} "$TMUX_PICKER_STATE" --move right)+refresh-preview' \
		--bind 'shift-left:execute-silent("$TMUX_PICKER_PREVIEW" {2} "$TMUX_PICKER_STATE" --move left)+refresh-preview' \
		--bind 'shift-right:execute-silent("$TMUX_PICKER_PREVIEW" {2} "$TMUX_PICKER_STATE" --move right)+refresh-preview' \
		--bind 'alt-b:execute-silent("$TMUX_PICKER_PREVIEW" {2} "$TMUX_PICKER_STATE" --move history)+refresh-preview' \
		--color="$FZF_THEME_COLOR" \
		--preview '"$TMUX_PICKER_PREVIEW" {2} "$TMUX_PICKER_STATE"' \
		--preview-window=right:68%:nowrap:border-left \
		--preview-label=' Source colors · Ctrl-/ toggle ')
picker_status=$?
(( picker_status == 0 )) || exit 0
[[ -n "$selection" ]] || exit 0
target=${selection##*$'\t'}
tmux switch-client -t "$target"

