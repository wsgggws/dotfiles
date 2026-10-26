# tmux 本机配置

`~/.config/tmux/scripts/` 是窗口选择器和预览程序的维护位置。配色数据位于 `themes/`，当前选择由 `~/.config/fzf/theme.sh` 提供。

## 窗口选择器

`Prefix + s` 通过 `~/.tmux.conf.local` 启动 `scripts/window-picker.zsh`，该脚本调用同目录的 `pane-preview.zsh` 与 `pane-preview.py`。Python 辅助程序使用 3.9+ 标准库。

列表使用各主题的侧栏色，右侧使用正文背景；源窗口的 ANSI 前景、背景和文字样式继续保留。界面省去快捷键帮助与屏幕行列标题，完整高度用于内容。

| 操作 | 功能 |
| --- | --- |
| `↑↓` / `Enter` | 选择 / 打开窗口 |
| `Shift+↑↓` 或右侧滚轮 | 上下滚动预览；左侧滚轮选择窗口 |
| `←→` 或 `Shift+←→` | 左右平移，每次 8 列 |
| `PgUp/PgDn` | 翻页 |
| `Ctrl+Home/End` | 顶部 / 底部 |
| `Alt+B` | 当前屏幕 / 最近 2000 行终端历史 |
| `Ctrl+/` | 显隐预览 |

横向平移保留纵向位置，各弹窗与窗口状态独立。预览来自 tmux 已显示的屏幕及历史；编辑器尚未显示的内容需先在编辑器中滚动。

修改脚本或配色后重新打开弹窗。若主题背景未更新，检查活动的 fzf 颜色变量；源颜色消失时检查源窗口与 `NO_COLOR`。需要更新 tmux 配色时运行 `tmux source-file ~/.tmux.conf`。

## 验证

```sh
python3.14 -m unittest discover -s ~/.config/tmux/tests -p 'test_*.py' -v
zsh -n ~/.config/tmux/scripts/*.zsh
```

测试在独立 socket 内启动真实 tmux 和 fzf，检查 ANSI 颜色、双向滚动、滚轮、历史与中文裁剪。测试不依赖主题仓库中的交互代码。

`switch_all_theme` 更新配色与重载 tmux；选择器只在按下 `Prefix + s` 时启动，并读取当前 fzf 配色。统一切换和配色文件更新说明见 `~/.zsh/functions/THEME_SWITCHING.md`。
