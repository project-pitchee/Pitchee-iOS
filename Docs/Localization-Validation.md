# 本地化验证记录

验证日期：2026-09-30。范围：当前 iOS 项目的 `Resources/Localizable.xcstrings`、
`Resources/InfoPlist.xcstrings`，以及标题在 SwiftUI 中的使用位置。

## 标题大小写

英文界面原先混用了 sentence case 和 Title Case，例如同一指标体系中同时存在
`Average pitch` 和 `Average Loudness`。本次统一了 146 条英文标题、指标标签、按钮和选择项，
包括共用的 `Average Pitch`、`Overall Score`、`Core Pitch Range` 和 `Voice Details`。
共用键的修改同时影响洞察、分析结果和导出报告。

修改只涉及英文显示值，保持其他语言、键、翻译状态、格式符、复数变体和换行不变。
映射表中已有的 62 条对应英文值已同步更新。
大小写规范见 [Localization-Keys.md 第 13 节](Localization-Keys.md#13-界面标题大小写)。

法语 `Hauteur moyenne`、西班牙语 `Promedio de tono` 等采用当地常见的标题句式；
德语 `Mittlere Tonhöhe` 按语法大写名词。其他语言第二个词小写不自动构成错误，
不能统一套用英文 Title Case。

## 资源检查结果

- Xcode `xcstringstool compile` 成功编译两个字符串目录，覆盖项目声明的 29 种语言。
- 检查了 9,344 个字符串单元，没有空值。
- 检查了 600 个带格式参数的字符串单元，参数位置和类型与源语言一致。
- 遍历了 42 个带复数变体的语言条目，变体均参与空值和格式参数检查，并通过编译。
- 比较修改前后的目录快照，确认大小写修正仅改变了预期的 146 个英文值。
- 核对编译产物中的全部 146 个英文值，并确认品牌、单位和标题换行保持正确。
- `git diff --check` 通过。

以上是资源和编译验证；不代表已完成 29 种语言的母语者审校，也未覆盖所有设备上的
标题截断、换行和 RTL 视觉布局。

## 现有翻译缺口

当前主目录共 463 个键，其中 462 个是实际文案。另有自动抽取的模板键
`settings.localDiagnostics.%@.%@.label`，仅带简体中文模板值；运行时诊断视图使用的是
拼接后的具体键，因此下表不把这个模板计入待翻译文案。

| 语言 | 已有实际文案 | 缺少实际文案 |
| --- | ---: | ---: |
| 简体中文 `zh-Hans` | 462 | 0 |
| 英文 `en` | 462 | 0 |
| 繁体中文 `zh-Hant` | 374 | 88 |
| 其余 26 种语言，各自 | 302 | 160 |

其余语言为 `ar`、`cs`、`da`、`de`、`el`、`es`、`fi`、`fr`、`he`、`hi`、`hr`、`hu`、
`id`、`it`、`ja`、`ko`、`ms`、`nl`、`pl`、`pt-BR`、`ru`、`sv`、`th`、`tr`、`uk`、`vi`。
`InfoPlist.xcstrings` 的 4 个键在全部 29 种语言中均有值。

| 待补充的功能文案 | 繁体中文缺少 | 其余 26 种语言各缺少 |
| --- | ---: | ---: |
| 洞察详情、活动日历和历史 `insights.*` | 0 | 33 |
| 本地评分对照 `scoreStudy.*` | 39 | 39 |
| 方向评分 `scoring.*` | 0 | 38 |
| 本地诊断 `settings.localDiagnostics.*` | 47 | 47 |
| 本地存储错误 `settings.privateStorage.*` | 2 | 2 |
| 方向评分说明 `settings.voicePreference.scoringNote` | 0 | 1 |
| 合计 | 88 | 160 |

这些缺口在本次修改前已存在，本次未补译。资源能编译成功不代表语言覆盖完整；
补译时仍需核对译者上下文、格式参数、术语和实际界面长度。
