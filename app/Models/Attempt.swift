import Foundation
import SwiftData

enum QuizMode: String, Codable {
    case daily      // 5 mixed questions, same set all day
    case timed      // 10 questions with a countdown
    case practice   // untimed, e.g. your own questions
    case level      // one level on a subject's path, untimed

    var label: String {
        switch self {
        case .daily: "Daily Challenge"
        case .timed: "Timed Test"
        case .practice: "Practice"
        case .level: "Level"
        }
    }
}

/// One finished quiz. Streaks, XP and history are computed from these.
@Model
final class Attempt {
    var date: Date
    /// nil when the quiz mixed several subjects.
    var subjectRaw: String?
    var modeRaw: String
    var score: Int
    var total: Int
    var duration: TimeInterval
    /// Game points earned; also counts as XP.
    var points: Int = 0
    var maxCombo: Int = 0
    var title: String = ""

    init(date: Date = .now, subject: Subject?, mode: QuizMode, score: Int, total: Int,
         duration: TimeInterval, points: Int = 0, maxCombo: Int = 0, title: String = "") {
        self.date = date
        self.subjectRaw = subject?.rawValue
        self.modeRaw = mode.rawValue
        self.score = score
        self.total = total
        self.duration = duration
        self.points = points
        self.maxCombo = maxCombo
        self.title = title
    }

    var subject: Subject? { subjectRaw.flatMap(Subject.init(rawValue:)) }
    var mode: QuizMode { QuizMode(rawValue: modeRaw) ?? .practice }
}
