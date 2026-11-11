import SwiftUI

struct ResultView: View {
    let game: GameState
    let total: Int
    let duration: TimeInterval
    let xpBefore: Int
    /// nil when this wasn't a path level. 0 = failed, 1–3 = stars earned.
    var levelStars: Int? = nil
    let onDone: () -> Void

    @State private var wide = false

    private var percent: Int { total == 0 ? 0 : game.correct * 100 / total }
    private var levelBefore: Level { Level(xp: xpBefore) }
    private var levelAfter: Level { Level(xp: xpBefore + game.score) }
    private var leveledUp: Bool { levelAfter.number > levelBefore.number }
    private var celebrate: Bool { leveledUp || (levelStars ?? 0) > 0 || (percent >= 80 && !game.isOver) }

    var body: some View {
        Group {
            if wide, !game.missed.isEmpty {
                // Score on the left, missed questions on the right.
                HStack(spacing: 0) {
                    List { summary }
                    List { missedSection }
                }
            } else {
                List {
                    summary
                    missedSection
                }
            }
        }
        .trackWide($wide)
        .safeAreaInset(edge: .bottom) {
            Button(action: onDone) {
                Text("Done").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .overlay { if celebrate { ConfettiView() } }
        .onAppear { if leveledUp { Sound.shared.play(.levelUp) } }
    }

    @ViewBuilder private var summary: some View {
        Section {
            VStack(spacing: 10) {
                if let levelStars, levelStars > 0 {
                    Text("Level complete").font(.title2.bold()).foregroundStyle(.green)
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: i < levelStars ? "star.fill" : "star")
                                .foregroundStyle(i < levelStars ? .yellow : .secondary)
                        }
                    }
                    .font(.title)
                } else if levelStars == 0 {
                    Text("Level not passed").font(.title2.bold()).foregroundStyle(.red)
                    Text("Finish with at least one heart left to unlock the next level.")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else if game.isOver {
                    Text("💔 Game Over").font(.title2.bold()).foregroundStyle(.red)
                } else if leveledUp {
                    Text("🎉 Level Up!").font(.title2.bold()).foregroundStyle(.orange)
                }
                Text("\(game.score)")
                    .font(.system(size: 60, weight: .heavy, design: .rounded))
                    .contentTransition(.numericText())
                Text("points").foregroundStyle(.secondary)
                Text(message).font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
        }

        Section {
            stat("Correct", "\(game.correct) / \(total)", "checkmark.circle")
            stat("Best combo", "\(game.maxCombo) in a row", "flame")
            stat("Lives left", "\(max(0, game.lives)) / \(GameState.maxLives)", "heart")
            stat("Time", Duration.seconds(duration).formatted(.time(pattern: .minuteSecond)), "clock")
        }

        Section("XP") {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Level \(levelAfter.number) · \(levelAfter.title)").bold()
                    Spacer()
                    Text("+\(game.score) XP").foregroundStyle(.green)
                }
                ProgressView(value: levelAfter.progress)
                Text("\(levelAfter.xpIntoLevel) / \(levelAfter.xpForNext) XP to level \(levelAfter.number + 1)")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private var missedSection: some View {
        if !game.missed.isEmpty {
            Section("Review what you missed") {
                ForEach(game.missed) { q in
                    VStack(alignment: .leading, spacing: 6) {
                        Label(q.kind.label, systemImage: q.kind.icon)
                            .font(.caption).foregroundStyle(.secondary)
                        Text(q.prompt).font(.subheadline.weight(.semibold))
                        if q.kind == .multipleChoice, let code = q.code { CodeBlock(code: code) }
                        if q.kind == .multipleChoice {
                            Text("Answer: \(q.solutionText)").foregroundStyle(.green)
                        } else {
                            CodeBlock(code: q.solutionText)
                        }
                        Text(q.explanation).font(.footnote).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func stat(_ title: String, _ value: String, _ icon: String) -> some View {
        LabeledContent { Text(value).monospacedDigit() } label: { Label(title, systemImage: icon) }
    }

    private var message: String {
        if game.isOver { return "Shake it off and try again" }
        switch percent {
        case 90...: return "Sharp! 🧠"
        case 70..<90: return "Nice work"
        case 50..<70: return "Getting there"
        default: return "Keep practicing"
        }
    }
}
