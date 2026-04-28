import SoundRemoverUI
import SwiftUI

@main
struct SoundRemoverApp: App {
    var body: some Scene {
        WindowGroup {
            SoundRemoverRootView()
        }
        .windowResizability(.contentSize)
    }
}
