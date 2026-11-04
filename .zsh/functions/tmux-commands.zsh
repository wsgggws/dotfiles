tmux_exec_all_win() {
  if [ -z "$1" ]; then
    echo "用法: tmux_exec_all_win <命令>"
    return 1
  fi

  local cmd="$*" panes pane foreground in_mode
  local -A seen
  panes=$(command tmux list-panes -a -F '#{pane_id} #{pane_current_command} #{pane_in_mode}') || return
  while read -r pane foreground in_mode; do
    [[ -n "$pane" && -z "${seen[$pane]-}" ]] || continue
    seen[$pane]=1
    # Use an allowlist so editors, SSH, REPLs and other foreground programs
    # never receive shell commands. Copy mode must not consume the keys either.
    case "$foreground" in
      zsh|-zsh|bash|-bash|sh|-sh|fish|-fish|ksh|-ksh|dash|-dash|csh|-csh|tcsh|-tcsh) ;;
      *) continue ;;
    esac
    [[ "$in_mode" == 0 ]] || continue
    command tmux send-keys -t "$pane" -l -- "$cmd" || return
    command tmux send-keys -t "$pane" Enter || return
  done <<< "$panes"
  return 0
}

tmux_kill_all_nvim() {
  local quit_command=':qa'
  case "${1-}" in
    '') ;;
    --force) quit_command=':qa!' ;;
    *) print -u2 -- '用法: tmux_kill_all_nvim [--force]'; return 2 ;;
  esac
  tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} #{pane_pid}" |
    while read -r pane pid; do
      if pgrep -P "$pid" -f nvim >/dev/null; then
        echo "Requesting nvim exit in $pane ($quit_command)"
        tmux send-keys -t "$pane" Escape
        tmux send-keys -t "$pane" -l "$quit_command"
        tmux send-keys -t "$pane" Enter
      fi
    done
}
