tmux_exec_all_win() {
  if [ -z "$1" ]; then
    echo "用法: tmux_exec_all_win <命令>"
    return 1
  fi

  local cmd="$*"

  tmux list-sessions -F "#{session_name}" | while read -r sess; do
    tmux list-windows -t "$sess" -F "#{window_index}" | while read -r win; do
      tmux send-keys -t "$sess:$win" -l "$cmd"
      tmux send-keys -t "$sess:$win" Enter
    done
  done
}

tmux_kill_all_nvim() {
  tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} #{pane_pid}" |
    while read -r pane pid; do
      if pgrep -P "$pid" -f nvim >/dev/null; then
        echo "Closing nvim in $pane"
        tmux send-keys -t "$pane" Escape
        tmux send-keys -t "$pane" -l ":qa!"
        tmux send-keys -t "$pane" Enter
      fi
    done
}
