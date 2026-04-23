import SwiftUI

@main
struct SoundRemoverApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(
                    minWidth: 760,
                    idealWidth: 880,
                    maxWidth: .infinity,
                    minHeight: 520,
                    idealHeight: 620,
                    maxHeight: .infinity
                )
                .preferredColorScheme(.dark)
        }
        .windowResizability(.contentSize)
    }
}
