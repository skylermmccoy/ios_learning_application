import Foundation

/// Where a teaching note's facts were checked. Books have no `url`.
struct LessonSource: Decodable, Hashable {
    let title: String
    let url: String?

    var link: URL? { url.flatMap(URL.init(string:)) }
}

/// One swipeable card. At least one of `body`, `code`, `bullets`, `visual` is set.
struct TeachingCard: Decodable, Hashable {
    let title: String
    let body: String?
    /// Shown in a monospaced block: Python, or a small trace.
    let code: String?
    let bullets: [String]?
    /// A diagram drawn by the app. Most cards have one.
    let visual: CardVisual?

    private enum CodingKeys: String, CodingKey { case title, body, code, bullets, visual }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        title = try c.decode(String.self, forKey: .title)
        body = try c.decodeIfPresent(String.self, forKey: .body)
        code = try c.decodeIfPresent(String.self, forKey: .code)
        bullets = try c.decodeIfPresent([String].self, forKey: .bullets)
        // A visual this version can't read is dropped rather than losing the whole lesson file.
        // The test `lessonVisualsAreValid` makes sure none are dropped in the shipped file.
        visual = try? c.decodeIfPresent(CardVisual.self, forKey: .visual)
    }
}

/// Teaches one topic of one subject. Questions point at it with their `topic`.
/// See docs/LESSON_FORMAT.md.
struct TeachingNote: Decodable, Identifiable, Hashable {
    let subject: Subject
    let topic: String
    /// Short name, also used as the lesson's title on the path.
    let title: String
    let cards: [TeachingCard]
    let sources: [LessonSource]

    var id: String { subject.rawValue + "/" + topic }
}

/// The built-in teaching notes (lessons.json), loaded once.
enum LessonLibrary {
    static func load(bundle: Bundle = .main) throws -> [TeachingNote] {
        guard let url = bundle.url(forResource: "lessons", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode([TeachingNote].self, from: Data(contentsOf: url))
    }

    /// Every note, in file order. File order is teaching order.
    static let all: [TeachingNote] = (try? load()) ?? []

    private static let bySubject = Dictionary(grouping: all, by: \.subject)

    /// A subject's notes in teaching order. Empty for subjects that have none yet.
    static func notes(for subject: Subject) -> [TeachingNote] { bySubject[subject] ?? [] }

    static func note(subject: Subject, topic: String?) -> TeachingNote? {
        guard let topic else { return nil }
        return notes(for: subject).first { $0.topic == topic }
    }

    /// The notes for a level's topics, in the level's order.
    static func notes(for level: LearningPath.PathLevel, in subject: Subject) -> [TeachingNote] {
        level.topics.compactMap { note(subject: subject, topic: $0) }
    }
}
