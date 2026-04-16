import SwiftUI

/// SwiftUI wrapper that hosts the Core Graphics racing game
/// and overlays the track selection menu.
struct GameContainerView: View {
    @State private var showMenu = true
    @State private var racerView = RetroRacerView()

    var body: some View {
        ZStack {
            GameViewRepresentable(racerView: racerView)
                .ignoresSafeArea()
                .onAppear {
                    racerView.startGameLoop()
                }
                .onDisappear {
                    racerView.stopGameLoop()
                }

            // Track the game phase for menu visibility
            if showMenu {
                MenuOverlay(onSelectTrack: { idx in
                    racerView.gameState.startGame(trackIndex: idx)
                    showMenu = false
                })
                .transition(.opacity)
            }

            // Touch hint overlay (only during play)
            if !showMenu && racerView.gameState.phase == .playing {
                TouchHintOverlay()
                    .allowsHitTesting(false)
            }
        }
        .onReceive(racerView.gameState.$phase) { phase in
            if phase == .menu {
                withAnimation { showMenu = true }
            }
        }
    }
}

// MARK: - UIViewRepresentable Bridge

struct GameViewRepresentable: UIViewRepresentable {
    let racerView: RetroRacerView

    func makeUIView(context: Context) -> RetroRacerView {
        racerView
    }

    func updateUIView(_ uiView: RetroRacerView, context: Context) {}
}

// MARK: - Menu Overlay

struct MenuOverlay: View {
    let onSelectTrack: (Int) -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.88)
                .ignoresSafeArea()

            VStack(spacing: 8) {
                Text("RETRO RACER")
                    .font(.custom("Courier-Bold", size: 44))
                    .foregroundColor(Color(red: 1, green: 211/255, blue: 42/255))
                    .shadow(color: .orange, radius: 10)
                    .shadow(color: .red, radius: 4, x: 3, y: 3)

                Text("Choose your track — fork left or right to pick your path!")
                    .font(.custom("Courier", size: 13))
                    .foregroundColor(Color(red: 112/255, green: 161/255, blue: 1))
                    .padding(.bottom, 20)

                TrackButton(title: "🌴 COASTAL CRUISE", color: .green) {
                    onSelectTrack(0)
                }
                TrackButton(title: "🏜️ DESERT STORM", color: .orange) {
                    onSelectTrack(1)
                }
                TrackButton(title: "🌙 NEON NIGHTS", color: .purple) {
                    onSelectTrack(2)
                }

                VStack(spacing: 4) {
                    Text("Touch Controls:")
                        .font(.custom("Courier-Bold", size: 12))
                    Text("Left/Right side to steer")
                    Text("Top half to accelerate · Bottom to brake")
                    Text("At forks: steer LEFT or RIGHT to choose")
                }
                .font(.custom("Courier", size: 11))
                .foregroundColor(.gray)
                .padding(.top, 16)
            }
        }
    }
}

struct TrackButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Courier-Bold", size: 15))
                .foregroundColor(color)
                .frame(width: 280, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color, lineWidth: 2)
                )
        }
    }
}

// MARK: - Touch Hint (fades out)

struct TouchHintOverlay: View {
    @State private var opacity: Double = 0.6

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Text("◀ STEER")
                    .font(.custom("Courier", size: 10))
                    .foregroundColor(.white.opacity(opacity))
                Spacer()
                Text("STEER ▶")
                    .font(.custom("Courier", size: 10))
                    .foregroundColor(.white.opacity(opacity))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 3)) {
                opacity = 0
            }
        }
    }
}
