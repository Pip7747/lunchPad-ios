import AVFoundation
import Foundation

/// Synthesized audio engine – pre-renders all sounds into buffers.
final class AudioEngine: ObservableObject {
    nonisolated(unsafe) static let shared = AudioEngine()

    private let engine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    private let sampleRate: Double = 44100
    private let format: AVAudioFormat

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        setupAudioSession()
        engine.attach(mixer)
        engine.connect(mixer, to: engine.mainMixerNode, format: nil)
        try? engine.start()
    }

    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    // MARK: - Buffer Helpers

    private func makeBuffer(frameCount: Int) -> AVAudioPCMBuffer {
        let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount))!
        buf.frameLength = AVAudioFrameCount(frameCount)
        return buf
    }

    private func playBuffer(_ buffer: AVAudioPCMBuffer, delay: Double = 0) {
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: mixer, format: format)
        player.scheduleBuffer(buffer) {
            DispatchQueue.main.async { [weak self] in
                player.stop()
                self?.engine.detach(player)
            }
        }
        if delay > 0 {
            let ms = Int(delay * 1000)
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(ms)) {
                player.play()
            }
        } else {
            player.play()
        }
    }

    // MARK: - Chord Playback

    func playChord(_ chordName: String) {
        guard let notes = Self.chords[chordName] else { return }
        for (i, note) in notes.enumerated() {
            guard let freq = Self.noteFreqs[note] else { continue }
            let delay: Double = Double(i) * 0.025
            playGuitarNote(frequency: freq, delay: delay)
        }
    }

    private func playGuitarNote(frequency: Double, delay: Double) {
        let sr: Double = sampleRate
        let freq: Double = frequency
        let totalFrames: Int = Int(sr * 1.5)
        let buffer = makeBuffer(frameCount: totalFrames)
        let data: UnsafeMutablePointer<Float> = buffer.floatChannelData![0]

        var phase1: Double = 0
        var phase2: Double = 0
        var phase3: Double = 0

        for i in 0..<totalFrames {
            let t: Double = Double(i) / sr

            let sawVal: Double = 2.0 * (phase1 - floor(phase1 + 0.5))
            let pluckEnv: Double = max(0.001, 0.15 * exp(-t / 0.02))
            let pluck: Double = sawVal * pluckEnv

            let triRaw: Double = 2.0 * abs(2.0 * (phase2 - floor(phase2 + 0.5))) - 1.0
            let bodyEnv: Double = max(0.001, 0.12 * exp(-t / 0.4))
            let body: Double = triRaw * bodyEnv

            let harmVal: Double = sin(phase3 * 2.0 * Double.pi)
            let harmEnv: Double = max(0.001, 0.04 * exp(-t / 0.15))
            let harm: Double = harmVal * harmEnv

            data[i] = Float(pluck + body + harm)

            phase1 += freq / sr
            phase2 += freq / sr
            phase3 += (freq * 2.0) / sr
        }

        playBuffer(buffer, delay: delay)
    }

    // MARK: - Drum Playback

    func playDrum(_ type: String) {
        switch type {
        case "kick":    playKick()
        case "snare":   playSnare()
        case "hihat":   playHiHat()
        case "tom":     playTom()
        case "crash":   playCrash()
        default: break
        }
    }

    private func playKick() {
        let sr: Double = sampleRate
        let totalFrames: Int = Int(sr * 0.5)
        let buffer = makeBuffer(frameCount: totalFrames)
        let data: UnsafeMutablePointer<Float> = buffer.floatChannelData![0]
        var phase: Double = 0

        for i in 0..<totalFrames {
            let t: Double = Double(i) / sr
            let freq: Double = 150.0 * pow(40.0 / 150.0, min(t / 0.12, 1.0))
            let env: Double = max(0.001, 0.8 * exp(-t / 0.12))
            data[i] = Float(sin(phase * 2.0 * Double.pi) * env)
            phase += freq / sr
        }
        playBuffer(buffer)
    }

    private func playSnare() {
        let sr: Double = sampleRate
        let totalFrames: Int = Int(sr * 0.2)
        let buffer = makeBuffer(frameCount: totalFrames)
        let data: UnsafeMutablePointer<Float> = buffer.floatChannelData![0]
        var phase: Double = 0

        for i in 0..<totalFrames {
            let t: Double = Double(i) / sr
            let noiseVal: Float = Float.random(in: -1...1)
            let noiseEnv: Float = Float(max(0.001, 0.5 * exp(-t / 0.05)))
            let toneVal: Float = Float(sin(phase * 2.0 * Double.pi))
            let toneEnv: Float = Float(max(0.001, 0.35 * exp(-t / 0.03)))
            data[i] = noiseVal * noiseEnv + toneVal * toneEnv
            phase += 180.0 / sr
        }
        playBuffer(buffer)
    }

    private func playHiHat() {
        let sr: Double = sampleRate
        let totalFrames: Int = Int(sr * 0.1)
        let buffer = makeBuffer(frameCount: totalFrames)
        let data: UnsafeMutablePointer<Float> = buffer.floatChannelData![0]

        for i in 0..<totalFrames {
            let t: Double = Double(i) / sr
            let noise: Float = Float.random(in: -1...1)
            let env: Float = Float(max(0.001, 0.3 * exp(-t / 0.02)))
            data[i] = noise * env * 0.5
        }
        playBuffer(buffer)
    }

    private func playTom() {
        let sr: Double = sampleRate
        let totalFrames: Int = Int(sr * 0.4)
        let buffer = makeBuffer(frameCount: totalFrames)
        let data: UnsafeMutablePointer<Float> = buffer.floatChannelData![0]
        var phase: Double = 0

        for i in 0..<totalFrames {
            let t: Double = Double(i) / sr
            let freq: Double = 120.0 * pow(70.0 / 120.0, min(t / 0.2, 1.0))
            let env: Double = max(0.001, 0.6 * exp(-t / 0.1))
            data[i] = Float(sin(phase * 2.0 * Double.pi) * env)
            phase += freq / sr
        }
        playBuffer(buffer)
    }

    private func playCrash() {
        let sr: Double = sampleRate
        let totalFrames: Int = Int(sr * 1.0)
        let buffer = makeBuffer(frameCount: totalFrames)
        let data: UnsafeMutablePointer<Float> = buffer.floatChannelData![0]

        for i in 0..<totalFrames {
            let t: Double = Double(i) / sr
            let noise: Float = Float.random(in: -1...1)
            let env: Float = Float(max(0.001, 0.35 * exp(-t / 0.3)))
            data[i] = noise * env
        }
        playBuffer(buffer)
    }

    // MARK: - Music Theory Data

    static let noteFreqs: [String: Double] = [
        "C3": 130.81, "C#3": 138.59, "Db3": 138.59, "D3": 146.83, "D#3": 155.56, "Eb3": 155.56,
        "E3": 164.81, "F3": 174.61, "F#3": 185.00, "Gb3": 185.00, "G3": 196.00, "G#3": 207.65,
        "Ab3": 207.65, "A3": 220.00, "A#3": 233.08, "Bb3": 233.08, "B3": 246.94,
        "C4": 261.63, "C#4": 277.18, "Db4": 277.18, "D4": 293.66, "D#4": 311.13, "Eb4": 311.13,
        "E4": 329.63, "F4": 349.23, "F#4": 369.99, "Gb4": 369.99, "G4": 392.00, "G#4": 415.30,
        "Ab4": 415.30, "A4": 440.00, "A#4": 466.16, "Bb4": 466.16, "B4": 493.88,
        "C5": 523.25, "D5": 587.33, "E5": 659.25
    ]

    static let chords: [String: [String]] = [
        "C": ["C4", "E4", "G4"], "Cm": ["C4", "Eb4", "G4"],
        "C#m": ["C#4", "E4", "G#4"],
        "D": ["D4", "F#4", "A4"], "Dm": ["D4", "F4", "A4"],
        "Eb": ["Eb4", "G4", "Bb4"],
        "E": ["E4", "G#4", "B4"], "Em": ["E4", "G4", "B4"],
        "F": ["F3", "A3", "C4"], "F#m": ["F#3", "A3", "C#4"],
        "G": ["G3", "B3", "D4"], "Gm": ["G3", "Bb3", "D4"],
        "G#m": ["G#3", "B3", "D#4"],
        "A": ["A3", "C#4", "E4"], "Am": ["A3", "C4", "E4"],
        "Bb": ["Bb3", "D4", "F4"],
        "B": ["B3", "D#4", "F#4"], "Bm": ["B3", "D4", "F#4"]
    ]

    static let keyChords: [String: [String]] = [
        "C": ["C", "Dm", "Em", "F", "G", "Am"],
        "G": ["G", "Am", "Bm", "C", "D", "Em"],
        "D": ["D", "Em", "F#m", "G", "A", "Bm"],
        "A": ["A", "Bm", "C#m", "D", "E", "F#m"],
        "E": ["E", "F#m", "G#m", "A", "B", "C#m"],
        "F": ["F", "Gm", "Am", "Bb", "C", "Dm"],
        "Bb": ["Bb", "Cm", "Dm", "Eb", "F", "Gm"],
        "Am": ["Am", "C", "Dm", "Em", "F", "G"],
        "Em": ["Em", "G", "Am", "Bm", "C", "D"],
        "Dm": ["Dm", "F", "Gm", "Am", "Bb", "C"]
    ]
}
