export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git autojump history zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

[[ -f ~/.env.sh ]] && source ~/.env.sh

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
