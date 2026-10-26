# 一键切换主题

当前终端首次使用时加载函数，之后直接运行 `alltheme`：

```zsh
source ~/.zsh/functions/tmux-commands.zsh
alltheme             # 显示帮助
alltheme sheepskin   # 暗黄色浅色主题
alltheme dracula
alltheme catppuccin  # Mocha
```

新开的 zsh 终端会自动加载函数。命令保存在 `~/.zsh/functions/tmux-commands.zsh`。
支持 `alltheme <Tab>` 补全主题名，也接受大小写混合的参数。

## 切换范围

| 工具 | 配置文件 | 切换方式 |
| --- | --- | --- |
| Neovim / nvimdiff | `~/.config/nvim/lua/plugins/colorschema.lua` | 只切换 `colorscheme` 名称 |
| WezTerm | `~/.wezterm.lua` | 只切换 `config.color_scheme` 名称 |
| tmux 状态栏和弹窗 | `~/.tmux.conf.local` | 启用目标配色，注释其余两套 |
| fzf 和文件预览 | `~/.config/fzf/theme.sh` | 切换共享配色和 bat 预览主题 |
| bat | `~/.config/bat/config` | 切换 `--theme` |
| Git diff / delta | `~/.gitconfig` | 切换 `[delta]` 中的配色和明暗模式 |

## Neovim

Sheepskin、Catppuccin 和 Dracula 的插件配置始终启用，三者都保留安装。
`lazy = true` 表示按需加载，不影响安装，也不会因为切换主题而被列入 clean。
`alltheme` 只切换 `LazyVim/LazyVim` 的 `opts.colorscheme`，不再注释插件块。

| 命令参数 | Neovim | WezTerm | bat / delta |
| --- | --- | --- | --- |
| `sheepskin` | `sheepskin` | `Sheepskin` | `SheepskinLight` |
| `dracula` | `dracula` | `Dracula (Official)` | `Dracula` |
| `catppuccin` | `catppuccin` | `Catppuccin Mocha` | `Catppuccin Mocha` |

切换后重新打开 Neovim 即可，无需安装、删除或清理主题插件。

## 生效方式

- 当前终端的 fzf 自动重新加载；其他已打开的 zsh 终端需执行 `source ~/.zsh/functions/fzf.zsh`。
- tmux 配色有变化且服务正在运行时，自动重新加载状态栏和 popup。
- WezTerm 自动读取配置变化；Sheepskin 配色独立存放于 `~/.config/wezterm/colors/Sheepskin.toml`。
- bat、delta 下次运行时读取新配置；仅切换主题不需要重建 bat 缓存。
- fzf 的 tmux 窗口选择器也读取共享主题文件，无需单独设置。

修改 `~/.config/bat/themes/SheepskinLight.tmTheme` 后才需要执行 `bat cache --build`。

## 速度与维护

- 六份配置由同一个 Perl 进程处理，只写入发生变化的文件；重复切换相同主题不会触发 WezTerm 配置重载或 tmux 重载。
- 每次都刷新当前终端的 fzf，保证其他终端切换过主题后，本终端也能同步。
- 不运行插件安装、清理或 bat 缓存构建。切换速度主要取决于 tmux 主配置重载。
- 修改配色时保留三套主题的标题、空行分隔和注释选项；脚本按标题识别配色块，空行结束该块。
- 如果 tmux 重载失败，可执行 `tmux source-file ~/.tmux.conf` 重试。

## Alfred

Alfred 单独切换，不属于 `alltheme` 的切换范围：

```sh
~/.config/alfred/themes/switch-theme.sh sheepskin
~/.config/alfred/themes/switch-theme.sh alfred
```

导出的外观文件也位于 `~/.config/alfred/themes/`，可用 Git 跟踪。
