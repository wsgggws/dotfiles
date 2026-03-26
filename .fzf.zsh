# Setup fzf
# ---------
if [[ ! "$PATH" == */usr/local/opt/fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/usr/local/opt/fzf/bin"
fi

if [[ $(uname -m) == "arm64" ]]; then
  export FZF_COMPLETION_PATH="/opt/homebrew/opt/fzf/shell/completion.zsh"
  export FZF_KEY_BINDINGS_PATH="/opt/homebrew/opt/fzf/shell/key-bindings.zsh"
else
  export FZF_COMPLETION_PATH="/usr/local/opt/fzf/shell/completion.zsh"
  export FZF_KEY_BINDINGS_PATH="/usr/local/opt/fzf/shell/key-bindings.zsh"
fi

# Source fzf
source $FZF_COMPLETION_PATH
source $FZF_KEY_BINDINGS_PATH
