import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct PitchImageExportButton: View {
    let timeline: () -> PitchTimeline
    @State private var exportedImage: ExportedPitchImage?
    @State private var exportError: String?

    var body: some View {
        Button("保存完整音高图", systemImage: "square.and.arrow.up") {
            let renderer = ImageRenderer(content: PitchTimelineImage(timeline: timeline()))
            renderer.scale = 2
            renderer.isOpaque = true
            guard let image = renderer.uiImage, let data = image.pngData() else {
                exportError = "图片生成失败，请稍后重试。"
                return
            }
            exportedImage = ExportedPitchImage(image: image, data: data)
        }
        .sheet(item: $exportedImage) { image in
            PitchImageExportSheet(export: image)
        }
        .alert("无法保存图片", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("好", role: .cancel) { exportError = nil }
        } message: {
            Text(exportError ?? "请稍后再试。")
        }
    }
}

private struct ExportedPitchImage: Identifiable {
    let id = UUID()
    let image: UIImage
    let data: Data
}

private struct PitchImageExportSheet: View {
    let export: ExportedPitchImage
    @Environment(\.dismiss) private var dismiss
    @State private var showsFileExporter = false
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                Image(uiImage: export.image)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel("完整音高曲线图片")
                    .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("完整音高图")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 16) {
                    Button("存储到文件", systemImage: "folder") { showsFileExporter = true }
                    Spacer()
                    ShareLink(
                        item: Image(uiImage: export.image),
                        preview: SharePreview("完整音高图", image: Image(uiImage: export.image))
                    ) {
                        Label("保存或分享", systemImage: "square.and.arrow.up")
                    }
                }
                .buttonStyle(.bordered)
                .padding()
                .background(.regularMaterial)
            }
            .fileExporter(
                isPresented: $showsFileExporter,
                document: PitchPNGDocument(data: export.data),
                contentType: .png,
                defaultFilename: "Pitchee-F0-\(export.id.uuidString.prefix(8)).png"
            ) { result in
                if case .failure = result { saveError = "图片未能保存，请检查存储空间后重试。" }
            }
            .alert("无法保存图片", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("好", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "请稍后再试。")
            }
        }
    }
}

private struct PitchPNGDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.png] }
    let data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
