import SwiftUI

extension Subject.Category {
    var color: Color {
        switch self {
        case .criticalThinking: .indigo
        case .homework: .teal
        case .cybersecurity: .green
        case .algorithms: .orange
        case .certifications: .blue
        case .history: .brown
        }
    }

    var icon: String {
        switch self {
        case .criticalThinking: "brain.head.profile"
        case .homework: "book.closed"
        case .cybersecurity: "lock.shield"
        case .algorithms: "chart.line.uptrend.xyaxis"
        case .certifications: "rosette"
        case .history: "clock.arrow.circlepath"
        }
    }
}

extension Subject {
    var color: Color { category.color }
}

extension QuestionKind {
    var color: Color {
        switch self {
        case .multipleChoice: .blue
        case .fillBlank: .orange
        case .buildCode: .purple
        case .match: .pink
        }
    }
}

/// Rounded colored square with a white symbol, like the icons in Settings.
struct IconBadge: View {
    let icon: String
    let color: Color
    var size: CGFloat = 36

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.48, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color.gradient, in: .rect(cornerRadius: size * 0.28))
    }
}

extension View {
    /// Standard card: padded, rounded, sits on the grouped background.
    func card() -> some View {
        padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
    }

    /// Card filled with a diagonal gradient. Use white content on top.
    func gradientCard(_ colors: [Color]) -> some View {
        padding(18)
            .background(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: .rect(cornerRadius: 24))
            .foregroundStyle(.white)
    }
}

/// White capsule button for use on gradient cards.
struct PillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.black)
            .padding(.horizontal, 22).padding(.vertical, 10)
            .background(.white, in: .capsule)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}
