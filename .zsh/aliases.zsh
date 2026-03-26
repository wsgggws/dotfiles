# need npm install trash
alias rm=trash

alias vi=nvim
alias vim=nvim
alias ve="nvim ~/.zsh/env.sh"
alias vz="nvim ~/.zshrc"
alias vr="nvim ./README.md"
alias vs="nvim ~/.config/starship.toml"
alias vt='vi "$(mktemp /tmp/vt.XXXXXX)"'
alias src="source ~/.zshrc"

alias ls='eza --icons=auto'
alias ll='eza -al --icons=auto'
alias lt='eza --tree --level=2 --icons=auto'

alias vk='nvim ~/.config/kitty/kitty.conf'

alias show='kitty +kitten icat'
alias kdiff='kitty +kitten diff'

alias brewbackup='brew bundle dump --describe --force --file="~/.config/brew/Brewfile"'

alias duh='du -sh *'
alias psa="ps aux | grep"
alias k9="kill -9"
alias ports="lsof -iTCP -sTCP:LISTEN -n -P"

alias g='git'
alias ga='git add'
alias gcb='git checkout -b'
alias gsw='git switch'
alias gst='git status'
alias gd='git diff'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gbD='git branch --delete --force'
alias glg='git log --oneline --graph --decorate'
