import SwiftUI

/// What a question view reports back to QuizView when you finish answering.
struct AnswerOutcome {
    let correct: Bool
    var usedHint = false
}

/// Picks the right interaction for the question's kind.
struct QuestionBody: View {
    let question: Question
    /// true once answered or time ran out. Shows the solution and locks input.
    let revealed: Bool
    let onAnswer: (AnswerOutcome) -> Void

    var body: some View {
        switch question.kind {
        case .multipleChoice: MultipleChoiceView(question: question, revealed: revealed, onAnswer: onAnswer)
        case .fillBlank: FillBlankView(question: question, revealed: revealed, onAnswer: onAnswer)
        case .buildCode: BuildCodeView(question: question, revealed: revealed, onAnswer: onAnswer)
        case .match: MatchView(question: question, revealed: revealed, onAnswer: onAnswer)
        }
    }
}

// MARK: - Multiple choice

struct MultipleChoiceView: View {
    let question: Question
    let revealed: Bool
    let onAnswer: (AnswerOutcome) -> Void
    @State private var selected: Int?
    /// Display order (indices into choices), shuffled once so the answer isn't always in the same spot.
    @State private var order: [Int]

    init(question: Question, revealed: Bool, onAnswer: @escaping (AnswerOutcome) -> Void) {
        self.question = question
        self.revealed = revealed
        self.onAnswer = onAnswer
        _order = State(initialValue: Array(question.choices.indices).shuffled())
    }

    var body: some View {
        VStack(spacing: 10) {
            if let code = question.code, !code.isEmpty { CodeBlock(code: code) }
            ForEach(Array(order.enumerated()), id: \.offset) { position, i in
                AnswerButton(letter: String(UnicodeScalar(UInt8(65 + position % 26))), text: question.choices[i], state: state(for: i)) {
                    selected = i
                    onAnswer(AnswerOutcome(correct: i == question.correctIndex))
                }
                .disabled(revealed)
            }
        }
    }

    private func state(for i: Int) -> AnswerButton.State {
        guard revealed else { return .idle }
        if i == question.correctIndex { return .correct }
        if i == selected { return .wrong }
        return .dimmed
    }
}

// MARK: - Fill in the blank

struct FillBlankView: View {
    let question: Question
    let revealed: Bool
    let onAnswer: (AnswerOutcome) -> Void

    @State private var typed = ""
    @State private var usedHint = false
    @State private var wasCorrect: Bool?
    @FocusState private var focused: Bool

    private var template: String { question.code ?? question.prompt }
    private var hint: String {
        guard let a = question.answers.first, let first = a.first else { return "" }
        return "Starts with \"\(first)\", \(a.count) character\(a.count == 1 ? "" : "s")"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Live preview with your answer dropped into the blank.
            CodeBlock(code: template.replacingOccurrences(of: "___", with: typed.isEmpty ? "____" : typed))
                .overlay {
                    if let wasCorrect {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(wasCorrect ? .green : .red, lineWidth: 2)
                    }
                }

            HStack {
                TextField("Type the missing code", text: $typed)
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.asciiCapable)
                    .focused($focused)
                    .submitLabel(.done)
                    .onSubmit(submit)
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 12))
                Button("Check", action: submit)
                    .buttonStyle(.borderedProminent)
                    .disabled(typed.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .disabled(revealed)

            if !revealed {
                if usedHint {
                    Label(hint, systemImage: "lightbulb.fill").foregroundStyle(.yellow)
                } else {
                    Button("Hint (half points)", systemImage: "lightbulb") { usedHint = true }
                        .font(.subheadline)
                }
            }
        }
        .onAppear { focused = true }
    }

    private func submit() {
        guard !revealed, !typed.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let ok = question.accepts(typed)
        wasCorrect = ok
        focused = false
        onAnswer(AnswerOutcome(correct: ok, usedHint: usedHint))
    }
}

// MARK: - Code builder

struct BuildCodeView: View {
    let question: Question
    let revealed: Bool
    let onAnswer: (AnswerOutcome) -> Void

    private struct Tile: Identifiable, Equatable {
        let id: Int
        let text: String
    }

    @State private var bank: [Tile]
    @State private var placed: [Tile] = []
    @State private var wasCorrect: Bool?

    init(question: Question, revealed: Bool, onAnswer: @escaping (AnswerOutcome) -> Void) {
        self.question = question
        self.revealed = revealed
        self.onAnswer = onAnswer
        let all = question.answers + question.extras
        _bank = State(initialValue: all.enumerated().map { Tile(id: $0.offset, text: $0.element) }.shuffled())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Surrounding code for context, when the question has some.
            if let code = question.code, !code.isEmpty { CodeBlock(code: code) }
            Text("Your code").font(.caption).foregroundStyle(.secondary)
            FlowLayout {
                ForEach(placed) { tile in
                    tileButton(tile, filled: true) {
                        placed.removeAll { $0 == tile }
                        bank.append(tile)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .topLeading)
            .padding(10)
            .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, style: StrokeStyle(lineWidth: 2, dash: wasCorrect == nil ? [6] : []))
            }

            Text("Tiles: tap to add").font(.caption).foregroundStyle(.secondary)
            FlowLayout {
                ForEach(bank) { tile in
                    tileButton(tile, filled: false) {
                        bank.removeAll { $0 == tile }
                        placed.append(tile)
                        Sound.shared.play(.tick)
                    }
                }
            }

            if !revealed {
                HStack {
                    Button("Clear") {
                        bank += placed
                        placed = []
                    }
                    .disabled(placed.isEmpty)
                    Spacer()
                    Button("Check", action: check)
                        .buttonStyle(.borderedProminent)
                        .disabled(placed.isEmpty)
                }
            }
        }
        .animation(.snappy, value: placed)
        .disabled(revealed)
    }

    private var borderColor: Color {
        switch wasCorrect {
        case .none: .secondary
        case .some(true): .green
        case .some(false): .red
        }
    }

    private func tileButton(_ tile: Tile, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(tile.text)
                .font(.system(.callout, design: .monospaced))
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(filled ? Color.accentColor.opacity(0.2) : Color(.secondarySystemGroupedBackground),
                            in: .rect(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.tertiary))
        }
        .buttonStyle(.plain)
        .matchedGeometryEffect(id: tile.id, in: ns)
    }

    @Namespace private var ns

    private func check() {
        let ok = placed.map(\.text) == question.answers
        wasCorrect = ok
        onAnswer(AnswerOutcome(correct: ok))
    }
}

// MARK: - Match-up

struct MatchView: View {
    let question: Question
    let revealed: Bool
    let onAnswer: (AnswerOutcome) -> Void

    /// Right-column order (indices into extras), shuffled once.
    @State private var rightOrder: [Int]
    @State private var selectedLeft: Int?
    @State private var selectedRight: Int?
    @State private var matched: Set<Int> = []
    @State private var wrongPair: (Int, Int)?
    @State private var mistakes = 0

    /// You can make one mistake and still count the question as correct.
    static let allowedMistakes = 1

    init(question: Question, revealed: Bool, onAnswer: @escaping (AnswerOutcome) -> Void) {
        self.question = question
        self.revealed = revealed
        self.onAnswer = onAnswer
        _rightOrder = State(initialValue: Array(question.extras.indices).shuffled())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Tap one on each side")
                Spacer()
                Text("Mistakes: \(mistakes)").foregroundStyle(mistakes > Self.allowedMistakes ? .red : .secondary)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: 10) {
                VStack(spacing: 8) {
                    ForEach(question.answers.indices, id: \.self) { i in
                        cell(question.answers[i], mono: true, isSelected: selectedLeft == i,
                             isMatched: matched.contains(i), isWrong: wrongPair?.0 == i) {
                            selectedLeft = i
                            evaluate()
                        }
                    }
                }
                VStack(spacing: 8) {
                    ForEach(rightOrder, id: \.self) { j in
                        cell(question.extras[j], mono: false, isSelected: selectedRight == j,
                             isMatched: matched.contains(j), isWrong: wrongPair?.1 == j) {
                            selectedRight = j
                            evaluate()
                        }
                    }
                }
            }
        }
        .disabled(revealed)
    }

    private func cell(_ text: String, mono: Bool, isSelected: Bool, isMatched: Bool, isWrong: Bool,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(mono ? .system(.footnote, design: .monospaced) : .footnote)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .padding(8)
                .background(background(isSelected: isSelected, isMatched: isMatched, isWrong: isWrong),
                            in: .rect(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2))
                .opacity(isMatched || revealed ? 0.55 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isMatched)
        .animation(.snappy, value: isMatched)
        .animation(.snappy, value: isWrong)
    }

    private func background(isSelected: Bool, isMatched: Bool, isWrong: Bool) -> Color {
        if isMatched { return .green.opacity(0.3) }
        if isWrong { return .red.opacity(0.35) }
        return Color(.secondarySystemGroupedBackground)
    }

    private func evaluate() {
        guard let l = selectedLeft, let r = selectedRight else { return }
        selectedLeft = nil
        selectedRight = nil
        if l == r {
            matched.insert(l)
            Sound.shared.play(.tick)
            if matched.count == question.answers.count {
                onAnswer(AnswerOutcome(correct: mistakes <= Self.allowedMistakes))
            }
        } else {
            mistakes += 1
            wrongPair = (l, r)
            Sound.shared.play(.wrong)
            Task {
                try? await Task.sleep(for: .milliseconds(450))
                wrongPair = nil
            }
        }
    }
}
