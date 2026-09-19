//
//  PianoSoundEngine.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/18.
//

import AVFoundation
import Combine
import Foundation

struct PianoNote: Identifiable, Hashable {
    let midi: Int
    let displayName: String

    var id: Int { midi }
    var octave: Int { (midi / 12) - 1 }
    var frequency: Double {
        440 * pow(2, Double(midi - 69) / 12)
    }

    static let allNotes: [PianoNote] = [
        ("F#2", 42), ("G2", 43), ("G#2", 44), ("A2", 45), ("A#2", 46), ("B2", 47),
        ("C3", 48), ("C#3", 49), ("D3", 50), ("D#3", 51), ("E3", 52), ("F3", 53),
        ("F#3", 54), ("G3", 55), ("G#3", 56), ("A3", 57), ("A#3", 58), ("B3", 59),
        ("C4", 60), ("C#4", 61), ("D4", 62), ("D#4", 63), ("E4", 64), ("F4", 65)
    ].map { PianoNote(midi: $0.1, displayName: $0.0) }
}

final class PianoSoundEngine: ObservableObject {
    private let engine = AVAudioEngine()
    private let renderer = PianoToneRenderer(sampleRate: 48_000)
    private var sourceNode: AVAudioSourceNode?
    private var pendingPause: DispatchWorkItem?

    func prepare() {
        pendingPause?.cancel()
        pendingPause = nil
        configureAudioSession()

        if sourceNode == nil {
            let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1)!
            let renderer = renderer
            let source = AVAudioSourceNode(format: format) { isSilent, _, frameCount, output in
                let buffers = UnsafeMutableAudioBufferListPointer(output)
                guard let samples = buffers[0].mData?.assumingMemoryBound(to: Float.self) else {
                    return noErr
                }
                isSilent.pointee = ObjCBool(
                    renderer.render(into: samples, frameCount: Int(frameCount))
                )
                return noErr
            }
            engine.attach(source)
            engine.connect(source, to: engine.mainMixerNode, format: format)
            sourceNode = source
        }

        if !engine.isRunning {
            engine.prepare()
            try? engine.start()
        }
    }

    func play(note: PianoNote) {
        renderer.noteOn(midi: note.midi, oneShot: true)
    }

    func start(note: PianoNote) {
        renderer.noteOn(midi: note.midi)
    }

    func stop(note: PianoNote) {
        renderer.noteOff(midi: note.midi)
    }

    func stopAll() {
        renderer.releaseAll()
        pendingPause?.cancel()
        // Let the audio thread render the release to zero before suspending it.
        let pause = DispatchWorkItem { [weak self] in
            self?.engine.pause()
        }
        pendingPause = pause
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: pause)
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setPreferredIOBufferDuration(0.005)
        try? session.setActive(true, options: [])
    }
}
