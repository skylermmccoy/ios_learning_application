import SwiftUI

/// What to open when a level starts: optionally the teaching cards, then the questions.
struct LessonStart: Identifiable {
    let id = UUID()
    let session: QuizSession
    let notes: [TeachingNote]
    /// false = go straight to the questions.
    let teachFirst: Bool
}

/// A level in one full-screen flow: the teaching cards, then the quiz, without closing in between.
struct LessonFlowView: View {
    let start: LessonStart
    @State private var quizStarted: Bool

    init(start: LessonStart) {
        self.start = start
        _quizStarted = State(initialValue: !start.teachFirst || start.notes.isEmpty)
    }

    var body: some View {
        if quizStarted {
            QuizView(session: start.session)
                .transition(.move(edge: .trailing))
        } else {
            TeachView(subject: start.session.subject ?? .bigO, notes: start.notes) {
                withAnimation(.smooth) { quizStarted = true }
            }
        }
    }
}

/// Swipeable teaching cards for one or more notes. The last page lists the sources and,
/// when `onStart` is set, starts the questions. Without `onStart` it's a read-only review.
struct TeachView: View {
    let subject: Subject
    let notes: [TeachingNote]
    var onStart: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var page = 0

    /// One swipeable page: a card of a note, or the closing page.
    private struct Page: Identifiable {
        let id: Int
        let note: TeachingNote?
        let card: TeachingCard?
        /// 1-based position of the card within its note.
        let cardNumber: Int
    }

    private var pages: [Page] {
        var out: [Page] = []
        for note in notes {
            for (i, card) in note.cards.enumerated() {
                out.append(Page(id: out.count, note: note, card: card, cardNumber: i + 1))
            }
        }
        out.append(Page(id: out.count, note: nil, card: nil, cardNumber: 0))
        return out
    }

    var body: some View {
        let pages = pages
        let isLast = page >= pages.count - 1
        NavigationStack {
            VStack(spacing: 0) {
                PageDots(count: pages.count, current: page, color: subject.color)
                    .padding(.horizontal)
                    .padding(.top, 4)

                TabView(selection: $page) {
                    ForEach(pages) { p in
                        Group {
                            if let note = p.note, let card = p.card {
                                CardPage(subject: subject, note: note, card: card, number: p.cardNumber)
                            } else {
                                closingPage
                            }
                        }
                        .tag(p.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.snappy, value: page)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(notes.count == 1 ? notes[0].title : "Lesson")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }
                }
                if onStart != nil, !isLast {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Skip") { withAnimation { page = pages.count - 1 } }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    if page > 0 {
                        Button {
                            withAnimation { page -= 1 }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.headline)
                                .frame(width: 44, height: 32)
                        }
                        .buttonStyle(.glass)
                        .accessibilityLabel("Previous card")
                    }
                    Button {
                        if !isLast {
                            withAnimation { page += 1 }
                        } else if let onStart {
                            onStart()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Text(!isLast ? "Next" : onStart != nil ? "Start questions" : "Done")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(subject.color)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
    }

    /// Recap of what was covered, the sources, and the way into the questions.
    private var closingPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: onStart != nil ? "checkmark.seal.fill" : "book.closed.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(subject.color)
                    Text(onStart != nil ? "Ready to practise" : "That's the lesson")
                        .font(.title2.bold())
                    Text(onStart != nil
                         ? "Now answer questions on what you just read. Wrong answers come back tomorrow, right ones twice more within a week."
                         : "Swipe back any time to read a card again.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(notes) { note in
                        HStack(spacing: 12) {
                            IconBadge(icon: "book.fill", color: subject.color, size: 30)
                            Text(note.title).font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(note.cards.count) cards")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        if note.id != notes.last?.id { Divider().padding(.leading, 56) }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))

                let sources = Array(Set(notes.flatMap(\.sources))).sorted { $0.title < $1.title }
                if !sources.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SOURCES").font(.caption.bold()).foregroundStyle(.secondary)
                        ForEach(sources, id: \.self) { source in
                            if let link = source.link {
                                Link(destination: link) {
                                    Label(source.title, systemImage: "link")
                                        .font(.subheadline)
                                        .multilineTextAlignment(.leading)
                                }
                            } else {
                                Label(source.title, systemImage: "books.vertical")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()
                }
            }
            .padding()
            .padding(.bottom, 24)
        }
    }
}

/// One teaching card, full page.
private struct CardPage: View {
    let subject: Subject
    let note: TeachingNote
    let card: TeachingCard
    let number: Int

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("\(note.title.uppercased()) · \(number) OF \(note.cards.count)")
                    .font(.caption.bold())
                    .foregroundStyle(subject.color)

                Text(card.title)
                    .font(.title.bold())
                    .fixedSize(horizontal: false, vertical: true)

                if let body = card.body {
                    Text(body)
                        .font(.body)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let code = card.code {
                    CodeBlock(code: code)
                }

                if let bullets = card.bullets, !bullets.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(bullets, id: \.self) { bullet in
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(subject.color)
                                Text(bullet)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()
                }
            }
            .padding()
            .padding(.bottom, 24)
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .accessibilityElement(children: .contain)
    }
}

/// Thin segments, one per page, filled up to the current one.
private struct PageDots: View {
    let count: Int
    let current: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i <= current ? color : Color(.systemFill))
                    .frame(height: 5)
            }
        }
        .animation(.snappy, value: current)
        .accessibilityElement()
        .accessibilityLabel("Card \(min(current + 1, count)) of \(count)")
    }
}
