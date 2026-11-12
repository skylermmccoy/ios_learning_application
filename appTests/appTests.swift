import Foundation
import Testing
@testable import app

struct appTests {

    @Test func starterQuestionsAreValid() throws {
        let questions = try QuestionBank.loadStarter()
        #expect(questions.count >= 700)
        for q in questions {
            #expect((1...3).contains(q.difficulty ?? 0), "Missing difficulty: \(q.prompt)")
            if let ref = q.ref { #expect(URL(string: ref)?.scheme == "https", "Bad ref: \(ref)") }
            switch q.resolvedKind {
            case .multipleChoice:
                #expect((q.choices ?? []).indices.contains(q.answer ?? -1), "Bad answer index: \(q.prompt)")
            case .fillBlank:
                #expect(!(q.answers ?? []).isEmpty, "No answers: \(q.prompt)")
                #expect((q.code ?? q.prompt).contains("___"), "No blank: \(q.prompt)")
            case .buildCode:
                #expect((q.answers ?? []).count >= 2, "Too few tiles: \(q.prompt)")
            case .match:
                let left = q.answers ?? [], right = q.extras ?? []
                #expect(left.count == right.count && left.count >= 3, "Bad pairs: \(q.prompt)")
                #expect(Set(right).count == right.count, "Duplicate outputs: \(q.prompt)")
            }
        }
        // Keys must be unique so bank updates can keep each question's review schedule.
        let keys = questions.map { Question.bankKey(prompt: $0.prompt, code: $0.code) }
        #expect(Set(keys).count == keys.count)
        for subject in Subject.allCases {
            #expect(questions.contains { $0.subject == subject }, "No questions for \(subject)")
        }
    }

    @Test func fillBlankIsLenient() {
        let q = Question(subject: .python, kind: .fillBlank, prompt: "p", code: "x ___ 2",
                         answers: ["**", "\"$1\""], explanation: "")
        #expect(q.accepts(" ** "))
        #expect(q.accepts("“$1”"))   // smart quotes from the iOS keyboard
        #expect(!q.accepts("*"))
        #expect(!q.accepts(""))
    }

    @Test func correctAnswersComeBackTwiceInAWeek() {
        let cal = Calendar.current
        let day0 = cal.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 9))!
        func day(_ n: Int) -> Date { cal.date(byAdding: .day, value: n, to: day0)! }
        let q = Question(subject: .logic, prompt: "p", explanation: "")

        q.recordAnswer(correct: true, now: day0)                 // first correct answer
        #expect(q.reviewsLeft == 2)
        #expect(QuestionBank.dueForReview(from: [q], now: day(1)).isEmpty)
        #expect(QuestionBank.dueForReview(from: [q], now: day(2)).count == 1)

        q.recordAnswer(correct: true, now: day(1))               // too early: doesn't count
        #expect(q.reviewsLeft == 2)

        q.recordAnswer(correct: true, now: day(2))               // review 1
        #expect(q.reviewsLeft == 1)
        #expect(QuestionBank.dueForReview(from: [q], now: day(5)).count == 1)

        q.recordAnswer(correct: true, now: day(5))               // review 2, inside the week
        #expect(q.isMastered && q.nextReview == nil)

        q.recordAnswer(correct: false, now: day(6))              // a miss restarts it tomorrow
        #expect(!q.isMastered && q.reviewsLeft == 2)
        #expect(QuestionBank.dueForReview(from: [q], now: day(7)).count == 1)
    }

    @Test func pathHasUnitsReviewsAndMastery() {
        func make(_ n: Int, difficulty: Int, kind: QuestionKind = .multipleChoice, from start: Int) -> [Question] {
            (0..<n).map { i in
                let q = Question(subject: .python, kind: kind, prompt: "d\(difficulty) \(i)", explanation: "")
                q.difficultyRaw = difficulty
                q.order = start + i
                return q
            }
        }
        // 12 foundations, 5 core, 2 advanced (too few for a unit: they join Core).
        let qs = make(12, difficulty: 1, from: 0) + make(5, difficulty: 2, from: 12) + make(2, difficulty: 3, from: 17)
        let path = LearningPath.path(for: qs.shuffled())
        typealias Style = LearningPath.PathLevel.Style
        // Unit 1: lessons of 5 and 7 (remainder of 2 folded in), then a review.
        // Unit 2: one lesson of 7, no review. Then mastery.
        #expect(path.map(\.style) == [Style.lesson, .lesson, .review, .lesson, .mastery])
        #expect(path.map(\.unit) == [1, 1, 1, 2, 2])
        #expect(path.map(\.questions.count) == [5, 7, 8, 7, 10])
        #expect(path[0].questions.map(\.order) == [0, 1, 2, 3, 4])            // stable order
        #expect(path[2].questions.allSatisfy { $0.difficulty == 1 })          // review stays in its unit
        #expect(path[2].isTimed && path[4].isTimed && !path[0].isTimed)
        #expect(path.map(\.title) == ["Lesson 1", "Lesson 2", "Foundations review", "Lesson 3", "Mastery challenge"])
        #expect(Set(path[4].questions.map(\.difficulty)) == [1, 2, 3])        // mastery spans everything

        #expect(LearningPath.path(for: []).isEmpty)
        // A small subject is a single lesson with no extras.
        #expect(LearningPath.path(for: make(4, difficulty: 2, from: 0)).map(\.style) == [Style.lesson])

        // Without an explicit difficulty, the format decides the unit.
        let build = Question(subject: .python, kind: .buildCode, prompt: "b", explanation: "")
        let blank = Question(subject: .python, kind: .fillBlank, prompt: "f", explanation: "")
        #expect(build.difficulty == 3 && blank.difficulty == 2)

        #expect(LearningPath.currentLevel(count: 3, completed: []) == 0)
        #expect(LearningPath.currentLevel(count: 3, completed: [0, 1]) == 2)
        #expect(LearningPath.currentLevel(count: 3, completed: [0, 1, 2]) == 3)
    }

    @Test func progressCountsLevelsAndStars() {
        let records = [
            LevelProgress(subject: .sorting, level: 0, stars: 3),
            LevelProgress(subject: .sorting, level: 1, stars: 1),
            LevelProgress(subject: .sorting, level: 1, stars: 2),   // duplicate: best stars win
            LevelProgress(subject: .sorting, level: 9, stars: 3),   // past the end: ignored
        ]
        let p = LearningPath.progress(levelCount: 4, records: records)
        #expect(p == LearningPath.Progress(done: 2, total: 4, stars: 5))
        #expect(p.fraction == 0.5 && p.isStarted && !p.isComplete)

        let empty = LearningPath.progress(levelCount: 0, records: [])
        #expect(empty.fraction == 0 && !empty.isStarted && !empty.isComplete)
        #expect(LearningPath.progress(levelCount: 2, records: Array(records.prefix(2))).isComplete)
    }

    @Test func resumePicksLatestUnfinishedSubject() {
        let now = Date.now
        func done(_ subject: Subject, _ level: Int, minutesAgo: Double) -> LevelProgress {
            LevelProgress(subject: subject, level: level, stars: 3, completedAt: now.addingTimeInterval(-60 * minutesAgo))
        }
        let counts: [Subject: Int] = [.sorting: 2, .graphs: 5, .bigO: 5]
        // Sorting was played last but is finished, so Graphs (next most recent) is offered.
        let records = [done(.bigO, 0, minutesAgo: 90), done(.graphs, 0, minutesAgo: 30),
                       done(.sorting, 0, minutesAgo: 10), done(.sorting, 1, minutesAgo: 5)]
        #expect(LearningPath.resumeSubject(records: records, levelCounts: counts) == .graphs)
        #expect(LearningPath.resumeSubject(records: [], levelCounts: counts) == nil)
        // Everything started is finished: nothing to resume.
        #expect(LearningPath.resumeSubject(records: Array(records.suffix(2)), levelCounts: counts) == nil)
    }

    @Test func levelListsItsFormatsInOrder() {
        let kinds: [QuestionKind] = [.multipleChoice, .multipleChoice, .match, .fillBlank, .multipleChoice]
        let qs = kinds.enumerated().map { i, kind in
            Question(subject: .python, kind: kind, prompt: "q\(i)", explanation: "")
        }
        let level = LearningPath.PathLevel(style: .lesson, unit: 1, lessonNumber: 1, questions: qs)
        #expect(level.kindCounts.map(\.kind) == [.multipleChoice, .match, .fillBlank])
        #expect(level.kindCounts.map(\.count) == [3, 1, 1])
    }

    @Test func weakSubjectsAreRankedByAccuracy() {
        func q(_ subject: Subject, right: Int, wrong: Int) -> Question {
            let q = Question(subject: subject, prompt: "\(subject.rawValue) \(right) \(wrong)", explanation: "")
            for _ in 0..<right { q.recordAnswer(correct: true) }
            for _ in 0..<wrong { q.recordAnswer(correct: false) }
            return q
        }
        let all = [q(.python, right: 9, wrong: 1),      // 90%: fine
                   q(.bash, right: 3, wrong: 7),        // 30%: weakest
                   q(.racket, right: 6, wrong: 4),      // 60%
                   q(.zsh, right: 0, wrong: 2)]         // too few answers to judge
        let weak = LearningPath.weakSubjects(in: all)
        #expect(weak.map(\.subject) == [.bash, .racket])
        #expect(weak.first?.stats.percent == 30)
    }

    @Test func comboMultiplierAndLives() {
        let g = GameState()
        let q = Question(subject: .logic, prompt: "p", explanation: "")
        for _ in 0..<3 { g.record(q, correct: true, usedHint: false, timeFraction: nil) }
        #expect(g.multiplier == 2)
        #expect(g.score == 100 + 100 + 200)
        g.record(q, correct: false, usedHint: false, timeFraction: nil)
        #expect(g.combo == 0 && g.lives == 2 && g.multiplier == 1)
        g.record(q, correct: false, usedHint: false, timeFraction: nil)
        g.record(q, correct: false, usedHint: false, timeFraction: nil)
        #expect(g.isOver)
    }

    @Test func levels() {
        #expect(Level(xp: 0).number == 1)
        #expect(Level(xp: 399).number == 1)
        #expect(Level(xp: 400).number == 2)
        #expect(Level(xp: 1200).number == 3)
        #expect(Level(xp: 800).xpIntoLevel == 400)
    }

    @Test func streakCountsConsecutiveDays() {
        let cal = Calendar.current
        let today = Date.now
        func daily(_ daysAgo: Int) -> Attempt {
            Attempt(date: cal.date(byAdding: .day, value: -daysAgo, to: today)!,
                    subject: nil, mode: .daily, score: 5, total: 5, duration: 60)
        }
        #expect(QuestionBank.streak(from: [], today: today) == 0)
        #expect(QuestionBank.streak(from: [daily(0), daily(1), daily(2)], today: today) == 3)
        #expect(QuestionBank.streak(from: [daily(1), daily(2)], today: today) == 2)
        #expect(QuestionBank.streak(from: [daily(0), daily(2)], today: today) == 1)
    }

    @Test func stableHashIsDeterministic() {
        #expect(QuestionBank.stableHash("abc") == QuestionBank.stableHash("abc"))
        #expect(QuestionBank.stableHash("abc") != QuestionBank.stableHash("abd"))
    }
}
