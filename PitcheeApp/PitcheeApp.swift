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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: RecordingAssessment.self)
    }
}
