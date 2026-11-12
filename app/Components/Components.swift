import SwiftUI

/// Monospaced code snippet box.
struct CodeBlock: View {
    let code: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(code)
                .font(.system(.callout, design: .monospaced))
                .textSelection(.enabled)
                .padding(14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemGroupedBackground), in: .rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.quaternary))
    }
}

/// An answer choice with a letter badge. Turns green/red once the question is answered.
struct AnswerButton: View {
    enum State { case idle, correct, wrong, dimmed }

    let letter: String
    let text: String
    let state: State
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(letter)
                    .font(.subheadline.bold())
                    .foregroundStyle(badgeForeground)
                    .frame(width: 30, height: 30)
                    .background(badgeBackground, in: .circle)
                Text(text).multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                switch state {
                case .correct: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                case .wrong: Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                default: EmptyView()
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(background, in: .rect(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(border, lineWidth: 1.5))
            .opacity(state == .dimmed ? 0.5 : 1)
        }
        .buttonStyle(.plain)
    }

    private var background: Color {
        switch state {
        case .idle, .dimmed: Color(.secondarySystemGroupedBackground)
        case .correct: .green.opacity(0.18)
        case .wrong: .red.opacity(0.18)
        }
    }

    private var border: Color {
        switch state {
        case .idle, .dimmed: .clear
        case .correct: .green
        case .wrong: .red
        }
    }

    private var badgeBackground: Color {
        switch state {
        case .correct: .green
        case .wrong: .red
        default: Color.accentColor.opacity(0.15)
        }
    }

    private var badgeForeground: Color {
        state == .correct || state == .wrong ? .white : .accentColor
    }
}

/// Circular progress. `value` is 0 → 1. Put a label on top with an overlay or ZStack.
struct ProgressRing: View {
    let value: Double
    var color: Color = .accentColor
    var track: Color = Color(.systemFill)
    var lineWidth: CGFloat = 5

    var body: some View {
        ZStack {
            Circle().stroke(track, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(1, max(0, value)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .animation(.snappy, value: value)
        .accessibilityHidden(true)
    }
}

/// Three stars, `filled` of them gold.
struct StarRow: View {
    let filled: Int
    var empty: Color = .secondary

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { s in
                Image(systemName: s < filled ? "star.fill" : "star")
                    .foregroundStyle(s < filled ? Color.yellow : empty)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(filled) of 3 stars")
    }
}

/// Countdown bar for timed questions. `fraction` is 1 → 0.
struct TimerBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule()
                    .fill(fraction > 0.3 ? Color.accentColor : .red)
                    .frame(width: geo.size.width * max(0, fraction))
            }
        }
        .frame(height: 6)
        .animation(.linear(duration: 0.1), value: fraction)
    }
}

/// One segment per question: green if right, red if wrong, highlighted if current.
struct SegmentedProgress: View {
    let total: Int
    let results: [Bool]

    var body: some View {
        Group {
            if total <= 20 {
                HStack(spacing: 4) {
                    ForEach(0..<total, id: \.self) { i in
                        Capsule()
                            .fill(color(for: i))
                            .frame(height: 6)
                    }
                }
            } else {
                // Too many questions for one segment each.
                ProgressView(value: Double(results.count), total: Double(total))
            }
        }
        .animation(.snappy, value: results)
    }

    private func color(for i: Int) -> Color {
        if i < results.count { return results[i] ? .green : .red }
        if i == results.count { return .accentColor }
        return Color(.systemFill)
    }
}

// MARK: - Wide layout (unfolded iPhone Duo, big phones in landscape, iPad)

extension View {
    /// Keeps `wide` true while this view is at least 700 points across.
    /// An unfolded iPhone Duo held sideways is about 950 points wide. Its outer screen never gets there.
    func trackWide(_ wide: Binding<Bool>) -> some View {
        onGeometryChange(for: Bool.self) { $0.size.width >= 700 } action: { wide.wrappedValue = $0 }
    }
}

/// Two groups of content: stacked when narrow, side by side in equal columns when wide.
/// The gap between the columns lands on the screen's centre, which is where the Duo's fold is.
/// Switching keeps the state of everything inside, so folding mid-question loses nothing.
struct Columns<Leading: View, Trailing: View>: View {
    let wide: Bool
    var spacing: CGFloat = 16
    @ViewBuilder var leading: Leading
    @ViewBuilder var trailing: Trailing

    var body: some View {
        let layout = wide ? AnyLayout(HStackLayout(alignment: .top, spacing: 28))
                          : AnyLayout(VStackLayout(alignment: .leading, spacing: spacing))
        layout {
            VStack(alignment: .leading, spacing: spacing) { leading }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            VStack(alignment: .leading, spacing: spacing) { trailing }
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}
