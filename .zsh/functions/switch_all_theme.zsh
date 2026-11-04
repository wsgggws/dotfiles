# Source this file to load switch_all_theme and its completion.
# Switch the themes already installed in this account.
# --refresh reloads installed theme data without installing from a repository.
_alltheme_reload_shell() {
  source "${ALLTHEME_HOME:-$HOME}/.zsh/functions/fzf.zsh"
}

_alltheme_sync_tmux_shells() {
  local panes pid registered
  panes=$(command tmux list-panes -a -F '#{pane_pid} #{@alltheme_shell_pid}') || return
  while read -r pid registered; do
    # Only notify a pane's original shell after it has installed our handler.
    # Matching both PIDs also excludes stale options left by respawn-pane.
    [[ "$pid" == <-> && "$registered" == "$pid" && "$pid" != "$$" ]] || continue
    builtin kill -USR1 "$pid" 2>/dev/null || {
      # A pane may close between list-panes and kill.
      builtin kill -0 "$pid" 2>/dev/null || continue
      printf '无法通知 tmux shell %s 重载主题\n' "$pid" >&2
      return 1
    }
  done <<< "$panes"
  return 0
}

_alltheme_register_tmux_shell() {
  [[ -o interactive && -n "$TMUX" && -n "$TMUX_PANE" ]] || return 0
  [[ "$(command tmux display-message -p -t "$TMUX_PANE" '#{pane_pid}')" == "$$" ]] || return 0
  local existing_traps
  # $(trap) resets string traps in its subshell. Capture in this shell instead;
  # zsh removes the =(...) temporary file when the anonymous function returns.
  () {
    trap > "$1"
    existing_traps=$(<"$1")
  } =(:)
  # Leave existing function and string SIGUSR1 traps alone. A re-source after
  # installing a custom trap also withdraws our previous registration.
  if [[ -n "${functions[TRAPUSR1]-}" && "${functions[TRAPUSR1]}" != *'_alltheme_reload_shell'* ]] ||
     [[ "$existing_traps" == *' USR1'* ]]; then
    command tmux set-option -pu -t "$TMUX_PANE" @alltheme_shell_pid
    return
  fi
  # No text/Enter is sent into terminals. zsh handles the signal at its prompt,
  # or after its foreground child exits, preserving the current edit buffer.
  TRAPUSR1() {
    _alltheme_reload_shell
    return 0
  }
  command tmux set-option -p -t "$TMUX_PANE" @alltheme_shell_pid "$$"
}
_alltheme_register_tmux_shell

switch_all_theme() {
  local choice="${1:l}" file changed refresh=0
  local theme_home="${ALLTHEME_HOME:-$HOME}"
  case "$choice" in
    qinshan) choice=qingshan ;;
    luzhu|qingshan|huangpao|dracula|catppuccin) ;;
    ""|-h|--help)
      printf '用法: switch_all_theme <qinshan|luzhu|qingshan|huangpao|dracula|catppuccin> [--refresh]\n--refresh: 重建 bat/delta 缓存，并重载 WezTerm 和 tmux\n'
      return 0 ;;
    *) printf '未知主题: %s\n' "$1" >&2; return 2 ;;
  esac
  if (( $# == 2 )) && [[ "$2" == --refresh ]]; then
    refresh=1
  elif (( $# != 1 )); then
    switch_all_theme --help >&2
    return 2
  fi

  local alfred_switch="$theme_home/.config/alfred/themes/switch-theme.sh"
  local alfred_theme=alfred
  [[ "$choice" == luzhu || "$choice" == qingshan || "$choice" == huangpao ]] && alfred_theme="$choice"
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
  if [[ "$choice" == luzhu || "$choice" == qingshan ]]; then
    local display=QingShan
    [[ "$choice" == luzhu ]] && display=LuZhu
    for file in "$theme_home/.config/wezterm/colors/$display.toml" "$theme_home/.config/bat/themes/$display.tmTheme"; do
      [[ -f "$file" ]] || { printf '缺少主题文件，请先安装对应配色: %s\n' "$file" >&2; return 1; }
    done
  fi

  # Rebuild before changing selectors; keep cache diagnostics on stderr.
  if (( refresh )); then
    BAT_CONFIG_PATH=/dev/null command bat cache --build >/dev/null || return
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
        if (/^([ \t]*)(?:-- )?((?:colorscheme|config\.color_scheme) = "(luzhu|LuZhu|qingshan|QingShan|huangpao|dracula|catppuccin|HuangPao|Dracula \(Official\)|Catppuccin Mocha)".*)/) {
          my ($indent, $line, $name) = ($1, $2, lc $3);
          $name =~ s/ .*//;
          $_ = $indent . ($name eq $want ? "" : "-- ") . $line . "\n";
        }
        if (/^([ \t]*# (?:Original )?(LuZhu|QingShan|HuangPao|Catppuccin Mocha|Dracula)(?: palette| configuration)?)(?: \([^)]*\))?[ \t]*$/) {
          my $header = $1;
          $block = lc $2;
          $block =~ s/ .*//;
          $_ = $header . ($block eq $want ? " (active)\n" : " (inactive)\n");
        } elsif (/^\s*$/) {
          undef $block;
        } elsif (defined $block && /^([ \t]*)(?:# ?)?((?:[A-Za-z_][\w-]*\s*=|--theme="(?:LuZhu|QingShan|HuangPao|Dracula|Catppuccin Mocha)"|set -g popup-(?:border-)?style ).*)/) {
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
  _alltheme_reload_shell || return
  if (( refresh )); then
    command touch "$theme_home/.wezterm.lua" || return
  fi
  if { (( refresh )) || [[ -n "$changed" ]]; } && command tmux list-sessions >/dev/null 2>&1; then
    if (( refresh )) || [[ "$changed" == *"$theme_home/.tmux.conf.local"* ]]; then
      command tmux source-file "$theme_home/.tmux.conf" || {
        printf '配置已更新，但 tmux 重载失败；请运行 tmux source-file ~/.tmux.conf\n' >&2
        return 1
      }
    fi
    _alltheme_sync_tmux_shells || return
  fi

  if [[ "$OSTYPE" == darwin* ]]; then
    "$alfred_switch" "$alfred_theme" || return
  fi
  return 0
}

_switch_all_theme() {
  _arguments '1:主题:(luzhu qinshan qingshan huangpao dracula catppuccin)' '2:更新配色:(--refresh)'
}
if (( $+functions[compdef] )); then
  compdef _switch_all_theme switch_all_theme
fi
