# 本地化键名规范 (Localization key naming)

本项目所有面向用户的文案都存放在 `Resources/Localizable.xcstrings`（String Catalog）里，
键名统一采用 **语义化 + 层级式** 的 `<feature>.<context>.<semantic>[.<role>]` 形式。
完整的「旧键 → 新键」对照见 `Docs/Localization-Key-Mapping.md`。

## 1. 依据

规范来自 Apple 的三份材料，并在本次改造中逐条落地：

| 来源 | 采纳的做法 | 在本项目中的体现 |
| --- | --- | --- |
| WWDC19-403《Creating Great Localized Experiences with Xcode 11》 | 标识符要 **唯一且稳定**，不要用待翻译的文案本身当标识符；为译者补充上下文注释；改文案不应让译文失效 | 键名与中文原文解耦；每个键都带 `comment`；`VoicePreference` 的持久化值改为稳定标识符 |
| WWDC22-10037《Writing for interfaces》 | 术语要一致，同一个概念始终用同一句话；每个词都要有用 | 跨页面复用的度量名称合并成 `common.metric.*` 单一键 |
| HIG ▸ Writing | 建立语言模式、统一术语与大小写；按钮用动词；避免物主代词 | 动作类键统一用动词短语；单位与品牌名单独归类 |

## 2. 命名语法

```
<feature>.<context>.<semantic>[.<role>]
```

- **feature**：产品功能区，取自下面的固定词表（小写 camelCase）。
- **context**：该功能内的页面 / 区块 / 组件，例如 `metric`、`controls`、`privacyPromise`。优先复用已有 context，不要造近似词。
- **semantic**：这段文案「表达什么」，而不是它「写了什么」。
- **role**：可选的第 4 段。只有当同一个 `feature.context.semantic` 下有多条文案时才需要，用来区分角色。

### feature 词表

| feature | 含义 | 键数量 |
| --- | --- | --- |
| `export` | 导出：导出面板、预览、PDF 报告、音高图存图与分享 | 75 |
| `analysis` | 分析结果页、练习建议、资源、声音详情、错误 | 70 |
| `scoring` | 评分说明、基础公式、各条评分规则 | 40 |
| `recording` | 录制标签页、实时音高、参考语料、错误 | 27 |
| `common` | 跨功能复用：度量术语、单位、通用动作、品牌 | 24 |
| `onboarding` | 首次启动引导流程 | 14 |
| `voiceProfile` | 声音偏好选项与隐私承诺 | 13 |
| `insights` | 洞察标签页（趋势与汇总） | 9 |
| `settings` | 偏好与隐私页 | 5 |
| `about` | 关于页 | 4 |
| `piano` | 钢琴键页 | 3 |

### role 词表

| role | 用途 |
| --- | --- |
| `title` | 页面 / 区块 / 元素的标题 |
| `subtitle` | 标题下的辅助说明 |
| `label` | 键值行、图表轴等处的名称 |
| `caption` | 标题下方一行短说明 |
| `description` | 较长的解释句 |
| `value` | 展示用的值 |
| `unit` | 单位或符号 |
| `action` | 按钮 / 可点操作的标题 |
| `message` | 弹窗正文、错误正文 |
| `condition` | 规则触发条件 |
| `formula` | 计算公式 |
| `result` | 规则处理结果 |
| `a11y` | VoiceOver 读出的标签 |
| `hint` | VoiceOver 的提示语 |
| `note` | 脚注 |

## 3. 规则

1. **不用原文当键。** 改文案、修错别字、换语气都不应该让译文失效。
2. **一个概念一个键。** 同一术语在多处出现时共用一个键，例如
   `common.metric.compositeScore.title`（综合评分）同时用于洞察页、结果页和导出报告；
   `common.unit.hertz`、`common.action.ok` 同理。
3. **页面外壳各自成键。** 即使当前中文恰好相同（如「导出」既是入口按钮也是弹窗标题），
   按钮、弹窗标题、区块标题仍分开命名，避免某个页面想改措辞时被迫连带改动。
4. **插值字符串把格式符留在键里。** 编译器抽取出来的键本身就带 `%@` / `%lld`，例如
   `insights.metric.baselineAverage.caption %@`；**译文里**再改用位置参数 `%1$@`，便于译者调整语序。
5. **单位、数字、符号不逐字翻译。** `Hz`、`dBFS`、`—`、`350 Hz` 这类放在 `common.unit.*` 或
   `common.placeholder.*` 下，多语言值保持一致。
6. **品牌名标记为不翻译。** `common.brand.wordmark`、`common.brand.name`、`export.report.brandName`
   设 `shouldTranslate: false`，中英文都保持 `Pitchee` / `PITCHEE`。
7. **注释写给译者。** `comment` 只描述这条文案出现在哪个界面、对谁说话、语气如何、有哪些注意事项，
   不写代码位置、行号、Swift 语法或内部重构待办。
8. **平台定义的键不改名。** 例如 `Info.plist` 的 `NSMicrophoneUsageDescription`、
   `NSPhotoLibraryAddUsageDescription` 由系统定义，只能通过 `Resources/InfoPlist.xcstrings` 翻译其值。
9. **大小写按语言和用途确定。** 英文界面标题、指标名和按钮统一使用 Title Case；
   正文和辅助说明使用 sentence case。其他语言遵循各自惯例，具体见第 13 节。

## 4. 存储键（UserDefaults / @AppStorage）

存储键是**数据**不是文案，必须稳定、与语言无关，同样使用层级命名，集中定义在 `PitcheeApp/App/AppStorage.swift`：

| 键 | 含义 |
| --- | --- |
| `onboarding.progress.completedVersion` | 已完成的引导流程版本号（Int） |
| `voiceProfile.selection.preference` | 声音偏好，存 `VoicePreference.rawValue` |
| `insights.activity.openedDates` | 打开过的日期列表，逗号分隔 |

改名会让老用户的本地数据「失联」，所以 `AppStorageMigration` 在启动时把旧键
（`pitchee.onboarding2.completed` / `pitchee.voice.preference` / `pitchee.opened.calendar.days`）
的值搬到新键并删除旧键。原来的 `onboarding2` 用 "2" 表示流程版本，现在改为把版本号当**值**存进
`completedVersion`，需要重新引导时只要递增 `OnboardingFlow.currentVersion` 即可，不必再改名。

## 5. 本次一并修复的问题

这些是「用文案当标识符」导致的真实缺陷：

1. **`VoicePreference` 的 rawValue 原本是中文文案**（`男性向声音` 等），既存进 UserDefaults 又直接用于显示。
   用户把 App 语言切到英文后，`rawValue` 会变成英文，已保存的偏好就再也匹配不上。
   现在 rawValue 是 `masculine` / `feminine` / `undecided`，显示文案由 `title` / `detail` 从目录里取。
2. **有 128 条文案从来就没有键。** 它们写在 `String` 上下文里（例如 `ExportMetric.title`、
   `ResultSuggestion.title`、错误信息赋值），编译器根本不会抽取，Xcode 里也翻译不了。
   现在统一包成 `String(localized:)`，全部进入目录。
3. **用显示文案做判断条件。** `resource.badge == "阅读"` 与 ContentView 里的 `value == "—"`
   都是拿界面上显示的字去做逻辑判断；前者改为按稳定的 `id` 判断，后者改为共用同一个常量。
4. **术语漂移。** 同一个指标在结果页叫「音量」、在导出报告里叫「响度」。
   本次把中文完全相同的指标合并成共享键；中文本身不一致的（音量/响度、中位音量/中位响度、音量范围/响度范围）
   保持独立键，建议后续统一措辞。
5. **构建失败。** `PitcheeApp.swift` 在 `SceneBuilder` 里用了 `if/else`，项目当时无法编译；
   已把条件移进 `ViewBuilder`，属于本次改造之外的顺带修复。

6. **源语言里残留的英文标签。** `analysis.statistics.pitch.title`、`volume.title`、
`analysis.voiceProfile.female.label`、`male.label`、`analysis.pitchScale.averageMarker` 的
**中文源值本身写的是英文**（Pitch / Volume / Female / Male / AVG），而其余 28 种语言都翻译了。
这是「以原文为键」时代的遗留：中文界面里混着五个英文词，用户看到的是半英文。现已改为
音高 / 音量 / 女性 / 男性 / 平均，英文值保持不变（Pitch / Volume / Female / Male / AVG）。

## 6. 新增一条文案

1. 先判断它属于哪个 feature / context，再想清楚 semantic，拼出键名。
2. 在代码里写键：SwiftUI 语境直接写字符串字面量（`Text("recording.screen.title")`），
   纯 `String` 语境用 `String(localized: "recording.screen.title")`。
3. 插值直接写在键后面：`String(localized: "common.unit.dbfsWithDelta \(delta)")`。
4. 往 `Resources/Localizable.xcstrings` 增加条目：`zh-Hans` 写中文原文，`en` 写英文，
   `comment` 写清上下文；多参数时译文用 `%1$` / `%2$` 位置参数。
5. 编译后在 Xcode 的 String Catalog 里确认没有新增 stale 条目。

## 7. 本次改造的规模

- 键：**290** 个（改造前目录里 141 条，多数以中文原文为键）
- 调用点：**354** 处，分布在 11 个 Swift 文件
- 带格式符的键：**15** 个
- 语言：**29** 种，每种 **290/290** 条（Info.plist 另 **4** 条 × 29 种）
- 目录单元合计 **8526** 个（(290 + 4) × 29）；不含源语言的译文 **8232** 条
- 源语言 `zh-Hans`；其余 28 种状态为 `needs_review`（见第 8 节）
- 改造后新增的文案：导出格式 `export.format.*`（3 条）、存相册 `export.photos.saved.*`（2 条）、相册权限错误 `export.error.photoLibraryAccessDenied.message`（1 条），以及应用名 `CFBundleDisplayName` / `CFBundleName`（2 条）——这些都已补齐 29 种语言

## 8. 语言与翻译状态

| 项 | 值 |
| --- | --- |
| 源语言 | `zh-Hans`（`developmentRegion`，也是 `sourceLanguage`） |
| 已支持语言 | 29 种：`ar`, `cs`, `da`, `de`, `el`, `en`, `es`, `fi`, `fr`, `he`, `hi`, `hr`, `hu`, `id`, `it`, `ja`, `ko`, `ms`, `nl`, `pl`, `pt-BR`, `ru`, `sv`, `th`, `tr`, `uk`, `vi`, `zh-Hans`, `zh-Hant` |
| 目录条目 | `Localizable.xcstrings` **290 键 × 29 语言**；`InfoPlist.xcstrings` **4 键 × 29 语言** |
| 翻译状态 | `zh-Hans` 之外的 28 种全部标为 `needs_review` |
| 语言列表来源 | `Pitchee.xcodeproj/project.pbxproj` 的 `knownRegions`；合并脚本只处理其中已产出译文的语言 |

**为什么是 `needs_review` 而不是 `translated`：** String Catalog 的 `translated` 表示「已定稿」。
译文按产品语气、术语表和界面长度约束逐条产出，并通过了格式符 / 空值 / 残留英文 / 方向控制字符的
程序化校验，但**还没有母语者终审**。标成 `needs_review` 后 Xcode 会把这些语言显示为「待复核」，
既不影响运行时显示，也不会让人误以为已经过母语校对；终审通过后在 Xcode 里改回 `translated` 即可。

**术语一致性**由 `comment` 承载：每条键都写明了它出现在哪个界面、对谁说话、语气如何。
`scoring.*.condition`（如 `F0 > 165, Naturalness ≥ 50`）保留变量名与阈值不译，只译分隔符。

**每批新增语言的流程**：① 从现有目录导出 `source.json`（键 + 中文源值 + 英文 + 注释 + 是否可译）；
② 逐语言翻译，简报里写死格式符规则、逐字保留清单和术语表；③ 用 `validate.py` 逐语言校验
（键集合、格式符集合、空值、残留英文、方向控制字符）；④ 用 `merge.py` 合并，并强制覆盖不变项
（品牌、单位、符号、文件名）与朗读型单位；⑤ 重建后核对 `.stringsdata` 抽取结果与产物里的 `.lproj`。

## 9. 从右到左（RTL）

`ar`、`he` 是 RTL 语言，SwiftUI 会自动镜像 leading/trailing，无需改代码，但有两处需要显式处理：

1. **钢琴键盘不镜像。** 钢琴是方向固定的实物（低音永远在左），而 `LazyVGrid` 在 RTL 下会从
   尾部开始排布，音符顺序会反过来。已对琴键网格加 `.environment(\.layoutDirection, .leftToRight)`。
2. **图表保持从左到右。** 音高曲线、导出曲线与结果图都用 `Canvas` 以绝对坐标绘制，本身不受
   布局方向影响；时间轴从左到右是数据图表的通行约定，因此保持不动。

SF Symbols 会自动镜像需要镜像的符号（`chevron.right` 表示「下一页」）而不镜像实物符号
（`arrow.up`/`arrow.down` 的趋势箭头），这部分无需干预。

## 10. 待确认事项

1. **复数形式。** `common.unit.days`、`seconds`、`count`、`channels` 是
   **独立于数字的单位标签**（界面上数字与单位是两段 Text），斯拉夫语族与芬兰语等无法体现 1 / 2–4 / 5+ 的变化。
   译者的处理是改用缩写（pl `kan.`、cs `oken`、ru `дн.`、fi `s`）或不变格形式。
   若要正确复数，需要把数字并入同一个格式化字符串，再在目录里用 plural variation。
2. **「音量」与「响度」用词不统一。** 结果页统计用「音量」（`analysis.statistics.volume.*`），
   导出报告用「响度」（`export.metric.*Loudness*`），指的是同一个 dBFS 指标。中文只差两个字，
   但 29 种语言的译文已按各自界面分别定型，统一措辞需要成批改动译文。
3. **标签长度。** `piano.screen.title`、`settings.screen.title` 等同时用作标签栏文字，
   hi（पियानो कुंजियाँ）、el（Πλήκτρα πιάνου）、fr（Enregistrement）接近上限，建议真机复核。
4. **`recording.reference.passage`** 是「朗读参考语料」，各语言都重写成了本语言的等长自然段落
   （而不是直译中文），这是有意为之——使用者要照着念。多语言为避免性别化过去时也统一用了现在时。
5. **马来语 / 印尼语**是两种语言而非同一语言的变体，已在简报中明确区分（ms 用 Tetapan/Peranti，id 用 Pengaturan/Perangkat），
   复核时请确认两者没有被互相污染。

## 11. 新增语言的复现步骤

1. 在 Xcode 里把语言加进项目的 Localizations（写入 `knownRegions`）。
2. 导出源数据：`python3 /tmp/pitchee-keys/l10n/prep.py`（读取 `Resources/*.xcstrings`）。
3. 逐语言翻译，产出 `/tmp/pitchee-keys/l10n/<code>.json`（一个 `{键: 译文}` 对象）。
4. 校验：`python3 /tmp/pitchee-keys/l10n/validate.py <code> ...`，必须 `errors=0`。
5. 合并：`python3 /tmp/pitchee-keys/l10n/merge.py`（自动只处理 `knownRegions` 里已有译文的语言，
   并强制覆盖品牌 / 单位 / 符号 / 文件名等不变项与朗读型单位）。
6. 重建并在 Xcode 里确认 String Catalog 无新增 stale 条目。

## 12. 有意保留不翻译的内容

以下内容**不是**「漏翻」，而是本来就不该翻译；它们要么不是语言，要么必须与代码 / 公式一一对应：

| 内容 | 键 | 原因 |
| --- | --- | --- |
| 品牌名 | `common.brand.wordmark`、`common.brand.name`、`export.report.brandName` | 标记 `shouldTranslate: false`，各语言保持 Pitchee / PITCHEE |
| 应用名 | `CFBundleDisplayName`、`CFBundleName` | 主屏幕与「设置」里显示的名字，品牌名，29 种语言都写 Pitchee |
| 单位与量纲符号 | `common.unit.hertz`、`dbfs`、`dbfsWithDelta`、`hertzPercentileRange`、`dbfsPercentileRange`、`pointsOutOf100` | Hz / dBFS / dB 是国际符号，各语言一致 |
| 刻度与纸张标注 | `analysis.pitchScale.minLabel`、`maxLabel`、`export.preview.pageIndicator`、`export.report.pageNumber` | 纯数字 + 单位 + A4 |
| 空值占位符 | `common.placeholder.noValue`（—）、`export.metric.valueRange`（范围连接符） | 符号而非语言 |
| 导出文件名 | `export.sheet.defaultFilename` | 文件名，跨语言保持一致便于在「文件」里认出 |
| 公式变量名 | `scoring.baseFormula.note`、`scoring.rules.*.condition` 里的 Standard / Naturalness / F0 / Base / Final / promoted / _r | 与代码里渲染的 LaTeX 公式（`\mathrm{Standard}_r` 等）必须是同一个记号；只有分隔符随语言变化 |
| 乐音名 | `PianoSoundEngine` 的 C4 / F#2 等 | 国际音名，也是音频引擎的输入 |
| 图表刻度数字 | `PitchPlot` 的 600 Hz / 300 / 150 / 75、秒数 | 纯数字 |
| 开发预览文案 | `#if DEBUG` / `#Preview` 里的英文（如 “Primary pane”） | 只在 Xcode 预览里出现，不随包发布 |

朗读型的无障碍文本是例外：`recording.timeline.currentPitch.a11y` 要把单位**读出来**（`%1$lld hertz` / `%1$lld 赫兹`），
所以它不走单位符号，各语言各有自己的写法（ko `헤르츠`、fi `hertsi`、pl `herc`、ru `герц`）。

## 13. 界面标题大小写

英文页面标题、区块标题、指标名称、按钮、选择项和独立的图例名称使用 **Title Case**，
直接在 String Catalog 中保存最终文案。例如 `Average Pitch`、`Overall Score`、
`Voice Details`、`Save to Files`、`Stop and Analyze`。

- 首尾词和主要词大写，包括动词（如 `Is`、`Are`、`Be`）和代词；中间的冠词、并列连词及
  四个字母以内的介词通常小写，例如 `a`、`the`、`and`、`or`、`to`、`of`、`in`、`with`。
- 连字符连接的主要词分别大写，例如 `Feminine-Leaning Voice`、`Practice Self-Rating`。
- 正文、说明、字幕、错误消息正文、无障碍朗读句和数值后的单位使用正常句式，
  不因附近的标题大写而同步改写。例如说明中的 `average pitch`、数值区间中的 `5 seconds`。
- 保留品牌、缩写、公式、格式符和单位的固有写法，例如 `Pitchee`、`PITCHEE`、`PDF`、`F0`、
  `Hz`、`dBFS`、`s`、`%1$@`。排版换行也不应被改写。
- 不通过 `.capitalized`、`.localizedCapitalized` 或统一的 `.textCase` 来修正文案。
  这些转换不了解文案用途，可能错误改变介词、缩写、单位或其他语言的拼写。

**英文的 Title Case 不是跨语言规则。** 法语 `Hauteur moyenne`、西班牙语 `Promedio de tono`
和意大利语 `Tono medio` 的后续普通词小写符合标题惯例；德语按语法大写名词，
例如 `Mittlere Tonhöhe`；中文、日文、韩文、阿拉伯文等没有英文式的字母大小写规则。
其他语言的标题应由该语言的界面书写惯例决定，不能仅凭「第二个词小写」判定为错误。

改标题时同时检查 `.title`、实际用作指标名的 `.label`、操作按钮及未使用这些后缀的标题键
（如 `settings.voicePreference.sectionTitle`、`onboarding.footer.finishSetup`），并同步映射表中已有的英文值。
验证时编译两个 `.xcstrings` 目录，检查占位符、复数变体、空值和语言覆盖率；
大小写修正不代表其他语言已经通过母语者审校或新增文案已经补齐翻译。
