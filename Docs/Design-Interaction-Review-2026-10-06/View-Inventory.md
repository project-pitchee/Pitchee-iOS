# Pitchee 视图覆盖清单

审查日期：2026-10-06。此清单用于核对本次静态审查覆盖范围，不代表运行时可达性或视觉验收已经通过。

共 **31 个 Swift 文件、126 个声明类型、9,724 行**。类型包括入口视图、嵌套视图、修饰器和 Preview；“当前可达性”和具体结论见各分报告。

| 文件 | 行数 | 类型数 | 声明类型（源码行） |
| --- | ---: | ---: | --- |
| [`PitcheeApp/Analysis/LivePitchChartView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/LivePitchChartView.swift) | 159 | 3 | `LivePitchChartView` (10)<br>`PitchPlot` (41)<br>`PitchTimelineImage` (111) |
| [`PitcheeApp/Analysis/PitchImageExportButton.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/PitchImageExportButton.swift) | 142 | 2 | `PitchImageExportButton` (12)<br>`PitchImageExportSheet` (48) |
| [`PitcheeApp/Analysis/RecordingAnalysisView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingAnalysisView.swift) | 1059 | 10 | `RecordingAnalysisView` (11)<br>`RecordingResultView` (94)<br>`ScoreExplanationView` (465)<br>`FormulaBlock` (625)<br>`VoiceProfileReferenceChart` (747)<br>`PitchGenderScale` (840)<br>`GlassRangeModifier` (944)<br>`GlassBubbleModifier` (964)<br>`ResultMetric` (987)<br>`RecordingAnalysisPreview` (1020) |
| [`PitcheeApp/Analysis/RecordingExportView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingExportView.swift) | 1180 | 8 | `RecordingExportButton` (13)<br>`RecordingExportView` (33)<br>`ExportSelectionListRow` (304)<br>`ExportReportPagePreview` (672)<br>`ExportReportPage` (700)<br>`ExportMetricValueRow` (845)<br>`ExportCurvesChart` (879)<br>`ExportResultChart` (1115) |
| [`PitcheeApp/Analysis/RecordingTabAccessory.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingTabAccessory.swift) | 189 | 5 | `RecordingTabAccessory` (13)<br>`TabBarAccessory` (26)<br>`RecordingAccessoryContent` (52)<br>`RecordingAccessoryButton` (137)<br>`RecordingAccessoryPressStyle` (168) |
| [`PitcheeApp/Analysis/RecordingView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Analysis/RecordingView.swift) | 148 | 2 | `RecordingView` (10)<br>`RecordingViewPreview` (107) |
| [`PitcheeApp/App/AccessibilitySupport.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/AccessibilitySupport.swift) | 102 | 2 | `AccessibleStack` (22)<br>`AccessiblePickerStyle` (37) |
| [`PitcheeApp/App/AppIconSettingsView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/AppIconSettingsView.swift) | 184 | 3 | `AppIconSettingsView` (68)<br>`AppIconOptionRow` (117)<br>`AppIconThumbnail` (146) |
| [`PitcheeApp/App/ContentView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/ContentView.swift) | 942 | 8 | `ContentView` (13)<br>`MainTabView` (40)<br>`ScoringAccessoryHost` (148)<br>`TrendsView` (190)<br>`PianoKeysView` (679)<br>`PianoNoteButton` (776)<br>`PianoKeyTouchSurface` (822)<br>`LiquidGlassModifier` (886) |
| [`PitcheeApp/App/FoldAwareArrangementView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/FoldAwareArrangementView.swift) | 74 | 1 | `FoldAwareArrangementView` (15) |
| [`PitcheeApp/App/OnboardingView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/OnboardingView.swift) | 335 | 3 | `OnboardingView` (10)<br>`LiquidGlassProminentButtonStyleModifier` (281)<br>`OnboardingFeatureRow` (292) |
| [`PitcheeApp/App/PitcheeApp.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/PitcheeApp.swift) | 60 | 1 | `PitcheeApp` (13) |
| [`PitcheeApp/App/SettingsView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/SettingsView.swift) | 349 | 6 | `SettingsView` (11)<br>`SettingsLabel` (148)<br>`SettingsIcon` (168)<br>`VoicePreferenceSettingsView` (185)<br>`ThemeSettingsView` (219)<br>`PrivacySettingsView` (296) |
| [`PitcheeApp/App/VoicePreferences.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/App/VoicePreferences.swift) | 177 | 3 | `VoicePreferenceCard` (82)<br>`PrivacyPromiseView` (122)<br>`VoicePreferencesPreview` (151) |
| [`PitcheeApp/Diagnostics/LocalDiagnosticsView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Diagnostics/LocalDiagnosticsView.swift) | 111 | 1 | `LocalDiagnosticsView` (10) |
| [`PitcheeApp/Diagnostics/LocalScoreStudyView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Diagnostics/LocalScoreStudyView.swift) | 145 | 2 | `LocalScoreStudyView` (10)<br>`ScoreStudyFeedbackView` (96) |
| [`PitcheeApp/Insights/InsightsActivityCalendar.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsActivityCalendar.swift) | 140 | 1 | `InsightsActivityCalendar` (6) |
| [`PitcheeApp/Insights/InsightsDetailViews.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Insights/InsightsDetailViews.swift) | 539 | 12 | `InsightsRangePicker` (12)<br>`InsightsPage` (26)<br>`InsightsCard` (48)<br>`InsightsStat` (60)<br>`InsightsEmptyState` (82)<br>`RecordingHistoryView` (97)<br>`InsightsRecordingRows` (133)<br>`RecordingHistoryDetailView` (189)<br>`InsightsMetricDetailView` (216)<br>`InsightsMetricChartCard` (314)<br>`InsightsActivityView` (405)<br>`InsightsDetailPreview` (496) |
| [`PitcheeApp/Monitoring/MonitorCharts.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorCharts.swift) | 302 | 5 | `MonitorSpectrumPlot` (5)<br>`MonitorPitchPlot` (100)<br>`MonitorPitchGrid` (125)<br>`MonitorPitchTimeAxis` (154)<br>`MonitorPitchTrace` (180) |
| [`PitcheeApp/Monitoring/MonitorFrequencyGauge.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorFrequencyGauge.swift) | 156 | 2 | `MonitorFrequencyGauge` (5)<br>`MonitorFrequencyRuler` (60) |
| [`PitcheeApp/Monitoring/MonitorSpectrogramPlot.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorSpectrogramPlot.swift) | 182 | 6 | `MonitorSpectrogramPlot` (5)<br>`MonitorSpectrogramHeatmap` (26)<br>`MonitorSpectrogramFrequencyAxis` (51)<br>`MonitorSpectrogramTimeAxis` (90)<br>`MonitorSpectrogramCursor` (113)<br>`MonitorSpectrogramLegend` (131) |
| [`PitcheeApp/Monitoring/MonitorTabAccessory.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorTabAccessory.swift) | 128 | 1 | `MonitorAccessoryContent` (4) |
| [`PitcheeApp/Monitoring/MonitorViews.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Monitoring/MonitorViews.swift) | 399 | 11 | `MonitoringHubView` (3)<br>`SpectrumMonitorView` (23)<br>`PitchMonitorView` (28)<br>`MonitorPage` (44)<br>`MonitorReadout` (115)<br>`MonitorInstrument` (181)<br>`MonitorTimelineControl` (239)<br>`MonitorWindowMenu` (273)<br>`MonitorHelpView` (312)<br>`MonitorReviewModifier` (350)<br>`MonitorScreenPreview` (365) |
| [`PitcheeApp/Practice/GuidedPracticeSessionView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/GuidedPracticeSessionView.swift) | 67 | 1 | `GuidedPracticeSessionView` (14) |
| [`PitcheeApp/Practice/PracticeHubView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeHubView.swift) | 73 | 1 | `PracticeHubView` (12) |
| [`PitcheeApp/Practice/PracticeSpectrumView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeSpectrumView.swift) | 243 | 6 | `PracticeSpectrumView` (5)<br>`PracticeSpectrumReadout` (81)<br>`PracticeSpectrumInstrument` (128)<br>`PracticeSpectrumTimeline` (161)<br>`PracticeSpectrumSettings` (191)<br>`PracticeSpectrumHelp` (212) |
| [`PitcheeApp/Practice/PracticeSuggestionsSection.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeSuggestionsSection.swift) | 54 | 1 | `PracticeSuggestionsSection` (4) |
| [`PitcheeApp/Practice/PracticeTrendsView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeTrendsView.swift) | 158 | 1 | `PracticeTrendsView` (11) |
| [`PitcheeApp/Practice/PracticeViews.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/PracticeViews.swift) | 261 | 4 | `PracticeSetupView` (11)<br>`RecordingQualityView` (54)<br>`PracticeResultPanel` (80)<br>`RecordingContextView` (240) |
| [`PitcheeApp/Practice/ScoringView.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/ScoringView.swift) | 196 | 5 | `ScoringView` (6)<br>`ScoringReadout` (80)<br>`ScoringElapsedTime` (115)<br>`ScoringInstrument` (135)<br>`ScoringPitchChart` (163) |
| [`PitcheeApp/Practice/VoiceTrainingLibrary.swift`](/Users/dannyfeng/Documents/Pitchee/PitcheeApp/Practice/VoiceTrainingLibrary.swift) | 1470 | 9 | `VoiceArticleDetailView` (724)<br>`VoiceArticleContentView` (746)<br>`VoiceTrainingLibraryBrowserView` (889)<br>`VoiceTrainingLibraryContentView` (917)<br>`VoiceLibraryListRow` (1026)<br>`AdaptiveRowStack` (1056)<br>`VoiceArticleRowView` (1071)<br>`RichInlineText` (1137)<br>`ArticleBodyView` (1220) |

## 证据边界

- 文件、类型、行数和声明位置来自当前工作区源码扫描。
- 该清单不证明首屏布局、动态效果、触觉、真实录音、VoiceOver 播报或最终对比度；这些项目在分报告中标为待渲染/运行验证。
- 未接入导航的旧视图仍列入覆盖范围，但不会被当作当前用户必然看到的界面。
