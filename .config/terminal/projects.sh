# Shared by zsh directory hooks and bash tmux launchers; no external processes.
# Lookup results are read by the scripts sourcing this file.
# shellcheck disable=SC2034
_terminal_project_lookup() {
  local kind=$1 value=$2 id dirs env session window address remote marker
  local file=${TERMINAL_PROJECTS_FILE:-$HOME/.config/terminal/projects.tsv} tab=$'\t'
  TERMINAL_PROJECT_ID='' TERMINAL_PROJECT_CONDA='' TERMINAL_PROJECT_SESSION=''
  TERMINAL_PROJECT_WINDOW='' TERMINAL_PROJECT_ADDRESS='' TERMINAL_PROJECT_COMMAND='' TERMINAL_PROJECT_MARKER=''
  [ -r "$file" ] || return 1
  while IFS="$tab" read -r id dirs env session window address remote marker; do
    case "$id" in ''|'#'*) continue ;; esac
    case "$kind" in
      dir) case ",$dirs," in *",$value,"*) ;; *) continue ;; esac ;;
      tmux) [ "$session:$window" = "$value" ] || continue ;;
      *) return 1 ;;
    esac
    TERMINAL_PROJECT_ID=$id
    [ "$env" = - ] || TERMINAL_PROJECT_CONDA=$env
    [ "$session" = - ] || TERMINAL_PROJECT_SESSION=$session
    [ "$window" = - ] || TERMINAL_PROJECT_WINDOW=$window
    [ "$address" = - ] || TERMINAL_PROJECT_ADDRESS=$address
    [ "$remote" = - ] || TERMINAL_PROJECT_COMMAND=$remote
    [ "$marker" = - ] || TERMINAL_PROJECT_MARKER=$marker
    return 0
  done < "$file"
  return 1
}

terminal_project_for_dir() {
  local directory=${1%/}
  # The nearest matching ancestor owns the environment, including nested projects.
  while [ -n "$directory" ]; do
    _terminal_project_lookup dir "${directory##*/}" && return 0
    case "$directory" in */*) directory=${directory%/*} ;; *) break ;; esac
  done
  return 1
}

terminal_project_for_tmux() {
  _terminal_project_lookup tmux "$1"
}
