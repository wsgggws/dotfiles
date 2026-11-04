source "$HOME/.config/terminal/projects.sh"

_project_conda_chpwd() {
  local environment=""
  if terminal_project_for_dir "$PWD"; then
    environment=$TERMINAL_PROJECT_CONDA
  fi

  if [[ -n "$environment" ]]; then
    if [[ "${CONDA_DEFAULT_ENV-}" != "$environment" ]]; then
      conda activate "$environment" || return
    fi
    typeset -g _PROJECT_CONDA_ENV=$environment
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
if [[ ${functions[chpwd]-} == *web3_property* &&
      ${functions[chpwd]-} == *bitslots_game* &&
      ${functions[chpwd]-} == *'conda deactivate'* ]]; then
  unfunction chpwd
fi
autoload -Uz add-zsh-hook
add-zsh-hook -d chpwd _project_conda_chpwd
add-zsh-hook chpwd _project_conda_chpwd
