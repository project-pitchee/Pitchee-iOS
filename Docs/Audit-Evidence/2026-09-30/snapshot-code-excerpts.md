# 固定副本源码证据

来源：2026-09-30 20:08:35 Asia/Shanghai 审查副本。左侧数字为原文件行号。A05 后来已在工作区修正。完整结论和适用范围见主报告。

## A01: UserDefaults

PitcheeApp/AppStorage.swift · SHA-256 2b06ba97c79412780405b8da0a72e333105d618d6f6f2aa35d728ef6dcaa54f9

```text
  35 /// deleted after every install has migrated.
  36 enum AppStorageMigration {
  37     private static let legacyOnboardingCompleted = "pitchee.onboarding.completed"
  38     private static let legacyVoicePreference = "pitchee.voice.preference"
  39     private static let legacyOpenedDateKeys = "pitchee.opened.calendar.days"
  40 
  41     static func run(in defaults: UserDefaults = .standard) {
  42         migrateOnboarding(in: defaults)
  43         migrateVoicePreference(in: defaults)
  44         migrateOpenedDateKeys(in: defaults)
  45 
  46         for legacy in [legacyOnboardingCompleted, legacyVoicePreference, legacyOpenedDateKeys] {
  47             defaults.removeObject(forKey: legacy)
  48         }
  49     }
  50 
  51     /// The legacy Boolean also encoded "onboarding flow revision 2".
  52     private static func migrateOnboarding(in defaults: UserDefaults) {
  53         guard defaults.object(forKey: AppStorageKey.onboardingCompletedVersion) == nil,
  54               defaults.object(forKey: legacyOnboardingCompleted) != nil else { return }
  55         let completed = defaults.bool(forKey: legacyOnboardingCompleted)
  56         defaults.set(completed ? OnboardingFlow.currentVersion : 0,
  57                      forKey: AppStorageKey.onboardingCompletedVersion)
  58     }
  59 
```

## A01: monotonic timing

PitcheeApp/AnalysisViewModel.swift · SHA-256 576b3c34af3948d8228ee36d4b6a6068dcf628ec28da40acaf1e90e715323a12

```text
 299         recordedAt: Date,
 300         modelContext: ModelContext,
 301         studyAttempt: LocalScoreStudyStore.Attempt? = nil
 302     ) {
 303         analysisTask?.cancel()
 304         let diagnostics = LocalDiagnosticsStore.shared
 305         let diagnosticToken = diagnostics.beginAttempt()
 306         let recordedSeconds = elapsedTime
 307         let startedAt = ProcessInfo.processInfo.systemUptime
 308         analysisTask = Task { [weak self] in
 309             var diagnosticOutcome = DiagnosticOutcome.interrupted
 310             var inputSeconds: Double? = recordedSeconds
 311             var speechSeconds: Double?
```

## A01: local study timing

PitcheeApp/LocalScoreStudyStore.swift · SHA-256 34a36a75cbc0f5df1f7c44a03fe2a6582fb0b9f3bc8645b13184dac0abb3a381

```text
  29     private let now: () -> Date
  30     private let uptime: () -> TimeInterval
  31     private let select: () -> Bool
  32     private var authorization = Authorization()
  33     private var active: ActiveAttempt?
  34 
  35     init(fileURL: URL, configuration: DiagnosticConfiguration, now: @escaping () -> Date = Date.init,
  36          uptime: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime },
  37          select: @escaping () -> Bool = { Int.random(in: 0..<4) == 0 }) {
  38         self.fileURL = fileURL
  39         self.configuration = configuration
  40         self.now = now
  41         self.uptime = uptime
  42         self.select = select
```

## A02: recording session

PitcheeApp/AnalysisViewModel.swift · SHA-256 576b3c34af3948d8228ee36d4b6a6068dcf628ec28da40acaf1e90e715323a12

```text
 136             } else {
 137                 showRecordingError(String(localized: "recording.error.microphonePermissionDenied"))
 138             }
 139         }
 140     }
 141 
 142     private func requestMicrophonePermission() async -> Bool {
 143         await withCheckedContinuation { continuation in
 144             AVAudioApplication.requestRecordPermission { granted in
 145                 continuation.resume(returning: granted)
 146             }
 147         }
 148     }
 149 
 150     private func beginRecording() async {
 151         guard state == .requestingPermission else { return }
 152 
 153         do {
 154             let analyzer = try await preparedAnalyzer()
 155             try await analyzer.resetRealtimeF0()
 156             guard !Task.isCancelled, state == .requestingPermission else { return }
 157             try await AudioSessionController.activate(category: .record, mode: .measurement)
 158             guard !Task.isCancelled, state == .requestingPermission else {
 159                 deactivateAudioSession()
 160                 return
 161             }
```

## A02: piano session

PitcheeApp/PianoSoundEngine.swift · SHA-256 1a4f576e28fe733dc850a0fc2d8c34f0b9f175bed8e1a53d079a34e056339c03

```text
  99     private func configureAudioSession() async -> Bool {
 100         do {
 101             try await AudioSessionController.activate(
 102                 category: .playback,
 103                 mode: .default,
 104                 options: [.mixWithOthers],
 105                 preferredIOBufferDuration: 0.005
 106             )
 107             return true
 108         } catch is CancellationError {
 109             return false
 110         } catch {
 111             logger.error("Unable to configure piano audio session: \(String(describing: error), privacy: .public)")
 112             return false
 113         }
 114     }
 115 }
```

## A02: piano appearance

PitcheeApp/ContentView.swift · SHA-256 a336229511c68c81d924126774fed1fb64a8a065f598d61df34d15e6ba38b805

```text
 707                 colors: [
 708                     Color.blue.opacity(0.08),
 709                     Color.purple.opacity(0.05),
 710                     Color(uiColor: .systemBackground)
 711                 ],
 712                 startPoint: .topLeading,
 713                 endPoint: .bottomTrailing
 714             )
 715             .ignoresSafeArea()
 716         }
 717         .navigationTitle("piano.screen.title")
 718         .navigationBarTitleDisplayMode(.inline)
 719         .task(id: scenePhase) {
 720             guard scenePhase == .active else { return }
 721             feedback.prepare()
 722             await soundEngine.prepare()
 723         }
 724         .onChange(of: scenePhase) { _, phase in
 725             if phase != .active {
 726                 soundEngine.stopAll()
 727                 activeNote = nil
 728             }
 729         }
```

## A02: serial session access

PitcheeApp/AudioSessionController.swift · SHA-256 942f8030f89b9d567e2d86e3ca3b61492e2251086416bd72772cf2bfd018d762

```text
  19     private static let logger = Logger(subsystem: "com.lvyzhan.Pitchee", category: "AudioSession")
  20 
  21     static func activate(
  22         category: AVAudioSession.Category,
  23         mode: AVAudioSession.Mode,
  24         options: AVAudioSession.CategoryOptions = [],
  25         preferredIOBufferDuration: TimeInterval? = nil
  26     ) async throws {
  27         try Task.checkCancellation()
  28         try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
  29             queue.async {
  30                 do {
  31                     let session = AVAudioSession.sharedInstance()
  32                     try session.setCategory(category, mode: mode, options: options)
  33                     if let preferredIOBufferDuration {
  34                         try session.setPreferredIOBufferDuration(preferredIOBufferDuration)
  35                     }
  36                     // Keep configuration and activation together on this queue,
  37                     // including on OS versions without async activation APIs.
  38                     try session.setActive(true, options: [])
  39                     continuation.resume()
  40                 } catch {
  41                     continuation.resume(throwing: error)
  42                 }
  43             }
  44         }
  45     }
  46 
  47     static func deactivate() {
  48         let logger = logger
  49         // Enqueue immediately so a subsequent activation cannot overtake cleanup.
  50         queue.async {
  51             do {
  52                 try AVAudioSession.sharedInstance().setActive(
  53                     false,
  54                     options: .notifyOthersOnDeactivation
  55                 )
  56             } catch {
  57                 logger.error("Unable to deactivate audio session: \(String(describing: error), privacy: .public)")
  58             }
  59         }
  60     }
  61 }
```

## A03: timer

PitcheeApp/AnalysisViewModel.swift · SHA-256 576b3c34af3948d8228ee36d4b6a6068dcf628ec28da40acaf1e90e715323a12

```text
 258         analyze(pendingStudy.url, recordedAt: pendingStudy.recordedAt,
 259                 modelContext: pendingStudy.modelContext, studyAttempt: pendingStudy.attempt)
 260     }
 261 
 262     private func startTimer() {
 263         timerTask?.cancel()
 264         timerTask = Task { [weak self] in
 265             while !Task.isCancelled {
 266                 try? await Task.sleep(nanoseconds: 50_000_000)
 267                 guard let self,
 268                       self.state == .recording,
 269                       let recordingStartedAt = self.recordingStartedAt else { return }
 270                 elapsedTime = Date().timeIntervalSince(recordingStartedAt)
 271             }
 272         }
 273     }
 274 
 275     private func stopTimer() {
 276         timerTask?.cancel()
 277         timerTask = nil
 278     }
 279 
 280     private func appendLivePitch(_ frames: [PitcheeF0Frame]) {
 281         let samples = frames.map { LivePitchSample(elapsedTime: $0.elapsedTime, pitchHz: $0.pitchHz) }
 282         recordedPitchSamples.append(contentsOf: samples)
 283         livePitchSamples.append(contentsOf: samples)
 284 
```

## A03: scene lifecycle

PitcheeApp/PitcheeApp.swift · SHA-256 9a011cdaf03b7421f8cadcac97a70119b9ff2a9e3bf13b1da7e5c86d43f5ce51

```text
  32 
  33     var body: some Scene {
  34         WindowGroup {
  35             if let container {
  36                 ContentView()
  37                     .modelContainer(container)
  38                     .onAppear {
  39                         LocalDiagnosticsStore.shared.refresh()
  40                         LocalScoreStudyStore.shared.refresh()
  41                     }
  42                     .onChange(of: scenePhase) { _, phase in
  43                         if phase == .active {
  44                             LocalDiagnosticsStore.shared.refresh()
  45                             LocalScoreStudyStore.shared.refresh()
  46                         }
  47                     }
  48             } else {
  49                 ContentUnavailableView {
  50                     Label("settings.privateStorage.unavailable.title", systemImage: "lock.trianglebadge.exclamationmark")
```

## A04/A12: privacy screen

PitcheeApp/SettingsView.swift · SHA-256 58506dd3ef564a99eefe962808d66a6eceab080ece6e2e81c18b1027dd0195b9

```text
 160 }
 161 
 162 private struct PrivacySettingsView: View {
 163     @ScaledMetric(relativeTo: .body) private var iconSize = 22
 164 
 165     var body: some View {
 166         Form {
 167             Section {
 168                 promise("voiceProfile.privacyPromise.onDevice.title", detail: "voiceProfile.privacyPromise.onDevice.description", symbol: "iphone")
 169                 promise("voiceProfile.privacyPromise.recordingUsage.title", detail: "voiceProfile.privacyPromise.recordingUsage.description", symbol: "waveform")
 170                 promise("voiceProfile.privacyPromise.userControl.title", detail: "voiceProfile.privacyPromise.userControl.description", symbol: "slider.horizontal.3")
 171             }
 172         }
 173         .formStyle(.grouped)
 174         .navigationTitle("voiceProfile.privacyPromise.title")
 175         .navigationBarTitleDisplayMode(.inline)
 176     }
 177 
 178     private func promise(_ title: LocalizedStringKey, detail: LocalizedStringKey, symbol: String) -> some View {
 179         HStack(alignment: .top, spacing: 12) {
 180             Image(systemName: symbol)
 181                 .font(.system(size: min(iconSize, 32)))
 182                 .foregroundStyle(Color.accentColor)
 183                 .frame(width: min(iconSize, 32), height: min(iconSize, 32))
 184                 .accessibilityHidden(true)
 185 
 186             VStack(alignment: .leading, spacing: 6) {
 187                 Text(title)
 188                     .font(.body.weight(.medium))
 189                 Text(detail)
 190                     .font(.subheadline)
 191                     .foregroundStyle(.secondary)
 192             }
 193             .fixedSize(horizontal: false, vertical: true)
 194             .frame(maxWidth: .infinity, alignment: .leading)
```

## A05: diagnostic label before later correction

PitcheeApp/LocalDiagnosticsView.swift · SHA-256 159d43611a330b9e74dcd87fa8f1b947ace4ec42db1219184b7515bf89b27ef4

```text
  90     }
  91 
  92     private func histogram(_ title: LocalizedStringKey, counts: [Int], keys: [String], category: String) -> some View {
  93         Section {
  94             ForEach(keys.indices, id: \.self) { index in
  95                 LabeledContent(LocalizedStringKey("settings.localDiagnostics.\(category).\(keys[index]).label")) {
  96                     Text(counts[index], format: .number)
  97                 }
  98             }
  99         } header: {
 100             Text(title)
 101         }
 102     }
```

## A05: rating label before later correction

PitcheeApp/LocalScoreStudyView.swift · SHA-256 513e9dda4992f535261c9167d6d4be911291b19677a69bb278cf177d19be7eee

```text
 100                     .foregroundStyle(.secondary)
 101                 Text("scoreStudy.feedback.question")
 102                     .font(.title2.weight(.semibold))
 103                 LabeledContent("scoreStudy.feedback.direction.label") {
 104                     Text(direction == .feminine ? "voiceProfile.option.feminine.title" : "voiceProfile.option.masculine.title")
 105                 }
 106                 VStack(spacing: 10) {
 107                     ForEach(ScoreStudyRating.allCases, id: \.rawValue) { rating in
 108                         Button { submit(.rating(rating)) } label: {
 109                             Text(LocalizedStringKey("scoreStudy.feedback.rating.\(rating.rawValue).label"))
 110                                 .frame(maxWidth: .infinity, minHeight: 34)
 111                         }
 112                         .buttonStyle(.bordered)
 113                         .accessibilityIdentifier("scoreStudy.rating.\(rating.rawValue)")
 114                     }
 115                 }
 116                 Button("scoreStudy.feedback.unable.action") { submit(.unableToJudge) }
 117                     .frame(maxWidth: .infinity, minHeight: 44)
 118                 Button("scoreStudy.feedback.skip.action") { submit(.skipped) }
 119                     .frame(maxWidth: .infinity, minHeight: 44)
 120                     .accessibilityIdentifier("scoreStudy.skip")
```

## A07/A08: fixed sheets

PitcheeApp/RecordingAnalysisView.swift · SHA-256 55d62bfff0765c6a1f91970fc9dd5ffc31e472717334f2de792546ea61133548

```text
 965     let symbol: String
 966     let tint: Color
 967     let body: String
 968 }
 969 
 970 private struct ResultSuggestionSheet: View {
 971     let suggestion: ResultSuggestion
 972     @Environment(\.dismiss) private var dismiss
 973 
 974     var body: some View {
 975         NavigationStack {
 976             VStack(alignment: .leading, spacing: 20) {
 977                 Image(systemName: suggestion.symbol)
 978                     .font(.system(size: 28, weight: .semibold))
 979                     .foregroundStyle(suggestion.tint)
 980                     .frame(width: 64, height: 64)
 981                     .background(suggestion.tint.opacity(0.12), in: Circle())
 982 
 983                 VStack(alignment: .leading, spacing: 8) {
 984                     Text(suggestion.title)
 985                         .font(.title2.weight(.bold))
 986                     Text(suggestion.expandedDetail)
 987                         .font(.body)
 988                         .foregroundStyle(.secondary)
 989                         .fixedSize(horizontal: false, vertical: true)
 990                 }
 991 
 992                 Spacer()
 993             }
 994             .frame(maxWidth: 560, alignment: .leading)
 995             .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
 996             .padding(24)
 997             .background(Color(uiColor: .systemGroupedBackground))
 998             .navigationTitle("analysis.suggestionDetail.title")
 999             .navigationBarTitleDisplayMode(.inline)
1000             .toolbar {
1001                 ToolbarItem(placement: .confirmationAction) {
1002                     Button("common.action.done") { dismiss() }
1003                 }
1004             }
1005         }
1006         .presentationDetents([.medium])
1007     }
1008 }
1009 
1010 private struct ResultResourceSheet: View {
1011     let resource: ResultResource
1012     @Environment(\.dismiss) private var dismiss
1013 
1014     var body: some View {
1015         NavigationStack {
1016             VStack(alignment: .leading, spacing: 20) {
1017                 ZStack {
1018                     RoundedRectangle(cornerRadius: 18, style: .continuous)
1019                         .fill(resource.tint.gradient)
1020                     Image(systemName: resource.symbol)
1021                         .font(.system(size: 34, weight: .semibold))
1022                         .foregroundStyle(.white)
1023                 }
1024                 .frame(height: 160)
1025 
1026                 VStack(alignment: .leading, spacing: 8) {
1027                     Text(resource.title)
1028                         .font(.title2.weight(.bold))
1029                     Text(resource.body)
1030                         .font(.body)
1031                         .foregroundStyle(.secondary)
1032                         .fixedSize(horizontal: false, vertical: true)
1033                 }
1034 
1035                 Spacer()
1036             }
1037             .frame(maxWidth: 560, alignment: .leading)
1038             .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
1039             .padding(24)
1040             .background(Color(uiColor: .systemGroupedBackground))
1041             .navigationTitle(
1042                 resource.id == "voice-research"
1043                     ? String(localized: "analysis.resourceDetail.article.title")
1044                     : String(localized: "analysis.resourceDetail.video.title")
1045             )
1046             .navigationBarTitleDisplayMode(.inline)
1047             .toolbar {
1048                 ToolbarItem(placement: .confirmationAction) {
1049                     Button("common.action.done") { dismiss() }
1050                 }
1051             }
1052         }
1053         .presentationDetents([.medium])
1054     }
1055 }
1056 
1057 struct VoiceProfileReferenceChart: View {
```

## A08: resource promise

PitcheeApp/RecordingAnalysisView.swift · SHA-256 55d62bfff0765c6a1f91970fc9dd5ffc31e472717334f2de792546ea61133548

```text
 387         [
 388             ResultResource(
 389                 id: "naturalness-video",
 390                 title: String(localized: "analysis.resources.naturalnessTraining.title"),
 391                 detail: String(localized: "analysis.resources.naturalnessTraining.subtitle"),
 392                 badge: "01:09",
 393                 symbol: "play.fill",
 394                 tint: .blue,
 395                 body: String(localized: "analysis.resources.naturalnessTraining.description")
 396             ),
 397             ResultResource(
 398                 id: "voice-research",
 399                 title: String(localized: "analysis.resources.voiceResearch.title"),
 400                 detail: String(localized: "analysis.resources.voiceResearch.subtitle"),
 401                 badge: String(localized: "analysis.resources.readBadge"),
 402                 symbol: "doc.text.image",
 403                 tint: .purple,
 404                 body: String(localized: "analysis.resources.voiceResearch.description")
 405             )
 406         ]
 407     }
 408 
 409     private var voiceDetailsSheet: some View {
 410         NavigationStack {
```

## A09/A10: stream, file writes, synchronous stop

PitcheeApp/LivePitchAudioCapture.swift · SHA-256 ce367062e0c58ca3741186f4b1cde16c86a4943d989c6e0737129b913dfcfc50

```text
  59             interleaved: false
  60         )
  61         let converter = try LivePitchPCMConverter(sampleRate: inputFormat.sampleRate)
  62         let (stream, continuation) = AsyncStream<[Float]>.makeStream()
  63         pitchInput = continuation
  64         pitchTask = Task(priority: .userInitiated) {
  65             do {
  66                 for await samples in stream {
  67                     guard !Task.isCancelled else { return }
  68                     let frames = try await analyzer.processRealtimeF0(samples: samples)
  69                     guard !Task.isCancelled else { return }
  70                     if !frames.isEmpty { onPitch(frames) }
  71                 }
  72             } catch {
  73                 guard !Task.isCancelled else { return }
  74                 onError(error)
  75             }
  76         }
  77         recordingFile = file
  78         recordingError = nil
  79         acceptingBuffers = true
  80         inputNode.installTap(
  81             onBus: 0,
  82             bufferSize: 1_024,
  83             format: inputFormat
  84         ) { [weak self] buffer, _ in
  85             // The tap owns its buffer only until this callback returns. Copy it
  86             // before serializing file writes and detection off the audio thread.
  87             guard let self, let copy = Self.copyBuffer(buffer) else { return }
  88             self.pitchQueue.async {
  89                 guard self.acceptingBuffers else { return }
  90                 do {
  91                     try self.recordingFile?.write(from: copy)
  92                 } catch {
  93                     self.recordingError = error
  94                 }
  95                 guard let samples = Self.monoSamples(from: copy) else { return }
  96                 guard !converter.hasFailed else { return }
  97                 do {
  98                     let converted = try converter.convert(samples)
  99                     if !converted.isEmpty { continuation.yield(converted) }
 100                 } catch {
 101                     converter.hasFailed = true
 102                     continuation.finish()
 103                     onError(error)
 104                 }
 105             }
 106         }
 107         hasInputTap = true
 108 
 109         do {
 110             audioEngine.prepare()
 111             try audioEngine.start()
 112         } catch {
 113             stop()
 114             throw error
 115         }
 116     }
 117 
 118     @discardableResult
 119     func stop() -> Error? {
 120         if hasInputTap {
 121             audioEngine.inputNode.removeTap(onBus: 0)
 122             hasInputTap = false
 123         }
 124         audioEngine.stop()
 125         audioEngine.reset()
 126         // Drain pending writes before closing the WAV and handing it to Core.
 127         return pitchQueue.sync {
 128             acceptingBuffers = false
 129             pitchInput?.finish()
 130             pitchInput = nil
 131             pitchTask?.cancel()
 132             pitchTask = nil
 133             recordingFile = nil
 134             return recordingError
 135         }
 136     }
 137 
```

## A09: whole-file WAV read

Dependencies/PitcheeCore/src/wav_reader.cpp · SHA-256 6a9a4d4430dfdb5f85b4fb93d985b0ee9f034654aca6462e519fed09384f50da

```text
  18         | (static_cast<uint32_t>(data[2]) << 16)
  19         | (static_cast<uint32_t>(data[3]) << 24);
  20 }
  21 
  22 }  // namespace
  23 
  24 WavData read_wav(const std::filesystem::path& path) {
  25     std::ifstream input(path, std::ios::binary);
  26     if (!input) throw std::runtime_error("unable to open WAV: " + path.string());
  27     std::vector<unsigned char> bytes{
  28         std::istreambuf_iterator<char>(input),
  29         std::istreambuf_iterator<char>()
  30     };
  31     if (bytes.size() < 44 || std::memcmp(bytes.data(), "RIFF", 4) != 0
  32         || std::memcmp(bytes.data() + 8, "WAVE", 4) != 0) {
  33         throw std::runtime_error("invalid RIFF/WAVE file");
  34     }
  35 
  36     uint16_t audio_format = 0;
  37     uint16_t channels = 0;
  38     uint32_t sample_rate = 0;
  39     uint16_t bits_per_sample = 0;
  40     const unsigned char* pcm = nullptr;
  41     size_t pcm_size = 0;
  42 
  43     size_t offset = 12;
  44     while (offset + 8 <= bytes.size()) {
  45         const unsigned char* chunk = bytes.data() + offset;
  46         const uint32_t chunk_size = read_u32(chunk + 4);
  47         const size_t payload = offset + 8;
  48         if (payload + chunk_size > bytes.size()) break;
  49         if (std::memcmp(chunk, "fmt ", 4) == 0 && chunk_size >= 16) {
  50             audio_format = read_u16(bytes.data() + payload);
  51             channels = read_u16(bytes.data() + payload + 2);
  52             sample_rate = read_u32(bytes.data() + payload + 4);
  53             bits_per_sample = read_u16(bytes.data() + payload + 14);
  54         } else if (std::memcmp(chunk, "data", 4) == 0) {
  55             pcm = bytes.data() + payload;
  56             pcm_size = chunk_size;
  57         }
  58         offset = payload + chunk_size + (chunk_size & 1u);
  59     }
  60 
  61     if (!pcm || channels == 0 || sample_rate == 0) {
  62         throw std::runtime_error("WAV has no PCM data");
  63     }
  64     WavData result;
  65     result.sample_rate = static_cast<int>(sample_rate);
  66     result.channels = static_cast<int>(channels);
  67 
  68     if (audio_format == 3 && bits_per_sample == 32) {
  69         const size_t count = pcm_size / sizeof(float);
  70         result.samples.resize(count);
  71         std::memcpy(result.samples.data(), pcm, count * sizeof(float));
  72     } else if (audio_format == 1 && bits_per_sample == 16) {
  73         const size_t count = pcm_size / sizeof(int16_t);
  74         result.samples.resize(count);
  75         for (size_t index = 0; index < count; ++index) {
```

## A09: limit

Dependencies/PitcheeCore/src/internal.hpp · SHA-256 46d1d32e87f8980c2da724737e9bdd74ab1254594f5ec4685c4860e7e1f9d108

```text
   1 #ifndef PITCHEE_INTERNAL_HPP
   2 #define PITCHEE_INTERNAL_HPP
   3 
   4 #include <cstdint>
   5 #include <filesystem>
   6 #include <limits>
   7 #include <memory>
   8 #include <string>
   9 #include <vector>
  10 
  11 namespace pitchee {
  12 
  13 constexpr int kSampleRate = 16000;
  14 constexpr int kPatchSamples = 24240;
  15 constexpr int kStrideSamples = 1600;
  16 constexpr int kEmbeddingBatchSize = 8;
  17 constexpr int kEmbeddingDimensions = 192;
  18 constexpr int kSchemaVersion = 2;
  19 // An infinite limit disables input truncation in the analyzer.
  20 constexpr double kMaximumSeconds = std::numeric_limits<double>::infinity();
  21 
  22 struct VadSegment {
  23     double source_start_seconds = 0.0;
  24     double source_end_seconds = 0.0;
  25     double speech_start_seconds = 0.0;
  26     double speech_end_seconds = 0.0;
  27 };
  28 
  29 struct VadResult {
```

## A10: stop caller

PitcheeApp/AnalysisViewModel.swift · SHA-256 576b3c34af3948d8228ee36d4b6a6068dcf628ec28da40acaf1e90e715323a12

```text
 183             audioCapture = newCapture
 184             recordingURL = url
 185             recordingStartedAt = Date()
 186             state = .recording
 187             startTimer()
 188         } catch {
 189             if let recordingURL { try? FileManager.default.removeItem(at: recordingURL) }
 190             recordingURL = nil
 191             deactivateAudioSession()
 192             showRecordingError(recordingErrorMessage(for: error))
 193         }
 194     }
 195 
 196     private func stopRecording(modelContext: ModelContext) {
 197         guard state == .recording, let audioCapture else { return }
 198 
 199         stopTimer()
 200         if let recordingStartedAt { elapsedTime = Date().timeIntervalSince(recordingStartedAt) }
 201         let writeError = audioCapture.stop()
 202         self.audioCapture = nil
 203         deactivateAudioSession()
 204 
 205         if let writeError {
 206             Self.logger.error("Recording write failed: \(String(describing: writeError), privacy: .private)")
 207             if let recordingURL { try? FileManager.default.removeItem(at: recordingURL) }
 208             recordingURL = nil
 209             recordingStartedAt = nil
 210             showRecordingError(String(localized: "recording.error.saveFailed"))
 211             return
 212         }
 213 
 214         guard let recordingURL else {
 215             showRecordingError(String(localized: "recording.error.fileMissing"))
 216             return
 217         }
 218 
 219         let recordedAt = recordingStartedAt ?? Date()
 220         self.recordingURL = nil
 221         recordingStartedAt = nil
 222         clearRecordingError()
```

## A11: persisted model

PitcheeApp/RecordingAssessment.swift · SHA-256 b3068f0606137ce3f8648a8c6b69c7acda534fbd06470e37829a279346181b90

```text
  18     @Attribute(.unique) var id: UUID
  19     var recordedAt: Date
  20 
  21     var schemaVersion: Int
  22     var modelVersion: String
  23 
  24     var inputSeconds: Double
  25     var analyzedSeconds: Double
  26     var speechSeconds: Double
  27     var meanPitchHz: Double?
  28 
  29     var standardScore: Double
  30     var naturalnessScore: Double
  31     var finalScore: Double
  32     var scoreWasLimited: Bool
  33 
  34     var resultPayload: Data
  35 
  36     init(
  37         id: UUID = UUID(),
  38         recordedAt: Date,
  39         result: PitcheeAnalysisResult
  40     ) throws {
  41         self.id = id
  42         self.recordedAt = recordedAt
  43         schemaVersion = result.schemaVersion
  44         modelVersion = result.modelVersion
  45         inputSeconds = result.audio.inputSeconds
  46         analyzedSeconds = result.audio.analyzedSeconds
  47         speechSeconds = result.vad.speechSeconds
  48         meanPitchHz = result.f0.meanHz
  49         standardScore = result.vfp.vfpStandardScore
  50         naturalnessScore = result.naturalness.score
  51         finalScore = result.composite.finalScore
  52         scoreWasLimited = result.composite.limited
  53         resultPayload = try Self.encoder.encode(result)
  54     }
  55 
  56     /// The complete result as returned by PitcheeCore.
  57     var result: PitcheeAnalysisResult? {
  58         try? Self.decoder.decode(PitcheeAnalysisResult.self, from: resultPayload)
  59     }
  60 
```

## A11: history report/export

PitcheeApp/InsightsDetailViews.swift · SHA-256 fb5aedac869352bc3691b95de68425cc9c4e2da78a70ab8d62257ecbe7c8a9b9

```text
 205         .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
 206     }
 207 }
 208 
 209 struct RecordingHistoryDetailView: View {
 210     let assessment: RecordingAssessment
 211 
 212     var body: some View {
 213         Group {
 214             if let result = assessment.result {
 215                 RecordingResultView(result: result, volumeStatistics: nil, saveError: nil)
 216                     .toolbar {
 217                         ToolbarItem(placement: .topBarTrailing) {
 218                             RecordingExportButton(result: result, volumeStatistics: nil)
 219                                 .labelStyle(.iconOnly)
 220                         }
 221                     }
 222             } else {
 223                 ContentUnavailableView {
 224                     Label("insights.history.unavailable.title", systemImage: "exclamationmark.triangle")
 225                 } description: {
 226                     Text("insights.history.unavailable.description")
 227                 }
 228             }
 229         }
```

## A11: temporary file cleanup

PitcheeApp/AnalysisViewModel.swift · SHA-256 576b3c34af3948d8228ee36d4b6a6068dcf628ec28da40acaf1e90e715323a12

```text
 309             var diagnosticOutcome = DiagnosticOutcome.interrupted
 310             var inputSeconds: Double? = recordedSeconds
 311             var speechSeconds: Double?
 312             var quality = DiagnosticQuality.unavailable
 313             var studyPair: ScoreStudyPair?
 314             var studyFailed = true
 315             defer {
 316                 try? FileManager.default.removeItem(at: url)
 317                 LocalScoreStudyStore.shared.finish(studyAttempt, pair: studyPair, failed: studyFailed)
 318                 diagnostics.finish(diagnosticToken, outcome: diagnosticOutcome, observation: .init(
 319                     inputSeconds: inputSeconds, speechSeconds: speechSeconds, quality: quality,
 320                     latencySeconds: ProcessInfo.processInfo.systemUptime - startedAt
 321                 ))
 322             }
```

## A13: glass data shapes

PitcheeApp/RecordingAnalysisView.swift · SHA-256 55d62bfff0765c6a1f91970fc9dd5ffc31e472717334f2de792546ea61133548

```text
1283 
1284 private struct GlassRangeModifier: ViewModifier {
1285     @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
1286     @Environment(\.colorSchemeContrast) private var contrast
1287     func body(content: Content) -> some View {
1288         let shape = RoundedRectangle(cornerRadius: 9, style: .continuous)
1289 
1290         if reduceTransparency || contrast == .increased {
1291             content.background(Color(uiColor: .secondarySystemBackground), in: shape)
1292                 .overlay { shape.strokeBorder(.primary, lineWidth: 1.5) }
1293         } else if #available(iOS 26.0, *) {
1294             content
1295                 .glassEffect(.regular, in: shape)
1296                 .overlay {
1297                     shape.strokeBorder(.primary.opacity(0.12), lineWidth: 0.75)
1298                 }
1299         } else {
1300             content
1301                 .background(.thinMaterial, in: shape)
1302                 .overlay {
1303                     shape.strokeBorder(.primary.opacity(0.18), lineWidth: 0.75)
1304                 }
1305         }
1306     }
1307 }
1308 
1309 private struct GlassBubbleModifier: ViewModifier {
1310     @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
1311     @Environment(\.colorSchemeContrast) private var contrast
1312     let tint: Color
1313 
1314     func body(content: Content) -> some View {
1315         if reduceTransparency || contrast == .increased {
1316             content.background(Color(uiColor: .secondarySystemBackground), in: Circle())
1317                 .overlay { Circle().strokeBorder(.primary, lineWidth: 1.5) }
1318         } else if #available(iOS 26.0, *) {
1319             content.glassEffect(.regular.tint(tint), in: Circle())
1320         } else {
1321             content
1322                 .background(.thinMaterial, in: Circle())
1323                 .overlay {
1324                     Circle().stroke(tint.opacity(0.35), lineWidth: 1)
1325                 }
1326         }
1327     }
1328 }
1329 
```
