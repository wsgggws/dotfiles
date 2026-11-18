# Editor selection and editing shortcuts.
export EDITOR=nvim
alias vi=nvim
alias vim=nvim
alias ve='nvim ~/.zsh/functions/editor.zsh'
alias vz='nvim ~/.zshrc'
alias vr='nvim ./README.md'
alias vs='nvim ~/.config/starship.toml'
alias vt='vi "$(mktemp /tmp/vt.XXXXXX)"'
alias vc='nvim ~/.wezterm.lua'
unalias vp 2>/dev/null
vp() {
  local tmp py
  tmp=$(mktemp /tmp/vp.XXXXXX) || return
  py="${tmp}.py"
  mv -- "$tmp" "$py" || return
  vi "$py"
}
