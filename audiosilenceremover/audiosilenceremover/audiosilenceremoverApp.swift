//
//  audiosilenceremoverApp.swift
//  audiosilenceremover
//

import SoundRemoverUI
import SwiftUI

@main
struct audiosilenceremoverApp: App {
    var body: some Scene {
        WindowGroup {
            SoundRemoverRootView()
        }
        .windowResizability(.contentSize)
    }
}
