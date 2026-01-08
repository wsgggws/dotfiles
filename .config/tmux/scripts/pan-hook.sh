#!/bin/bash

SESSION=$(tmux display-message -p "#S")
WINDOW=$(tmux display-message -p "#W")
PANE=$(tmux display-message -p "#P")
TARGET="${SESSION}:${WINDOW}"
PANE_TARGET="${TARGET}.${PANE}"

# 获取 pane 最后一行（通常是 prompt）
LAST_LINE=$(tmux capture-pane -t "$PANE_TARGET" -p -J | grep -v '^$' | tail -1)

echo "LAST_LINE: $LAST_LINE" >>/tmp/tmux-hook.log

case "$TARGET" in
"ssh:prop")
  if echo "$LAST_LINE" | grep -qE "(root@sg_nginx_web3|@sg_nginx_web3)"; then
    echo "Already at target, skipping" >>/tmp/tmux-hook.log
  else
    # 这是我的 starship 的提示符，表示准备好接受命令, 其它情况不要发送命令，避免误操作
    if echo "$LAST_LINE" | grep -q " ❯ "; then
      tmux send-keys -t "$PANE_TARGET" 'ssh jumper' C-m
      sleep 2
      tmux send-keys -t "$PANE_TARGET" '10.11.195.241' C-m
      sleep 1
      tmux send-keys -t "$PANE_TARGET" 'jweb3' C-m
    else
      echo "Prompt not ready (no ❯), skipping" >>/tmp/tmux-hook.log
    fi
  fi
  ;;
"ssh:sql")
  if echo "$LAST_LINE" | grep -qE "(root@alisg-web3-app-01|@alisg-web3-app-01)"; then
    echo "Already at jumper, skipping" >>/tmp/tmux-hook.log
  else
    if echo "$LAST_LINE" | grep -q " ❯ "; then
      tmux send-keys -t "$PANE_TARGET" 'ssh jumper' C-m
      sleep 2
      tmux send-keys -t "$PANE_TARGET" '10.10.93.125' C-m
      sleep 1
      tmux send-keys -t "$PANE_TARGET" 'conda activate web3_user' C-m
    else
      echo "Prompt not ready (no ❯), skipping" >>/tmp/tmux-hook.log
    fi
  fi
  ;;
"ssh:kub")
  if echo "$LAST_LINE" | grep -qE "(newweb3-k8s-01-web3|tianhaijun)"; then
    echo "Already at jumper, skipping" >>/tmp/tmux-hook.log
  else
    if echo "$LAST_LINE" | grep -q " ❯ "; then
      tmux send-keys -t "$PANE_TARGET" 'ssh jumper' C-m
      sleep 2
      tmux send-keys -t "$PANE_TARGET" '10.11.193.41' C-m
    else
      echo "Prompt not ready (no ❯), skipping" >>/tmp/tmux-hook.log
    fi
  fi
  ;;
esac
