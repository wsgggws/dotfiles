#!/bin/zsh
set -euo pipefail

theme_dir=${0:A:h}
check_only=false
if [[ "${1:-}" == --check ]]; then
  check_only=true
  shift
fi
theme_choice=${1:-}
case "${theme_choice:l}" in
  luzhu|"luzhu dark large")
    theme_file="LuZhu Dark Large.alfredappearance"
    prefs_file="luzhu.plist"
    ;;
  qinshan|qingshan|"qingshan dark large")
    theme_file="QingShan Dark Large.alfredappearance"
    prefs_file="qingshan.plist"
    ;;
  huangpao|"huangpao light large")
    theme_file="HuangPao Light Large.alfredappearance"
    prefs_file="huangpao-light-large.plist"
    ;;
  alfred|dracula|catppuccin|"alfred modern dark large")
    theme_file="Alfred Modern Dark Large.alfredappearance"
    prefs_file="alfred-modern-dark-large.plist"
    ;;
  *) print -u2 "Usage: $0 [--check] luzhu|qinshan|qingshan|huangpao|dracula|catppuccin|alfred"; exit 2 ;;
esac

alfred_preferences=${ALFRED_PREFERENCES:-}
if [[ -z "$alfred_preferences" ]]; then
  sync_folder=$(/usr/bin/defaults read com.runningwithcrayons.Alfred-Preferences syncfolder 2>/dev/null) || sync_folder=''
  alfred_preferences="${sync_folder:-$HOME/Library/Application Support/Alfred}/Alfred.alfredpreferences"
fi
appearance_prefs=${ALFRED_APPEARANCE_PREFS:-}
if [[ -z "$appearance_prefs" ]]; then
  appearance_files=("$alfred_preferences"/preferences/local/*/appearance/prefs.plist(N))
  if (( ${#appearance_files} != 1 )); then
    print -u2 'Cannot uniquely locate appearance/prefs.plist; set ALFRED_APPEARANCE_PREFS.'
    exit 1
  fi
  appearance_prefs=$appearance_files[1]
fi

plist_value() {
  local output
  output=$(/usr/bin/plutil "$@" 2>&1) || { print -ru2 -- "$output"; return 1; }
  print -r -- "$output"
}

plist_value -extract alfredtheme json -o /dev/null "$theme_dir/$theme_file" >/dev/null
theme_name=$(plist_value -extract alfredtheme.name raw -o - "$theme_dir/$theme_file")
plist_value -lint "$theme_dir/$prefs_file" "$appearance_prefs" >/dev/null
theme_id=$(plist_value -extract lightthemeuid raw -o - "$theme_dir/$prefs_file")
dark_id=$(plist_value -extract darkthemeuid raw -o - "$theme_dir/$prefs_file")
[[ "$theme_id" == theme.custom.* && "$dark_id" == "$theme_id" ]] || { print -u2 'Theme profile UID mismatch'; exit 1; }
if [[ "$prefs_file" == qingshan.plist || "$prefs_file" == luzhu.plist ]]; then
  other_profile=qingshan.plist
  [[ "$prefs_file" == qingshan.plist ]] && other_profile=luzhu.plist
  if [[ -f "$theme_dir/$other_profile" ]]; then
    other_id=$(plist_value -extract lightthemeuid raw -o - "$theme_dir/$other_profile")
    [[ "$theme_id" != "$other_id" ]] || { print -u2 'QingShan and LuZhu must have distinct Alfred theme IDs; reinstall their theme profiles.'; exit 1; }
  fi
fi
$check_only && exit 0

apply_live_theme() {
  command osascript - "$theme_name" >/dev/null <<'APPLESCRIPT'
on run argv
  tell application id "com.runningwithcrayons.Alfred" to set theme (item 1 of argv)
end run
APPLESCRIPT
}
registered_theme="$alfred_preferences/themes/$theme_id/theme.json"
current_light=$(/usr/bin/plutil -extract lightthemeuid raw -o - "$appearance_prefs" 2>/dev/null) || current_light=''
current_dark=$(/usr/bin/plutil -extract darkthemeuid raw -o - "$appearance_prefs" 2>/dev/null) || current_dark=''
if [[ "$current_light" == "$theme_id" && "$current_dark" == "$theme_id" ]] \
  && cmp -s "$theme_dir/$theme_file" "$registered_theme"; then
  if command pgrep -x Alfred >/dev/null; then
    apply_live_theme
  fi
  exit 0
fi

# Alfred caches its preferences. Quit normally before updating only theme UIDs.
was_running=false
if command pgrep -x Alfred >/dev/null; then
  was_running=true
  command osascript -e 'tell application id "com.runningwithcrayons.Alfred" to quit' >/dev/null
  for attempt in {1..30}; do
    command pgrep -x Alfred >/dev/null || break
    sleep 0.1
  done
  if command pgrep -x Alfred >/dev/null; then
    print -u2 'Alfred did not quit; preferences were not changed.'
    exit 1
  fi
fi

umask 077
mkdir -p "$theme_dir/backups" "${registered_theme:h}"
backup="$theme_dir/backups/appearance-$(date -u +%Y%m%dT%H%M%SZ)-$$.plist"
cp -p "$appearance_prefs" "$backup"
cp "$theme_dir/$theme_file" "$registered_theme"
for appearance_key in lightthemeuid darkthemeuid; do
  /usr/libexec/PlistBuddy -c "Set :$appearance_key $theme_id" "$appearance_prefs" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :$appearance_key string $theme_id" "$appearance_prefs"
done
if $was_running; then
  command open -b com.runningwithcrayons.Alfred
  apply_live_theme
fi
exit 0
