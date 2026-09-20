#!/bin/bash
set -euo pipefail

POLL_INTERVAL=0.25
JUMPER_ATTEMPTS=40
TARGET_ATTEMPTS=80
PANE_TARGET=${1:-}
SOCKET_PATH=${2:-}
[[ $PANE_TARGET =~ ^%[0-9]+$ ]] || exit 0
[[ -n $SOCKET_PATH ]] || exit 0

TARGET=$(tmux -S "$SOCKET_PATH" display-message -p -t "$PANE_TARGET" '#{session_name}:#{window_name}' 2>/dev/null) || exit 0
case "$TARGET" in
  "web3_property:s-prop") address=10.11.195.241; final=conda_prop; host_marker=@sg_nginx_web3 ;;
  "bitslots_game:s-game") address=10.10.93.125; final=conda_game; host_marker=@alisg-web3-app-01 ;;
  "server_tg_lb:s-tg") address=10.10.93.125; final=conda_tg; host_marker=@alisg-web3-app-01 ;;
  "server_lucky_admin:s-admin") address=10.10.93.125; final=conda_admin; host_marker=@alisg-web3-app-01 ;;
  "web3_user:s-user") address=10.10.93.125; final=conda_user; host_marker=@alisg-web3-app-01 ;;
  "lb_cs_gateway:s-cs") address=10.10.93.125; final=conda_cs; host_marker=@alisg-web3-app-01 ;;
  "S0:sql") address=10.10.93.125; final=conda_user; host_marker=@alisg-web3-app-01 ;;
  "S0:kub") address=10.11.193.41; final=; host_marker=newweb3-k8s-01-web3 ;;
  *) exit 0 ;;
esac

# One connection attempt per pane; a second focus event must not start another sequence.
umask 077
lock_dir="${TMPDIR:-/tmp}/tmux-pan-hook-${UID}-${PANE_TARGET#%}.lock"
mkdir "$lock_dir" 2>/dev/null || exit 0
trap 'rmdir "$lock_dir" 2>/dev/null || true' EXIT
trap 'exit 0' HUP INT TERM

is_ready() {
  local expected=${1:-} state target active viewers mode input_off command
  state=$(tmux -S "$SOCKET_PATH" display-message -p -t "$PANE_TARGET" \
    '#{session_name}:#{window_name}|#{pane_active}|#{window_active_clients}|#{pane_in_mode}|#{pane_input_off}|#{pane_current_command}' 2>/dev/null) || return 1
  IFS='|' read -r target active viewers mode input_off command <<< "$state"
  [[ $target == "$TARGET" && $active == 1 && $viewers =~ ^[1-9][0-9]*$ &&
     $mode == 0 && $input_off == 0 ]] || return 1
  [[ -z $expected || $command == "$expected" ]]
}

last_line() {
  tmux -S "$SOCKET_PATH" capture-pane -t "$PANE_TARGET" -p -J 2>/dev/null | awk 'NF { line=$0 } END { print line }'
}

send_cmd() {
  tmux -S "$SOCKET_PATH" send-keys -t "$PANE_TARGET" -l "$1"
  tmux -S "$SOCKET_PATH" send-keys -t "$PANE_TARGET" Enter
}

has_blocking_prompt() {
  local normalized
  normalized=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  case "$normalized" in
    *password*|*passphrase*|*verification*|*otp*|*"are you sure you want to continue connecting"*) return 0 ;;
    *) return 1 ;;
  esac
}

wait_for_prompt() {
  local marker=$1 attempts=$2 line
  while (( attempts > 0 )); do
    is_ready || return 1
    line=$(last_line)
    has_blocking_prompt "$line" && return 1
    if [[ $line == *"$marker"* ]] && is_ready ssh; then
      return 0
    fi
    sleep "$POLL_INTERVAL"
    attempts=$((attempts - 1))
  done
  return 1
}

is_ready zsh || exit 0
initial_line=$(last_line)
[[ $initial_line == *" ❯ "* && $initial_line != *"$host_marker"* ]] || exit 0
send_cmd 'ssh jumper'

wait_for_prompt 'Opt>' "$JUMPER_ATTEMPTS" || exit 0
send_cmd "$address"

if [[ -n $final ]]; then
  wait_for_prompt "$host_marker" "$TARGET_ATTEMPTS" || exit 0
  send_cmd "$final"
fi
