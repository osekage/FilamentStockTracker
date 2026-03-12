import SwiftUI
import FirebaseCore

@main
struct FilamentStockTrackerApp: App {
    @StateObject private var auth = AuthManager()
    @StateObject private var store = CloudInventoryStore()

    init() {
        FirebaseApp.configure()
      
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(auth)
        }
    }
}
