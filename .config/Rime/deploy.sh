#!/bin/bash
# 在 yadm 恢复配置或编辑 YAML 后重新编译并通知鼠须管加载。
set -euo pipefail
rime_dir="$(cd "$(dirname "$0")" && pwd -P)"
if [[ -d "$HOME/Library/Input Methods/Squirrel.app" ]]; then
  squirrel_app="$HOME/Library/Input Methods/Squirrel.app"
elif [[ -d '/Library/Input Methods/Squirrel.app' ]]; then
  squirrel_app='/Library/Input Methods/Squirrel.app'
else
  echo '请先运行 ~/.config/Rime/install.sh 安装鼠须管。' >&2
  exit 1
fi
"$squirrel_app/Contents/MacOS/rime_deployer" --build \
  "$rime_dir" "$squirrel_app/Contents/SharedSupport" "$rime_dir/build"
"$squirrel_app/Contents/MacOS/Squirrel" --reload
