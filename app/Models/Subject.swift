import Foundation

/// Every topic the app can quiz you on.
enum Subject: String, CaseIterable, Identifiable, Codable {
    // Critical thinking
    case logic, fallacy, patterns, factOpinion
    // Algorithms
    case bigO, sorting, searching, graphs, codeDesign
    // Homework
    case discreteMath, python, bash, zsh, racket
    // Cybersecurity
    case cyber, nmap, metasploit, cve, knockd, netcat
    // Certifications
    case scrum, securityPlus, aws, azure
    // Computer history
    case history

    var id: String { rawValue }

    enum Category: String, CaseIterable {
        case criticalThinking = "Critical Thinking"
        case algorithms = "Algorithms"
        case homework = "Homework"
        case cybersecurity = "Cybersecurity"
        case certifications = "Certifications"
        case history = "Computer History"
    }

    var category: Category {
        switch self {
        case .logic, .fallacy, .patterns, .factOpinion: .criticalThinking
        case .discreteMath, .python, .bash, .zsh, .racket: .homework
        case .cyber, .nmap, .metasploit, .cve, .knockd, .netcat: .cybersecurity
        case .bigO, .sorting, .searching, .graphs, .codeDesign: .algorithms
        case .scrum, .securityPlus, .aws, .azure: .certifications
        case .history: .history
        }
    }

    var displayName: String {
        switch self {
        case .logic: "Logic Puzzles"
        case .fallacy: "Spot the Fallacy"
        case .patterns: "Patterns & Sequences"
        case .factOpinion: "Fact vs Opinion"
        case .discreteMath: "Discrete Math"
        case .python: "Python"
        case .bash: "Bash"
        case .zsh: "zsh"
        case .racket: "Racket"
        case .cyber: "Security Basics"
        case .nmap: "Nmap"
        case .metasploit: "Metasploit"
        case .cve: "CVEs & NIST"
        case .knockd: "Port Knocking (knockd)"
        case .netcat: "Netcat"
        case .bigO: "Big O"
        case .sorting: "Sorting"
        case .searching: "Searching"
        case .graphs: "Graphs"
        case .codeDesign: "Code Design"
        case .scrum: "Scrum Master"
        case .securityPlus: "CompTIA Security+"
        case .aws: "AWS"
        case .azure: "Azure"
        case .history: "People & Companies"
        }
    }

    /// SF Symbol name.
    var icon: String {
        switch self {
        case .logic: "puzzlepiece.extension"
        case .fallacy: "exclamationmark.bubble"
        case .patterns: "square.grid.3x3"
        case .factOpinion: "checkmark.seal"
        case .discreteMath: "function"
        case .python: "chevron.left.forwardslash.chevron.right"
        case .bash: "terminal"
        case .zsh: "apple.terminal"
        case .racket: "parentheses"
        case .cyber: "lock.shield"
        case .nmap: "dot.radiowaves.left.and.right"
        case .metasploit: "ant"
        case .cve: "exclamationmark.shield"
        case .knockd: "door.left.hand.closed"
        case .netcat: "cable.connector"
        case .bigO: "chart.line.uptrend.xyaxis"
        case .sorting: "arrow.up.arrow.down"
        case .searching: "magnifyingglass"
        case .graphs: "point.3.connected.trianglepath.dotted"
        case .codeDesign: "square.stack.3d.up"
        case .scrum: "person.3"
        case .securityPlus: "checkmark.shield"
        case .aws: "cloud"
        case .azure: "cloud.fill"
        case .history: "clock.arrow.circlepath"
        }
    }
}
