#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Sys Stats
# @raycast.mode inline

# Optional parameters:
# @raycast.icon 🖥️
# @raycast.refreshTime 1m

# ---- Disk ----
disk=$(df -H / | awk 'NR==2 {print $4}')

# ---- Memory ----
page_size=$(vm_stat | grep "page size of" | awk '{print $8}' | tr -d '.')
free_pages=$(vm_stat | grep "Pages free" | awk '{print $3}' | tr -d '.')
total_mem=$(sysctl -n hw.memsize)
free_mem=$((free_pages * page_size))
free_gb=$(echo "$free_mem/1024/1024/1024" | bc)
total_gb=$(echo "$total_mem/1024/1024/1024" | bc)

# ---- CPU ----
cpu=$(ps -A -o %cpu | awk '{s+=$1} END {printf "%.0f%%", s}')

echo "💾 $disk free | 🧠 ${free_gb}G/${total_gb}G | 🔥 $cpu"
