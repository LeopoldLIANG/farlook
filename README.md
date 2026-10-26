<p align="center"><img src="assets/AppIcon.png" width="128" alt="FarLook · 远眺一下"></p>

# FarLook · 远眺一下

一个免费、开源的 macOS 菜单栏休息提醒工具：连续使用电脑 **30 分钟**后，提醒你远眺 **30 秒**。完全本地运行，无需注册。

A free, open-source macOS menu bar app that reminds you to look into the distance for **30 seconds** after **30 minutes** of continuous computer use. Runs locally, with no account required.

**[下载 / Download](https://github.com/LeopoldLIANG/farlook/releases/latest)** · **[问题与建议 / Issues](https://github.com/LeopoldLIANG/farlook/issues/new/choose)** · **[讨论 / Discussions](https://github.com/LeopoldLIANG/farlook/discussions)** · [English only](README.en.md)

## 快速开始 / Quick start

1. 从 [Releases](https://github.com/LeopoldLIANG/farlook/releases/latest) 下载 `FarLook-v0.2.0-macOS-arm64.zip`。  
   Download `FarLook-v0.2.0-macOS-arm64.zip` from [Releases](https://github.com/LeopoldLIANG/farlook/releases/latest).
2. 解压，将“远眺一下.app”拖到“应用程序”文件夹，双击打开。  
   Unzip it, move “远眺一下.app” into Applications, and open it.
3. 点击菜单栏的眼睛图标，查看剩余时间、预览提醒或调整计时规则。  
   Click the eye icon in the menu bar to see the remaining time, preview a reminder, or adjust the timing rule.

**运行要求：** Apple Silicon（M 系列芯片），macOS 13 或更新版本。应用界面目前为简体中文，本文档提供中英对照。当前需手动启动，未设置开机自启；运行时没有常驻 Dock 图标。

**Requirements:** Apple Silicon and macOS 13 or later. The app interface is currently in Simplified Chinese; this README is bilingual. Launch the app manually after login. It runs in the menu bar without a persistent Dock icon.

**签名与安装：** 当前版本采用本地临时签名，尚未获 Apple 公证。如果系统阻止打开，可以查看源码并自行构建，或按 macOS“隐私与安全性”中的提示操作。

**Signing and installation:** The current build is ad-hoc signed and has not been notarized by Apple. If macOS blocks it, you can review and build the source or follow the system's Privacy & Security prompts.

## 怎样提醒 / How reminders work

达到 30 分钟时，应用显示一个可推迟的提醒窗口。点击“开始 30 秒休息”后启动倒计时，结束时播放可关闭的提示音；也可以选择“5 分钟后提醒”。休息结束后，下一次操作开始新一轮计时。

At 30 minutes, a reminder window appears. Start a 30-second break with an optional sound at the end, or postpone the reminder for 5 minutes. After a completed break, the next input starts a new session.

菜单还提供立即休息、重新计时和暂停提醒。倒计时表示时间经过，实际是否远眺由你决定。

The menu also lets you take a break immediately, reset the timer, or pause reminders. The countdown measures elapsed time; you decide when to look away.

## “连续使用”怎样定义？ / What counts as continuous use?

默认规则：**无键鼠操作达到 2 分钟，本轮计时清零；恢复操作后重新开始。** 不足 2 分钟的短暂停顿仍计入本轮 30 分钟。

Default rule: **2 minutes without keyboard or mouse input resets the session. Timing resumes with the next input.** Shorter input-free pauses count toward the current 30-minute session.

| 情况 / Scenario | 计时行为 / Timer behavior |
| --- | --- |
| 持续操作或静止不足 2 分钟<br>Active input or a pause shorter than 2 minutes | 继续累计<br>Keep counting |
| 无操作达到 2 分钟<br>No input for 2 minutes | 清零，等待下一次操作<br>Reset and wait for input |
| 锁屏、系统／屏幕休眠或切换用户<br>Screen lock, system/display sleep, or user switch | 清零<br>Reset |
| 休息结束<br>Break completed | 下一次操作开始新一轮<br>Start a new session with the next input |
| 推迟提醒<br>Reminder postponed | 5 分钟后再提醒；无操作重置规则仍生效<br>Remind again in 5 minutes; the idle-reset rule still applies |

可选择 **2、5、10 分钟无操作重置**，或选择**仅锁屏／睡眠及休息后重置**。改变规则、恢复提醒或重新打开应用会开始新一轮计时。

Choose an idle threshold of **2, 5, or 10 minutes**, or **reset only on lock/sleep and breaks**. Changing the rule, resuming reminders, or reopening the app starts a new session.

**阅读与视频：** 静止看屏幕也可能没有键鼠输入。按默认规则，读长文或看视频超过 2 分钟没有操作，同样会清零。经常遇到这种情况，可以调长阈值或使用仅锁屏／睡眠重置模式。

**Reading and video:** Watching the screen can involve no input. Under the default rule, reading or watching a video without input for 2 minutes also resets the timer. Choose a longer threshold or the lock/sleep-only mode if this better fits your workflow.

## 隐私 / Privacy

应用只读取系统输入空闲时长与会话／睡眠状态，将计时规则和提示音偏好保存在本机。不联网、不使用摄像头、不读取键盘输入内容、不记录应用使用情况或使用历史。无需辅助功能、屏幕录制或摄像头权限。

The app reads input idle duration and session/sleep status, and stores timing and sound preferences locally. It makes no network requests, uses no camera, captures no typed content, and keeps no app-usage log or activity history. No Accessibility, Screen Recording, or Camera permission is required.

## 反馈与参与 / Feedback and contributions

欢迎使用中文或英文交流。反馈时，最有帮助的信息是：你的使用场景、当前行为，以及你希望怎样调整。

Feedback in Chinese or English is welcome. The most useful details are your use case, what happens now, and what you would like to change.

- **[问题反馈 / Bug reports](https://github.com/LeopoldLIANG/farlook/issues/new?template=bug_report.yml)**：说明系统版本、芯片、计时规则和复现步骤。  
  Include your macOS version, chip, timing rule, and steps to reproduce.
- **[功能建议 / Feature requests](https://github.com/LeopoldLIANG/farlook/issues/new?template=feature_request.yml)**：描述具体场景与期望行为。  
  Describe the use case and the behavior you would prefer.
- **[开放讨论 / Discussions](https://github.com/LeopoldLIANG/farlook/discussions)**：交流提醒频率、阅读模式和日常使用体验。  
  Discuss reminder frequency, reading workflows, and everyday use.
- **[贡献指南 / Contributing](CONTRIBUTING.md)**：欢迎通过 Pull Request 改进代码与文档。  
  Code and documentation contributions are welcome through pull requests.

上传截图时，请只保留相关应用窗口，并去除个人信息。

When sharing screenshots, include only the relevant app window and remove personal information.

## 从源码构建 / Build from source

安装 Xcode 或 Xcode Command Line Tools 后，在项目目录执行：

With Xcode or Xcode Command Line Tools installed, run these commands in the project directory:

```sh
zsh scripts/test.sh
zsh build.sh
open build/远眺一下.app
```

无第三方运行依赖，默认生成 arm64 应用。图标 PNG、ICNS 和生成记录位于 `assets/`；构建脚本使用 macOS 自带的 `sips` 和 `iconutil` 生成图标。

There are no third-party runtime dependencies. The default build targets arm64. Icon artwork and its generation record are in `assets/`; the build uses macOS `sips` and `iconutil` to create the ICNS.

## 验证与已知范围 / Verification and current scope

已在 macOS 26.3.1 上构建并完成基本界面检查；计时状态机的 24 项检查通过。GitHub Actions 会检查计时逻辑、构建应用并验证签名。实际锁屏、全屏、多显示器及其他系统版本仍需要更多使用反馈，详见[验证记录](VERIFICATION.md)。

Built and checked on macOS 26.3.1, with 24 passing timer-state checks. GitHub Actions runs timing checks, builds the app, and verifies its signature. Real screen-lock behavior, fullscreen apps, multiple displays, and other macOS versions need further field testing; see the [verification record](VERIFICATION.md).

计时每秒采样一次，显示或触发可能有约 1 秒误差；应用退出或未运行时无法提醒。锁屏检测使用系统通知约定，并辅以公开的睡眠和会话通知。

Timing is sampled once per second, with approximately 1 second of display or trigger tolerance. The app must be running to remind you. Lock detection uses system notification conventions alongside documented sleep and session notifications.

## 许可证 / License

本项目采用 [MIT 许可证](LICENSE)，允许使用、修改和再分发，保留版权与许可声明。

Released under the [MIT License](LICENSE). You may use, modify, and redistribute it while retaining the copyright and license notice.

[更新记录 / Changelog](CHANGELOG.md) · [图标制作记录 / Icon generation record](assets/ICON-PROMPT.md)
