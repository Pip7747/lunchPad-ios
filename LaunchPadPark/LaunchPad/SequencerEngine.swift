import Foundation
import Combine

/// Drives the 8-step drum/chord sequencer — replaces the JS setInterval-based sequencer.
final class SequencerEngine: ObservableObject {
    let stepCount = 8
    let drumIds = ["kick", "snare", "hihat", "crash"]

    // Pattern grid: trackId -> [Bool] of length stepCount
    @Published var pattern: [String: [Bool]] = [:]
    @Published var currentStep: Int = 0
    @Published var isPlaying = false
    @Published var isRecording = false
    @Published var currentKey = "C"
    @Published var bpm: Int = 96
    @Published var loops: Int = 4
    @Published var statusMessage = "Tap cells to program a groove."

    // Live take
    struct LiveEvent {
        let kind: String   // "drum" or "chord"
        let value: String  // drum type or chord name
        let at: TimeInterval
    }
    var liveTake: [LiveEvent] = []
    private var recordStartTime: Date?

    private var timer: Timer?
    private let audio = AudioEngine.shared

    init() {
        initPatterns()
    }

    // MARK: - Pattern Management

    var tracks: [(id: String, label: String, type: String)] {
        let drums: [(String, String, String)] = [
            ("kick", "Kick", "drum"),
            ("snare", "Snare", "drum"),
            ("hihat", "Hi-Hat", "drum"),
            ("crash", "Crash", "drum")
        ]
        let chordNames = AudioEngine.keyChords[currentKey] ?? AudioEngine.keyChords["C"]!
        let chords = chordNames.map { ($0, $0, "chord") }
        return (drums + chords).map { (id: $0.0, label: $0.1, type: $0.2) }
    }

    func initPatterns() {
        for id in drumIds {
            if pattern[id] == nil {
                pattern[id] = Array(repeating: false, count: stepCount)
            }
        }
        let chordNames = AudioEngine.keyChords[currentKey] ?? AudioEngine.keyChords["C"]!
        for name in chordNames {
            if pattern[name] == nil {
                pattern[name] = Array(repeating: false, count: stepCount)
            }
        }
    }

    func toggleCell(trackId: String, step: Int) {
        if pattern[trackId] == nil {
            pattern[trackId] = Array(repeating: false, count: stepCount)
        }
        pattern[trackId]![step].toggle()
        if pattern[trackId]![step] {
            triggerTrack(trackId)
        }
    }

    func changeKey(_ newKey: String) {
        stop()
        // Remove old chord patterns
        let oldChords = pattern.keys.filter { !drumIds.contains($0) }
        for key in oldChords { pattern.removeValue(forKey: key) }
        currentKey = newKey
        initPatterns()
        statusMessage = "Key changed to \(keyLabel(newKey))"
    }

    func keyLabel(_ key: String) -> String {
        let labels: [String: String] = [
            "C": "C Major", "G": "G Major", "D": "D Major", "A": "A Major", "E": "E Major",
            "F": "F Major", "Bb": "Bb Major", "Am": "A Minor", "Em": "E Minor", "Dm": "D Minor"
        ]
        return labels[key] ?? key
    }

    // MARK: - Playback

    private var stepDurationSeconds: Double {
        let safeBpm = max(60, min(180, Double(bpm)))
        return (60.0 / safeBpm) / 2.0
    }

    func togglePlay() {
        if isPlaying { stop(); return }
        currentStep = 0
        runStep()
        timer = Timer.scheduledTimer(withTimeInterval: stepDurationSeconds, repeats: true) { [weak self] _ in
            self?.runStep()
        }
        isPlaying = true
        statusMessage = "Sequencer running. Tap the pads to layer a live take."
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isPlaying = false
        currentStep = 0
        statusMessage = "Sequencer stopped."
    }

    func clearPattern() {
        for track in tracks {
            pattern[track.id] = Array(repeating: false, count: stepCount)
        }
        currentStep = 0
        statusMessage = "Pattern cleared."
    }

    private func runStep() {
        for track in tracks {
            if pattern[track.id]?[currentStep] == true {
                triggerTrack(track.id)
            }
        }
        currentStep = (currentStep + 1) % stepCount
    }

    func triggerTrack(_ trackId: String) {
        if drumIds.contains(trackId) {
            audio.playDrum(trackId)
        } else {
            audio.playChord(trackId)
        }
        recordHit(kind: drumIds.contains(trackId) ? "drum" : "chord", value: trackId)
    }

    // MARK: - Recording

    func toggleRecording() {
        if isRecording {
            isRecording = false
            statusMessage = "Recorded \(liveTake.count) events. Use Play Take to hear it back."
        } else {
            liveTake = []
            recordStartTime = Date()
            isRecording = true
            statusMessage = "Recording live taps…"
        }
    }

    func recordHit(kind: String, value: String) {
        guard isRecording, let start = recordStartTime else { return }
        liveTake.append(LiveEvent(kind: kind, value: value, at: Date().timeIntervalSince(start)))
    }

    func playLiveTake() {
        guard !liveTake.isEmpty else {
            statusMessage = "No take recorded. Press Record first."
            return
        }
        statusMessage = "Playing back your recorded take."
        for event in liveTake {
            DispatchQueue.main.asyncAfter(deadline: .now() + event.at) { [weak self] in
                if event.kind == "drum" {
                    self?.audio.playDrum(event.value)
                } else {
                    self?.audio.playChord(event.value)
                }
            }
        }
    }

    // MARK: - Chord Colors

    static let chordColors: [Color] = [
        Color(red: 238/255, green: 90/255, blue: 36/255),
        Color(red: 230/255, green: 126/255, blue: 34/255),
        Color(red: 240/255, green: 196/255, blue: 25/255),
        Color(red: 46/255, green: 213/255, blue: 115/255),
        Color(red: 30/255, green: 144/255, blue: 255/255),
        Color(red: 108/255, green: 92/255, blue: 231/255)
    ]

    func chordColor(for name: String) -> Color {
        let names = AudioEngine.keyChords[currentKey] ?? AudioEngine.keyChords["C"]!
        if let idx = names.firstIndex(of: name), idx < Self.chordColors.count {
            return Self.chordColors[idx]
        }
        return .blue
    }
}

import SwiftUI
