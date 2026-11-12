# Development guide

## Prerequisites

- macOS with Xcode. The project's `IPHONEOS_DEPLOYMENT_TARGET` is `27.0`; if your installed iOS SDK/simulators are older (e.g. 26.x) the build may need the deployment target adjusted or a newer Xcode. Verify before assuming a failure is a code bug.
- Command-line: `git`, `gh` (for PRs).

## Build and test

```sh
# list simulators
xcrun simctl list devices available

# build
xcodebuild -project app.xcodeproj -scheme app \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# unit + UI tests
xcodebuild -project app.xcodeproj -scheme app \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test

# unit tests only
xcodebuild -project app.xcodeproj -scheme app \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:appTests test
```

Tests use Swift Testing (`import Testing`, `@Test`, `#expect`). `starterQuestionsAreValid` guards the question bank.

## Debug launch flags (DEBUG builds)

Pass as launch arguments (Scheme → Run → Arguments, or `xcrun simctl launch … -demo buildCode`):

| Flag | Effect |
| --- | --- |
| `-demo multipleChoice\|fillBlank\|buildCode\|match` | Jump straight into a 10-question timed quiz of that format |
| `-tab today\|learn\|practice\|mine` | Open that tab |

## Conventions

- SwiftUI + `@Observable` for state, SwiftData for persistence. No new dependencies without discussion.
- Rules go in pure functions on models/enums (see [ARCHITECTURE.md](ARCHITECTURE.md)) so they can be unit-tested; keep views thin.
- One screen per file in `app/Views`; shared bits in `app/Components`.
- Doc comments (`///`) on types and non-obvious functions; explain *why*.
- Add or update a test for every logic change.
- Keep `docs/` in sync with behavior changes.

## Gotchas

- Bump `QuestionBank.seedVersion` after editing `starter_questions.json`.
- Don't use `hashValue` for anything that must be stable across launches (daily set); use `stableHash`.
- Schema changes to `@Model` classes need defaults (lightweight migration) or a migration plan.
- Don't commit `xcuserdata/`, `.shots/` screenshots or vim swap files (see `.gitignore`).
