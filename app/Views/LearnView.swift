import SwiftUI
import SwiftData

/// The Learn tab: pick up where you left off, see your totals, then browse every subject by category.
struct LearnView: View {
    @Query private var questions: [Question]
    @Query private var progress: [LevelProgress]
    @State private var path: [Subject] = []
    @State private var session: QuizSession?

    /// The subject offered to someone who hasn't started anything. Algorithms come first for the owner.
    private static let firstSubject: Subject = .bigO

    var body: some View {
        let bySubject = Dictionary(grouping: questions, by: \.subject)
        let levels = Dictionary(uniqueKeysWithValues: bySubject.map { subject, qs in
            (subject, LearningPath.path(for: qs, notes: LessonLibrary.notes(for: subject)))
        })
        let records = Dictionary(grouping: progress, by: \.subjectRaw)
        let summary = Dictionary(uniqueKeysWithValues: Subject.allCases.map { subject in
            (subject, LearningPath.progress(levelCount: levels[subject]?.count ?? 0,
                                            records: records[subject.rawValue] ?? []))
        })
        let weak = LearningPath.weakSubjects(in: questions)

        NavigationStack(path: $path) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(spacing: 12) {
                            continueCard(summary: summary, levels: levels)
                            totals(summary)
                        }
                        categoryChips(proxy)
                        if !weak.isEmpty { improveSection(weak, bySubject: bySubject) }
                        ForEach(Subject.Category.allCases, id: \.self) { category in
                            categorySection(category, summary: summary).id(category)
                        }
                        if weak.isEmpty { improveHint }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                    .frame(maxWidth: 760)
                    .frame(maxWidth: .infinity)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Learn")
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

    // MARK: Continue

    private func continueCard(summary: [Subject: LearningPath.Progress],
                              levels: [Subject: [LearningPath.PathLevel]]) -> some View {
        let resumed = LearningPath.resumeSubject(records: progress, levelCounts: levels.mapValues(\.count))
        let subject = resumed ?? Self.firstSubject
        let state = summary[subject] ?? LearningPath.Progress(done: 0, total: 0, stars: 0)
        let subjectLevels = levels[subject] ?? []
        let done = Set(progress.filter { $0.subjectRaw == subject.rawValue }.map(\.level))
        let nextIndex = LearningPath.currentLevel(count: subjectLevels.count, completed: done)
        let next = subjectLevels.indices.contains(nextIndex) ? subjectLevels[nextIndex] : nil

        return Button { path = [subject] } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(resumed == nil ? "START HERE" : "CONTINUE")
                        .font(.caption.bold())
                        .opacity(0.85)
                    Text(subject.displayName)
                        .font(.title2.bold())
                        .multilineTextAlignment(.leading)
                    if let next {
                        Text(next.style == .lesson
                             ? "Next: \(next.title) · \(LearningPath.unitName(next.unit))"
                             : "Next: \(next.title)")
                            .font(.subheadline)
                            .opacity(0.9)
                            .multilineTextAlignment(.leading)
                    }
                    Label(resumed == nil ? "Start" : "Continue", systemImage: "play.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.black)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(.white, in: .capsule)
                        .padding(.top, 6)
                }
                Spacer(minLength: 0)
                ZStack {
                    ProgressRing(value: state.fraction, color: .white, track: .white.opacity(0.25), lineWidth: 8)
                    Image(systemName: subject.icon)
                        .font(.system(size: 30, weight: .semibold))
                }
                .frame(width: 84, height: 84)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .gradientCard([subject.color, subject.color.opacity(0.7)])
        }
        .buttonStyle(.plain)
        .disabled(subjectLevels.isEmpty)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the \(subject.displayName) path")
    }

    // MARK: Totals

    private func totals(_ summary: [Subject: LearningPath.Progress]) -> some View {
        let all = summary.values
        let done = all.reduce(0) { $0 + $1.done }
        let total = all.reduce(0) { $0 + $1.total }
        let stars = all.reduce(0) { $0 + $1.stars }
        let trophies = all.filter(\.isComplete).count
        return HStack(spacing: 12) {
            totalTile("\(done)", detail: "of \(total) levels", icon: "checkmark.circle.fill", color: .green)
            totalTile("\(stars)", detail: "stars", icon: "star.fill", color: .yellow)
            totalTile("\(trophies)", detail: trophies == 1 ? "path done" : "paths done", icon: "trophy.fill",
                      color: .orange)
        }
    }

    private func totalTile(_ value: String, detail: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value)
                .font(.title2.bold().monospacedDigit())
                .contentTransition(.numericText())
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }

    // MARK: Jump to a category

    private func categoryChips(_ proxy: ScrollViewProxy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Subject.Category.allCases, id: \.self) { category in
                    Button {
                        withAnimation(.snappy) { proxy.scrollTo(category, anchor: .top) }
                    } label: {
                        Label(category.rawValue, systemImage: category.icon)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(category.color)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(category.color.opacity(0.14), in: .capsule)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Scrolls to this category")
                }
            }
            .padding(.horizontal)
        }
        .padding(.horizontal, -16)
    }

    // MARK: Areas to improve

    private func improveSection(_ weak: [(subject: Subject, stats: LearningPath.Stats)],
                                bySubject: [Subject: [Question]]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Areas to improve", icon: "chart.bar.xaxis", color: .red, trailing: nil)

            VStack(spacing: 0) {
                ForEach(weak, id: \.subject) { item in
                    HStack(spacing: 12) {
                        ZStack {
                            ProgressRing(value: Double(item.stats.percent) / 100,
                                         color: color(for: item.stats.percent))
                            Text("\(item.stats.percent)")
                                .font(.caption.bold().monospacedDigit())
                        }
                        .frame(width: 42, height: 42)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.subject.displayName).font(.headline)
                            Text("\(item.stats.correct) of \(item.stats.answered) answers correct")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 8)
                        Button("Practice") {
                            let pool = bySubject[item.subject] ?? []
                            session = QuizSession(title: "\(item.subject.displayName): weak spots",
                                                  questions: LearningPath.weakSpots(in: pool),
                                                  mode: .practice, subject: item.subject)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 12)

                    if item.subject != weak.last?.subject {
                        Divider().padding(.leading, 68)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
        }
    }

    private var improveHint: some View {
        Label("Play a few levels and your weakest subjects will show up at the top, with a practice round built from the questions you miss most.",
              systemImage: "chart.bar.xaxis")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()
    }

    private func color(for percent: Int) -> Color {
        percent < 50 ? .red : percent < 70 ? .orange : .yellow
    }

    // MARK: Subjects

    private func sectionHeader(_ title: String, icon: String, color: Color, trailing: String?) -> some View {
        HStack(spacing: 10) {
            IconBadge(icon: icon, color: color, size: 30)
            Text(title).font(.title3.bold())
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private func categorySection(_ category: Subject.Category,
                                 summary: [Subject: LearningPath.Progress]) -> some View {
        let subjects = Subject.allCases.filter { $0.category == category }
        let done = subjects.reduce(0) { $0 + (summary[$1]?.done ?? 0) }
        let total = subjects.reduce(0) { $0 + (summary[$1]?.total ?? 0) }
        return VStack(alignment: .leading, spacing: 12) {
            sectionHeader(category.rawValue, icon: category.icon, color: category.color,
                          trailing: "\(done)/\(total)")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12, alignment: .top)], spacing: 12) {
                ForEach(subjects) { subject in
                    let state = summary[subject] ?? LearningPath.Progress(done: 0, total: 0, stars: 0)
                    NavigationLink(value: subject) {
                        SubjectCard(subject: subject, progress: state)
                    }
                    .buttonStyle(.plain)
                    .disabled(state.total == 0)
                }
            }
        }
    }
}

/// One subject in the Learn grid: icon, progress ring, name and level count.
private struct SubjectCard: View {
    let subject: Subject
    let progress: LearningPath.Progress

    private var status: String {
        if progress.total == 0 { return "No questions yet" }
        if progress.isComplete { return "Complete" }
        if progress.isStarted { return "\(progress.done) of \(progress.total) levels" }
        return "\(progress.total) levels"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                IconBadge(icon: subject.icon, color: subject.color, size: 44)
                Spacer()
                ZStack {
                    ProgressRing(value: progress.fraction, color: progress.isComplete ? .yellow : subject.color,
                                 lineWidth: 4)
                    if progress.isComplete {
                        Image(systemName: "trophy.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    } else if progress.isStarted {
                        Text("\(Int((progress.fraction * 100).rounded()))")
                            .font(.caption2.bold().monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 34, height: 34)
            }
            Text(subject.displayName)
                .font(.headline)
                .multilineTextAlignment(.leading)
                .lineLimit(2, reservesSpace: true)
            HStack(spacing: 4) {
                Text(status)
                Spacer(minLength: 4)
                if progress.stars > 0 {
                    Image(systemName: "star.fill").foregroundStyle(.yellow)
                    Text("\(progress.stars)").monospacedDigit()
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
        .contentShape(.rect(cornerRadius: 20))
        .opacity(progress.total == 0 ? 0.5 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(subject.displayName), \(status)"
                            + (progress.stars > 0 ? ", \(progress.stars) stars" : ""))
        .accessibilityAddTraits(.isButton)
    }
}
