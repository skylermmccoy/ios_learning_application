import Foundation
import SwiftData

/// A finished level on a subject's path. One record per subject + level.
@Model
final class LevelProgress {
    var subjectRaw: String
    /// 0-based position on the path.
    var level: Int
    /// 1–3: how many hearts were left when the level was finished.
    var stars: Int
    var completedAt: Date

    init(subject: Subject, level: Int, stars: Int, completedAt: Date = .now) {
        self.subjectRaw = subject.rawValue
        self.level = level
        self.stars = stars
        self.completedAt = completedAt
    }
}

/// Splits a subject's questions into ordered levels and measures how you're doing.
enum LearningPath {
    static let levelSize = 5

    /// Easier formats first: pick an answer, then match, then type, then build.
    private static func rank(_ kind: QuestionKind) -> Int {
        switch kind {
        case .multipleChoice: 0
        case .match: 1
        case .fillBlank: 2
        case .buildCode: 3
        }
    }

    /// Levels for one subject, in a stable order. Each level mixes in harder formats as you go:
    /// the questions are sorted easy-to-hard, then dealt out so later levels get the harder ones.
    static func levels(for questions: [Question], size: Int = levelSize) -> [[Question]] {
        let sorted = questions.sorted {
            if rank($0.kind) != rank($1.kind) { return rank($0.kind) < rank($1.kind) }
            if $0.isUserCreated != $1.isUserCreated { return !$0.isUserCreated }
            if $0.order != $1.order { return $0.order < $1.order }
            return $0.createdAt < $1.createdAt
        }
        guard !sorted.isEmpty else { return [] }
        var levels = stride(from: 0, to: sorted.count, by: size).map {
            Array(sorted[$0..<min($0 + size, sorted.count)])
        }
        // A tiny last level isn't worth a node: fold it into the one before.
        if levels.count > 1, let last = levels.last, last.count < 3 {
            levels.removeLast()
            levels[levels.count - 1] += last
        }
        return levels
    }

    /// Index of the first level not yet completed (equals `count` when all are done).
    static func currentLevel(count: Int, completed: Set<Int>) -> Int {
        (0..<count).first { !completed.contains($0) } ?? count
    }

    struct Stats {
        let answered: Int
        let correct: Int
        var percent: Int { answered == 0 ? 0 : correct * 100 / answered }
    }

    static func stats(for questions: [Question]) -> Stats {
        let correct = questions.reduce(0) { $0 + $1.timesCorrect }
        let wrong = questions.reduce(0) { $0 + $1.timesWrong }
        return Stats(answered: correct + wrong, correct: correct)
    }

    /// Subjects you've answered at least `minAnswers` questions in and score under `below`%,
    /// weakest first.
    static func weakSubjects(in questions: [Question], minAnswers: Int = 5, below: Int = 85,
                             limit: Int = 3) -> [(subject: Subject, stats: Stats)] {
        Dictionary(grouping: questions, by: \.subject)
            .map { (subject: $0.key, stats: stats(for: $0.value)) }
            .filter { $0.stats.answered >= minAnswers && $0.stats.percent < below }
            .sorted { ($0.stats.percent, $0.subject.rawValue) < ($1.stats.percent, $1.subject.rawValue) }
            .prefix(limit)
            .map { $0 }
    }

    /// The questions in a subject you miss most, for a targeted practice round.
    static func weakSpots(in questions: [Question], count: Int = 8) -> [Question] {
        Array(questions
            .sorted { ($0.timesWrong - $0.timesCorrect, $0.order) > ($1.timesWrong - $1.timesCorrect, $1.order) }
            .prefix(count))
    }
}
