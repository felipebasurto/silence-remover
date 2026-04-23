import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var appState = AppState()
    @State private var isImporterPresented = false
    @State private var isDropTargeted = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            RecentsSidebar(appState: appState) {
                isImporterPresented = true
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            EditorDetail(
                appState: appState,
                isDropTargeted: isDropTargeted,
                onPickFile: { isImporterPresented = true }
            )
            .toolbar { EditorToolbar(appState: appState) }
            .navigationTitle(appState.hasLoadedFile ? appState.displayFilename : AppLocale.text("app.title"))
            .navigationSubtitle(appState.hasLoadedFile ? (appState.displayDuration ?? "") : AppLocale.text("app.subtitle"))
        }
        .navigationSplitViewStyle(.balanced)
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.mp3],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                Task { await appState.selectFile(url) }
            }
        }
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isDropTargeted) { providers in
            guard let provider = providers.first else { return false }

            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard
                    let data = item as? Data,
                    let url = URL(dataRepresentation: data, relativeTo: nil)
                else {
                    return
                }

                Task { @MainActor in
                    await appState.selectFile(url)
                }
            }

            return true
        }
    }
}
