# Project configuration and lookup shared by bash/zsh. Source this file; it has
# no startup side effects. Each project is one block with named shell arguments.
# name is the repository name; Conda and tmux session names follow it by default.
# directory adds an alias; conda/session can override the default or be empty
# to disable it. directory_matching=false disables directory-based activation.
_terminal_project_lookup() {
  local query_kind=$1 query_value=$2
  TERMINAL_PROJECT_ID='' TERMINAL_PROJECT_KEY='' TERMINAL_PROJECT_CONDA=''
  TERMINAL_PROJECT_SESSION='' TERMINAL_PROJECT_WINDOW='' TERMINAL_PROJECT_ADDRESS=''
  TERMINAL_PROJECT_COMMAND='' TERMINAL_PROJECT_MARKER=''
  [ -n "$query_value" ] || return 1

  # Stable key: web3. Rename only name to update all dependent defaults.
  _terminal_project_match web3 \
    name=web3_property_lb \
    directory=peak \
    directory=platform \
    window=s-prop \
    address=10.11.195.241 \
    command=conda_prop \
    marker=@sg_nginx_web3 && return 0

  _terminal_project_match game \
    name=bitslots_game \
    window=s-game \
    address=10.10.93.125 \
    command=conda_game \
    marker=@alisg-web3-app-01 && return 0

  _terminal_project_match tg \
    name=server_tg_lb \
    window=s-tg \
    address=10.10.93.125 \
    command=conda_tg \
    marker=@alisg-web3-app-01 && return 0

  _terminal_project_match user \
    name=lb_user_svr \
    window=s-user \
    address=10.10.93.125 \
    command=conda_user \
    marker=@alisg-web3-app-01 && return 0

  _terminal_project_match admin \
    name=server_lucky_admin \
    window=s-admin \
    address=10.10.93.125 \
    command=conda_admin \
    marker=@alisg-web3-app-01 && return 0

  _terminal_project_match cs \
    name=lb_cs_gateway \
    window=s-cs \
    address=10.10.93.125 \
    command=conda_cs \
    marker=@alisg-web3-app-01 && return 0

  _terminal_project_match lark \
    name=lb_lark_cmdline \
    session='' && return 0

  _terminal_project_match sql \
    name=sql \
    directory_matching=false \
    conda='' \
    session=S0 \
    window=sql \
    address=10.10.93.125 \
    command=conda_user \
    marker=@alisg-web3-app-01 && return 0

  _terminal_project_match kub \
    name=kub \
    directory_matching=false \
    conda='' \
    session=S0 \
    window=kub \
    address=10.11.193.41 \
    marker=newweb3-k8s-01-web3 && return 0

  return 1
}

_terminal_project_match() {
  local key=$1 name='' conda='@project' session='@project' window=''
  local address='' remote='' marker='' directory_matching=true option directory matched=false
  local -a directories=()
  shift
  for option in "$@"; do
    case "$option" in
    name=*) name=${option#*=} ;;
    directory=*) directories+=("${option#*=}") ;;
    directory_matching=*) directory_matching=${option#*=} ;;
    conda=*) conda=${option#*=} ;;
    session=*) session=${option#*=} ;;
    window=*) window=${option#*=} ;;
    address=*) address=${option#*=} ;;
    command=*) remote=${option#*=} ;;
    marker=*) marker=${option#*=} ;;
    *)
      printf 'Unknown project option: %s\n' "$option" >&2
      return 2
      ;;
    esac
  done
  [ "$conda" != '@project' ] || conda=$name
  [ "$session" != '@project' ] || session=$name

  # query_kind/query_value are local to the calling lookup, in both bash/zsh.
  case "$query_kind" in
  dir)
    [ "$directory_matching" = true ] || return 1
    for directory in "$name" "${directories[@]-}"; do
      if [ "$directory" = "$query_value" ]; then
        matched=true
        break
      fi
    done
    [ "$matched" = true ] || return 1
    ;;
  tmux)
    [ -n "$session" ] && [ -n "$window" ] || return 1
    [ "$session:$window" = "$query_value" ] || return 1
    ;;
  key) [ "$key" = "$query_value" ] || return 1 ;;
  *) return 1 ;;
  esac
  TERMINAL_PROJECT_ID=$name TERMINAL_PROJECT_KEY=$key
  TERMINAL_PROJECT_CONDA=$conda TERMINAL_PROJECT_SESSION=$session
  TERMINAL_PROJECT_WINDOW=$window TERMINAL_PROJECT_ADDRESS=$address
  TERMINAL_PROJECT_COMMAND=$remote TERMINAL_PROJECT_MARKER=$marker
  return 0
}

terminal_project_for_dir() {
  local directory=${1%/}
  # Nearest ancestor wins, including projects nested inside another project.
  while [ -n "$directory" ]; do
    _terminal_project_lookup dir "${directory##*/}" && return 0
    case "$directory" in */*) directory=${directory%/*} ;; *) break ;; esac
  done
  _terminal_project_lookup dir ''
}

terminal_project_for_tmux() {
  _terminal_project_lookup tmux "$1"
}

terminal_project_by_key() {
  _terminal_project_lookup key "$1"
}
