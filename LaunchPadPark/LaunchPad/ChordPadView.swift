import SwiftUI

/// Full-screen chord pad overlay — replaces the left-side hover sidebar.
struct ChordPadView: View {
    @ObservedObject var sequencer: SequencerEngine
    @Environment(\.dismiss) private var dismiss
    @State private var flashedChord: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.12)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Text("Tap a chord to play it")
                        .font(.custom("Courier", size: 13))
                        .foregroundColor(.gray)

                    let chordNames = AudioEngine.keyChords[sequencer.currentKey]
                        ?? AudioEngine.keyChords["C"]!

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(Array(chordNames.enumerated()), id: \.offset) { idx, name in
                            Button {
                                AudioEngine.shared.playChord(name)
                                sequencer.recordHit(kind: "chord", value: name)
                                flashedChord = name
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    if flashedChord == name { flashedChord = nil }
                                }
                            } label: {
                                Text(name)
                                    .font(.custom("Courier-Bold", size: 28))
                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.2))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 90)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(chordGradient(idx))
                                    )
                                    .scaleEffect(flashedChord == name ? 0.92 : 1.0)
                                    .animation(.easeOut(duration: 0.1), value: flashedChord)
                                    .shadow(color: .black.opacity(0.3), radius: 4, y: 3)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)

                    // Big chord display
                    if let chord = flashedChord {
                        Text(chord)
                            .font(.custom("Courier-Bold", size: 64))
                            .foregroundColor(.yellow)
                            .transition(.scale.combined(with: .opacity))
                    }

                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle("Chords — \(sequencer.keyLabel(sequencer.currentKey))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func chordGradient(_ idx: Int) -> LinearGradient {
        let colors: [(Color, Color)] = [
            (Color(red: 1, green: 107/255, blue: 107/255), Color(red: 238/255, green: 90/255, blue: 36/255)),
            (Color(red: 1, green: 165/255, blue: 2/255), Color(red: 230/255, green: 126/255, blue: 34/255)),
            (Color(red: 1, green: 211/255, blue: 42/255), Color(red: 240/255, green: 196/255, blue: 25/255)),
            (Color(red: 123/255, green: 237/255, blue: 159/255), Color(red: 46/255, green: 213/255, blue: 115/255)),
            (Color(red: 112/255, green: 161/255, blue: 1), Color(red: 30/255, green: 144/255, blue: 1)),
            (Color(red: 162/255, green: 155/255, blue: 254/255), Color(red: 108/255, green: 92/255, blue: 231/255))
        ]
        let pair = idx < colors.count ? colors[idx] : colors[0]
        return LinearGradient(colors: [pair.0, pair.1], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
