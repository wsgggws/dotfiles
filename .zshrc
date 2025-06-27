export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(
  git
  zoxide
  fzf
  history
  zsh-autosuggestions
  fast-syntax-highlighting
  python
  poetry
  pip
  docker
  tmux
  extract
  zsh-you-should-use
)

source $ZSH/oh-my-zsh.sh

# === 载入 aliases
[[ -f ~/.zsh/aliases.zsh ]] && source ~/.zsh/aliases.zsh

# === 载入环境变量
[[ -f ~/.zsh/env.sh ]] && source ~/.zsh/env.sh

# === 载入 secret 环境变量（慎重）
[[ -f ~/.zsh/secret.env ]] && source ~/.zsh/secret.env

# === 载入所有函数
for func_file in ~/.zsh/functions/*.zsh; do
  [[ -f "$func_file" ]] && source "$func_file"
done

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
