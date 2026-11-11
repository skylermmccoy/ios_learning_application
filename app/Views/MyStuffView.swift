import SwiftUI
import SwiftData

/// Your own questions plus history of past attempts.
struct MyStuffView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Question> { $0.isUserCreated }, sort: \Question.createdAt, order: .reverse)
    private var myQuestions: [Question]
    @Query(sort: \Attempt.date, order: .reverse) private var attempts: [Attempt]

    @AppStorage("soundOn") private var soundOn = true
    @State private var showingAdd = false
    @State private var session: QuizSession?
    @State private var wide = false

    var body: some View {
        NavigationStack {
            Group {
                if wide {
                    // My questions on the left, settings and history on the right.
                    HStack(spacing: 0) {
                        List { questionsSection }
                        List { settingsAndHistory }
                    }
                } else {
                    List {
                        questionsSection
                        settingsAndHistory
                    }
                }
            }
            .trackWide($wide)
            .navigationTitle("My Stuff")
            .toolbar(id: "questions_bar") {
                ToolbarItem(id: "add", placement: .primaryAction) {
                    Button("Add question", systemImage: "plus") {
                        showingAdd = true
                    }
                }
            }
            .toolbarRole(.editor)
            .sheet(isPresented: $showingAdd) { AddQuestionView() }
            .fullScreenCover(item: $session) { QuizView(session: $0) }
        }
    }

    @ViewBuilder private var questionsSection: some View {
        Section {
            if myQuestions.isEmpty {
                Text("Add questions from your homework with the + button.")
                    .foregroundStyle(.secondary)
            } else {
                Button("Practice my questions", systemImage: "play.fill") {
                    session = QuizSession(title: "My Questions",
                                          questions: myQuestions.shuffled(),
                                          mode: .practice, subject: nil)
                }
                ForEach(myQuestions) { q in
                    VStack(alignment: .leading) {
                        Text(q.prompt).lineLimit(2)
                        Label("\(q.subject.displayName) · \(q.kind.label)", systemImage: q.kind.icon)
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .onDelete { offsets in
                    offsets.map { myQuestions[$0] }.forEach(context.delete)
                }
            }
        } header: {
            Text("My Questions (\(myQuestions.count))")
        }
    }

    @ViewBuilder private var settingsAndHistory: some View {
        Section("Settings") {
            Toggle("Sound effects", systemImage: "speaker.wave.2", isOn: $soundOn)
        }

        Section("History") {
            if attempts.isEmpty {
                Text("No quizzes yet.").foregroundStyle(.secondary)
            }
            ForEach(attempts) { a in
                HStack {
                    VStack(alignment: .leading) {
                        Text(a.title.isEmpty ? (a.subject?.displayName ?? a.mode.label) : a.title)
                        Text(a.date, format: .dateTime.month().day().hour().minute())
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("\(a.score)/\(a.total)").monospacedDigit().bold()
                        Text("\(a.points) pts").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
