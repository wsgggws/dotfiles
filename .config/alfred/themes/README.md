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

在当前机器上切换主题：

```sh
~/.config/alfred/themes/switch-theme.sh sheepskin
~/.config/alfred/themes/switch-theme.sh alfred
```

脚本会安装对应主题、更新浅色/深色外观选择，并重启 Alfred。

