import SwiftUI
import SwiftData

/// One subject's path: three units of lessons, timed reviews, and a final mastery challenge,
/// joined by a trail that fills in as you go. Tap a level to see what's in it, then start.
/// Finish a level with a heart left to unlock the next.
struct PathView: View {
    let subject: Subject

    @Query private var questions: [Question]
    @Query private var progress: [LevelProgress]
    @State private var selected: Selection?
    /// Set by the level sheet's buttons; the lesson opens once the sheet has gone.
    @State private var pending: LessonStart?
    @State private var lesson: LessonStart?

    /// The level whose sheet is showing.
    private struct Selection: Identifiable {
        let index: Int
        let level: LearningPath.PathLevel
        let stars: Int?
        var id: Int { index }
    }

    /// Sideways shift of each node, repeating, so the path winds left and right.
    private static let sway: [CGFloat] = [0, 55, 85, 55, 0, -55, -85, -55]

    var body: some View {
        let mine = questions.filter { $0.subject == subject }
        let notes = LessonLibrary.notes(for: subject)
        let levels = LearningPath.path(for: mine, notes: notes)
        let records = progress.filter { $0.subjectRaw == subject.rawValue }
        let stars = Dictionary(records.filter { $0.level < levels.count }.map { ($0.level, $0.stars) },
                               uniquingKeysWith: max)
        let current = LearningPath.currentLevel(count: levels.count, completed: Set(stars.keys))
        let summary = LearningPath.progress(levelCount: levels.count, records: records)
        let stats = LearningPath.stats(for: mine)

        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 26) {
                    header(summary, stats: stats)

                    ForEach(levels.indices, id: \.self) { i in
                        if i == 0 || levels[i - 1].unit != levels[i].unit {
                            unitHeader(levels[i].unit, levels: levels, stars: stars)
                        }
                        node(index: i, level: levels[i], stars: stars[i], isCurrent: i == current,
                             locked: i > current)
                            .offset(x: Self.sway[i % Self.sway.count])
                            .id(i)
                    }

                    if !levels.isEmpty { trophy(complete: summary.isComplete) }
                }
                .padding()
                .frame(maxWidth: 520)
                .backgroundPreferenceValue(NodeCenters.self) { anchors in
                    GeometryReader { geo in
                        Trail(points: anchors.mapValues { geo[$0] }, count: levels.count,
                              done: Set(stars.keys), color: subject.color)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .task {
                // Open on the level you're up to rather than the top of a long path.
                guard current > 1, current < levels.count else { return }
                try? await Task.sleep(for: .milliseconds(250))
                withAnimation(.smooth) { proxy.scrollTo(current, anchor: .center) }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(subject.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selected, onDismiss: {
            lesson = pending
            pending = nil
        }) { choice in
            let levelNotes = LessonLibrary.notes(for: choice.level, in: subject)
            LevelSheet(subject: subject, level: choice.level, notes: levelNotes, bestStars: choice.stars) { teachFirst in
                let session = QuizSession(title: "\(subject.displayName) · \(choice.level.title)",
                                          questions: choice.level.questions,
                                          mode: choice.level.isTimed ? .timed : .level,
                                          subject: subject, level: choice.index)
                pending = LessonStart(session: session, notes: levelNotes, teachFirst: teachFirst)
                selected = nil
            }
        }
        .fullScreenCover(item: $lesson) { LessonFlowView(start: $0) }
    }

    // MARK: Header

    private func header(_ summary: LearningPath.Progress, stats: LearningPath.Stats) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Label(subject.category.rawValue.uppercased(), systemImage: subject.category.icon)
                        .font(.caption.bold())
                        .opacity(0.85)
                    Text(subject.displayName).font(.title.bold())
                    Text(subject.tagline)
                        .font(.subheadline)
                        .opacity(0.9)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                ZStack {
                    ProgressRing(value: summary.fraction, color: .white, track: .white.opacity(0.25), lineWidth: 7)
                    Text("\(Int((summary.fraction * 100).rounded()))%")
                        .font(.system(.headline, design: .rounded).bold().monospacedDigit())
                }
                .frame(width: 68, height: 68)
                .accessibilityElement()
                .accessibilityLabel("\(Int((summary.fraction * 100).rounded())) percent complete")
            }
            HStack(spacing: 8) {
                headerStat("\(summary.done)/\(summary.total)", label: "levels", icon: "checkmark.circle.fill")
                headerStat("\(summary.stars)/\(summary.total * 3)", label: "stars", icon: "star.fill")
                if stats.answered > 0 {
                    headerStat("\(stats.percent)%", label: "accuracy", icon: "scope")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gradientCard([subject.color, subject.color.opacity(0.65)])
    }

    private func headerStat(_ value: String, label: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(value, systemImage: icon)
                .font(.subheadline.bold().monospacedDigit())
            Text(label).font(.caption2).opacity(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(.white.opacity(0.18), in: .rect(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    // MARK: Units

    private func unitHeader(_ unit: Int, levels: [LearningPath.PathLevel], stars: [Int: Int]) -> some View {
        let indices = levels.indices.filter { levels[$0].unit == unit }
        let done = indices.filter { stars[$0] != nil }.count
        let complete = done == indices.count
        return HStack(spacing: 12) {
            Text("\(unit)")
                .font(.system(.title3, design: .rounded).bold())
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(subject.color.gradient, in: .rect(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(LearningPath.unitName(unit)).font(.headline)
                Text(LearningPath.unitBlurb(unit))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            if complete {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            } else {
                Text("\(done)/\(indices.count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Unit \(unit), \(LearningPath.unitName(unit)), \(done) of \(indices.count) levels done")
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: Nodes

    private func node(index: Int, level: LearningPath.PathLevel, stars: Int?, isCurrent: Bool,
                      locked: Bool) -> some View {
        let special = level.style != .lesson
        let fill: Color = locked ? Color(.systemGray4) : level.style == .mastery ? .yellow : subject.color
        let size: CGFloat = special ? 88 : 76
        return Button {
            selected = Selection(index: index, level: level, stars: stars)
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    // Darker disc underneath gives the node a raised look.
                    Circle().fill(fill).brightness(-0.18).offset(y: 6)
                    Circle().fill(fill.gradient)
                    Circle().strokeBorder(.white.opacity(locked ? 0 : 0.25), lineWidth: 3)
                    Image(systemName: locked ? "lock.fill" : stars != nil ? "checkmark" : level.icon)
                        .font(.system(size: special ? 32 : 28, weight: .heavy))
                        .foregroundStyle(.white)
                }
                .frame(width: size, height: size)
                .padding(.bottom, 6)
                .background {
                    if isCurrent {
                        Circle().stroke(subject.color.opacity(0.3), lineWidth: 5).padding(-9).offset(y: -3)
                    }
                }
                .anchorPreference(key: NodeCenters.self, value: .center) { [index: $0] }
                .overlay(alignment: .top) {
                    if isCurrent {
                        Text(index == 0 ? "START" : "UP NEXT")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12).padding(.vertical, 5)
                            .background(subject.color, in: .capsule)
                            .overlay(Capsule().stroke(Color(.systemGroupedBackground), lineWidth: 3))
                            .fixedSize()
                            .offset(y: -20)
                    }
                }

                // The caption sits on the page colour so the trail passes behind it.
                VStack(spacing: 3) {
                    Text(level.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(locked ? .secondary : .primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(maxWidth: 170)
                    if let stars {
                        StarRow(filled: stars).font(.caption)
                    } else {
                        Text("\(level.questions.count) questions" + (level.isTimed ? " · timed" : ""))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Color(.systemGroupedBackground), in: .capsule)
            }
            .padding(.top, isCurrent ? 14 : 0)
        }
        .buttonStyle(NodeButtonStyle())
        .disabled(locked)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(level.title), \(locked ? "locked" : stars.map { "completed, \($0) of 3 stars" } ?? "ready")")
        .accessibilityAddTraits(.isButton)
    }

    private func trophy(complete: Bool) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 44))
                .foregroundStyle(complete ? Color.yellow : Color(.systemFill))
                .symbolEffect(.bounce, value: complete)
            Text(complete ? "Path complete!" : "Finish every level to earn the trophy")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Color(.systemGroupedBackground), in: .rect(cornerRadius: 16))
    }
}

extension LearningPath.PathLevel {
    /// SF Symbol for a level you can play.
    var icon: String {
        switch style {
        case .lesson: "play.fill"
        case .review: "arrow.triangle.2.circlepath"
        case .mastery: "crown.fill"
        }
    }
}

/// Nodes sink a little when pressed, like a physical button.
private struct NodeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

/// Where each node's circle sits, so the trail can be drawn through them.
private struct NodeCenters: PreferenceKey {
    static var defaultValue: [Int: Anchor<CGPoint>] { [:] }
    static func reduce(value: inout [Int: Anchor<CGPoint>], nextValue: () -> [Int: Anchor<CGPoint>]) {
        value.merge(nextValue()) { $1 }
    }
}

/// The winding line behind the nodes: solid in the subject colour out of each finished level,
/// dotted grey ahead of you.
private struct Trail: View {
    let points: [Int: CGPoint]
    let count: Int
    let done: Set<Int>
    let color: Color

    var body: some View {
        Canvas { context, _ in
            guard count > 1 else { return }
            for i in 0..<(count - 1) {
                guard let a = points[i], let b = points[i + 1] else { continue }
                var segment = Path()
                segment.move(to: a)
                let midY = (a.y + b.y) / 2
                segment.addCurve(to: b, control1: CGPoint(x: a.x, y: midY), control2: CGPoint(x: b.x, y: midY))
                if done.contains(i) {
                    context.stroke(segment, with: .color(color.opacity(0.45)),
                                   style: StrokeStyle(lineWidth: 10, lineCap: .round))
                } else {
                    context.stroke(segment, with: .color(Color(.systemGray3)),
                                   style: StrokeStyle(lineWidth: 6, lineCap: .round, dash: [1, 14]))
                }
            }
        }
        .accessibilityHidden(true)
    }
}

/// What's inside a level, shown before it starts.
struct LevelSheet: View {
    let subject: Subject
    let level: LearningPath.PathLevel
    /// Teaching notes for this level. Empty = no cards, the sheet starts the questions directly.
    let notes: [TeachingNote]
    let bestStars: Int?
    /// `true` = show the teaching cards first.
    let start: (_ teachFirst: Bool) -> Void

    private var tint: Color { level.style == .mastery ? .yellow : subject.color }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 10) {
                    Image(systemName: level.icon)
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 72, height: 72)
                        .background(tint.gradient, in: .circle)
                    Text(level.title).font(.title2.bold())
                    Text("\(subject.displayName) · Unit \(level.unit): \(LearningPath.unitName(level.unit))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let bestStars {
                        StarRow(filled: bestStars).font(.title3)
                    }
                }

                HStack(spacing: 8) {
                    fact("\(level.questions.count)", label: "questions", icon: "questionmark.circle.fill", color: .blue)
                    fact(level.isTimed ? "Timed" : "No clock", label: level.isTimed ? "per question" : "take your time",
                         icon: level.isTimed ? "timer" : "tortoise.fill", color: level.isTimed ? .orange : .green)
                    fact("\(GameState.maxLives)", label: "hearts", icon: "heart.fill", color: .red)
                }

                if !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("YOU'LL LEARN").font(.caption.bold()).foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(notes) { note in
                                HStack(spacing: 12) {
                                    IconBadge(icon: "book.fill", color: subject.color, size: 34)
                                    Text(note.title).font(.subheadline.weight(.semibold))
                                    Spacer()
                                    Text("\(note.cards.count) cards")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 14).padding(.vertical, 10)
                                .accessibilityElement(children: .combine)
                                if note.id != notes.last?.id { Divider().padding(.leading, 60) }
                            }
                        }
                        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
                    }
                }

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(level.kindCounts, id: \.kind) { item in
                        HStack(spacing: 12) {
                            IconBadge(icon: item.kind.icon, color: item.kind.color, size: 34)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.kind.label).font(.subheadline.weight(.semibold))
                                Text(item.kind.blurb).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("× \(item.count)")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .accessibilityElement(children: .combine)
                        if item.kind != level.kindCounts.last?.kind {
                            Divider().padding(.leading, 60)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))

                Text(level.blurb + " Finish with a heart left to pass; hearts left become stars.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal)
            .padding(.top, 28)
            .padding(.bottom, 12)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 6) {
                // Not yet passed: teach first. Passed: play again, with the cards one tap away.
                let teachIsPrimary = !notes.isEmpty && bestStars == nil
                Button { start(teachIsPrimary) } label: {
                    Label(teachIsPrimary ? "Learn first" : bestStars == nil ? "Start" : "Play again",
                          systemImage: teachIsPrimary ? "book.fill" : "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .tint(subject.color)
                if !notes.isEmpty {
                    Button(teachIsPrimary ? "Skip to questions" : "Review the lesson first") {
                        start(!teachIsPrimary)
                    }
                    .font(.subheadline.weight(.semibold))
                    .tint(subject.color)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .background(Color(.systemGroupedBackground))
        }
        .background(Color(.systemGroupedBackground))
        .presentationDetents([.fraction(0.7), .large])
        .presentationDragIndicator(.visible)
    }

    private func fact(_ value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(.subheadline.bold())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }
}
