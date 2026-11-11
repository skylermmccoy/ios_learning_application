import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @State private var demo: QuizSession?
    @State private var tab = "today"

    var body: some View {
        TabView(selection: $tab) {
            Tab("Today", systemImage: "sun.max", value: "today") { TodayView() }
            Tab("Learn", systemImage: "map", value: "learn") { LearnView() }
            Tab("Practice", systemImage: "gamecontroller", value: "practice") { PracticeView() }
            Tab("My Stuff", systemImage: "tray.full", value: "mine") { MyStuffView() }
        }
        // Bottom bar on a narrow iPhone; side bar on wide screens (iPhone Duo unfolded, iPad).
        .tabViewStyle(.sidebarAdaptable)
        .tabBarMinimizeBehavior(.onScrollDown)
        .task {
            QuestionBank.seedIfNeeded(context: context)
            #if DEBUG
            openDemoIfRequested()
            #endif
        }
        .fullScreenCover(item: $demo) { QuizView(session: $0) }
    }

    #if DEBUG
    /// Dev shortcuts: launch with `-demo buildCode` (or fillBlank, match, multipleChoice)
    /// to jump straight into that game type, or `-tab practice` / `-tab mine` to open a tab.
    private func openDemoIfRequested() {
        if let t = UserDefaults.standard.string(forKey: "tab") { tab = t }
        guard let raw = UserDefaults.standard.string(forKey: "demo"),
              let kind = QuestionKind(rawValue: raw) else { return }
        let all = (try? context.fetch(FetchDescriptor<Question>())) ?? []
        demo = QuizSession(title: kind.label, questions: Array(all.filter { $0.kind == kind }.shuffled().prefix(10)),
                           mode: .timed, subject: nil)
    }
    #endif
}

#Preview {
    ContentView()
        .modelContainer(for: [Question.self, Attempt.self, LevelProgress.self], inMemory: true)
}
