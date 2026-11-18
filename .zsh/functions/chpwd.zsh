# Directory-based Conda activation, including lazy initialization. This module
# can be sourced on its own; it does not depend on alphabetical loading order.
source "${${(%):-%x}:A:h:h}/scripts/projects.sh" || return

# Configuration: set CONDA_HOME before loading this file to override the prefix.
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

_project_conda_chpwd() {
  local environment=""
  if terminal_project_for_dir "$PWD"; then
    environment=$TERMINAL_PROJECT_CONDA
  fi

  if [[ -n "$environment" ]]; then
    if [[ "${CONDA_DEFAULT_ENV-}" != "$environment" ]]; then
      conda activate "$environment" || return
      typeset -g _PROJECT_CONDA_ENV=$environment
    fi
  else
    # Leave manually selected environments alone; only undo our own activation.
    if [[ -n "${_PROJECT_CONDA_ENV-}" && "${CONDA_DEFAULT_ENV-}" == "$_PROJECT_CONDA_ENV" ]]; then
      conda deactivate || return
    fi
    unset _PROJECT_CONDA_ENV
  fi
  return 0
}

# Remove the former single chpwd handler when this file is reloaded in an old shell.
if [[ ${functions[chpwd]-} == *CONDA_DEFAULT_ENV* &&
      ${functions[chpwd]-} == *bitslots_game* &&
      ${functions[chpwd]-} == *'conda deactivate'* ]]; then
  unfunction chpwd
fi
autoload -Uz add-zsh-hook
add-zsh-hook -d chpwd _project_conda_chpwd
add-zsh-hook chpwd _project_conda_chpwd

# Also handle shells opened directly in a project and explicit module reloads.
_project_conda_chpwd
