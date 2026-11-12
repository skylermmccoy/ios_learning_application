# Architecture

SwiftUI app with SwiftData persistence. No networking, no third-party packages. All content ships in the bundle as JSON.

## Data model (`app/Models`)

| Type | File | Purpose |
| --- | --- | --- |
| `Subject` (enum) | `Subject.swift` | The 25 topics, plus their `Category`, display name and SF Symbol. |
| `QuestionKind` (enum) | `Question.swift` | `multipleChoice`, `fillBlank`, `buildCode`, `match`; label, icon, time limit. |
| `Question` (`@Model`) | `Question.swift` | One question + its review schedule (`nextReview`, `reviewsLeft`, `isMastered`) and counters (`timesCorrect`, `timesWrong`). |
| `Attempt` (`@Model`) | `Attempt.swift` | One finished quiz. Streaks, XP and history are *computed* from attempts. |
| `LevelProgress` (`@Model`) | `LearningPath.swift` | A finished level (subject + level index + stars). |
| `QuizMode` (enum) | `Attempt.swift` | `daily`, `timed`, `practice`, `level`. |
| `GameState` (`@Observable`) | `Game.swift` | Lives, score, combo, missed questions for one run. |
| `Level` (struct) | `Game.swift` | Player level derived from total XP. |
| `LearningPath` (enum) | `LearningPath.swift` | Pure functions: split a subject into levels, stats, weak subjects/spots. |

The SwiftData container is created in `appApp.swift` with `Question`, `Attempt` and `LevelProgress`. Adding a stored property with a default value is a lightweight migration; anything else needs a migration plan.

## Content pipeline

```
starter_questions.json  ──decode──▶  [StarterQuestion]  ──seedIfNeeded──▶  SwiftData Question rows
```

- `QuestionBank.seedIfNeeded` runs at launch (`ContentView.task`).
- It re-syncs only when `QuestionBank.seedVersion` is higher than the value stored in `UserDefaults`. **Bump it whenever the JSON changes.**
- Built-in questions are matched across updates by `bankKey` (`prompt + code`), so existing review schedules survive edits to other fields. Changing a question's prompt or code makes it a *new* question (progress on it resets).
- User-created questions (`isUserCreated == true`) are never touched by seeding.

## Screens (`app/Views`)

| File | Role |
| --- | --- |
| `TodayView` | Daily challenge, due reviews, XP/level, streak, weak subjects. |
| `LearnView` | Per-subject level path and level entry. |
| `PracticeView` | Practice / timed tests by subject or format. |
| `MyStuffView` | User questions, history. |
| `AddQuestionView` | In-app question editor. |
| `QuizView` | The quiz runner. Takes a `QuizSession` (title, questions, mode, subject). |
| `QuestionViews` | One view per `QuestionKind`. |
| `ResultView` | End-of-run summary, writes the `Attempt`. |

`ContentView` hosts a `TabView` with `.sidebarAdaptable` (bottom bar on iPhone, sidebar on wide screens).

## Shared UI (`app/Components`)

- `Theme.swift`: category/kind colors, `IconBadge`, `.card()` modifier.
- `Components.swift`: reusable views.
- `GameEffects.swift`: confetti / feedback / haptic style effects.

## Where logic lives

Keep rules in the model layer as pure, testable functions (see `LearningPath`, `QuestionBank.dailySet/dueForReview/streak`, `Question.recordAnswer`). Views should call these rather than re-implement them.

## Debug-only entry points

`ContentView.openDemoIfRequested()` (compiled under `#if DEBUG`) reads launch arguments `-demo <kind>` and `-tab <name>`. See [DEVELOPMENT.md](DEVELOPMENT.md).
