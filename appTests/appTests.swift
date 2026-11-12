import Foundation
import Testing
@testable import app

struct appTests {

    @Test func starterQuestionsAreValid() throws {
        let questions = try QuestionBank.loadStarter()
        #expect(questions.count >= 340)
        for q in questions {
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

    @Test func levelsAreChunkedEasyToHard() {
        func make(_ n: Int, _ kind: QuestionKind, from start: Int) -> [Question] {
            (0..<n).map { i in
                let q = Question(subject: .python, kind: kind, prompt: "\(kind.rawValue) \(i)", explanation: "")
                q.order = start + i
                return q
            }
        }
        // 12 questions → levels of 5, 5, and a remainder of 2 folded into the last: 5 + 7.
        let qs = make(4, .buildCode, from: 0) + make(8, .multipleChoice, from: 4)
        let levels = LearningPath.levels(for: qs.shuffled())
        #expect(levels.map(\.count) == [5, 7])
        #expect(levels[0].allSatisfy { $0.kind == .multipleChoice })      // easy format first
        #expect(levels[0].map(\.order) == [4, 5, 6, 7, 8])                 // stable order
        #expect(LearningPath.levels(for: []).isEmpty)
        #expect(LearningPath.levels(for: make(3, .match, from: 0)).map(\.count) == [3])

        #expect(LearningPath.currentLevel(count: 3, completed: []) == 0)
        #expect(LearningPath.currentLevel(count: 3, completed: [0, 1]) == 2)
        #expect(LearningPath.currentLevel(count: 3, completed: [0, 1, 2]) == 3)
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
