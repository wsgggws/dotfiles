#!/usr/bin/env bash
set -u

FAILED=()

FORMULAE="$(brew outdated --formula)"

echo "🍺 需要升级的 formula 数量:"
echo "$FORMULAE" | wc -l
echo "--------------------------------"

for pkg in $FORMULAE; do
  echo
  echo "🔄 正在升级: $pkg"
  if brew upgrade "$pkg"; then
    echo "✅ 成功: $pkg"
  else
    echo "❌ 失败: $pkg"
    FAILED+=("$pkg")
  fi
done

echo
echo "--------------------------------"
if [ ${#FAILED[@]} -eq 0 ]; then
  echo "🎉 所有 formula 升级完成！"
else
  echo "⚠️ 以下 formula 升级失败："
  for p in "${FAILED[@]}"; do
    echo "  - $p"
  done
fi
