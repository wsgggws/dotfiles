
if [[ $(uname -m) == "arm64" ]]; then
  # >>> conda initialize >>>
  # !! Contents within this block are managed by 'conda init' !!
  __conda_setup="$('/Users/thj/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
  if [ $? -eq 0 ]; then
      eval "$__conda_setup"
  else
      if [ -f "/Users/thj/miniconda3/etc/profile.d/conda.sh" ]; then
          . "/Users/thj/miniconda3/etc/profile.d/conda.sh"
      else
          export PATH="/Users/thj/miniconda3/bin:$PATH"
      fi
  fi
  unset __conda_setup
# <<< conda initialize <<<
else
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
  # export CONDA_AUTO_ACTIVATE_BASE=false
  unset __conda_setup  && conda deactivate && chpwd
  # <<< conda initialize <<<
fi
