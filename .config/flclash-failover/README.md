# FlClash 节点故障切换

适用于 macOS 上的 FlClash。监控「节点选择」组里的当前节点。延迟在 600 ms 以内时继续使用。连续两次延迟超过 600 ms 或超时后，脚本最多并行检测 6 个候选，并在有更快的候选时切换。与最快节点相差 50 ms 以内时，按香港、日本、其他地区排序。若最快候选在 600 ms 以内，也只在该延迟范围内应用地区优先。脚本从本机配置读取控制器地址和密钥，通过 `127.0.0.1` 调用 FlClash。订阅更新仍使用 FlClash 的设置。

## 安装

1. 在已配置 yadm 的 Mac 上，等包含本目录的提交同步到远端后，运行 `yadm pull --ff-only`，文件会出现在 `~/.config/flclash-failover/`。当前电脑已有本目录时，直接执行下一步。
2. 启动 FlClash。在「代理 → 节点选择」里选择一个具体节点作为起点。脚本适用于配置中直接列出节点的 `select` 策略组。
3. 用 macOS 自带的 Ruby 预览一次。预览只检测并打印结果。

```sh
/usr/bin/ruby "$HOME/.config/flclash-failover/flclash-failover.rb"
```

## 后台启动

已安装的 LaunchAgent 在登录 macOS 后自动运行。控制器离线时每 5 秒重试连接，日志在进入等待时记录一次。FlClash 上线后每 120 秒开始一轮检测，每轮结果都会写入日志。检测超过 120 秒时，下一轮等当前轮完成。终端可以关闭。

首次安装时，在终端运行以下命令。已安装的电脑可跳过。

```sh
mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
install -m 644 "$HOME/.config/flclash-failover/local.flclash-failover.plist" \
  "$HOME/Library/LaunchAgents/local.flclash-failover.plist"
launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/local.flclash-failover.plist"
```

查看运行状态和日志。

```sh
launchctl print "gui/$(id -u)/local.flclash-failover"
tail -n 20 "$HOME/Library/Logs/flclash-failover.log"
```

临时暂停后台监控。当前登录会话内可用上面的 `launchctl bootstrap` 命令恢复，重新登录也会恢复。

```sh
launchctl bootout "gui/$(id -u)/local.flclash-failover"
```

通过 yadm 更新脚本后，可用以下命令立即重新载入。如果更新的是 plist，请先暂停，覆盖 `~/Library/LaunchAgents/` 里的副本，然后重新加载。

```sh
launchctl kickstart -k "gui/$(id -u)/local.flclash-failover"
```

## 前台使用

在终端启动监控。每隔约 120 秒开始一轮检测。按 `Ctrl+C` 停止监控。运行期间保持 FlClash 和终端开启。

```sh
/usr/bin/ruby "$HOME/.config/flclash-failover/flclash-failover.rb" --watch
```

地区按节点名称识别。检测地址为 `https://www.gstatic.com/generate_204`。如需调整组名、间隔、延迟阈值、地区优先范围或检测地址，可以修改脚本顶部的常量，然后重新启动监控。

如果脚本提示选择具体节点，请在 FlClash 中确认「节点选择」当前指向一个节点。FlClash 重载配置时可能恢复应用保存的选择，脚本在下一轮读取实际生效的节点。

## 卸载

前台运行时按 `Ctrl+C`。后台运行时先执行上面的 `launchctl bootout`，然后移除 LaunchAgent 的安装副本。

```sh
rm -f "$HOME/Library/LaunchAgents/local.flclash-failover.plist"
```

若还要从本机和 yadm 仓库移除脚本、说明和 LaunchAgent 配置，执行以下命令。

```sh
cd "$HOME"
yadm rm -r -- .config/flclash-failover/
yadm commit --only -m "Remove FlClash failover" -- .config/flclash-failover/
```

停止监控后，可以在 FlClash 的「代理 → 节点选择」里恢复自己的选择。
