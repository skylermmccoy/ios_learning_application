import SwiftUI
import SwiftData

/// The Learn tab: your weakest areas, then every subject with its level progress.
struct LearnView: View {
    @Query private var questions: [Question]
    @Query private var progress: [LevelProgress]
    @State private var path: [Subject] = []
    @State private var session: QuizSession?

    private var bySubject: [Subject: [Question]] { Dictionary(grouping: questions, by: \.subject) }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    improveSection
                    ForEach(Subject.Category.allCases, id: \.self) { category in
                        categorySection(category)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Learn")
            .navigationSubtitle("\(progress.count) levels completed")
            .navigationDestination(for: Subject.self) { PathView(subject: $0) }
            .fullScreenCover(item: $session) { QuizView(session: $0) }
        }
        #if DEBUG
        .task {
            // Dev shortcut: launch with `-tab learn -path python` to open a subject's path.
            if let raw = UserDefaults.standard.string(forKey: "path"), let s = Subject(rawValue: raw) {
                path = [s]
            }
        }
        #endif
    }

    // MARK: Areas to improve

    private var improveSection: some View {
        let weak = LearningPath.weakSubjects(in: questions)
        return VStack(alignment: .leading, spacing: 10) {
            Label("Areas to improve", systemImage: "chart.bar.xaxis")
                .font(.title3.bold())

            if weak.isEmpty {
                Text("Play a few levels and your weakest subjects will show up here, with a practice round built from the questions you miss most.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()
            } else {
                ForEach(weak, id: \.subject) { item in
                    HStack(spacing: 12) {
                        IconBadge(icon: item.subject.icon, color: item.subject.color, size: 42)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(item.subject.displayName).font(.headline)
                                Spacer()
                                Text("\(item.stats.percent)%")
                                    .font(.headline.monospacedDigit())
                                    .foregroundStyle(color(for: item.stats.percent))
                            }
                            ProgressView(value: Double(item.stats.percent), total: 100)
                                .tint(color(for: item.stats.percent))
                            Text("\(item.stats.correct) of \(item.stats.answered) answers correct")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Button("Practice") {
                            let pool = bySubject[item.subject] ?? []
                            session = QuizSession(title: "\(item.subject.displayName): weak spots",
                                                  questions: LearningPath.weakSpots(in: pool),
                                                  mode: .practice, subject: item.subject)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                    }
                    .card()
                }
            }
        }
    }

    private func color(for percent: Int) -> Color {
        percent < 50 ? .red : percent < 70 ? .orange : .yellow
    }

    // MARK: Subjects

    private func categorySection(_ category: Subject.Category) -> some View {
        let subjects = Subject.allCases.filter { $0.category == category }
        return VStack(alignment: .leading, spacing: 10) {
            Label(category.rawValue, systemImage: category.icon)
                .font(.title3.bold())

            VStack(spacing: 0) {
                ForEach(subjects) { subject in
                    let total = LearningPath.levels(for: bySubject[subject] ?? []).count
                    let done = progress.filter { $0.subjectRaw == subject.rawValue && $0.level < total }
                    NavigationLink(value: subject) {
                        HStack(spacing: 12) {
                            IconBadge(icon: subject.icon, color: subject.color)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(subject.displayName)
                                ProgressView(value: Double(done.count), total: Double(max(total, 1)))
                                    .tint(subject.color)
                            }
                            Spacer(minLength: 8)
                            if total > 0, done.count == total {
                                Image(systemName: "trophy.fill").foregroundStyle(.yellow)
                            }
                            Text("\(done.count)/\(total)")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .disabled(total == 0)

                    if subject != subjects.last {
                        Divider().padding(.leading, 62)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
        }
    }
}

/// One subject's levels as a winding path. Finish a level to unlock the next.
struct PathView: View {
    let subject: Subject

    @Query private var questions: [Question]
    @Query private var progress: [LevelProgress]
    @State private var session: QuizSession?

    /// Sideways shift of each node, repeating, so the path winds left and right.
    private static let sway: [CGFloat] = [0, 55, 85, 55, 0, -55, -85, -55]

    private var levels: [[Question]] {
        LearningPath.levels(for: questions.filter { $0.subject == subject })
    }

    private var stars: [Int: Int] {
        Dictionary(progress.filter { $0.subjectRaw == subject.rawValue }.map { ($0.level, $0.stars) },
                   uniquingKeysWith: max)
    }

    var body: some View {
        let levels = levels
        let stars = stars
        let current = LearningPath.currentLevel(count: levels.count, completed: Set(stars.keys))
        let stats = LearningPath.stats(for: levels.flatMap { $0 })

        ScrollView {
            VStack(spacing: 22) {
                header(done: min(current, levels.count), total: levels.count, stats: stats)

                ForEach(levels.indices, id: \.self) { i in
                    node(index: i, questions: levels[i], stars: stars[i], isCurrent: i == current,
                         locked: i > current)
                        .offset(x: Self.sway[i % Self.sway.count])
                }

                if !levels.isEmpty {
                    VStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(current >= levels.count ? Color.yellow : Color(.systemFill))
                        Text(current >= levels.count ? "Path complete!" : "Finish every level to earn the trophy")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(subject.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $session) { QuizView(session: $0) }
    }

    private func header(done: Int, total: Int, stats: LearningPath.Stats) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(subject.category.rawValue.uppercased(), systemImage: subject.icon)
                .font(.caption.bold())
                .opacity(0.85)
            Text(subject.displayName).font(.title.bold())
            Text("\(done) of \(total) levels" + (stats.answered > 0 ? " · \(stats.percent)% accuracy" : ""))
                .font(.subheadline)
                .opacity(0.9)
            ProgressView(value: Double(done), total: Double(max(total, 1)))
                .tint(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gradientCard([subject.color, subject.color.opacity(0.65)])
    }

    private func node(index: Int, questions: [Question], stars: Int?, isCurrent: Bool, locked: Bool) -> some View {
        let fill: Color = locked ? Color(.systemGray4) : subject.color
        return Button {
            session = QuizSession(title: "\(subject.displayName) · Level \(index + 1)",
                                  questions: questions, mode: .level, subject: subject, level: index)
        } label: {
            VStack(spacing: 6) {
                if isCurrent {
                    Text("START")
                        .font(.caption.bold())
                        .foregroundStyle(subject.color)
                        .padding(.horizontal, 12).padding(.vertical, 5)
                        .background(Color(.secondarySystemGroupedBackground), in: .capsule)
                        .overlay(Capsule().stroke(subject.color.opacity(0.4)))
                }
                ZStack {
                    // Darker disc underneath gives the node a raised look.
                    Circle().fill(fill.opacity(0.55)).offset(y: 6)
                    Circle().fill(fill.gradient)
                    Image(systemName: locked ? "lock.fill" : stars != nil ? "checkmark" : "play.fill")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(.white)
                        .symbolEffect(.pulse, isActive: isCurrent)
                }
                .frame(width: 78, height: 78)
                .padding(.bottom, 6)
                .overlay {
                    if isCurrent {
                        Circle().stroke(subject.color.opacity(0.35), lineWidth: 5).padding(-8).offset(y: -3)
                    }
                }

                Text("Level \(index + 1)").font(.subheadline.weight(.semibold))
                if let stars {
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { s in
                            Image(systemName: s < stars ? "star.fill" : "star")
                                .foregroundStyle(s < stars ? .yellow : .secondary)
                        }
                    }
                    .font(.caption)
                } else {
                    Text("\(questions.count) questions").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(locked)
        .accessibilityLabel("Level \(index + 1), \(locked ? "locked" : stars != nil ? "completed" : "ready")")
    }
}
