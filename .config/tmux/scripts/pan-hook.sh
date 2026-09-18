#!/bin/bash
set -euo pipefail

STEP1=3.5
STEP2=1.5
PANE_TARGET=${1:-}
SOCKET_PATH=${2:-}
[[ $PANE_TARGET =~ ^%[0-9]+$ ]] || exit 0
[[ -n $SOCKET_PATH ]] || exit 0

TARGET=$(tmux -S "$SOCKET_PATH" display-message -p -t "$PANE_TARGET" '#{session_name}:#{window_name}' 2>/dev/null) || exit 0
case "$TARGET" in
  "web3_property:s-prop") address=10.11.195.241; final=conda_prop; host_marker=@sg_nginx_web3 ;;
  "bitslots_game:s-game") address=10.10.93.125; final=conda_game; host_marker=@sg_nginx_web3 ;;
  "server_tg_lb:s-tg") address=10.10.93.125; final=conda_tg; host_marker=@sg_nginx_web3 ;;
  "server_lucky_admin:s-admin") address=10.10.93.125; final=conda_admin; host_marker=@sg_nginx_web3 ;;
  "web3_user:s-user") address=10.10.93.125; final=conda_user; host_marker=@sg_nginx_web3 ;;
  "lb_cs_gateway:s-cs") address=10.10.93.125; final=conda_cs; host_marker=@sg_nginx_web3 ;;
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
  local state target active viewers mode input_off command
  state=$(tmux -S "$SOCKET_PATH" display-message -p -t "$PANE_TARGET" \
    '#{session_name}:#{window_name}|#{pane_active}|#{window_active_clients}|#{pane_in_mode}|#{pane_input_off}|#{pane_current_command}' 2>/dev/null) || return 1
  IFS='|' read -r target active viewers mode input_off command <<< "$state"
  [[ $target == "$TARGET" && $active == 1 && $viewers =~ ^[1-9][0-9]*$ &&
     $mode == 0 && $input_off == 0 && $command == "$1" ]]
}

last_line() {
  tmux -S "$SOCKET_PATH" capture-pane -t "$PANE_TARGET" -p -J 2>/dev/null | awk 'NF { line=$0 } END { print line }'
}

send_cmd() {
  tmux -S "$SOCKET_PATH" send-keys -t "$PANE_TARGET" -l "$1"
  tmux -S "$SOCKET_PATH" send-keys -t "$PANE_TARGET" Enter
}

is_ready zsh || exit 0
initial_line=$(last_line)
[[ $initial_line == *" ❯ "* && $initial_line != *"$host_marker"* ]] || exit 0
send_cmd 'ssh jumper'

sleep "$STEP1"
is_ready ssh || exit 0
line=$(last_line)
[[ -n $line && $line != "$initial_line" ]] || exit 0
case "$(printf '%s' "$line" | tr '[:upper:]' '[:lower:]')" in
  *password*|*passphrase*|*verification*|*otp*|*"are you sure you want to continue connecting"*) exit 0 ;;
esac
send_cmd "$address"

if [[ -n $final ]]; then
  sleep "$STEP2"
  is_ready ssh || exit 0
  [[ $(last_line) == *"$host_marker"* ]] || exit 0
  send_cmd "$final"
fi
