#!/bin/bash
# 新 Mac：安装鼠须管，链接 yadm 配置并部署五笔 86。
set -euo pipefail

if [[ "${1:-}" == '--help' ]]; then
  echo '用法：~/.config/Rime/install.sh'
  echo '安装当前用户的鼠须管，创建 ~/Library/Rime 链接并部署五笔 86。'
  echo '已有鼠须管时直接复用；程序升级请使用输入法菜单中的“检查更新”。'
  exit 0
fi
if [[ $# -ne 0 ]]; then
  echo '不支持的参数；使用 --help 查看说明。' >&2
  exit 1
fi
if [[ "$(uname -s)" != Darwin ]]; then
  echo '此脚本仅支持 macOS。' >&2
  exit 1
fi
macos_version="$(sw_vers -productVersion)"
if (( ${macos_version%%.*} < 13 )); then
  echo '鼠须管 1.1.2 需要 macOS 13 或更新版本。' >&2
  exit 1
fi

rime_dir="$(cd "$(dirname "$0")" && pwd -P)"
expected_dir="$HOME/.config/Rime"
if [[ "$rime_dir" != "$(cd "$expected_dir" && pwd -P)" ]]; then
  echo '请先将此目录恢复到 ~/.config/Rime，再运行安装脚本。' >&2
  exit 1
fi

# 已安装的程序直接复用，不覆盖、不降级。
if [[ -x "$HOME/Library/Input Methods/Squirrel.app/Contents/MacOS/Squirrel" ]]; then
  squirrel_app="$HOME/Library/Input Methods/Squirrel.app"
elif [[ -x '/Library/Input Methods/Squirrel.app/Contents/MacOS/Squirrel' ]]; then
  squirrel_app='/Library/Input Methods/Squirrel.app'
else
  squirrel_version='1.1.2'
  squirrel_sha256='614746013212937623d5bbab9901e9c43d1ec937aa32307d6b6092a05e308287'
  install_tmp="$(mktemp -d "${TMPDIR:-/tmp}/rime-install.XXXXXX")"
  trap 'rm -rf "$install_tmp"' EXIT
  pkg="$install_tmp/Squirrel-$squirrel_version.pkg"
  echo "下载官方鼠须管 $squirrel_version……"
  curl --fail --location --retry 3 --connect-timeout 20 \
    "https://github.com/rime/squirrel/releases/download/$squirrel_version/Squirrel-$squirrel_version.pkg" \
    --output "$pkg"
  downloaded_sha256="$(shasum -a 256 "$pkg")"
  if [[ "${downloaded_sha256%% *}" != "$squirrel_sha256" ]]; then
    echo '安装包 SHA-256 校验失败，已停止安装。' >&2
    exit 1
  fi
  pkgutil --check-signature "$pkg"
  pkgutil --expand-full "$pkg" "$install_tmp/expanded"
  extracted_app="$install_tmp/expanded/Payload/Squirrel.app"
  codesign --verify --deep --strict "$extracted_app"
  mkdir -p "$HOME/Library/Input Methods"
  squirrel_app="$HOME/Library/Input Methods/Squirrel.app"
  ditto "$extracted_app" "$squirrel_app"
fi
codesign --verify --deep --strict "$squirrel_app"
echo "使用鼠须管：$squirrel_app"

mkdir -p "$HOME/Library"
rime_link="$HOME/Library/Rime"
if [[ -L "$rime_link" && "$(readlink "$rime_link")" == '../.config/Rime' ]]; then
  echo '配置链接已就绪。'
else
  if [[ -e "$rime_link" || -L "$rime_link" ]]; then
    "$squirrel_app/Contents/MacOS/Squirrel" --quit
    # 停止后再备份，确保学习词库已经关闭。
    for ((attempt = 0; attempt < 50; attempt++)); do
      if ! pgrep -u "$(id -u)" -x Squirrel >/dev/null; then
        break
      fi
      sleep 0.1
    done
    if pgrep -u "$(id -u)" -x Squirrel >/dev/null; then
      echo '鼠须管尚未退出，请退出后重新运行。' >&2
      exit 1
    fi
    backup_dir="$(mktemp -d "$HOME/Library/Rime.backup.XXXXXX")"
    mv "$rime_link" "$backup_dir/Rime"
    echo "原配置与学习词库已备份：$backup_dir/Rime"
  fi
  ln -s '../.config/Rime' "$rime_link"
  echo "已链接：$rime_link → $rime_dir"
fi

# 使用系统自带的 JXA 注册实际安装路径，不需要 Xcode 或 Swift。
osascript -l JavaScript - "$squirrel_app" <<'JXA'
ObjC.import('Carbon');
function run(argv) {
  var status = $.TISRegisterInputSource($.NSURL.fileURLWithPath(argv[0]));
  if (status !== 0) throw new Error('注册输入法失败，状态码：' + status);
  return '鼠须管注册完成。';
}
JXA
"$squirrel_app/Contents/MacOS/Squirrel" --enable-input-source im.rime.inputmethod.Squirrel.Hans
"$rime_dir/deploy.sh"
open -a "$squirrel_app"
"$squirrel_app/Contents/MacOS/Squirrel" --reload
echo '安装和部署完成。首次安装请注销并重新登录，再用 Fn 切换至鼠须管。'
