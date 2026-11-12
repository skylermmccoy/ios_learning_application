# CLAUDE.md: iOS Learning Application

SwiftUI + SwiftData study app (quizzes, learning paths, spaced repetition). Read `README.md` for the overview and `docs/` for details. The workspace-level rules in `~/Code/claude/CLAUDE.md` also apply: work only inside `~/Code/claude`.

## How the owner wants to work

The owner reviews **one thing only: a pull request**. Do the work autonomously, then deliver a PR. Don't ask for confirmation on routine decisions; pick sensible defaults and record them in the PR description.

### The loop

1. **Branch.** Never work on `main`. Use `claude/<short-topic>` (e.g. `claude/add-graph-questions`).
2. **Pick work.** If the owner gave a task, do that. Otherwise take the first unchecked item under "Next up" in `docs/ROADMAP.md`.
3. **Do it**, with tests, and update docs affected by the change.
4. **Verify** (see below). Fix failures; don't hand back broken work.
5. **Commit** in small logical commits (end with the attribution line the harness gives you).
6. **Keep going.** Tick the roadmap item, then take the next unchecked one. Stop when the roadmap's "Next up" is empty, you hit something that truly needs the owner's decision (log it under "Needs owner" in the PR), or you've covered a coherent batch (~5–8 items; don't let one PR grow unreviewable).
7. **Open the PR** with `/open-pr` (or `.claude/scripts/open-pr.sh`). Write the description to `.claude/pr-body.md` first (template below). A Stop hook runs the same script as a safety net on `claude/*` branches, but a hand-written body is better than the auto-generated one.

### Hard rules

- **Never push to `main`, never merge a PR, never force-push.** The owner merges. (`.claude/settings.json` denies these.)
- Don't modify things outside this repo.
- Don't commit secrets, `xcuserdata/`, `.shots/`, or `*.swp`.
- Don't invent facts for certification or history questions. Cite or omit; flag uncertainty in the PR.
- If a build/test can't run in this environment, say so in the PR instead of claiming it passed.

### Verification

```sh
xcodebuild -project app.xcodeproj -scheme app \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
xcodebuild -project app.xcodeproj -scheme app \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:appTests test
```

For content-only changes, at minimum validate the JSON (`python3 -m json.tool app/Data/starter_questions.json >/dev/null`) and run `starterQuestionsAreValid`. Note the project's deployment target (iOS 27.0) may not match installed simulators; if so, report it rather than silently editing the target.

### PR description template (`.claude/pr-body.md`)

```markdown
## Summary
What changed and why, in 2–4 bullets.

## Changes
- Grouped list of notable changes (files/areas)

## How I verified
- Commands run and results (be honest about anything not run)

## Decisions I made
- Defaults I chose that you might want to change

## Needs owner
- Anything blocked on a human decision (or "Nothing")

## Review tips
- Where to look first
```

## Project map

- `app/Models`: `Question`, `Subject`, `Attempt`, `LearningPath`, `Game` (rules live here as pure functions)
- `app/Views`: one screen per file; `QuestionViews.swift` has the 4 question formats
- `app/Components`: theme + shared UI
- `app/Data`: `QuestionBank.swift` + `starter_questions.json` (**bump `seedVersion` when the JSON changes**)
- `appTests` / `appUITests`: Swift Testing / XCUITest
- `docs/`: architecture, gameplay rules, question format, dev guide, roadmap

## Owner priorities

- **Algorithms are the big focus** (Big O, sorting, searching, graphs, coding design in Python/TypeScript). Favor this area when choosing content work.
- Correctly answered questions return twice within a week (already implemented; preserve it).
- Topic sources: `qustions.txt` (owner's list, they add to it) and `~/Code/claude/tutor/tracks/` (read-only reference; ask before reading since it's outside this repo).

## Agents and commands

Project agents (`.claude/agents/`): `question-writer`, `swift-reviewer`, `docs-keeper`, `build-verifier`. Use them, and spawn parallel ones for independent work (e.g. one `question-writer` per subject). Slash commands (`.claude/commands/`): `/next-task`, `/add-questions`, `/open-pr`.
