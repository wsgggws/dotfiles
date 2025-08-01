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
