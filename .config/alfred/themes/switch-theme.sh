#!/bin/zsh

set -euo pipefail

theme_dir=${0:A:h}
alfred_preferences=${ALFRED_PREFERENCES:-}
if [[ -z "$alfred_preferences" ]]; then
  sync_folder=$(/usr/bin/defaults read com.runningwithcrayons.Alfred-Preferences syncfolder 2>/dev/null) || sync_folder=''
  alfred_preferences="${sync_folder:-$HOME/Library/Application Support/Alfred}/Alfred.alfredpreferences"
fi

appearance_prefs=${ALFRED_APPEARANCE_PREFS:-}
if [[ -z "$appearance_prefs" ]]; then
  appearance_files=("$alfred_preferences"/preferences/local/*/appearance/prefs.plist(N))
  if (( ${#appearance_files} != 1 )); then
    print -u2 'Cannot uniquely locate appearance/prefs.plist; set ALFRED_APPEARANCE_PREFS to the current device file.'
    exit 1
  fi
  appearance_prefs=$appearance_files[1]
fi

case "${1:-}" in
  sheepskin|"SheepSkin Light Large")
    theme_id="theme.custom.1718079A-1C3F-44DA-A83C-BC93AA51C9FA"
    theme_file="SheepSkin Light Large.alfredappearance"
    prefs_file="sheepskin-light-large.plist"
    ;;
  alfred|"Alfred Modern Dark Large")
    theme_id="theme.custom.F96B87FC-EEDF-4B05-8478-01DDD5AEE210"
    theme_file="Alfred Modern Dark Large.alfredappearance"
    prefs_file="alfred-modern-dark-large.plist"
    ;;
  *)
    print -u2 "Usage: $0 sheepskin|alfred"
    exit 2
    ;;
esac

# Validate everything before stopping Alfred or changing live preferences.
/usr/bin/plutil -extract alfredtheme json -o /dev/null "$theme_dir/$theme_file"
/usr/bin/plutil -lint "$theme_dir/$prefs_file" "$appearance_prefs" >/dev/null
for appearance_key in lightthemeuid darkthemeuid; do
  profile_id=$(/usr/bin/plutil -extract "$appearance_key" raw -o - "$theme_dir/$prefs_file")
  [[ "$profile_id" == "$theme_id" ]] || { print -u2 'Theme profile UID mismatch'; exit 1; }
done

# Quit first so Alfred cannot save its cached appearance over the update.
/usr/bin/osascript -e 'tell application id "com.runningwithcrayons.Alfred" to quit'
for attempt in {1..30}; do
  /usr/bin/pgrep -x Alfred >/dev/null || break
  sleep 0.1
done
if /usr/bin/pgrep -x Alfred >/dev/null; then
  print -u2 'Alfred did not quit; preferences were not changed.'
  exit 1
fi

mkdir -p "$theme_dir/backups" "$alfred_preferences/themes/$theme_id"
cp -p "$appearance_prefs" "$theme_dir/backups/appearance-before-switch.plist"
cp "$theme_dir/$theme_file" "$alfred_preferences/themes/$theme_id/theme.json"
# Preserve all unrelated appearance preferences.
for appearance_key in lightthemeuid darkthemeuid; do
  /usr/libexec/PlistBuddy -c "Set :$appearance_key $theme_id" "$appearance_prefs" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :$appearance_key string $theme_id" "$appearance_prefs"
done
/usr/bin/open -b com.runningwithcrayons.Alfred

print "Activated: ${theme_file%.alfredappearance}"
