import SwiftUI

@main
struct AudioSilenceRemoverApp: App {
    var body: some Scene {
        WindowGroup {
            SoundRemoverRootView()
        }
        .windowResizability(.contentSize)
    }
}
