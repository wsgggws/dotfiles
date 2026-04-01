tmux_all_exec() {
  if [ -z "$1" ]; then
    echo "用法: tmux_all_exec <命令>"
    return 1
  fi

  local cmd="$*"

  tmux list-sessions -F "#{session_name}" | while read -r sess; do
    tmux list-windows -t "$sess" -F "#{window_index}" | while read -r win; do
      tmux send-keys -t "$sess:$win" "$cmd" C-m
    done
  done
}

tmux_kill_all_nvim() {
    tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} #{pane_pid}" | \
    while read pane pid; do
        if pgrep -P "$pid" -f nvim >/dev/null; then
            echo "Closing nvim in $pane"
            tmux send-keys -t "$pane" Escape ":qa!" Enter
        fi
    done
}
