# ******* start fzf config

# 所有本机 zsh / tmux pane 共用历史；内存留余量，优先淘汰重复项。
HISTFILE="$HOME/.zsh_history"
HISTSIZE=60000
SAVEHIST=30000
unsetopt INC_APPEND_HISTORY INC_APPEND_HISTORY_TIME
setopt APPEND_HISTORY SHARE_HISTORY EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_DUPS HIST_SAVE_NO_DUPS

# zsh 补全和 tmux 窗口选择器共用同一套 fzf 主题。
source "$HOME/.config/fzf/theme.sh"

# Shared fzf layout; select a theme in ~/.config/fzf/theme.sh.
export FZF_DEFAULT_OPTS="
  --height=95%
  --layout=reverse
  --border=rounded
  --border-label=' $FZF_THEME_NAME · Files '
  --preview-label=' Preview · Ctrl-/ toggle '
  --preview-window='right:62%:nowrap:border-left'
  --bind 'ctrl-/:toggle-preview'
  --highlight-line
  --pointer='▶'
  --info=inline-right
  --preview '$FZF_THEME_PREVIEW_CMD {}'
  --color='$FZF_THEME_COLOR'
"
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_CTRL_T_OPTS="
  --preview '$FZF_THEME_PREVIEW_CMD {}'"

export FZF_CTRL_R_OPTS="
  --preview 'echo {}' --preview-window up:3:hidden:wrap
  --bind 'ctrl-/:toggle-preview'
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'"

# 用 fzf 内置遍历，Esc 时同步取消，避免外部 fd 管道在 HOME 扫描时阻塞。
# 清理已有 shell 中的旧生成器；文件补全仍只显示文件，并包含隐藏文件。
unfunction _fzf_compgen_path _fzf_compgen_dir 2>/dev/null
export FZF_COMPLETION_PATH_OPTS='--walker=file,hidden,follow --walker-skip=.git,node_modules,.cache,.Trash'
export FZF_COMPLETION_DIR_OPTS='--walker=dir,hidden,follow --walker-skip=.git,node_modules,.cache,.Trash'

_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
  cd) fzf --preview 'tree -C {} | head -200' "$@" ;;
  export | unset) fzf --preview "eval 'echo \$'{}" "$@" ;;
  ssh) fzf --preview 'dig {}' "$@" ;;
  *) fzf --preview "$FZF_THEME_PREVIEW_CMD {}" "$@" ;;
  esac
}
alias f='fzf --bind "enter:become(nvim {})"'

[[ -f "$HOME/.fzf.zsh" ]] && source "$HOME/.fzf.zsh"

# 停在提示符的窗口也能通过 Ctrl+R 搜到其他窗口刚执行的命令。
if (( $+functions[fzf-history-widget] )); then
  fzf-shared-history-widget() {
    [[ -r "$HISTFILE" ]] && builtin fc -RI "$HISTFILE"
    fzf-history-widget "$@"
  }
  zle -N fzf-shared-history-widget
  bindkey -M emacs '^R' fzf-shared-history-widget
  bindkey -M viins '^R' fzf-shared-history-widget
  bindkey -M vicmd '^R' fzf-shared-history-widget
fi
# ******* end fzf config
