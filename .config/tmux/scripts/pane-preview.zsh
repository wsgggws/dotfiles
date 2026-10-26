#!/bin/zsh
# Keep the historical entry point used by local tmux pickers.
exec python3 "${0:A:h}/pane-preview.py" "$@"

