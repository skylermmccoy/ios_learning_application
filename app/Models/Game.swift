import Foundation
import Observation

/// Score, combo and lives for one quiz run.
@Observable
final class GameState {
    static let maxLives = 3

    var lives = GameState.maxLives
    var score = 0
    /// Correct answers in a row.
    var combo = 0
    var maxCombo = 0
    var correct = 0
    var answered = 0
    var missed: [Question] = []
    /// Points from the most recent answer (0 if wrong).
    var lastPoints = 0

    var wrong: Int { answered - correct }
    var isOver: Bool { lives <= 0 }

    /// x1, then x2 at 3 in a row, x3 at 6, x4 at 9+.
    var multiplier: Int { min(1 + combo / 3, 4) }

    /// - Parameter timeFraction: share of time left (0...1) in timed mode, nil otherwise.
    func record(_ question: Question, correct isCorrect: Bool, usedHint: Bool, timeFraction: Double?) {
        answered += 1
        if isCorrect {
            combo += 1
            maxCombo = max(maxCombo, combo)
            correct += 1
            let base = usedHint ? 50 : 100
            let speedBonus = Int((timeFraction ?? 0) * 50)
            lastPoints = (base + speedBonus) * multiplier
            score += lastPoints
        } else {
            combo = 0
            lives -= 1
            lastPoints = 0
            missed.append(question)
        }
    }
}

/// Level computed from total XP. Level L starts at 200·(L-1)·L XP:
/// L2 = 400, L3 = 1200, L4 = 2400, L5 = 4000…
struct Level: Equatable {
    let number: Int
    let xpIntoLevel: Int
    let xpForNext: Int

    var progress: Double { Double(xpIntoLevel) / Double(xpForNext) }

    static func xpRequired(for level: Int) -> Int { 200 * (level - 1) * level }

    init(xp: Int) {
        var n = 1
        while xp >= Self.xpRequired(for: n + 1) { n += 1 }
        number = n
        xpIntoLevel = xp - Self.xpRequired(for: n)
        xpForNext = Self.xpRequired(for: n + 1) - Self.xpRequired(for: n)
    }

    var title: String {
        switch number {
        case 1...2: "Novice"
        case 3...4: "Apprentice"
        case 5...7: "Thinker"
        case 8...11: "Logician"
        default: "Mastermind"
        }
    }
}
