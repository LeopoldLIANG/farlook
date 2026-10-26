# 参与改进 / Contributing

欢迎中文或英文反馈。请先搜索已有 Issues，避免重复。

## 问题反馈

提供 macOS 版本、芯片类型、应用版本、所选无操作规则、复现步骤、预期行为和实际行为。涉及睡眠、锁屏、全屏或多显示器时，请说明相关状态。截图只截取应用窗口，并先去除个人信息。

## 功能建议

描述你遇到的具体使用场景、当前行为为何不适合、希望改成什么，以及是否会影响其他用户。计时定义本身也欢迎讨论。

## Pull Request

1. Fork 仓库，创建一个范围明确的分支。
2. 保持计时规则的变化显式、可说明；不要默默改变默认时长。
3. 修改计时逻辑时，补充能区分正确和错误行为的边界检查。
4. 运行 `zsh scripts/test.sh` 和 `zsh build.sh`。
5. 说明改动目的、可见行为及验证方式。影响界面时附应用窗口截图。

源码、讨论和反馈均应尊重他人。不要提交凭据、私人使用记录或未经授权的内容。提交贡献即表示你同意贡献按本项目 MIT 许可证分发。

## English

Search existing issues before opening one. For bugs, include macOS/app versions, chip, selected idle rule, reproduction steps, expected behavior, and actual behavior. For suggestions, describe the concrete use case and tradeoffs. Keep PRs focused, explain visible changes, and run the build and timing checks. Do not include secrets or personal data. Contributions are accepted under the project's MIT license.
