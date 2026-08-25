import SwiftUI

@main
struct ReddSaveMediaApp: App {
    @StateObject private var downloads = DownloadCoordinator()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(downloads)
        }
    }
}
