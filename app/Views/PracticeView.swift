import SwiftUI
import SwiftData

/// Game modes by question type, then subjects grouped by category.
/// Every run is timed, 10 questions, 3 lives.
struct PracticeView: View {
    @Query private var questions: [Question]
    @State private var session: QuizSession?
    @State private var wide = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Four game cards in a row when wide, two by two otherwise.
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: wide ? 4 : 2),
                              spacing: 12) {
                        ForEach(QuestionKind.allCases) { kind in
                            gameCard(kind)
                        }
                    }

                    // Categories go two across when wide.
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 28, alignment: .top),
                                             count: wide ? 2 : 1),
                              spacing: 24) {
                        ForEach(Subject.Category.allCases, id: \.self) { category in
                            categorySection(category)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .trackWide($wide)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Practice")
            .navigationSubtitle("\(questions.count) questions")
            .fullScreenCover(item: $session) { QuizView(session: $0) }
        }
    }

    private func gameCard(_ kind: QuestionKind) -> some View {
        let pool = questions.filter { $0.kind == kind }
        return Button {
            start(kind.label, pool, subject: nil)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: kind.icon).font(.title2.weight(.semibold))
                    Spacer()
                    Text("\(pool.count)")
                        .font(.caption.bold())
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(.white.opacity(0.25), in: .capsule)
                }
                Spacer(minLength: 8)
                Text(kind.label).font(.headline)
                Text(kind.blurb).font(.caption).opacity(0.9)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
            .gradientCard([kind.color, kind.color.opacity(0.7)])
        }
        .buttonStyle(.plain)
        .disabled(pool.isEmpty)
    }

    private func categorySection(_ category: Subject.Category) -> some View {
        let subjects = Subject.allCases.filter { $0.category == category }
        return VStack(alignment: .leading, spacing: 10) {
            Label(category.rawValue, systemImage: category.icon)
                .font(.title3.bold())

            VStack(spacing: 0) {
                ForEach(subjects) { subject in
                    let pool = questions.filter { $0.subject == subject }
                    Button {
                        start(subject.displayName, pool, subject: subject)
                    } label: {
                        HStack(spacing: 12) {
                            IconBadge(icon: subject.icon, color: subject.color)
                            Text(subject.displayName)
                            Spacer()
                            Text("\(pool.count)").foregroundStyle(.secondary).monospacedDigit()
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .disabled(pool.isEmpty)

                    if subject != subjects.last {
                        Divider().padding(.leading, 62)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))

            if category == .cybersecurity {
                Text("Only test systems you own or have written permission to test, like your own lab VMs or a training platform.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
        }
    }

    private func start(_ title: String, _ pool: [Question], subject: Subject?) {
        session = QuizSession(title: title, questions: Array(pool.shuffled().prefix(10)),
                              mode: .timed, subject: subject)
    }
}
