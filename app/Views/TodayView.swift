import SwiftUI
import SwiftData

struct TodayView: View {
    @Query private var questions: [Question]
    @Query(sort: \Attempt.date, order: .reverse) private var attempts: [Attempt]
    @State private var session: QuizSession?
    @State private var wide = false

    private var streak: Int { QuestionBank.streak(from: attempts) }
    private var totalXP: Int { attempts.reduce(0) { $0 + $1.points } }
    private var level: Level { Level(xp: totalXP) }
    private var doneToday: Bool {
        attempts.contains { $0.mode == .daily && Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Columns(wide: wide) {
                        levelCard
                        HStack(spacing: 16) {
                            statTile(value: "\(streak)", label: "day streak", icon: "flame.fill",
                                     color: streak > 0 ? .orange : .gray)
                            statTile(value: "\(attempts.count)", label: "games played", icon: "gamecontroller.fill",
                                     color: .blue)
                        }
                        weekCard
                    } trailing: {
                        reviewCard
                        dailyCard
                        quickMixCard
                    }
                    gamesRow
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .trackWide($wide)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Today")
            .navigationSubtitle(Text(Date.now, format: .dateTime.weekday(.wide).month().day()))
            .fullScreenCover(item: $session) { QuizView(session: $0) }
        }
    }

    // MARK: Cards

    private var levelCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().stroke(.white.opacity(0.25), lineWidth: 7)
                    Circle()
                        .trim(from: 0, to: max(0.02, level.progress))
                        .stroke(.white, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(level.number)").font(.system(size: 30, weight: .heavy, design: .rounded))
                }
                .frame(width: 72, height: 72)

                VStack(alignment: .leading, spacing: 2) {
                    Text("LEVEL \(level.number)").font(.caption.bold()).opacity(0.8)
                    Text(level.title).font(.title.bold())
                    Text("\(totalXP) XP total").font(.subheadline).opacity(0.85)
                }
                Spacer()
            }
            Text("\(level.xpForNext - level.xpIntoLevel) XP to level \(level.number + 1)")
                .font(.footnote.weight(.medium))
                .opacity(0.9)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gradientCard([.indigo, .purple])
    }

    private func statTile(value: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            IconBadge(icon: icon, color: color, size: 42)
            VStack(alignment: .leading, spacing: 0) {
                Text(value).font(.title2.bold().monospacedDigit())
                Text(label).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .card()
    }

    /// Last 7 days, with a check on days the daily challenge was done.
    private var weekCard: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let doneDays = Set(attempts.filter { $0.mode == .daily }.map { cal.startOfDay(for: $0.date) })
        return HStack {
            ForEach((0..<7).reversed(), id: \.self) { back in
                let day = cal.date(byAdding: .day, value: -back, to: today)!
                let done = doneDays.contains(day)
                VStack(spacing: 6) {
                    Text(day, format: .dateTime.weekday(.narrow))
                        .font(.caption2.bold())
                        .foregroundStyle(back == 0 ? .primary : .secondary)
                    ZStack {
                        Circle().fill(done ? Color.orange : Color(.systemFill))
                        if done {
                            Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(.white)
                        }
                    }
                    .frame(width: 30, height: 30)
                    .overlay {
                        if back == 0 { Circle().stroke(Color.orange, lineWidth: 2).padding(-3) }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .card()
    }

    private var dailyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(doneToday ? "Done for today" : "Daily Challenge",
                  systemImage: doneToday ? "checkmark.seal.fill" : "calendar")
                .font(.caption.bold())
                .opacity(0.9)
            Text("5 questions.\nOne shot at your streak.")
                .font(.title2.bold())
            Text("A mix of logic, code and security. The same set all day.")
                .font(.subheadline)
                .opacity(0.9)
            Button(doneToday ? "Play again" : "Start") {
                session = QuizSession(title: "Daily Challenge",
                                      questions: QuestionBank.dailySet(from: questions),
                                      mode: .daily, subject: nil)
            }
            .buttonStyle(PillButtonStyle())
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gradientCard([.orange, .pink])
    }

    /// Questions you got right come back twice within a week. Misses come back tomorrow.
    private var reviewCard: some View {
        let due = QuestionBank.dueForReview(from: questions)
        let scheduled = questions.filter { $0.nextReview != nil }.count
        return Button {
            session = QuizSession(title: "Review", questions: Array(due.prefix(15)),
                                  mode: .practice, subject: nil)
        } label: {
            HStack(spacing: 14) {
                IconBadge(icon: "arrow.triangle.2.circlepath", color: due.isEmpty ? .gray : .green, size: 46)
                VStack(alignment: .leading, spacing: 2) {
                    Text(due.isEmpty ? "Review" : "Review: \(due.count) due").font(.headline)
                    Text(due.isEmpty
                         ? (scheduled == 0 ? "Answer questions to build your review queue"
                                           : "Nothing due today. \(scheduled) scheduled this week")
                         : "Revisit what you learned so it sticks")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                if !due.isEmpty { Image(systemName: "play.fill").foregroundStyle(.green) }
            }
            .card()
        }
        .buttonStyle(.plain)
        .disabled(due.isEmpty)
    }

    private var quickMixCard: some View {
        Button {
            session = QuizSession(title: "Quick Mix",
                                  questions: Array(questions.shuffled().prefix(10)),
                                  mode: .timed, subject: nil)
        } label: {
            HStack(spacing: 14) {
                IconBadge(icon: "timer", color: .blue, size: 46)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quick Timed Mix").font(.headline)
                    Text("10 random questions, 3 lives")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "play.fill").foregroundStyle(Color.accentColor)
            }
            .card()
        }
        .buttonStyle(.plain)
    }

    private var gamesRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Games").font(.title3.bold()).padding(.top, 4)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(QuestionKind.allCases) { kind in
                        Button {
                            let pool = questions.filter { $0.kind == kind }
                            session = QuizSession(title: kind.label,
                                                  questions: Array(pool.shuffled().prefix(10)),
                                                  mode: .timed, subject: nil)
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                Image(systemName: kind.icon).font(.title2.weight(.semibold))
                                Spacer(minLength: 0)
                                Text(kind.label).font(.headline)
                                Text(kind.blurb).font(.caption).opacity(0.9)
                                    .multilineTextAlignment(.leading)
                            }
                            .frame(width: 130, height: 130, alignment: .leading)
                            .gradientCard([kind.color, kind.color.opacity(0.7)])
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollClipDisabled()
        }
    }
}
