# Compatibility entry point; defaults live next to their corresponding feature.
() {
  local root="${${(%):-%x}:A:h}/functions" module
  for module in docker editor man; do
    source "$root/$module.zsh" || return
  done
}
