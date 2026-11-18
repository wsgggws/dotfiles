# Compatibility entry point; new shells load functions/*.zsh directly.
() {
  local root="${${(%):-%x}:A:h}/functions" module
  for module in brew editor files git process reload; do
    source "$root/$module.zsh" || return
  done
}
