# Alfred themes

固定主题目录：

```text
~/.config/alfred/themes/
```

包含：

- `Alfred Modern Dark Large.alfredappearance`：原始主题导出。
- `SheepSkin Light Large.alfredappearance`：当前 SheepSkin 主题导出。
- `alfred-modern-dark-large.plist`：原主题的选择配置。
- `sheepskin-light-large.plist`：SheepSkin Light Large 的选择配置。

在 Alfred 中手动导入 `.alfredappearance` 即可使用主题。

切换主题：

```sh
~/.config/alfred/themes/switch-theme.sh sheepskin
~/.config/alfred/themes/switch-theme.sh alfred
```

脚本会自动查找默认或同步的偏好设置目录，先退出 Alfred，再安装主题、
仅更新浅色/深色主题选择，最后重启 Alfred。其它外观设置保持原值。
每次切换前的外观配置保存在 `backups/appearance-before-switch.plist`。

SheepSkin 使用不透明的暖黄色背景，避免壁纸改变显示颜色；尺寸沿用原主题。

迁移机器或存在多台设备配置时，可用 `ALFRED_PREFERENCES` 指定
`Alfred.alfredpreferences` 目录，用 `ALFRED_APPEARANCE_PREFS` 指定本机的
`appearance/prefs.plist`。两份 `.alfredappearance` 和 `.plist` 可直接提交 Git。
`backups/` 是切换时生成的本机备份，无需提交。

