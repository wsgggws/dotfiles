# Source this file to load switch_all_theme and its completion.
# Switch the themes already installed in this account.
# Theme switching does not install plugins or rebuild bat's cache.
switch_all_theme() {
  local choice="${1:l}" file changed
  local theme_home="${ALLTHEME_HOME:-$HOME}"
  case "$choice" in
    qinshan) choice=qingshan ;;
    qingshan|huangpao|dracula|catppuccin) ;;
    ""|-h|--help)
      printf '用法: switch_all_theme <qinshan|qingshan|huangpao|dracula|catppuccin>\n示例: switch_all_theme qinshan\n'
      return 0 ;;
    *) printf '未知主题: %s\n' "$1" >&2; return 2 ;;
  esac
  (( $# == 1 )) || { switch_all_theme --help >&2; return 2; }

  local alfred_switch="$theme_home/.config/alfred/themes/switch-theme.sh"
  local alfred_theme=alfred
  [[ "$choice" == qingshan || "$choice" == huangpao ]] && alfred_theme="$choice"
  if [[ "$OSTYPE" == darwin* ]]; then
    [[ -x "$alfred_switch" ]] || { printf '缺少 Alfred 切换脚本: %s\n' "$alfred_switch" >&2; return 1; }
    "$alfred_switch" --check "$alfred_theme" || return
  fi

  local -a files=(
    "$theme_home/.config/nvim/lua/plugins/colorschema.lua"
    "$theme_home/.tmux.conf.local" "$theme_home/.config/fzf/theme.sh"
    "$theme_home/.gitconfig" "$theme_home/.config/bat/config" "$theme_home/.wezterm.lua"
  )
  for file in "${files[@]}"; do
    [[ -f "$file" && -w "$file" ]] || { printf '配置不可写: %s\n' "$file" >&2; return 1; }
  done
  if [[ "$choice" == qingshan ]]; then
    for file in "$theme_home/.config/wezterm/colors/QingShan.toml" "$theme_home/.config/bat/themes/QingShan.tmTheme"; do
      [[ -f "$file" ]] || { printf '缺少主题文件，请先安装对应配色: %s\n' "$file" >&2; return 1; }
    done
  fi

  changed=$(command perl -e '
    use strict;
    use warnings;
    my $want = shift @ARGV;
    my @pending;
    for my $file (@ARGV) {
      open my $fh, "<", $file or die "$file: $!\n";
      my @lines = <$fh>;
      close $fh;
      my $original = join "", @lines;
      my $block;
      for (@lines) {
        if (/^([ \t]*)(?:-- )?((?:colorscheme|config\.color_scheme) = "(qingshan|QingShan|huangpao|dracula|catppuccin|HuangPao|Dracula \(Official\)|Catppuccin Mocha)".*)/) {
          my ($indent, $line, $name) = ($1, $2, lc $3);
          $name =~ s/ .*//;
          $_ = $indent . ($name eq $want ? "" : "-- ") . $line . "\n";
        }
        if (/^([ \t]*# (?:Original )?(QingShan|HuangPao|Catppuccin Mocha|Dracula)(?: palette| configuration)?)(?: \([^)]*\))?[ \t]*$/) {
          my $header = $1;
          $block = lc $2;
          $block =~ s/ .*//;
          $_ = $header . ($block eq $want ? " (active)\n" : " (inactive)\n");
        } elsif (/^\s*$/) {
          undef $block;
        } elsif (defined $block && /^([ \t]*)(?:# ?)?((?:[A-Za-z_][\w-]*\s*=|--theme="(?:QingShan|HuangPao|Dracula|Catppuccin Mocha)"|set -g popup-(?:border-)?style ).*)/) {
          $_ = $1 . ($block eq $want ? "" : "# ") . $2 . "\n";
        }
      }
      my $updated = join "", @lines;
      push @pending, [$file, $updated] if $updated ne $original;
    }
    # Finish reading every configuration before writing any of them.
    for my $change (@pending) {
      my ($file, $updated) = @$change;
      open my $fh, ">", $file or die "$file: $!\n";
      print {$fh} $updated or die "$file: $!\n";
      close $fh or die "$file: $!\n";
      print "$file\n";
    }
  ' "$choice" "${files[@]}") || return

  # Refresh this shell even when another terminal has already switched the files.
  source "$theme_home/.zsh/functions/fzf.zsh" || return
  if [[ "$changed" == *"$theme_home/.tmux.conf.local"* ]] && command tmux list-sessions >/dev/null 2>&1; then
    command tmux source-file "$theme_home/.tmux.conf" || {
      printf '配置已更新，但 tmux 重载失败；请运行 tmux source-file ~/.tmux.conf\n' >&2
      return 1
    }
  fi

  if [[ "$OSTYPE" == darwin* ]]; then
    "$alfred_switch" "$alfred_theme" || return
  fi
  return 0
}

_switch_all_theme() { _arguments '1:主题:(qinshan qingshan huangpao dracula catppuccin)'; }
if (( $+functions[compdef] )); then
  compdef _switch_all_theme switch_all_theme
fi
