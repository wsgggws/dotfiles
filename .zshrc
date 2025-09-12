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

# 避免多次加载 zsh-autosuggestions
[[ -n "$ZSH_AUTOSUGGEST_LOADED" ]] || export ZSH_AUTOSUGGEST_LOADED=1

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

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/navy/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/navy/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/navy/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/navy/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

