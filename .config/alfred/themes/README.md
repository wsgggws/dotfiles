# Alfred themes

固定主题目录：

```text
~/.config/alfred/themes/
```

包含：

- `Alfred Modern Dark Large.alfredappearance`：原始主题导出。
- `HuangPao Light Large.alfredappearance`：当前 HuangPao 主题导出。
- `LuZhu Dark Large.alfredappearance`：绿珠，古代美人之名与珍宝之意，松绿深色外观。
- `luzhu.plist`：绿珠的选择配置，使用独有 UUID，与青山分别注册。
- `QingShan Dark Large.alfredappearance`：青山入墨，黛青深色外观。
- `alfred-modern-dark-large.plist`：原主题的选择配置。
- `huangpao-light-large.plist`：HuangPao Light Large 的选择配置。
- `qingshan.plist`：QingShan Dark Large 的选择配置，沿用原有 UID。

在 Alfred 中手动导入 `.alfredappearance` 即可使用主题。

切换主题：

```sh
~/.config/alfred/themes/switch-theme.sh luzhu
~/.config/alfred/themes/switch-theme.sh qinshan  # 也接受 qingshan
~/.config/alfred/themes/switch-theme.sh huangpao
~/.config/alfred/themes/switch-theme.sh alfred
```

`switch_all_theme` 会自动调用切换脚本：

| 命令 | Alfred 外观 |
| --- | --- |
| `switch_all_theme luzhu` | `LuZhu Dark Large` |
| `switch_all_theme qinshan` / `switch_all_theme qingshan` | `QingShan Dark Large` |
| `switch_all_theme huangpao` | `HuangPao Light Large` |
| `switch_all_theme dracula` / `switch_all_theme catppuccin` | `Alfred Modern Dark Large` |

独立脚本也接受 `dracula`、`catppuccin`，均使用原外观；`--check <主题>` 只预检文件，不更新应用。

切换和预检成功时均无输出，返回 `0`；出错时保留错误信息并返回非零状态。

脚本自动查找默认或同步的偏好设置目录，校验主题及 plist，然后安装主题，
仅更新浅色/深色主题 UID。运行中的 Alfred 会先正常退出，更新后重新启动；
原先未运行时保持关闭。即使偏好文件与主题文件一致，也通过原生 `set theme` 同步运行中的 Alfred，避免磁盘记录与实际外观不一致；此时无需重启。其他外观设置保持原值。
每次实际切换前的外观配置保存在 `backups/appearance-<时间>-<进程号>.plist`。
旧的 `appearance-before-switch.plist` 是历史备份，不会覆盖。

HuangPao 使用不透明的暖黄色背景，避免壁纸改变显示颜色；尺寸沿用原主题。
QingShan Dark Large 使用不透明黛青背景，搜索区域为浮层黛青，选中项为较亮的深青。

迁移机器或存在多台设备配置时，可用 `ALFRED_PREFERENCES` 指定
`Alfred.alfredpreferences` 目录，用 `ALFRED_APPEARANCE_PREFS` 指定本机的
`appearance/prefs.plist`。原生 `.alfredappearance` 和 `.plist` 可直接提交 Git。
`backups/` 是切换时生成的本机备份，无需提交。

恢复外观选择时，先正常退出 Alfred，将所需备份恢复到本机的
`appearance/prefs.plist`，再启动 Alfred。若只想换回原主题，运行 `switch-theme.sh alfred`。

本目录的 `switch-theme.sh` 是自动切换的唯一源码，与外观文件就近维护。绿珠配色源文件位于 `~/github/LuZhu.nvim/extras/alfred/`，青山的配色源文件位于 `~/github/QingShan.nvim/extras/alfred/`；该仓库只维护外观及 UID 数据，不分发切换脚本。黄袍与原主题外观保留本目录已有文件。

使用隔离偏好与替代应用命令验证，不操作实际 Alfred：

```sh
python3.14 -m unittest discover -s ~/.config/alfred/themes/tests -p 'test_*.py' -v
zsh -n ~/.config/alfred/themes/switch-theme.sh
```

测试覆盖青山与绿珠的静默成功、预检失败、原生同步错误、往返切换后两套外观并存及重复 UUID 拒绝。完整统一切换与本机配色安装说明见 `~/.zsh/functions/THEME_SWITCHING.md`。
