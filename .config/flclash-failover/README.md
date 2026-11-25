# FlClash 节点故障切换

适用于 macOS 上的 FlClash。监控 FlClash「节点选择」组里的当前节点。当前节点可用时继续使用。连续两次检测失败后，按香港、日本、其他地区的顺序选择第一个可用节点。脚本从本机配置读取控制器地址和密钥，通过 `127.0.0.1` 调用 FlClash。订阅更新仍使用 FlClash 的设置。

## 安装

1. 在已配置 yadm 的 Mac 上，等包含本目录的提交同步到远端后，运行 `yadm pull --ff-only`，脚本会出现在 `~/.config/flclash-failover/`。当前电脑已有这两个文件时，直接执行下一步。
2. 启动 FlClash。在「代理 → 节点选择」里选择一个具体节点作为起点。脚本适用于配置中直接列出节点的 `select` 策略组。
3. 用 macOS 自带的 Ruby 预览一次。预览只检测并打印结果。

```sh
/usr/bin/ruby "$HOME/.config/flclash-failover/flclash-failover.rb"
```

## 使用

在终端启动监控。每轮检测完成后等待 120 秒再检查。按 `Ctrl+C` 停止监控。运行期间保持 FlClash 和终端开启。

```sh
/usr/bin/ruby "$HOME/.config/flclash-failover/flclash-failover.rb" --watch
```

地区按节点名称识别。检测地址为 `https://www.gstatic.com/generate_204`。如需调整组名、间隔、检测地址或地区匹配规则，可以修改脚本顶部的常量，然后重新启动监控。

如果脚本提示选择具体节点，请在 FlClash 中确认「节点选择」当前指向一个节点。FlClash 重载配置时可能恢复应用保存的选择，脚本在下一轮读取实际生效的节点。

## 卸载

先按 `Ctrl+C` 停止正在运行的脚本。若要从 yadm 仓库和本机同时移除，执行以下命令。

```sh
cd "$HOME"
yadm rm -- .config/flclash-failover/README.md .config/flclash-failover/flclash-failover.rb
yadm commit --only -m "Remove FlClash failover" -- .config/flclash-failover/README.md .config/flclash-failover/flclash-failover.rb
```

停止监控后，可以在 FlClash 的「代理 → 节点选择」里恢复自己的选择。
