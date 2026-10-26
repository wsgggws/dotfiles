# 一键切换主题

当前终端首次使用时加载函数，之后直接运行 `switch_all_theme`。四套主题保留安装，切换只调整配色选择：

```zsh
source ~/.zsh/functions/switch_all_theme.zsh
switch_all_theme             # 显示帮助
switch_all_theme qinshan     # 青山入墨：黛青深色
switch_all_theme qingshan    # 青山的同义参数
switch_all_theme huangpao    # 黄袍：古绢暖黄、玄墨文字
switch_all_theme dracula
switch_all_theme catppuccin  # Mocha
```

新开的 zsh 终端会自动加载函数。`switch_all_theme` 函数与补全直接定义在 `~/.zsh/functions/switch_all_theme.zsh`，加载时只读取本机配置。支持 `switch_all_theme <Tab>` 补全，也接受大小写混合的参数。

正常切换不输出内容并返回 `0`；重复选择同一主题也保持静默。出错时向 stderr 输出原因并返回非零状态。查看用法可运行 `switch_all_theme --help`。

仓库目录分别为 `~/github/QingShan.nvim` 与 `~/github/HuangPao.nvim`，保留大小写。仓库只维护主题与同色板原生文件，独立导入方法见各自的 `extras/README.md`。切换脚本、选择器和账户安装工具由下面的本机目录维护。

## 代码归属

| 功能 | 唯一维护位置 | 验证位置 |
| --- | --- | --- |
| `switch_all_theme` 与补全 | `~/.zsh/functions/switch_all_theme.zsh` | `~/.zsh/tests/test_themes.py` |
| 本机青山文件安装与配色块更新 | `~/.zsh/scripts/install_qingshan.py` | `~/.zsh/tests/test_themes.py` |
| Alfred 自动切换 | `~/.config/alfred/themes/switch-theme.sh` | `~/.config/alfred/themes/tests/` |
| tmux 窗口选择器与预览 | `~/.config/tmux/scripts/` | `~/.config/tmux/tests/` |
| Neovim 主题、原生配色导出 | `~/github/QingShan.nvim`、`~/github/HuangPao.nvim` | 各仓库的 `tests/` |

主题仓库不再分发个人配置脚本，运行切换命令不再从仓库加载 shell 代码。Neovim 仍通过插件配置加载主题，安装器更新原生主题时才读取主题仓库。

## 切换范围

| 工具 | 配置文件 | 切换方式 |
| --- | --- | --- |
| Neovim / nvimdiff | `~/.config/nvim/lua/plugins/colorschema.lua` | 只切换 `colorscheme` 名称 |
| WezTerm | `~/.wezterm.lua` | 只切换 `config.color_scheme` 名称 |
| tmux 状态栏、选区和弹窗 | `~/.tmux.conf.local` | 启用目标配色，注释其余三套 |
| fzf 和文件预览 | `~/.config/fzf/theme.sh` | 切换共享配色和 bat 预览主题 |
| bat | `~/.config/bat/config` | 切换 `--theme` |
| Git diff / delta | `~/.gitconfig` | 切换 `[delta]` 中的配色和明暗模式 |
| Alfred | `~/.config/alfred/themes/` | 青山、黄袍选择各自外观，其他主题选择 Alfred Modern Dark Large |
| slides / Markdown PPT | `~/github/slides-md-ppt/*_theme.json` | 文稿指定 JSON，命令保留文稿内容 |

## Neovim

QingShan、HuangPao、Catppuccin 和 Dracula 的插件配置始终保留，四者均可按需加载。
`lazy = true` 表示按需加载，不影响安装，也不会因为切换主题而被列入 clean。
`switch_all_theme` 只切换 `LazyVim/LazyVim` 的 `opts.colorscheme`，不再注释插件块。

| 命令参数 | Neovim | WezTerm | bat / delta | Alfred |
| --- | --- | --- | --- | --- |
| `qinshan` / `qingshan` | `qingshan` | `QingShan` | `QingShan` | `QingShan Dark Large` |
| `huangpao` | `huangpao` | `HuangPao` | `HuangPao` | `HuangPao Light Large` |
| `dracula` | `dracula` | `Dracula (Official)` | `Dracula` | `Alfred Modern Dark Large` |
| `catppuccin` | `catppuccin` | `Catppuccin Mocha` | `Catppuccin Mocha` | `Alfred Modern Dark Large` |

切换后重新打开 Neovim 即可，无需安装、删除或清理主题插件。

## 调用关系

`~/.zshrc` 批量加载 `~/.zsh/functions/*.zsh`，因此新终端会自动定义 `switch_all_theme`。`tmux-commands.zsh` 只保留 tmux 操作函数，两者独立加载。

运行 `switch_all_theme <主题>` 时：

1. macOS 上执行 `~/.config/alfred/themes/switch-theme.sh --check <外观>`，先预检 Alfred 文件。
2. 更新六份终端配置，`source ~/.zsh/functions/fzf.zsh` 刷新当前 shell 的 fzf 配色；tmux 配色变化且服务存在时执行 `tmux source-file ~/.tmux.conf`。
3. macOS 上执行 `~/.config/alfred/themes/switch-theme.sh <外观>`，同步 Alfred 的实际主题。

Alfred 脚本作为独立进程执行。tmux 窗口选择器由 `Prefix + s` 调用 `~/.config/tmux/scripts/window-picker.zsh`，再读取当前 `~/.config/fzf/theme.sh`。主题切换不启动选择器；已开的弹窗关闭重开后使用新配色。

## 生效方式

- 当前终端的 fzf 自动重新加载；其他已打开的 zsh 终端可再运行同一 `switch_all_theme` 命令，或执行 `source ~/.zsh/functions/fzf.zsh`。
- tmux 配色有变化且服务正在运行时，自动重新加载状态栏和 popup。
- WezTerm 自动读取配置变化；青山、黄袍配色独立存放于 `~/.config/wezterm/colors/`。
- bat、delta 下次运行时读取新配置；仅切换主题不需要重建 bat 缓存。
- `Prefix + s` 的窗口选择器读取共享 fzf 主题文件，关闭重开后读取新色板。

首次安装或修改 `~/.config/bat/themes/*.tmTheme` 后才需要执行 `bat cache --build`。

## 终端选区与窗口预览

青山终端拖选为浅玉底、深墨字；黄袍为玄墨底、暖绢字。WezTerm 原生选区与 tmux copy mode 都配置了明显反差。tmux 开启鼠标后，普通拖选由其 copy mode 接管；按住 Shift 可使用 WezTerm 原生选区。

窗口选择器左侧使用各主题的侧栏色，右侧使用正文底色，并保留源窗口 ANSI 前景、背景和文字样式。预览直接显示内容，完整高度用于浏览。

窗口选择器源码与操作说明位于 `~/.config/tmux/README.md`；更新 `~/.config/tmux/scripts/` 后关闭重开弹窗即可。辅助程序使用 Python 3.9+ 标准库，选择器与各主题独立维护。

## 速度与维护

- 六份终端配置由同一个 Perl 进程处理，只写入发生变化的文件；重复切换相同主题不会触发 WezTerm 配置重载或 tmux 重载。Alfred 偏好文件相同时仍通过原生 `set theme` 校准运行中的应用，通常无需重启。
- 每次都刷新当前终端的 fzf，保证其他终端切换过主题后，本终端也能同步。
- 不运行插件安装、清理或 bat 缓存构建。切换速度主要取决于 tmux 主配置重载。
- 修改配色时保留四套主题的标题、空行分隔和注释选项；脚本按标题识别配色块，空行结束该块。
- 如果 tmux 重载失败，可执行 `tmux source-file ~/.tmux.conf` 重试。

## 更新本机配色文件

主题仓库中的导出工具只生成配色。更新青山文件时，从任意目录运行本机安装器（Python 3.10+）：

```sh
python3.14 ~/.zsh/scripts/install_qingshan.py ~/github/QingShan.nvim --integrate --dry-run
python3.14 ~/.zsh/scripts/install_qingshan.py ~/github/QingShan.nvim --integrate
```

`--integrate` 同步本账户已有的六份终端配置中的青山配色块，保留活动主题。该工具只安装配色数据与更新选择项；切换函数、Alfred 自动化和 tmux 选择器在各自目录直接维护。

已有文件备份在 `~/.config/qingshan/backups/<批次>/`，`manifest.json` 记录原路径。失败时回滚已写文件，保留符号链接。恢复时按清单将备份写回原路径，多批次按时间逆序恢复。更新当前主题的 tmux 配色后执行 `tmux source-file ~/.tmux.conf`。

黄袍主题文件由 `HuangPao.nvim/scripts/export.lua` 导出。复制后同步本机配置中的黄袍配色块，导入方法见该仓库 `extras/README.md`。两套主题仓库中的脚本均不管理 shell 切换或窗口选择器。

修改函数后重新加载：

```zsh
source ~/.zsh/functions/switch_all_theme.zsh
```

## 本机验证

以下测试使用临时账户、独立 tmux socket 和替代应用命令，不更新真实 Alfred 或日常配置：

```sh
python3.14 -m unittest discover -s ~/.zsh/tests -p 'test_*.py' -v
python3.14 -m unittest discover -s ~/.config/alfred/themes/tests -p 'test_*.py' -v
python3.14 -m unittest discover -s ~/.config/tmux/tests -p 'test_*.py' -v
zsh -n ~/.zsh/functions/switch_all_theme.zsh ~/.config/alfred/themes/switch-theme.sh
zsh -n ~/.config/tmux/scripts/*.zsh
```

shell 测试使用青山仓库的主题文件构建安装夹具；仓库位于其他路径时设置 `QINGSHAN_SOURCE=/path/to/QingShan.nvim`。Alfred 和 tmux 测试直接验证各自目录的脚本。

## Alfred 与 Markdown PPT

所有 `switch_all_theme` 选择都会调用 Alfred 切换脚本，映射见上表。切换前校验相应外观与 `.plist` 文件，缺失时明确报错并保留终端配置。若只想独立切换 Alfred，可运行：

```sh
~/.config/alfred/themes/switch-theme.sh qingshan
~/.config/alfred/themes/switch-theme.sh huangpao
~/.config/alfred/themes/switch-theme.sh alfred
```

原生外观和选择配置均位于 `~/.config/alfred/themes/`，青山文件名为 `QingShan Dark Large.alfredappearance`，显示名与文件名一致，仍使用黛青深色配色及原有 UUID。脚本只改主题选择；需要更新文件或选择时正常退出并重启 Alfred，并通过原生接口同步应用缓存。外观备份在该目录 `backups/appearance-<时间>-<进程号>.plist`。详细说明见同目录 `README.md`。

Markdown PPT 通过文稿 frontmatter 选择：

```yaml
---
theme: ./qingshan_theme.json  # 黄袍改为 ./huangpao_theme.json
---
```

从 `~/github/slides-md-ppt` 启动 `slides path/to/deck.md`；相对路径以启动目录为准，亦可使用 JSON 绝对路径。`switch_all_theme` 不修改 frontmatter。

## 排错

- 命令不识别青山：重新加载 `~/.zsh/functions/switch_all_theme.zsh`，检查其中的函数定义。
- tmux 配色仍旧：`tmux source-file ~/.tmux.conf`，再重开 `Prefix + s`。
- 预览颜色消失：检查源窗口是否带颜色、是否启用了 `NO_COLOR`，以及共享 fzf 配色块是否正确。
- bat / delta 找不到主题：`bat --list-themes` 检查 `QingShan` / `HuangPao`，必要时重建缓存。
- Alfred 未变化：检查本机切换脚本和命令报错；可运行 `switch-theme.sh --check <主题>` 预检本机文件。磁盘 UID 相同不代表应用缓存相同，脚本会调用原生接口校准。
- PPT 未变化：修改文稿的 `theme:`，再重新启动演示。
