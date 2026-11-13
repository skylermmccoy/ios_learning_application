# iOS Learning Application

A SwiftUI study app that turns learning into a game. Short quizzes, a Duolingo-style learning path per subject, spaced-repetition reviews, XP, streaks and combos. It ships with **978 built-in questions across 38 subjects**, with a heavy focus on **algorithms**, and lets you add your own.

> Status: early / actively developed. See [`docs/ROADMAP.md`](docs/ROADMAP.md).

## Features

| Tab | What it does |
| --- | --- |
| **Today** | Daily Challenge (5 mixed questions, same set all day, builds a streak), questions due for review, XP / level, and your weakest subjects. |
| **Learn** | A Continue card, your totals, and a grid of subjects by category. Each subject opens a path in three units (Foundations, Core, Advanced). Lessons of 5 questions, a timed review after each unit, and a timed mastery challenge at the end. Tap a level to preview it; lessons in the algorithm subjects teach first with swipeable cards, most with a diagram or a tap-through animation (based on *Grokking Algorithms* and other sources), then quiz you. 1–3 stars based on hearts left. |
| **Practice** | Free practice and 10-question Timed Tests, by subject or by question format. |
| **My Stuff** | Questions you created, history of attempts, and weak spots. |

### Four question formats

- **Quick Pick**: multiple choice.
- **Fill the Blank**: type the missing piece of code (`___`).
- **Code Builder**: tap tiles in the right order (decoy tiles included).
- **Match-Up**: pair code with its output.

### Game mechanics

- 3 hearts per run; a wrong answer costs one.
- Combo multiplier: x1, x2 at 3 in a row, x3 at 6, x4 at 9+.
- Points: 100 per correct answer (50 if you used a hint) plus up to 50 speed bonus in timed mode, times the multiplier.
- XP = points earned. Level *L* starts at `200·(L-1)·L` XP (L2 = 400, L3 = 1200, …).
- **Spaced repetition**: a correct answer comes back twice (2 days later, then 3 days after that) and is then "mastered". A wrong answer comes back tomorrow.

Full details: [`docs/GAMEPLAY.md`](docs/GAMEPLAY.md).

## Subjects

| Category | Subjects |
| --- | --- |
| Critical Thinking | Logic Puzzles, Spot the Fallacy, Patterns & Sequences, Fact vs Opinion |
| **Algorithms** | Big O, Sorting, Searching, Graphs, Code Design |
| Homework | Discrete Math, Python, Java, Bash, zsh, Racket, Prolog, Lean 4, Scanners & Parsers |
| Cybersecurity | Security Basics, Nmap, Metasploit, CVEs & NIST, Port Knocking (knockd), Netcat |
| Certifications | Scrum Master, CompTIA Security+, AWS, Azure |
| Computer History | People & Companies |

## Tech stack

- Swift 5 / **SwiftUI**, `@Observable`
- **SwiftData** for persistence (`Question`, `Attempt`, `LevelProgress`)
- Swift Testing for unit tests
- No third-party dependencies
- Questions are data: [`app/Data/starter_questions.json`](app/Data/starter_questions.json)

## Getting started

Requirements: a recent Xcode (the project's deployment target is **iOS 27.0**; check it against your installed SDK/simulators) and macOS.

```sh
git clone git@github.com:skylermmccoy/ios_learning_application.git
cd ios_learning_application
open app.xcodeproj
```

Then pick the `app` scheme and a simulator and press Run. Or from the command line:

```sh
xcodebuild -project app.xcodeproj -scheme app \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
xcodebuild -project app.xcodeproj -scheme app \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

More in [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md), including debug launch flags (`-demo buildCode`, `-tab practice`).

## Project layout

```
app/                     App source
  appApp.swift           Entry point, SwiftData container
  ContentView.swift      Tab bar (Today / Learn / Practice / My Stuff)
  Models/                Question, Subject, Attempt, LearningPath, Game
  Views/                 One file per screen (+ QuestionViews for the 4 formats)
  Components/            Theme, shared UI, game effects
  Data/                  QuestionBank.swift + starter_questions.json
appTests/                Unit tests (Swift Testing)
appUITests/              UI tests
docs/                    Documentation (start at docs/README.md)
.claude/                 Claude Code config: agents, commands, hooks
CLAUDE.md                Instructions for Claude Code in this repo
qustions.txt             The owner's running list of topics to add
```

## Adding questions

Edit `app/Data/starter_questions.json`, **bump `QuestionBank.seedVersion`**, and run the tests. The format is documented in [`docs/QUESTION_FORMAT.md`](docs/QUESTION_FORMAT.md). Players can also create their own questions in-app.

## Documentation

- [`docs/README.md`](docs/README.md): index
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md): how the code fits together
- [`docs/GAMEPLAY.md`](docs/GAMEPLAY.md): scoring, lives, review schedule, levels
- [`docs/QUESTION_FORMAT.md`](docs/QUESTION_FORMAT.md): content schema and authoring rules
- [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md): build, test, debug, conventions
- [`docs/CLAUDE_WORKFLOW.md`](docs/CLAUDE_WORKFLOW.md): how Claude works on this repo and delivers PRs
- [`docs/ROADMAP.md`](docs/ROADMAP.md): what's next

## Contributing / workflow

Changes land through pull requests only; `main` is never pushed to directly. Claude Code works on a `claude/*` branch and opens a PR for review when it finishes. See [`docs/CLAUDE_WORKFLOW.md`](docs/CLAUDE_WORKFLOW.md).
