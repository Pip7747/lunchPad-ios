import SwiftUI

struct LaunchPadView: View {
    @StateObject private var seq = SequencerEngine()
    @State private var showChordPad = false
    @State private var showDrumPad = false

    private let keys = ["C", "G", "D", "A", "E", "F", "Bb", "Am", "Em", "Dm"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Status
                    Text(seq.statusMessage)
                        .font(.custom("Courier", size: 13))
                        .foregroundColor(.cyan.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    // Transport controls
                    transportBar

                    // Sequencer grid
                    sequencerGrid
                        .padding(.horizontal, 4)

                    // Side pad buttons
                    HStack(spacing: 12) {
                        Button {
                            showChordPad = true
                        } label: {
                            Label("Chords", systemImage: "guitars.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(12)
                        }

                        Button {
                            showDrumPad = true
                        } label: {
                            Label("Drums", systemImage: "drum.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.2))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(
                LinearGradient(colors: [Color(red: 0.06, green: 0.09, blue: 0.13),
                                         Color(red: 0.1, green: 0.15, blue: 0.2)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            )
            .navigationTitle("LaunchPad")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showChordPad) {
                ChordPadView(sequencer: seq)
            }
            .sheet(isPresented: $showDrumPad) {
                DrumPadView(sequencer: seq)
            }
        }
    }

    // MARK: - Transport Bar

    private var transportBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Key picker
                Menu {
                    ForEach(keys, id: \.self) { key in
                        Button(seq.keyLabel(key)) {
                            seq.changeKey(key)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "music.note")
                        Text(seq.currentKey)
                            .fontWeight(.bold)
                    }
                    .transportButton()
                }

                // BPM
                HStack(spacing: 4) {
                    Text("BPM")
                        .font(.caption2)
                    TextField("BPM", value: $seq.bpm, format: .number)
                        .keyboardType(.numberPad)
                        .frame(width: 44)
                        .multilineTextAlignment(.center)
                }
                .transportButton()

                // Play / Pause
                Button {
                    seq.togglePlay()
                } label: {
                    Image(systemName: seq.isPlaying ? "pause.fill" : "play.fill")
                        .transportButton(highlight: seq.isPlaying)
                }

                // Stop
                Button { seq.stop() } label: {
                    Image(systemName: "stop.fill")
                        .transportButton()
                }

                // Clear
                Button { seq.clearPattern() } label: {
                    Image(systemName: "trash")
                        .transportButton()
                }

                // Record
                Button { seq.toggleRecording() } label: {
                    Image(systemName: "record.circle")
                        .transportButton(highlight: seq.isRecording, highlightColor: .red)
                }

                // Play take
                Button { seq.playLiveTake() } label: {
                    Image(systemName: "waveform")
                        .transportButton()
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Sequencer Grid

    private var sequencerGrid: some View {
        VStack(spacing: 4) {
            // Header row
            HStack(spacing: 4) {
                Text("Track")
                    .font(.custom("Courier-Bold", size: 11))
                    .foregroundColor(.gray)
                    .frame(width: 70, alignment: .leading)

                ForEach(0..<seq.stepCount, id: \.self) { step in
                    Text("\(step + 1)")
                        .font(.custom("Courier-Bold", size: 11))
                        .foregroundColor(.cyan.opacity(0.6))
                        .frame(maxWidth: .infinity)
                }
            }

            // Track rows
            ForEach(seq.tracks, id: \.id) { track in
                HStack(spacing: 4) {
                    Text(track.label)
                        .font(.custom("Courier-Bold", size: 11))
                        .foregroundColor(.white)
                        .frame(width: 70, alignment: .leading)
                        .lineLimit(1)

                    ForEach(0..<seq.stepCount, id: \.self) { step in
                        stepCell(trackId: track.id, step: step, trackType: track.type)
                    }
                }
            }
        }
    }

    private func stepCell(trackId: String, step: Int, trackType: String) -> some View {
        let isActive = seq.pattern[trackId]?[step] ?? false
        let isPlayhead = seq.isPlaying && seq.currentStep == step

        return Button {
            seq.toggleCell(trackId: trackId, step: step)
        } label: {
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive
                      ? LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                      : LinearGradient(colors: [Color.white.opacity(0.08)], startPoint: .top, endPoint: .bottom))
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isPlayhead ? Color.yellow : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Transport Button Style

struct TransportButtonModifier: ViewModifier {
    var highlight: Bool = false
    var highlightColor: Color = .yellow

    func body(content: Content) -> some View {
        content
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(highlight ? .black : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(highlight ? highlightColor : Color.white.opacity(0.1))
            .cornerRadius(10)
    }
}

extension View {
    func transportButton(highlight: Bool = false, highlightColor: Color = .yellow) -> some View {
        modifier(TransportButtonModifier(highlight: highlight, highlightColor: highlightColor))
    }
}
