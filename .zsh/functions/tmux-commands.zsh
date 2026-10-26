tmux_exec_all_win() {
  if [ -z "$1" ]; then
    echo "用法: tmux_exec_all_win <命令>"
    return 1
  fi

  local cmd="$*"

  tmux list-sessions -F "#{session_name}" | while read -r sess; do
    tmux list-windows -t "$sess" -F "#{window_index}" | while read -r win; do
      tmux send-keys -t "$sess:$win" -l "$cmd"
      tmux send-keys -t "$sess:$win" Enter
    done
  done
}

tmux_kill_all_nvim() {
  tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} #{pane_pid}" |
    while read -r pane pid; do
      if pgrep -P "$pid" -f nvim >/dev/null; then
        echo "Closing nvim in $pane"
        tmux send-keys -t "$pane" Escape
        tmux send-keys -t "$pane" -l ":qa!"
        tmux send-keys -t "$pane" Enter
      fi
    done
}

# Switch theme names; keep Neovim plugins installed and other palettes commented.
alltheme() {
  local choice="${1:l}" file changed
  case "$choice" in
    sheepskin|dracula|catppuccin) ;;
    ""|-h|--help)
      printf '用法: alltheme <sheepskin|dracula|catppuccin>\n示例: alltheme sheepskin\n'
      return 0 ;;
    *) printf '未知主题: %s\n用法: alltheme <sheepskin|dracula|catppuccin>\n' "$1" >&2; return 2 ;;
  esac
  (( $# == 1 )) || { alltheme --help; return 2; }

  local -a files=(
    "$HOME/.config/nvim/lua/plugins/colorschema.lua"
    "$HOME/.tmux.conf.local" "$HOME/.config/fzf/theme.sh"
    "$HOME/.gitconfig" "$HOME/.config/bat/config" "$HOME/.wezterm.lua"
  )
  for file in "${files[@]}"; do
    [[ -f "$file" && -w "$file" ]] || { printf '配置不可写: %s\n' "$file" >&2; return 1; }
  done

  # One Perl process for all files; unchanged files keep their modification time.
  changed=$(command perl -e '
    use strict;
    use warnings;
    my $want = shift @ARGV;
    for my $file (@ARGV) {
      open my $fh, "+<", $file or die "$file: $!\n";
      my @lines = <$fh>;
      my $original = join "", @lines;
      my $block;
      for (@lines) {
        # Lua selectors: leave all plugin definitions and unrelated schemes alone.
        if (/^([ \t]*)(?:-- )?((?:colorscheme|config\.color_scheme) = "(sheepskin|dracula|catppuccin|Sheepskin|Dracula \(Official\)|Catppuccin Mocha)".*)/) {
          my ($indent, $line, $name) = ($1, $2, lc $3);
          $name =~ s/ .*//;
          $_ = $indent . ($name eq $want ? "" : "-- ") . $line . "\n";
        }
        # Palette blocks start with a theme header and end at a blank line.
        if (/^([ \t]*# (?:Original )?(Sheepskin Light|Catppuccin Mocha|Dracula)(?: palette| configuration)?)(?: \([^)]*\))?[ \t]*$/) {
          my $header = $1;
          $block = lc $2;
          $block =~ s/ .*//;
          $_ = $header . ($block eq $want ? " (active)\n" : " (inactive)\n");
        } elsif (/^\s*$/) {
          undef $block;
        } elsif (defined $block && /^([ \t]*)(?:# ?)?((?:[A-Za-z_][\w-]*\s*=|--theme="(?:SheepskinLight|Dracula|Catppuccin Mocha)"|set -g popup-(?:border-)?style ).*)/) {
          $_ = $1 . ($block eq $want ? "" : "# ") . $2 . "\n";
        }
      }
      my $updated = join "", @lines;
      if ($updated ne $original) {
        seek $fh, 0, 0 or die "$file: $!\n";
        print {$fh} $updated or die "$file: $!\n";
        truncate $fh, tell($fh) or die "$file: $!\n";
        close $fh or die "$file: $!\n";
        print "$file\n";
      }
    }
  ' "$choice" "${files[@]}") || return

  # Always refresh this shell, even if another shell already switched the files.
  source "$HOME/.zsh/functions/fzf.zsh" || return
  if [[ "$changed" == *"$HOME/.tmux.conf.local"* ]] && command tmux list-sessions >/dev/null 2>&1; then
    command tmux source-file "$HOME/.tmux.conf" || {
      printf '配置已切换，但 tmux 重载失败；请执行 tmux source-file ~/.tmux.conf\n' >&2
      return 1
    }
  fi
  if [[ -n "$changed" ]]; then
    printf '已切换到 %s（Neovim 重新打开后生效）。\n' "$choice"
  else
    printf '当前配置已是 %s，已刷新本终端 fzf。\n' "$choice"
  fi
}

_alltheme() { _arguments '1:主题:(sheepskin dracula catppuccin)'; }
if (( $+functions[compdef] )); then
  compdef _alltheme alltheme
fi
