import Foundation
import SwiftData

/// How a question is answered.
enum QuestionKind: String, Codable, CaseIterable, Identifiable {
    /// Pick one of `choices`; `correctIndex` is right.
    case multipleChoice
    /// `code` (or `prompt` if no code) contains `___`. Any of `answers` is accepted.
    case fillBlank
    /// Tap tiles in order. `answers` is the correct tile order, `extras` are decoy tiles.
    case buildCode
    /// Match pairs. `answers[i]` (code) goes with `extras[i]` (output).
    case match

    var id: String { rawValue }

    var label: String {
        switch self {
        case .multipleChoice: "Quick Pick"
        case .fillBlank: "Fill the Blank"
        case .buildCode: "Code Builder"
        case .match: "Match-Up"
        }
    }

    var icon: String {
        switch self {
        case .multipleChoice: "list.bullet.circle"
        case .fillBlank: "character.cursor.ibeam"
        case .buildCode: "square.stack.3d.up"
        case .match: "arrow.left.arrow.right"
        }
    }

    var blurb: String {
        switch self {
        case .multipleChoice: "Pick the right answer fast"
        case .fillBlank: "Type the missing piece of code"
        case .buildCode: "Build the code from tiles"
        case .match: "Match code to its output"
        }
    }

    /// Seconds allowed in timed mode.
    var timeLimit: Double {
        switch self {
        case .multipleChoice: 20
        case .fillBlank: 30
        case .buildCode: 45
        case .match: 45
        }
    }
}

@Model
final class Question {
    var id: UUID
    var subjectRaw: String
    var kindRaw: String
    var prompt: String
    /// Optional code snippet shown in a monospaced block.
    var code: String?
    var choices: [String]
    var correctIndex: Int
    var answers: [String] = []
    var extras: [String] = []
    var explanation: String
    var isUserCreated: Bool
    var createdAt: Date

    // Review schedule. A correct answer queues two more reviews within a week
    // (2 days later, then 3 days after that). A wrong answer brings it back tomorrow.
    /// When this question is next due. nil = not scheduled.
    var nextReview: Date?
    var reviewsLeft: Int = 0
    /// true once both follow-up reviews were answered correctly.
    var isMastered: Bool = false

    /// Position in the built-in bank, used to keep level order stable.
    var order: Int = 0
    var timesCorrect: Int = 0
    var timesWrong: Int = 0

    /// 1 = foundations, 2 = core, 3 = advanced. 0 = not set: falls back to the format.
    var difficultyRaw: Int = 0
    /// Optional "read more" link shown after answering.
    var reference: String?

    init(subject: Subject,
         kind: QuestionKind = .multipleChoice,
         prompt: String,
         code: String? = nil,
         choices: [String] = [],
         correctIndex: Int = 0,
         answers: [String] = [],
         extras: [String] = [],
         explanation: String,
         isUserCreated: Bool = false) {
        self.id = UUID()
        self.subjectRaw = subject.rawValue
        self.kindRaw = kind.rawValue
        self.prompt = prompt
        self.code = code
        self.choices = choices
        self.correctIndex = correctIndex
        self.answers = answers
        self.extras = extras
        self.explanation = explanation
        self.isUserCreated = isUserCreated
        self.createdAt = .now
    }

    var subject: Subject { Subject(rawValue: subjectRaw) ?? .logic }
    var kind: QuestionKind { QuestionKind(rawValue: kindRaw) ?? .multipleChoice }

    /// 1–3. Questions without an explicit difficulty are rated by how hard their format is.
    var difficulty: Int {
        if (1...3).contains(difficultyRaw) { return difficultyRaw }
        switch kind {
        case .multipleChoice, .match: return 1
        case .fillBlank: return 2
        case .buildCode: return 3
        }
    }

    /// The link to show after answering: the question's own, or its subject's.
    var referenceLink: URL? {
        (reference ?? subject.referenceURL).flatMap(URL.init(string:))
    }

    /// Identifies a built-in question across bank updates.
    static func bankKey(prompt: String, code: String?) -> String { prompt + "\u{1}" + (code ?? "") }
    var bankKey: String { Self.bankKey(prompt: prompt, code: code) }

    /// Updates the review schedule after an answer.
    func recordAnswer(correct: Bool, now: Date = .now, calendar: Calendar = .current) {
        let today = calendar.startOfDay(for: now)
        func inDays(_ n: Int) -> Date { calendar.date(byAdding: .day, value: n, to: today)! }
        if correct { timesCorrect += 1 } else { timesWrong += 1 }

        guard correct else {
            isMastered = false
            reviewsLeft = 2
            nextReview = inDays(1)
            return
        }
        if let due = nextReview {
            guard due <= now else { return }   // answered early: doesn't count as a review
            reviewsLeft -= 1
            if reviewsLeft > 0 {
                nextReview = inDays(3)
            } else {
                nextReview = nil
                isMastered = true
            }
        } else if !isMastered {
            reviewsLeft = 2
            nextReview = inDays(2)
        }
    }

    /// The correct answer as readable text, for feedback and review.
    var solutionText: String {
        switch kind {
        case .multipleChoice:
            return choices.indices.contains(correctIndex) ? choices[correctIndex] : ""
        case .fillBlank:
            return (code ?? prompt).replacingOccurrences(of: "___", with: answers.first ?? "")
        case .buildCode:
            return answers.joined(separator: " ")
        case .match:
            return zip(answers, extras).map { "\($0)  →  \($1)" }.joined(separator: "\n")
        }
    }

    /// Lenient comparison for typed answers: ignores whitespace and smart quotes.
    static func normalize(_ s: String) -> String {
        s.replacingOccurrences(of: "[‘’]", with: "'", options: .regularExpression)
            .replacingOccurrences(of: "[“”]", with: "\"", options: .regularExpression)
            .filter { !$0.isWhitespace }
    }

    func accepts(_ typed: String) -> Bool {
        let t = Self.normalize(typed)
        return !t.isEmpty && answers.contains { Self.normalize($0) == t }
    }
}
