# Initialize Conda only when requested or when entering a registered project.
_conda_load() {
  [[ ${_CONDA_LAZY_LOADED-} == 1 ]] && return 0
  local prefix=${CONDA_HOME:-$HOME/miniconda3} setup
  if [[ -r "$prefix/etc/profile.d/conda.sh" ]]; then
    source "$prefix/etc/profile.d/conda.sh" || return
  elif [[ -x "$prefix/bin/conda" ]]; then
    setup=$(CONDA_AUTO_ACTIVATE_BASE=false "$prefix/bin/conda" shell.zsh hook) || return
    eval "$setup" || return
  else
    print -u2 -- "Conda not found: $prefix (set CONDA_HOME to its installation directory)"
    return 127
  fi
  if [[ ${functions[conda]-} == *'_conda_load'* || -z ${functions[conda]-} ]]; then
    print -u2 -- 'Conda initialization did not define its shell function'
    return 1
  fi
  typeset -g _CONDA_LAZY_LOADED=1
}

if [[ ${_CONDA_LAZY_LOADED-} != 1 ]]; then
  conda() {
    _conda_load || return
    conda "$@"
  }
fi

_project_conda_chpwd
