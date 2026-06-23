#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Sys Stats
# @raycast.mode inline

# Optional parameters:
# @raycast.icon 🖥️
# @raycast.refreshTime 1m

set -euo pipefail
export LC_ALL=C

# ---- Disk ----
disk=$(df -H / | awk 'NR==2 {print $4}')

# ---- Memory ----
total_mem=$(sysctl -n hw.memsize)

eval "$(
  vm_stat | awk '
    function num(v) {
      gsub(/[^0-9]/, "", v)
      return v + 0
    }

    /page size of/ {
      page_size = num($8)
    }

    /Pages free:/ {
      free_pages = num($3)
    }

    /Pages speculative:/ {
      speculative_pages = num($3)
    }

    /Pages purgeable:/ {
      purgeable_pages = num($3)
    }

    /Pages wired down:/ {
      wired_pages = num($4)
    }

    /File-backed pages:/ {
      file_backed_pages = num($3)
    }

    /Anonymous pages:/ {
      anonymous_pages = num($3)
    }

    /Pages occupied by compressor:/ {
      compressed_pages = num($5)
    }

    END {
      if (page_size == 0) {
        page_size = 4096
      }

      printf "page_size=%d\n", page_size
      printf "free_pages=%d\n", free_pages
      printf "speculative_pages=%d\n", speculative_pages
      printf "purgeable_pages=%d\n", purgeable_pages
      printf "wired_pages=%d\n", wired_pages
      printf "file_backed_pages=%d\n", file_backed_pages
      printf "anonymous_pages=%d\n", anonymous_pages
      printf "compressed_pages=%d\n", compressed_pages
    }
  '
)"

free_bytes=$((free_pages * page_size))

# Activity Monitor 的“已缓存文件”大致对应 file-backed + purgeable。
# 不同 macOS 版本下会有少量差异，但这个比 active+wired+compressed 更接近活动监控器。
cached_bytes=$(((file_backed_pages + purgeable_pages) * page_size))

# 更接近 Activity Monitor 左侧“已使用内存”的口径。
used_bytes=$((total_mem - cached_bytes - free_bytes))

# 防止 vm_stat 字段在不同系统版本上出现异常时显示负数或超过总内存。
if ((used_bytes < 0 || used_bytes > total_mem)); then
  used_bytes=$(((anonymous_pages + wired_pages + compressed_pages) * page_size))
fi

mem=$(
  awk -v used="$used_bytes" -v total="$total_mem" '
    BEGIN {
      printf "%.1f/%.1fG", used / 1024 / 1024 / 1024, total / 1024 / 1024 / 1024
    }
  '
)

cache=$(
  awk -v cached="$cached_bytes" '
    BEGIN {
      printf "%.1fG", cached / 1024 / 1024 / 1024
    }
  '
)

# ---- Swap ----
swap=$(
  sysctl vm.swapusage 2>/dev/null | awk '
    function to_gb(v) {
      if (v ~ /G$/) {
        sub(/G$/, "", v)
        return v + 0
      }

      if (v ~ /M$/) {
        sub(/M$/, "", v)
        return (v + 0) / 1024
      }

      if (v ~ /K$/) {
        sub(/K$/, "", v)
        return (v + 0) / 1024 / 1024
      }

      return (v + 0) / 1024 / 1024 / 1024
    }

    {
      for (i = 1; i <= NF; i++) {
        if ($i == "used") {
          printf "%.1fG", to_gb($(i + 2))
          exit
        }
      }
    }
  '
)

if [ -z "${swap:-}" ]; then
  swap="0.0G"
fi

# ---- CPU ----
cores=$(sysctl -n hw.logicalcpu 2>/dev/null || sysctl -n hw.ncpu)

cpu=$(
  ps -A -o %cpu= | awk -v cores="$cores" '
    {
      sum += $1
    }

    END {
      usage = sum / cores

      if (usage > 100) {
        usage = 100
      }

      printf "%.0f%%", usage
    }
  '
)

echo "💾 $disk free | 🧠 $mem | 📦 $cache | 🔁 $swap | 🔥 $cpu"
