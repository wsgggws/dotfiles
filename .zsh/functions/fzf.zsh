# ******* start fzf config
export FZF_DEFAULT_OPTS='--height 95% --layout=reverse --border --preview "bat --style=numbers {}"'
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_CTRL_T_OPTS="
  --preview 'bat -n {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"

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
  *) fzf --preview 'bat {}' "$@" ;;
  esac
}
alias f='fzf --bind "enter:become(nvim {})"'
# ******* start fzf config
