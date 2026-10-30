# `lazygit log` normally forces a 50/50 layout. Use the review layout instead.
# ~/.zshrc already sources this directory for new interactive shells.
function lazygit() {
  if [[ "${1-}" == log ]]; then
    command lazygit \
      --use-config-file "$HOME/.config/lazygit/config.yml,$HOME/.config/lazygit/review.yml" \
      --screen-mode normal "$@"
  else
    command lazygit "$@"
  fi
}
