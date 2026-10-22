# App Hotkeys

Alfred Workflow，用全局快捷键激活常用 App。

| 快捷键 | App |
| --- | --- |
| `⌘E` | WezTerm |
| `⌘G` | Google Chrome |
| 双击 `⌥` | ChatGPT |

唯一配置文件是 `hotkeys.json`。新增 App 时，在 `apps` 中增加一项，填写稳定的 `id`、显示名称 `name`、组合键 `hotkey` 和 macOS 的 `bundle_id`，然后运行 `make sync`。支持字母键以及 `cmd`、`shift`、`ctrl`、`alt`/`option` 修饰键。例如：

```json
{
  "id": "notes",
  "name": "Notes",
  "hotkey": "cmd+shift+n",
  "bundle_id": "com.apple.Notes"
}
```

`hotkey` 也支持 `option+option`，表示连续按两次 Option。本机 `/Applications/ChatGPT.app` 的 bundle ID 是 `com.openai.codex`；若迁移到别的 Mac，请核对该 App 的 bundle ID。

`make package` 生成 `dist/App Hotkeys.alfredworkflow`，可导入另一台 Mac 的 Alfred。配置同步会覆盖此 Workflow 中手动修改的快捷键，因此后续请编辑 `hotkeys.json`。`icon.svg` 是图标源文件，打包前用 `magick -background none icon.svg -resize 256x256 -depth 8 PNG32:icon.png` 更新位图。这些是全局快捷键，会占用其他 App 中相同的组合键。
