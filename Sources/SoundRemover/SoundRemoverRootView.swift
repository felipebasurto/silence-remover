import SwiftUI

/// Entry surface for the macOS UI (used by the SwiftPM `SoundRemover` tool and the Xcode app target).
public struct SoundRemoverRootView: View {
    public init() {}

    public var body: some View {
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
}
