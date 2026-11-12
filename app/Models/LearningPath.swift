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

    /// One stop on a subject's path.
    struct PathLevel {
        enum Style { case lesson, review, mastery }
        let style: Style
        /// 1 = Foundations, 2 = Core, 3 = Advanced. Mastery belongs to the last unit.
        let unit: Int
        /// 1-based lesson number within the whole path (0 for reviews and mastery).
        let lessonNumber: Int
        let questions: [Question]

        /// Lessons are untimed so you can think. Reviews and mastery run against the clock.
        var isTimed: Bool { style != .lesson }

        var title: String {
            switch style {
            case .lesson: "Lesson \(lessonNumber)"
            case .review: "\(LearningPath.unitName(unit)) review"
            case .mastery: "Mastery challenge"
            }
        }
    }

    static func unitName(_ unit: Int) -> String {
        switch unit {
        case 1: "Foundations"
        case 2: "Core"
        default: "Advanced"
        }
    }

    static let reviewSize = 8
    static let masterySize = 10

    /// The full path for one subject, in a stable order:
    /// each unit's lessons (easy formats first), a timed review after any unit with two or more
    /// lessons, and a timed mastery challenge at the end once the subject has enough questions.
    static func path(for questions: [Question], size: Int = levelSize) -> [PathLevel] {
        let sorted = questions.sorted {
            if $0.difficulty != $1.difficulty { return $0.difficulty < $1.difficulty }
            if rank($0.kind) != rank($1.kind) { return rank($0.kind) < rank($1.kind) }
            if $0.isUserCreated != $1.isUserCreated { return !$0.isUserCreated }
            if $0.order != $1.order { return $0.order < $1.order }
            return $0.createdAt < $1.createdAt
        }
        guard !sorted.isEmpty else { return [] }

        // Group by difficulty. A unit too small for its own lesson joins its neighbour.
        var units: [(unit: Int, questions: [Question])] = (1...3).compactMap { u in
            let qs = sorted.filter { $0.difficulty == u }
            return qs.isEmpty ? nil : (u, qs)
        }
        while units.count > 1, let small = units.firstIndex(where: { $0.questions.count < 3 }) {
            let target = small == 0 ? 1 : small - 1
            units[target].questions = small == 0
                ? units[small].questions + units[target].questions
                : units[target].questions + units[small].questions
            units.remove(at: small)
        }

        var path: [PathLevel] = []
        var lessonNumber = 0
        for (unit, qs) in units {
            var lessons = stride(from: 0, to: qs.count, by: size).map { Array(qs[$0..<min($0 + size, qs.count)]) }
            // A tiny last lesson isn't worth a node: fold it into the one before.
            if lessons.count > 1, let last = lessons.last, last.count < 3 {
                lessons.removeLast()
                lessons[lessons.count - 1] += last
            }
            for lesson in lessons {
                lessonNumber += 1
                path.append(PathLevel(style: .lesson, unit: unit, lessonNumber: lessonNumber, questions: lesson))
            }
            if lessons.count >= 2 {
                path.append(PathLevel(style: .review, unit: unit, lessonNumber: 0,
                                      questions: spread(qs, count: reviewSize)))
            }
        }
        if sorted.count >= masterySize, lessonNumber >= 2 {
            path.append(PathLevel(style: .mastery, unit: units.last?.unit ?? 3, lessonNumber: 0,
                                  questions: spread(sorted, count: masterySize)))
        }
        return path
    }

    /// `count` items taken at even intervals, so a review touches every lesson of its unit.
    static func spread(_ items: [Question], count: Int) -> [Question] {
        guard items.count > count else { return items }
        return (0..<count).map { items[$0 * items.count / count] }
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
