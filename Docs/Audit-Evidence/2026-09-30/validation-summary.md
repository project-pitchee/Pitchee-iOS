# Pitchee Apple 平台审查验证摘要

交付记录生成于 2026-09-30T20:27:06+08:00。源码固定于 **2026-09-30 20:08:35 Asia/Shanghai**，基础提交 f8ed325507df85335541d53b93eb35fa184062fb，包含当时未提交的修改。

## 构建与测试

| 验证 | 结果 | 证据 |
| --- | --- | --- |
| Debug arm64 iOS Simulator build | BUILD SUCCEEDED | [日志摘要](/Users/dannyfeng/Documents/Pitchee/Docs/Audit-Evidence/2026-09-30/debug-build-analyze-summary.txt) |
| Xcode Analyze | ANALYZE SUCCEEDED | [日志摘要](/Users/dannyfeng/Documents/Pitchee/Docs/Audit-Evidence/2026-09-30/debug-build-analyze-summary.txt) |
| Release arm64 iPhoneOS build | BUILD SUCCEEDED | [日志摘要](/Users/dannyfeng/Documents/Pitchee/Docs/Audit-Evidence/2026-09-30/release-build-summary.txt) |
| 历史与趋势 | 53 检查通过 | [日志](/Users/dannyfeng/Documents/Pitchee/Docs/Audit-Evidence/2026-09-30/test-insights.log) |
| 实时 F0 | 54 检查，0 失败 | [日志](/Users/dannyfeng/Documents/Pitchee/Docs/Audit-Evidence/2026-09-30/test-live-f0.log) |
| 本地诊断与存储 | 45 检查通过 | [日志](/Users/dannyfeng/Documents/Pitchee/Docs/Audit-Evidence/2026-09-30/test-local-diagnostics.log) |
| 本地评分对照 | 59 检查通过 | [日志](/Users/dannyfeng/Documents/Pitchee/Docs/Audit-Evidence/2026-09-30/test-local-score-study.log) |
| 音高图与时间轴 | 22 检查通过 | [日志](/Users/dannyfeng/Documents/Pitchee/Docs/Audit-Evidence/2026-09-30/final-test-pitch-image.log) |
| 评分一致性 | 10,742 检查、1,530 Core 参考案例 | [日志](/Users/dannyfeng/Documents/Pitchee/Docs/Audit-Evidence/2026-09-30/test-voice-scoring.log) |
| Native CTest | 6/6 测试通过 | [日志](/Users/dannyfeng/Documents/Pitchee/Docs/Audit-Evidence/2026-09-30/native-tests.log) |

六组脚本合计 **11,075 项检查通过**；检查条数包含参数化断言，不等于 11,075 个独立用户流程。除重新执行的音高图测试外，其余脚本和相关实现与先前测试副本一致。早期构建错误与时间轴测试失败已在最终副本重验通过，不列为最终未修复问题。

工具链 Xcode 27.1 / Swift 6.4；项目为 Swift 5 语言模式、iOS 17 部署目标。构建参数为 ARCHS=arm64、ONLY_ACTIVE_ARCH=YES、CODE_SIGNING_ALLOWED=NO、SWIFT_EMIT_LOC_STRINGS=NO，未修改部署目标。构建内浅层 bundle validation 不等同于签名归档验证或 App Store Connect 提交验证。

## 其他证据

- [固定应用源码 SHA-256](/Users/dannyfeng/Documents/Pitchee/Docs/Audit-Evidence/2026-09-30/final-snapshot-manifest.json)、[原生源码 SHA-256](/Users/dannyfeng/Documents/Pitchee/Docs/Audit-Evidence/2026-09-30/native-source-hashes.json)、[带原始行号的源码摘录](/Users/dannyfeng/Documents/Pitchee/Docs/Audit-Evidence/2026-09-30/snapshot-code-excerpts.md)。
- [Debug/Release 包内隐私清单](/Users/dannyfeng/Documents/Pitchee/Docs/Audit-Evidence/2026-09-30/built-privacy-manifests.json)：应用根目录均缺少清单，只有 MathJaxSwift bundle 自带的清单。
- [LocalizedStringKey 探针](/Users/dannyfeng/Documents/Pitchee/Docs/Audit-Evidence/2026-09-30/key-probe.swift)与[输出](/Users/dannyfeng/Documents/Pitchee/Docs/Audit-Evidence/2026-09-30/key-probe.txt)：固定副本中两处错误已复现，工作区后续源码已改正。
- [快照本地化缺项](/Users/dannyfeng/Documents/Pitchee/Docs/Audit-Evidence/2026-09-30/missing-localizations.json)：476 个应用键、29 个语言。繁中缺 104 项，另 26 个语言各缺 175 项；英文 1 个缺项是错误模板键。
- [swift-format 配置](/Users/dannyfeng/Documents/Pitchee/Docs/Audit-Evidence/2026-09-30/swift-format-audit.json)和[结果](/Users/dannyfeng/Documents/Pitchee/Docs/Audit-Evidence/2026-09-30/final-swift-format.log)：按现有 4 空格缩进检查，共 1,273 条格式提示；不作为功能缺陷或拒审条件计数。
- [英文引导页](/Users/dannyfeng/Documents/Pitchee/Docs/Audit-Evidence/2026-09-30/onboarding-standard.png)；[日语最大辅助字号趋势首页](/Users/dannyfeng/Documents/Pitchee/Docs/Audit-Evidence/2026-09-30/trends-japanese-largest.png)。截图不能证明所有内容可滚动、控件可操作或 VoiceOver 顺序正确。onboarding-largest-text.png 是调整字号后重启前的补充截图，不单独用它证明字号已生效。
- [交付前有限复核](/Users/dannyfeng/Documents/Pitchee/Docs/Audit-Evidence/2026-09-30/post-snapshot-review.json)记录 A05 源码修正、当前资源缺翻译及文件哈希；[变动文件清单](/Users/dannyfeng/Documents/Pitchee/Docs/Audit-Evidence/2026-09-30/post-snapshot-changes.json)不包含快照之后首次新增的文件。

## 范围限制

主报告记录固定副本的 13 项发现（4 P1、9 P2），其中 A05 已观察到后续源码修正。新练习功能等持续修改未完整重建或重新审查。完整原始日志与源码副本暂存在 /tmp/pitchee-apple-audit-20260930。

没有执行 App Store Connect 提交、签名归档、真机麦克风/来电/蓝牙路径、长期内存和能耗压力测试、完整 VoiceOver/Switch Control/键盘检查或 iOS 17/18 与 iPad 设备矩阵测试。静态检查和通过的测试只覆盖已列范围，不能作为 Apple 审核通过保证。
