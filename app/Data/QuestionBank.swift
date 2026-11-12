import Foundation
import SwiftData

/// `kind` defaults to multipleChoice. See `QuestionKind` for what each field means per kind.
struct StarterQuestion: Decodable {
    let subject: Subject
    let kind: QuestionKind?
    let prompt: String
    let code: String?
    let choices: [String]?
    let answer: Int?
    let answers: [String]?
    let extras: [String]?
    let explanation: String
    /// 1 = foundations, 2 = core, 3 = advanced.
    let difficulty: Int?
    /// "Read more" link shown after answering.
    let ref: String?
    /// Id of the teaching note that covers this question (see docs/LESSON_FORMAT.md).
    let topic: String?

    var resolvedKind: QuestionKind { kind ?? .multipleChoice }
}

enum QuestionBank {
    /// Bump this when starter_questions.json changes so installed apps reload it.
    static let seedVersion = 8

    static func loadStarter(bundle: Bundle = .main) throws -> [StarterQuestion] {
        guard let url = bundle.url(forResource: "starter_questions", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode([StarterQuestion].self, from: Data(contentsOf: url))
    }

    /// Loads the built-in questions into SwiftData on first run, and syncs them whenever
    /// `seedVersion` goes up. Questions that still exist keep their review schedule.
    /// Your own questions are never touched.
    static func seedIfNeeded(context: ModelContext, defaults: UserDefaults = .standard) {
        let builtIn = FetchDescriptor<Question>(predicate: #Predicate { $0.isUserCreated == false })
        let upToDate = defaults.integer(forKey: "seedVersion") >= seedVersion
        if upToDate, (try? context.fetchCount(builtIn)) ?? 0 > 0 { return }
        do {
            var existing: [String: Question] = [:]
            for q in try context.fetch(builtIn) {
                if existing[q.bankKey] == nil { existing[q.bankKey] = q } else { context.delete(q) }
            }
            for (position, s) in try loadStarter().enumerated() {
                let key = Question.bankKey(prompt: s.prompt, code: s.code)
                if let q = existing.removeValue(forKey: key) {
                    q.order = position
                    q.difficultyRaw = s.difficulty ?? 0
                    q.reference = s.ref
                    q.topic = s.topic
                    q.subjectRaw = s.subject.rawValue
                    q.kindRaw = s.resolvedKind.rawValue
                    q.choices = s.choices ?? []
                    q.correctIndex = s.answer ?? 0
                    q.answers = s.answers ?? []
                    q.extras = s.extras ?? []
                    q.explanation = s.explanation
                } else {
                    let q = Question(subject: s.subject, kind: s.resolvedKind,
                                     prompt: s.prompt, code: s.code,
                                     choices: s.choices ?? [], correctIndex: s.answer ?? 0,
                                     answers: s.answers ?? [], extras: s.extras ?? [],
                                     explanation: s.explanation)
                    q.order = position
                    q.difficultyRaw = s.difficulty ?? 0
                    q.reference = s.ref
                    q.topic = s.topic
                    context.insert(q)
                }
            }
            for removed in existing.values { context.delete(removed) }
            try context.save()
            defaults.set(seedVersion, forKey: "seedVersion")
        } catch {
            print("Seeding failed: \(error)")
        }
    }

    /// Same 5 questions all day; changes at midnight.
    static func dailySet(from all: [Question], on date: Date = .now, count: Int = 5) -> [Question] {
        let day = date.formatted(.iso8601.year().month().day())
        return Array(all.sorted { stableHash(day + $0.prompt) < stableHash(day + $1.prompt) }.prefix(count))
    }

    /// Questions whose scheduled review date has arrived, oldest first.
    static func dueForReview(from all: [Question], now: Date = .now) -> [Question] {
        all.filter { ($0.nextReview ?? .distantFuture) <= now }
            .sorted { ($0.nextReview ?? .distantFuture) < ($1.nextReview ?? .distantFuture) }
    }

    /// FNV-1a. Swift's hashValue changes every launch, so we can't use it for a daily seed.
    static func stableHash(_ s: String) -> UInt64 {
        var h: UInt64 = 0xcbf29ce484222325
        for b in s.utf8 { h = (h ^ UInt64(b)) &* 0x100000001b3 }
        return h
    }

    /// Consecutive days (ending today or yesterday) with a finished daily challenge.
    static func streak(from attempts: [Attempt], today: Date = .now, calendar: Calendar = .current) -> Int {
        let days = Set(attempts.filter { $0.mode == .daily }.map { calendar.startOfDay(for: $0.date) })
        var day = calendar.startOfDay(for: today)
        if !days.contains(day) { day = calendar.date(byAdding: .day, value: -1, to: day)! }
        var count = 0
        while days.contains(day) {
            count += 1
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return count
    }
}
