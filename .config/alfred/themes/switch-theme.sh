#!/bin/zsh

set -euo pipefail

theme_dir=${0:A:h}
alfred_preferences="$HOME/Library/Application Support/Alfred/Alfred.alfredpreferences"
appearance_prefs="$alfred_preferences/preferences/local/10f16cfbbd2f7bd1f14ac65d9306cfe8ea572d49/appearance/prefs.plist"

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

mkdir -p "$alfred_preferences/themes/$theme_id"
cp "$theme_dir/$theme_file" "$alfred_preferences/themes/$theme_id/theme.json"
cp "$theme_dir/$prefs_file" "$appearance_prefs"

osascript -e 'tell application id "com.runningwithcrayons.Alfred" to quit' 2>/dev/null || true
sleep 1
open -a "Alfred 5"
sleep 1

print "Activated: ${theme_file%.alfredappearance}"
