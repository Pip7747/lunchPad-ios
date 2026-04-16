import SwiftUI

/// Full-screen drum pad overlay — replaces the right-side hover sidebar.
struct DrumPadView: View {
    @ObservedObject var sequencer: SequencerEngine
    @Environment(\.dismiss) private var dismiss
    @State private var flashedDrum: String?

    private let drums: [(id: String, label: String, emoji: String)] = [
        ("kick", "Kick", "💥"),
        ("snare", "Snare", "🪘"),
        ("hihat", "Hi-Hat", "🎩"),
        ("tom", "Tom", "🔊"),
        ("crash", "Crash", "💫")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.12)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Text("Tap a pad to play it")
                        .font(.custom("Courier", size: 13))
                        .foregroundColor(.gray)

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(Array(drums.enumerated()), id: \.offset) { idx, drum in
                            Button {
                                AudioEngine.shared.playDrum(drum.id)
                                sequencer.recordHit(kind: "drum", value: drum.id)
                                flashedDrum = drum.id
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    if flashedDrum == drum.id { flashedDrum = nil }
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    Text(drum.emoji)
                                        .font(.system(size: 32))
                                    Text(drum.label)
                                        .font(.custom("Courier-Bold", size: 14))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 100)
                                .background(
                                    Circle()
                                        .fill(drumGradient(idx))
                                        .shadow(color: .black.opacity(0.4), radius: 4, y: 3)
                                )
                                .scaleEffect(flashedDrum == drum.id ? 0.88 : 1.0)
                                .animation(.easeOut(duration: 0.1), value: flashedDrum)
                            }
                            .buttonStyle(.plain)
                        }

                        // Drum roll button
                        Button {
                            for i in 0..<12 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.06) {
                                    AudioEngine.shared.playDrum("snare")
                                }
                            }
                            flashedDrum = "roll"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                if flashedDrum == "roll" { flashedDrum = nil }
                            }
                        } label: {
                            VStack(spacing: 6) {
                                Text("🥁")
                                    .font(.system(size: 32))
                                Text("Roll")
                                    .font(.custom("Courier-Bold", size: 14))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                            .background(
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [Color(red: 230/255, green: 126/255, blue: 34/255),
                                                     Color(red: 160/255, green: 64/255, blue: 0)],
                                            center: UnitPoint(x: 0.35, y: 0.35), startRadius: 0, endRadius: 60
                                        )
                                    )
                                    .shadow(color: .black.opacity(0.4), radius: 4, y: 3)
                            )
                            .scaleEffect(flashedDrum == "roll" ? 0.88 : 1.0)
                            .animation(.easeOut(duration: 0.1), value: flashedDrum)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)

                    // Hit display
                    if let drum = flashedDrum {
                        let info = drums.first(where: { $0.id == drum })
                        Text(info.map { "\($0.emoji) \($0.label)" } ?? "🥁 DRUM ROLL!")
                            .font(.custom("Courier-Bold", size: 42))
                            .foregroundColor(.red)
                            .transition(.scale.combined(with: .opacity))
                    }

                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle("Drum Kit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func drumGradient(_ idx: Int) -> RadialGradient {
        let colors: [(Color, Color)] = [
            (Color(red: 231/255, green: 76/255, blue: 60/255), Color(red: 146/255, green: 43/255, blue: 33/255)),
            (Color(red: 243/255, green: 156/255, blue: 18/255), Color(red: 183/255, green: 149/255, blue: 11/255)),
            (Color(red: 46/255, green: 204/255, blue: 113/255), Color(red: 26/255, green: 152/255, blue: 80/255)),
            (Color(red: 52/255, green: 152/255, blue: 219/255), Color(red: 33/255, green: 97/255, blue: 140/255)),
            (Color(red: 155/255, green: 89/255, blue: 182/255), Color(red: 108/255, green: 52/255, blue: 131/255))
        ]
        let pair = idx < colors.count ? colors[idx] : colors[0]
        return RadialGradient(
            colors: [pair.0, pair.1],
            center: UnitPoint(x: 0.35, y: 0.35),
            startRadius: 0, endRadius: 60
        )
    }
}
