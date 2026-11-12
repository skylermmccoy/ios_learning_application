import SwiftUI
import SwiftData
import Combine

/// Everything needed to start a quiz. Created when you tap, so the question set stays fixed.
struct QuizSession: Identifiable {
    let id = UUID()
    let title: String
    let questions: [Question]
    let mode: QuizMode
    let subject: Subject?
    /// Set when this quiz is a level on a subject's path (0-based).
    var level: Int? = nil
}

struct QuizView: View {
    let session: QuizSession

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var attempts: [Attempt]

    @State private var game = GameState()
    @State private var index = 0
    @State private var results: [Bool] = []
    @State private var revealed = false
    @State private var lastCorrect = false
    @State private var timedOut = false
    @State private var timeLeft: Double = 0
    @State private var startedAt = Date.now
    @State private var xpBefore = 0
    @State private var finished = false
    @State private var wide = false

    private let ticker = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    private var isTimed: Bool { session.mode == .timed }
    private var question: Question { session.questions[index] }
    private var isLast: Bool { index + 1 >= session.questions.count || game.isOver }

    var body: some View {
        NavigationStack {
            Group {
                if session.questions.isEmpty {
                    ContentUnavailableView("No questions yet", systemImage: "questionmark.folder")
                } else if finished {
                    ResultView(game: game, total: session.questions.count,
                               duration: Date.now.timeIntervalSince(startedAt),
                               xpBefore: xpBefore,
                               levelStars: session.level == nil ? nil : max(0, game.lives)) { dismiss() }
                } else {
                    questionScreen
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(session.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }
                }
                if !finished, !session.questions.isEmpty {
                    ToolbarItem(placement: .principal) { hearts }
                    ToolbarItem(placement: .topBarTrailing) { scoreLabel }
                }
            }
        }
        .onAppear {
            xpBefore = attempts.reduce(0) { $0 + $1.points }
            if !session.questions.isEmpty { timeLeft = question.kind.timeLimit }
        }
        .onReceive(ticker) { _ in tick() }
        .sensoryFeedback(.success, trigger: game.correct)
        .sensoryFeedback(.error, trigger: game.wrong)
    }

    // MARK: Toolbar pieces

    private var hearts: some View {
        HStack(spacing: 3) {
            ForEach(0..<GameState.maxLives, id: \.self) { i in
                Image(systemName: i < game.lives ? "heart.fill" : "heart")
                    .foregroundStyle(i < game.lives ? .red : .secondary)
            }
        }
        .font(.subheadline)
        .symbolEffect(.bounce, value: game.lives)
        .accessibilityLabel("\(max(0, game.lives)) lives left")
    }

    private var scoreLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill").foregroundStyle(.yellow)
            Text("\(game.score)")
                .font(.subheadline.bold().monospacedDigit())
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 6)
        .animation(.spring, value: game.score)
    }

    // MARK: Question

    private var questionScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SegmentedProgress(total: session.questions.count, results: results)

                HStack(spacing: 8) {
                    chip(question.kind.label, icon: question.kind.icon, color: question.kind.color)
                    chip(question.subject.displayName, icon: question.subject.icon, color: question.subject.color)
                    Spacer()
                    if game.multiplier > 1 {
                        Text("🔥 x\(game.multiplier)")
                            .font(.caption.bold())
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(.orange.opacity(0.25), in: .capsule)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring, value: game.multiplier)

                if isTimed {
                    TimerBar(fraction: timeLeft / question.kind.timeLimit)
                }

                // Wide: question on the left, answers on the right. Narrow: stacked.
                Columns(wide: wide) {
                    promptCard
                    if revealed, wide { feedback }
                } trailing: {
                    QuestionBody(question: question, revealed: revealed, onAnswer: handle)
                    if revealed, !wide { feedback }
                }
            }
            .padding()
        }
        .id(index) // fresh question view and scroll position each time
        .trackWide($wide)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            if revealed {
                Button(action: next) {
                    Text(isLast ? "See results" : "Next")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    /// The question itself, on a card with a stripe in the subject's colour.
    private var promptCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("QUESTION \(index + 1) OF \(session.questions.count)")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(question.prompt)
                .font(.title3.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .padding(.leading, 22)
        .padding(.trailing, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .overlay(alignment: .leading) { question.subject.color.frame(width: 6) }
        .clipShape(.rect(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }

    private func chip(_ text: String, icon: String, color: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(color.opacity(0.15), in: .capsule)
    }

    private var feedback: some View {
        let tint: Color = lastCorrect ? .green : .red
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(timedOut ? "Time's up" : lastCorrect ? "Correct" : "Not quite",
                      systemImage: timedOut ? "clock.badge.xmark" : lastCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(tint)
                Spacer()
                if lastCorrect {
                    Text("+\(game.lastPoints)")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(tint)
                }
            }
            if !lastCorrect, question.kind != .multipleChoice {
                Text("Answer").font(.caption).foregroundStyle(.secondary)
                CodeBlock(code: question.solutionText)
            }
            Text(question.explanation)
            if let link = question.referenceLink {
                Link(destination: link) {
                    Label("Read more on \(link.host()?.replacingOccurrences(of: "www.", with: "") ?? "the web")",
                          systemImage: "book")
                        .font(.subheadline.weight(.medium))
                }
            }
            if game.isOver {
                Label("Out of lives", systemImage: "heart.slash.fill")
                    .font(.headline).foregroundStyle(.red)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.12), in: .rect(cornerRadius: 18))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: Logic

    private func handle(_ outcome: AnswerOutcome) {
        guard !revealed else { return }
        let oldMultiplier = game.multiplier
        game.record(question, correct: outcome.correct, usedHint: outcome.usedHint,
                    timeFraction: isTimed ? timeLeft / question.kind.timeLimit : nil)
        question.recordAnswer(correct: outcome.correct)
        try? context.save()
        lastCorrect = outcome.correct
        results.append(outcome.correct)
        if outcome.correct {
            Sound.shared.play(game.multiplier > oldMultiplier ? .combo : .correct)
        } else {
            Sound.shared.play(.wrong)
        }
        withAnimation(.snappy) { revealed = true }
    }

    private func tick() {
        guard isTimed, !finished, !revealed, !session.questions.isEmpty else { return }
        timeLeft -= 0.1
        if timeLeft <= 0 {
            timedOut = true
            handle(AnswerOutcome(correct: false))
        }
    }

    /// Finishing a level with at least one heart left completes it. Stars = hearts left.
    private func saveLevelProgress() {
        guard let level = session.level, let subject = session.subject, !game.isOver else { return }
        let raw = subject.rawValue
        let existing = try? context.fetch(FetchDescriptor<LevelProgress>(
            predicate: #Predicate { $0.subjectRaw == raw && $0.level == level })).first
        if let existing {
            existing.stars = max(existing.stars, game.lives)
        } else {
            context.insert(LevelProgress(subject: subject, level: level, stars: game.lives))
        }
    }

    private func next() {
        if isLast {
            context.insert(Attempt(subject: session.subject, mode: session.mode,
                                   score: game.correct, total: session.questions.count,
                                   duration: Date.now.timeIntervalSince(startedAt),
                                   points: game.score, maxCombo: game.maxCombo,
                                   title: session.title))
            saveLevelProgress()
            try? context.save()
            finished = true
        } else {
            index += 1
            revealed = false
            timedOut = false
            timeLeft = question.kind.timeLimit
        }
    }
}
