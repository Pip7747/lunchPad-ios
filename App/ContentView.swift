import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            GameContainerView()
                .tabItem {
                    Label("Retro Racer", systemImage: "car.fill")
                }

            LaunchPadView()
                .tabItem {
                    Label("LaunchPad", systemImage: "music.note.list")
                }
        }
        .tint(.yellow)
    }
}
