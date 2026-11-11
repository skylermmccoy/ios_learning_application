import SwiftUI
import SwiftData

@main
struct appApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Question.self, Attempt.self, LevelProgress.self])
    }
}
