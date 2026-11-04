# 终端共用入口

`projects.tsv` 统一维护目录别名、Conda 环境和 tmux 远端路由。每列以 Tab 分隔；目录别名以逗号分隔；未使用的字段写 `-`。不存放密码或令牌。

`projects.sh` 供 zsh 和 bash 共用。目录查找包含项目全部子目录，嵌套项目优先使用最近的匹配祖先。添加项目时只修改登记表。

Conda 在首次运行 `conda` 或进入登记项目时初始化，默认安装位置为 `$HOME/miniconda3`，可通过 `CONDA_HOME` 覆盖。离开项目时只退出自动激活的环境，手动选择的环境保留。

`bin/rg-fzf-open` 是内容搜索的唯一实现：

```zsh
rgf                 # 输入内容搜索，Enter 定位至 Neovim 行列，Esc 退出
rgf 'search text'   # 预填查询
```

Yazi 的 Ctrl+f 通过兼容入口调用同一脚本，复用依赖检查、实时搜索和预览。搜索从当前目录开始，遵循 ripgrep 的忽略规则。

Alfred 的 `~/.config/alfred/terminal-to-tmux` 默认定位 S0 的 deploy 窗口；窗口不存在时才创建。已有窗口直接切换过去，只有 shell 且未进入 copy mode 时才接受命令。正在运行其他程序时保留它并提示，不额外创建窗口或重建窗格。

`tmux_kill_all_nvim` 默认用 `:qa` 请求退出，保留未保存的修改；明确传入 `--force` 时才使用 `:qa!`。
