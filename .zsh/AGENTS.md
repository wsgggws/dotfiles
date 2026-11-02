# 本机 shell 维护

修改统一主题切换、主题安装或跨工具配色时，先阅读 [切换说明](functions/THEME_SWITCHING.md)。

- `switch_all_theme` 与补全维护在 `functions/switch_all_theme.zsh`，由 `.zshrc` 自动加载；`functions/tmux-commands.zsh` 只维护 tmux 操作函数。
- 本机青山、绿珠配色安装器分别为 `scripts/install_qingshan.py`、`scripts/install_luzhu.py`，它只安装主题数据及更新现有配置选择项。
- Alfred 自动化在 `~/.config/alfred/themes/switch-theme.sh`，tmux 选择器在 `~/.config/tmux/scripts/`；修改时阅读各目录 README，在原位置维护唯一源码。
- LuZhu.nvim、QingShan.nvim、HuangPao.nvim 只维护主题和配色导出，shell 函数与交互程序不回迁主题仓库。
- 同名主题更新后使用 `switch_all_theme <主题> --refresh` 刷新缓存与应用；普通重复切换保持轻量。
- 切换正常完成与重复执行均保持静默；错误写入 stderr 并返回非零状态。保留显式帮助、别名、补全和 Alfred 映射。
- shell/安装检查位于 `tests/`，Alfred、tmux 检查分别位于对应配置目录。验证使用临时 home、独立 tmux socket 和替代应用命令，按切换说明运行相关测试。

完成修改时核对所有相关路径与文档引用，确认运行时没有对主题仓库 shell 脚本的依赖。报告执行的检查；实际工具验证保持用户当前主题。
