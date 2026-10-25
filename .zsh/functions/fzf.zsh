# ******* start fzf config

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

# this effect vim **<tab>, "--type f" show file and do not show empty dir ;)
_fzf_compgen_path() {
  fd --type f --hidden --follow --exclude ".git" . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude ".git" . "$1"
}

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
# ******* end fzf config
