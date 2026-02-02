# =================================
#     1. Homebrew + zsh-completions
# =================================
if type brew &>/dev/null; then
  # 使用原生方法增加 FPATH（避免重复）
  FPATH="$(brew --prefix)/share/zsh-completions:$FPATH"
  FPATH="$(brew --prefix)/share/zsh/site-functions:$FPATH"

  autoload -Uz compinit
  # 使用安全模式，避免 Homebrew 权限问题警告
  compinit -d ~/.cache/zsh/compdump
fi

# =================================
#     2. 载入用户自己的配置
# =================================
[[ -f ~/.zsh/aliases.zsh ]]       && source ~/.zsh/aliases.zsh
[[ -f ~/.zsh/env.sh ]]            && source ~/.zsh/env.sh
[[ -f ~/.zsh/secret.env ]]        && source ~/.zsh/secret.env

# 从 ~/.zsh/functions 批量载入函数
for func_file in ~/.zsh/functions/*.zsh; do
  [[ -f "$func_file" ]] && source "$func_file"
done

# =================================
#     3. ESC 相关行为修复 (关键)
# =================================
# 强制使用 Emacs 模式，阻止 zsh 自动进入 vicmd
bindkey -e

# 禁用 autosuggestions 的 ESC fallback
export ZSH_AUTOSUGGEST_USE_FALLBACK=false

# =================================
#     4. 插件加载顺序（正确顺序）
# =================================
source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# syntax-highlighting 必须最后加载，这是官方要求
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

. "$HOME/.local/bin/env"

# 强制光标为闪烁竖线（beam）
echo -ne '\e[5 q'

# FZF（如已安装）
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && \. "/usr/local/opt/nvm/nvm.sh"  # This loads nvm

# 1. ctrl+ee 编辑长命令 2. ctrl+_ 撤销误操作 3. alias -s json="jless"
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^e^e' edit-command-line
# =================================
#     5. Starship 初始化
# =================================
# Starship 无冲突初始化
eval "$(starship init zsh)"
