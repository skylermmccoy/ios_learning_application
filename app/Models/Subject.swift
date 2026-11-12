import Foundation

/// Every topic the app can quiz you on.
enum Subject: String, CaseIterable, Identifiable, Codable {
    // Critical thinking
    case logic, fallacy, patterns, factOpinion
    // Information theory
    case informationTheory
    // Algorithms
    case bigO, sorting, searching, graphs, dataStructures, recursion, codeDesign
    // Homework
    case discreteMath, python, java, bash, zsh, racket, prolog, lean4, parsing
    // Cybersecurity
    case cyber, nmap, metasploit, cve, knockd, netcat
    // Networking
    case servers, protocols
    // Computer engineering
    case circuits, components, digitalLogic
    // Database
    case sql
    // Certifications
    case scrum, securityPlus, aws, azure
    // Computer history
    case history

    var id: String { rawValue }

    enum Category: String, CaseIterable {
        case criticalThinking = "Critical Thinking"
        case informationTheory = "Information Theory"
        case algorithms = "Algorithms"
        case homework = "Homework"
        case cybersecurity = "Cybersecurity"
        case networking = "Networking"
        case computerEngineering = "Computer Engineering"
        case database = "Database"
        case certifications = "Certifications"
        case history = "Computer History"
    }

    var category: Category {
        switch self {
        case .logic, .fallacy, .patterns, .factOpinion: .criticalThinking
        case .informationTheory: .informationTheory
        case .servers, .protocols: .networking
        case .circuits, .components, .digitalLogic: .computerEngineering
        case .sql: .database
        case .discreteMath, .python, .java, .bash, .zsh, .racket, .prolog, .lean4, .parsing: .homework
        case .cyber, .nmap, .metasploit, .cve, .knockd, .netcat: .cybersecurity
        case .bigO, .sorting, .searching, .graphs, .dataStructures, .recursion, .codeDesign: .algorithms
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
        case .java: "Java"
        case .prolog: "Prolog"
        case .lean4: "Lean 4"
        case .parsing: "Scanners & Parsers"
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
        case .dataStructures: "Data Structures"
        case .recursion: "Recursion & DP"
        case .codeDesign: "Code Design"
        case .scrum: "Scrum Master"
        case .securityPlus: "CompTIA Security+"
        case .aws: "AWS"
        case .azure: "Azure"
        case .history: "People & Companies"
        case .informationTheory: "Claude Shannon & Information"
        case .servers: "Servers & Services"
        case .protocols: "Network Protocols"
        case .circuits: "Circuits"
        case .components: "Electronic Components"
        case .digitalLogic: "Digital Logic"
        case .sql: "SQL"
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
        case .java: "cup.and.saucer"
        case .prolog: "arrow.triangle.branch"
        case .lean4: "x.squareroot"
        case .parsing: "text.magnifyingglass"
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
        case .dataStructures: "tablecells"
        case .recursion: "repeat"
        case .codeDesign: "square.stack.3d.up"
        case .scrum: "person.3"
        case .securityPlus: "checkmark.shield"
        case .aws: "cloud"
        case .azure: "cloud.fill"
        case .history: "clock.arrow.circlepath"
        case .informationTheory: "waveform.path.ecg"
        case .servers: "server.rack"
        case .protocols: "network"
        case .circuits: "bolt"
        case .components: "memorychip"
        case .digitalLogic: "cpu"
        case .sql: "cylinder.split.1x2"
        }
    }

    /// One line on what the subject covers, shown on its path.
    var tagline: String {
        switch self {
        case .logic: "Reason step by step to the only answer that fits."
        case .fallacy: "Name the flaw in an argument."
        case .patterns: "Find the rule, predict what comes next."
        case .factOpinion: "Tell what can be checked from what is believed."
        case .bigO: "How running time and memory grow with input size."
        case .sorting: "Bubble to quicksort: how they work and what they cost."
        case .searching: "Linear, binary, two pointers and sliding windows."
        case .graphs: "BFS, DFS, shortest paths and spanning trees."
        case .dataStructures: "Stacks, queues, hash tables, trees, heaps and tries."
        case .recursion: "Base cases, memoization and dynamic programming."
        case .codeDesign: "Write code that is easy to read, test and change."
        case .discreteMath: "Sets, logic, counting and proofs."
        case .python: "Core Python: types, functions, classes and idioms."
        case .java: "Types, classes, inheritance and collections."
        case .bash: "Commands, pipes, variables and scripts."
        case .zsh: "Globbing, expansion and shell shortcuts."
        case .racket: "Lists, recursion and higher-order functions."
        case .prolog: "Facts, rules, unification and backtracking."
        case .lean4: "Terms, types and your first proofs."
        case .parsing: "Tokens, grammars and recursive descent."
        case .cyber: "The ideas every security topic builds on."
        case .nmap: "Scan types, flags and reading the results."
        case .metasploit: "Modules, payloads and the console workflow."
        case .cve: "How vulnerabilities are named, scored and tracked."
        case .knockd: "Hide a port behind a secret knock."
        case .netcat: "Listen, connect and move data over TCP and UDP."
        case .scrum: "Roles, events, artifacts and values."
        case .securityPlus: "Threats, architecture, operations and governance."
        case .aws: "Core services, pricing and shared responsibility."
        case .azure: "Core services, regions and identity."
        case .history: "The people and companies that built computing."
        case .informationTheory: "Bits, entropy and the man who measured information."
        case .servers: "DHCP, DNS, NTP and the services a network runs on."
        case .protocols: "Layers, Ethernet, IP addressing, TCP and UDP."
        case .circuits: "Voltage, current, resistance and Ohm's law."
        case .components: "Resistors, capacitors, diodes and transistors."
        case .digitalLogic: "Binary, logic gates, flip-flops and counters."
        case .sql: "Query, join, group and design relational tables."
        }
    }

    /// A page to read more about the subject. Only pages that were checked to exist.
    /// A question's own `ref` takes priority over this.
    var referenceURL: String? {
        let base = "https://www.w3schools.com/"
        return switch self {
        case .python: base + "python/default.asp"
        case .java: base + "java/default.asp"
        case .bash: base + "bash/index.php"
        case .bigO, .sorting, .searching, .graphs, .dataStructures, .recursion: base + "dsa/index.php"
        case .cyber, .securityPlus: base + "cybersecurity/index.php"
        case .aws: base + "aws/index.php"
        case .sql: base + "sql/default.asp"
        default: nil
        }
    }
}
