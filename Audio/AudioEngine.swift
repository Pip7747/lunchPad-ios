import AVFoundation
import Foundation

/// Synthesized audio engine – replaces Web Audio API with AVAudioEngine.
/// Generates all sounds procedurally (no sample files needed).
final class AudioEngine: ObservableObject {
    static let shared = AudioEngine()

    private let engine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    private let sampleRate: Double = 44100

    private init() {
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

    // MARK: - Chord Playback

    /// Play a guitar-style chord using additive synthesis
    func playChord(_ chordName: String) {
        guard let notes = Self.chords[chordName] else { return }
        for (i, note) in notes.enumerated() {
            guard let freq = Self.noteFreqs[note] else { continue }
            let delay = Double(i) * 0.025
            playGuitarNote(frequency: freq, delay: delay)
        }
    }

    private func playGuitarNote(frequency: Double, delay: Double) {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        var phase1: Double = 0
        var phase2: Double = 0
        var phase3: Double = 0
        var elapsed: Double = 0
        let freq = frequency
        let sr = sampleRate

        let sourceNode = AVAudioSourceNode { _, _, frameCount, bufferList -> OSStatus in
            let buffer = UnsafeMutableBufferPointer<Float>(
                start: bufferList.pointee.mBuffers.mData?.assumingMemoryBound(to: Float.self),
                count: Int(frameCount)
            )
            for i in 0..<Int(frameCount) {
                let t = elapsed
                // Attack pluck (sawtooth, fast decay)
                let saw = Float(2.0 * (phase1 - floor(phase1 + 0.5)))
                let pluckEnv = Float(max(0.001, 0.15 * exp(-t / 0.02)))
                // Body (triangle, slow decay)
                let tri = Float(2.0 * abs(2.0 * (phase2 - floor(phase2 + 0.5))) - 1.0)
                let bodyEnv = Float(max(0.001, 0.12 * exp(-t / 0.4)))
                // Harmonic (sine at 2x, medium decay)
                let harm = Float(sin(phase3 * 2.0 * .pi))
                let harmEnv = Float(max(0.001, 0.04 * exp(-t / 0.15)))

                buffer[i] = saw * pluckEnv + tri * bodyEnv + harm * harmEnv

                phase1 += freq / sr
                phase2 += freq / sr
                phase3 += (freq * 2) / sr
                elapsed += 1.0 / sr
            }
            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: mixer, format: format)

        let delayTime = DispatchTimeInterval.milliseconds(Int(delay * 1000))
        DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) { [weak self] in
            // Auto-remove after 1.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self?.engine.detach(sourceNode)
            }
        }
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
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        var phase: Double = 0
        var elapsed: Double = 0
        let sr = sampleRate

        let node = AVAudioSourceNode { _, _, frameCount, bufferList -> OSStatus in
            let buf = UnsafeMutableBufferPointer<Float>(
                start: bufferList.pointee.mBuffers.mData?.assumingMemoryBound(to: Float.self),
                count: Int(frameCount)
            )
            for i in 0..<Int(frameCount) {
                let freq = 150.0 * pow(40.0 / 150.0, min(elapsed / 0.12, 1.0))
                let env = Float(max(0.001, 0.8 * exp(-elapsed / 0.12)))
                buf[i] = Float(sin(phase * 2.0 * .pi)) * env
                phase += freq / sr
                elapsed += 1.0 / sr
            }
            return noErr
        }
        playSynthNode(node, format: format, duration: 0.5)
    }

    private func playSnare() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        var elapsed: Double = 0
        var phase: Double = 0
        let sr = sampleRate

        let node = AVAudioSourceNode { _, _, frameCount, bufferList -> OSStatus in
            let buf = UnsafeMutableBufferPointer<Float>(
                start: bufferList.pointee.mBuffers.mData?.assumingMemoryBound(to: Float.self),
                count: Int(frameCount)
            )
            for i in 0..<Int(frameCount) {
                let noise = Float.random(in: -1...1) * Float(max(0.001, 0.5 * exp(-elapsed / 0.05)))
                let tone = Float(sin(phase * 2.0 * .pi)) * Float(max(0.001, 0.35 * exp(-elapsed / 0.03)))
                buf[i] = noise + tone
                phase += 180.0 / sr
                elapsed += 1.0 / sr
            }
            return noErr
        }
        playSynthNode(node, format: format, duration: 0.2)
    }

    private func playHiHat() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        var elapsed: Double = 0

        let node = AVAudioSourceNode { _, _, frameCount, bufferList -> OSStatus in
            let buf = UnsafeMutableBufferPointer<Float>(
                start: bufferList.pointee.mBuffers.mData?.assumingMemoryBound(to: Float.self),
                count: Int(frameCount)
            )
            for i in 0..<Int(frameCount) {
                let noise = Float.random(in: -1...1)
                let env = Float(max(0.001, 0.3 * exp(-elapsed / 0.02)))
                // Simple high-pass approximation
                buf[i] = noise * env * 0.5
                elapsed += 1.0 / 44100.0
            }
            return noErr
        }
        playSynthNode(node, format: format, duration: 0.1)
    }

    private func playTom() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        var phase: Double = 0
        var elapsed: Double = 0
        let sr = sampleRate

        let node = AVAudioSourceNode { _, _, frameCount, bufferList -> OSStatus in
            let buf = UnsafeMutableBufferPointer<Float>(
                start: bufferList.pointee.mBuffers.mData?.assumingMemoryBound(to: Float.self),
                count: Int(frameCount)
            )
            for i in 0..<Int(frameCount) {
                let freq = 120.0 * pow(70.0 / 120.0, min(elapsed / 0.2, 1.0))
                let env = Float(max(0.001, 0.6 * exp(-elapsed / 0.1)))
                buf[i] = Float(sin(phase * 2.0 * .pi)) * env
                phase += freq / sr
                elapsed += 1.0 / sr
            }
            return noErr
        }
        playSynthNode(node, format: format, duration: 0.4)
    }

    private func playCrash() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        var elapsed: Double = 0

        let node = AVAudioSourceNode { _, _, frameCount, bufferList -> OSStatus in
            let buf = UnsafeMutableBufferPointer<Float>(
                start: bufferList.pointee.mBuffers.mData?.assumingMemoryBound(to: Float.self),
                count: Int(frameCount)
            )
            for i in 0..<Int(frameCount) {
                let noise = Float.random(in: -1...1)
                let env = Float(max(0.001, 0.35 * exp(-elapsed / 0.3)))
                buf[i] = noise * env
                elapsed += 1.0 / 44100.0
            }
            return noErr
        }
        playSynthNode(node, format: format, duration: 1.0)
    }

    private func playSynthNode(_ node: AVAudioSourceNode, format: AVAudioFormat, duration: Double) {
        engine.attach(node)
        engine.connect(node, to: mixer, format: format)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.engine.detach(node)
        }
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
