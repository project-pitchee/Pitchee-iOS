//
//  ContentView.swift
//  Pitchee
//
//  Created by Lvy Zhan on 2026/6/12.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, World!")
            Text("PitcheeCore \(PitcheeCore.version)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
