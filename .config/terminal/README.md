# 终端共用入口

项目登记及查找的唯一源码是 `~/.zsh/scripts/projects.sh`，本目录的 `projects.sh` 是指向它的相对符号链接，供 bash/tmux 兼容调用。

每个项目使用一个带字段名的 shell 配置块，名称、目录别名、Conda 环境、tmux 路由在同一块维护。项目改名只修改 `name=...`；默认 Conda 环境名、tmux 会话名及部署目标随之更新。目录别名通过 `directory=...` 添加，可重复填写；带空格的值使用 shell 引号。

Conda 与会话可用 `conda=...`、`session=...` 单独指定；空字符串表示停用。`directory_matching=false` 停用目录匹配。其余字段及示例见 `~/.zsh/README.md`。配置使用普通 shell 语法，所有项目直接在脚本内维护，不读取外部登记表。不存放密码或令牌。

当前 `web3` 对应 `web3_property_lb`，`user` 对应 `lb_user_svr`；服务名称在 `~/.zsh/functions/deploy.zsh` 维护。

Conda 在首次运行 `conda` 或进入登记项目时初始化，默认安装位置为 `$HOME/miniconda3`，可通过 `CONDA_HOME` 覆盖。离开项目时只退出自动激活的环境，手动选择的环境保留。

`bin/rg-fzf-open` 是内容搜索的唯一实现：

```zsh
rgf                 # 输入内容搜索，Enter 定位至 Neovim 行列，Esc 退出
rgf 'search text'   # 预填查询
```

Yazi 的 Ctrl+f 通过兼容入口调用同一脚本，复用依赖检查、实时搜索和预览。搜索从当前目录开始，遵循 ripgrep 的忽略规则。

Alfred 的 `~/.config/alfred/terminal-to-tmux` 默认定位 S0 的 deploy 窗口；窗口不存在时才创建。已有窗口直接切换过去，只有 shell 且未进入 copy mode 时才接受命令。正在运行其他程序时保留它并提示，不额外创建窗口或重建窗格。

`tmux_kill_all_nvim` 默认用 `:qa` 请求退出，保留未保存的修改；明确传入 `--force` 时才使用 `:qa!`。
