//
//  PitchImageExportButton.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/26.
//

import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct PitchImageExportButton: View {
    let timeline: () -> PitchTimeline
    @State private var exportedImage: ExportedPitchImage?
    @State private var exportError: String?

    var body: some View {
        Button("export.pitchImage.saveChart", systemImage: "square.and.arrow.up") {
            let renderer = ImageRenderer(content: PitchTimelineImage(timeline: timeline()))
            renderer.scale = 2
            renderer.isOpaque = true
            guard let image = renderer.uiImage, let data = image.pngData() else {
                exportError = String(localized: "export.error.imageGenerationFailed")
                return
            }
            exportedImage = ExportedPitchImage(image: image, data: data)
        }
        .sheet(item: $exportedImage) { image in
            PitchImageExportSheet(export: image)
        }
        .alert("export.error.imageSaveFailed.title", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("common.action.ok", role: .cancel) { exportError = nil }
        } message: {
            Text(exportError ?? String(localized: "common.error.tryAgainLater"))
        }
    }
}

private struct ExportedPitchImage: Identifiable {
    let id = UUID()
    let image: UIImage
    let data: Data
}

private struct PitchImageExportSheet: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
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
                    .accessibilityLabel("export.pitchImage.preview.a11y")
                    .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("export.pitchImage.sheet.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.action.done") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                AccessibleStack(spacing: 16) {
                    Button("export.pitchImage.saveToFiles", systemImage: "folder") { showsFileExporter = true }
                    Spacer()
                    ShareLink(
                        item: Image(uiImage: export.image),
                        preview: SharePreview("export.pitchImage.share.subject", image: Image(uiImage: export.image))
                    ) {
                        Label("export.pitchImage.share", systemImage: "square.and.arrow.up")
                    }
                }
                .buttonStyle(.bordered)
                .padding()
                .background {
                    if reduceTransparency { Color(uiColor: .systemBackground) }
                    else { Rectangle().fill(.regularMaterial) }
                }
            }
            .fileExporter(
                isPresented: $showsFileExporter,
                document: PitchPNGDocument(data: export.data),
                contentType: .png,
                defaultFilename: "Pitchee-F0-\(export.id.uuidString.prefix(8)).png"
            ) { result in
                if case .failure = result { saveError = String(localized: "export.error.imageSaveFailed.message") }
            }
            .alert("export.error.imageSaveFailed.title", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("common.action.ok", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? String(localized: "common.error.tryAgainLater"))
            }
        }
    }
}

#if DEBUG
#Preview("Debug - Export Button", traits: .sizeThatFitsLayout) {
    PitchImageExportButton {
        PitchTimeline(result: DebugPreviewData.result)
    }
        .padding()
}

#Preview("Mock - Image Sheet") {
    let renderer = ImageRenderer(content: PitchTimelineImage(timeline: PitchTimeline(result: DebugPreviewData.result)))
    if let image = renderer.uiImage, let data = image.pngData() {
        PitchImageExportSheet(export: ExportedPitchImage(image: image, data: data))
    } else {
        Text(verbatim: "Unable to render the mock pitch image.")
    }
}
#endif

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
