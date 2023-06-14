alias bi='brew install'
alias src="exec zsh"
alias rm=trash
alias python3=/opt/homebrew/bin/python3.8
alias python=/opt/homebrew/bin/python3.8
alias pip3=/opt/homebrew/bin/pip3.8
alias pip=/opt/homebrew/bin/pip3.8
alias brewbackup='brew bundle dump --describe --force --file="~/github/dotfiles/brew/Brewfile"'

# ****** start 给cd命令别名为 cd 并ls
which -a cd | grep 'cd: aliased to cdd' >/dev/null
if [ $? -ne 0 ]; then
	function cdd() {
		cd $1
		ls
	}
	alias cd='cdd'
fi
# ****** end

# ******* start nvim config
alias vi=$HOME/softwares/nvim-macos/bin/nvim
alias vim=vi
alias nvim=vi
alias ve="vim ~/.env.sh"
alias vz="vim ~/.zshrc"
alias vv='nvim ~/.config/nvim/init.vim'
export EDITOR=nvim
# ******* end nvim config

# ******* start bat config
# 可以使用 bat --config-file 生成配置文件并配置默认参数, 见 GitHub repo
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
alias bathelp='bat --plain --language=help'
help() {
	"$@" --help 2>&1 | bathelp
}
# ******* end bat config

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

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
