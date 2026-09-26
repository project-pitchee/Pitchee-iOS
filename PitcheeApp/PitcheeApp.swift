//
//  PitcheeApp.swift
//  Pitchee
//
//  Created by Lvy Zhan on 2026/6/12.
//

import SwiftUI
import SwiftData

@main
struct PitcheeApp: App {
    init() {
        #if DEBUG
        guard !DebugPreviewRuntime.isRunning else { return }
        #endif
        AppStorageMigration.run()
    }

    var body: some Scene {
        WindowGroup {
            // Keep the scene content monomorphic for the Preview JIT. The
            // conditional preview root otherwise makes AppGraph resolve a
            // nested opaque result type before Canvas can render a view.
            AnyView(PitcheeRootView())
        }
    }
}

struct PitcheeRootView: View {
    var body: some View {
        #if DEBUG
        if DebugPreviewRuntime.isRunning {
            // Each preview supplies its own data and preferences. Do not open
            // the real store just to start the Canvas host process.
            Color.clear
        } else {
            appContent
        }
        #else
        appContent
        #endif
    }

    private var appContent: some View {
        ContentView()
            .modelContainer(for: RecordingAssessment.self)
    }
}

#if DEBUG
#Preview("Mock - App") {
    DebugPreviewHost(withHistory: true, completedOnboarding: true) {
        ContentView()
    }
}
#endif
