export EDITOR=nvim

export DOCKER_DEFAULT_PLATFORM=linux/amd64

# Better man with colors + bat (only if bat is available)
if command -v bat >/dev/null 2>&1; then
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi
