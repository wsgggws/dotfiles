#!/bin/bash

STEP1=3.5
STEP2=1.5
LOG=/tmp/tmux-hook.log

SESSION=$(tmux display-message -p "#S")
WINDOW=$(tmux display-message -p "#W")
TARGET="${SESSION}:${WINDOW}"
PANE_TARGET=$(tmux display-message -p "#{pane_id}")

send_cmd() {
  tmux send-keys -t "$PANE_TARGET" -l "$1"
  tmux send-keys -t "$PANE_TARGET" Enter
}

is_prompt_ready() {
  echo "$LAST_LINE" | grep -q " ❯ "
}

log() {
  echo "$1" >>"$LOG"
}

# 获取 pane 最后一行（通常是 prompt）
LAST_LINE=$(tmux capture-pane -t "$PANE_TARGET" -p -J | grep -v '^$' | tail -1)

log "LAST_LINE: $LAST_LINE"

case "$TARGET" in
"web3_property:s-prop")
  if echo "$LAST_LINE" | grep -qE "(root@sg_nginx_web3|@sg_nginx_web3)"; then
    log "Already at target, skipping"
  else
    # 这是我的 starship 的提示符，表示准备好接受命令，其它情况不要发送命令，避免误操作
    if is_prompt_ready; then
      send_cmd 'ssh jumper'
      sleep "$STEP1"
      send_cmd '10.11.195.241'
      sleep "$STEP2"
      send_cmd 'conda_prop'
    else
      log "Prompt not ready (no ❯), skipping"
    fi
  fi
  ;;

"bitslots_game:s-game")
  if echo "$LAST_LINE" | grep -qE "(root@sg_nginx_web3|@sg_nginx_web3)"; then
    log "Already at target, skipping"
  else
    # 这是我的 starship 的提示符，表示准备好接受命令，其它情况不要发送命令，避免误操作
    if is_prompt_ready; then
      send_cmd 'ssh jumper'
      sleep "$STEP1"
      send_cmd '10.10.93.125'
      sleep "$STEP2"
      send_cmd 'conda_game'
    else
      log "Prompt not ready (no ❯), skipping"
    fi
  fi
  ;;

"server_tg_lb:s-tg")
  if echo "$LAST_LINE" | grep -qE "(root@sg_nginx_web3|@sg_nginx_web3)"; then
    log "Already at target, skipping"
  else
    # 这是我的 starship 的提示符，表示准备好接受命令，其它情况不要发送命令，避免误操作
    if is_prompt_ready; then
      send_cmd 'ssh jumper'
      sleep "$STEP1"
      send_cmd '10.26.14.204'
    else
      log "Prompt not ready (no ❯), skipping"
    fi
  fi
  ;;

"server_lucky_admin:s-admin")
  if echo "$LAST_LINE" | grep -qE "(root@sg_nginx_web3|@sg_nginx_web3)"; then
    log "Already at target, skipping"
  else
    # 这是我的 starship 的提示符，表示准备好接受命令，其它情况不要发送命令，避免误操作
    if is_prompt_ready; then
      send_cmd 'ssh jumper'
      sleep "$STEP1"
      send_cmd '10.10.93.125'
      sleep "$STEP2"
      send_cmd 'conda_admin'
    else
      log "Prompt not ready (no ❯), skipping"
    fi
  fi
  ;;

"web3_user:s-user")
  if echo "$LAST_LINE" | grep -qE "(root@sg_nginx_web3|@sg_nginx_web3)"; then
    log "Already at target, skipping"
  else
    # 这是我的 starship 的提示符，表示准备好接受命令，其它情况不要发送命令，避免误操作
    if is_prompt_ready; then
      send_cmd 'ssh jumper'
      sleep "$STEP1"
      send_cmd '10.10.93.125'
      sleep "$STEP2"
      send_cmd 'conda_user'
    else
      log "Prompt not ready (no ❯), skipping"
    fi
  fi
  ;;

"lb_cs_gateway:s-cs")
  if echo "$LAST_LINE" | grep -qE "(root@sg_nginx_web3|@sg_nginx_web3)"; then
    log "Already at target, skipping"
  else
    # 这是我的 starship 的提示符，表示准备好接受命令，其它情况不要发送命令，避免误操作
    if is_prompt_ready; then
      send_cmd 'ssh jumper'
      sleep "$STEP1"
      send_cmd '10.10.93.125'
      sleep "$STEP2"
      send_cmd 'conda_cs'
    else
      log "Prompt not ready (no ❯), skipping"
    fi
  fi
  ;;

"S0:sql")
  if echo "$LAST_LINE" | grep -qE "(root@alisg-web3-app-01|@alisg-web3-app-01)"; then
    log "Already at jumper, skipping"
  else
    if is_prompt_ready; then
      send_cmd 'ssh jumper'
      sleep "$STEP1"
      send_cmd '10.10.93.125'
      sleep "$STEP2"
      send_cmd 'conda_user'
    else
      log "Prompt not ready (no ❯), skipping"
    fi
  fi
  ;;

"S0:kub")
  if echo "$LAST_LINE" | grep -qE "(newweb3-k8s-01-web3|tianhaijun)"; then
    log "Already at jumper, skipping"
  else
    if is_prompt_ready; then
      send_cmd 'ssh jumper'
      sleep "$STEP1"
      send_cmd '10.11.193.41'
    else
      log "Prompt not ready (no ❯), skipping"
    fi
  fi
  ;;

esac
