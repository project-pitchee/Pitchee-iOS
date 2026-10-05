# 嗓音训练知识库：内容集成与阅读器检查

日期：2026-10-05。本文记录本次文章修订的集成验证及实际可视检查范围，不代表 VFP、自然分或新共鸣评分模型的有效性研究。

## 内容与资源

- 全部 49 篇文章完成第二轮复核，45 篇进一步修改；文章 ID 与子仓库原有集合一致，文件名保留。
- 每篇四项元信息、四个正文分节、标题与正文资源一致；Markdown 与 JSON 的 rawContent 一致。
- App 内置 JSON 与文章仓库镜像一致，两个构建脚本副本一致。
- 136 处引用使用 34 个不同的 HTTPS 地址。链接格式检查与文献内容复核分别进行；链接为 HTTPS 本身不代表科学有效。
- 25 个本地化键、75 个中英译文值已核对。范围为简体中文、繁体中文和英文；最终集成时保留了并行编辑中的 8 处繁体措辞优化（如“跳過”改“略過”），含义不变，修订清单同步记录实际值。
- Core 评分未修改。高基频低自然分保留 30 分上限，音色不足分支保留自然分 ≥50；新增三组计算例子与现有公式相符。

可复查材料：[内容检查](Research-Evidence/voice-training-reader-2026-10-05/content-validation.json)、[逐篇第二轮差异](Research-Evidence/voice-training-reader-2026-10-05/content-second-pass-changes.json)、[本地化清单](Research-Evidence/voice-training-reader-2026-10-05/localization-changes.json)。

## 自动检查

`python3 Scripts/build-voice-training-library.py` 已生成 49 篇文章资源。

`bash Scripts/test-voice-training-library.sh` 通过文章结构、资源、17 个匹配分类及 Swift 推荐匹配检查。测试覆盖采集质量、缺失值、目标方向、边界和 A/B 反馈等现有行为；[日志](Research-Evidence/voice-training-reader-2026-10-05/library-tests.log)保留实际输出。

行内公式分隔符标准化检查与独立块公式分类检查通过；后者覆盖 24 个有效块、行内公式、混合文本、多块及不完整分隔符样例。

第一轮及第二轮最终 iOS Simulator 构建均通过。第二轮构建包含新版 49 篇资源与独立长公式滚动修订，命令如下：

```sh
xcodebuild -project Pitchee.xcodeproj -scheme Pitchee -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/pitchee-library-qa.XITkRb/DerivedData \
  CODE_SIGNING_ALLOWED=NO -quiet
```

最终构建退出码为 0，安静模式日志为空；[构建记录](Research-Evidence/voice-training-reader-2026-10-05/build-validation.json)记录了对应产物和资源核对结果。主仓库及文章子仓库的 `git diff --check` 通过。

## 阅读器观察与限制

使用本次专用的 iPhone 17 / iOS 27.0 模拟器，UDID 为 `0EE9E806-76FA-4517-8D67-C28EC5BB54D4`。普通字号下曾看到新版正文、行内公式与按列对齐的表格。

[长公式修复前原生截图](Research-Evidence/voice-training-reader-2026-10-05/reader-formulas-before.png)显示公式超出可视宽度，不能作为完整显示的通过证据。后续修订将部分连续公式拆成独立段落，并为完整单个显示公式提供显式横向滚动容器；行内公式和普通文字保持原来的换行路径。

最初的浏览器镜像曾与指定模拟器原生截图不一致，隔离预览仍出现画面和控件状态不稳定，因此这些浏览器画面不用于确认最终交互结果。最终构建已安装并成功启动于指定模拟器，但尚未完成长公式滑至两端、大字号、VoiceOver、真实设备和全文参考链接点击的完整可视验收。文献与固定提交链接的内容核对不等于 App 内跳转行为已验证。
