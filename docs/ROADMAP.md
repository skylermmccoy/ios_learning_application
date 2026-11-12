# Roadmap

Claude works top-down through **Next up**, ticking items as they ship. Add items freely; keep them small enough to finish in one commit or two. Mark anything that needs a human decision with `(needs owner)`.

## Next up

### Algorithms (top priority)
- [ ] Audit current algorithm coverage (Big O 49, Sorting 55, Searching 48, Graphs 52, Data Structures 30, Recursion & DP 27, Code Design 30) against the Educative "must-know algorithms" list in `qustions.txt`; write the gap list to `docs/CONTENT_GAPS.md`.
- [ ] Code Design: TypeScript variants alongside Python (add a `typescript` subject or tag; (needs owner) which).

### Certifications and history (from `qustions.txt`)
- [ ] Scrum Master: expand to ≥ 30 questions across roles, events, artifacts, values.
- [ ] CompTIA Security+: expand to ≥ 40 questions across the current exam domains.
- [ ] AWS and Azure: expand to ≥ 25 each (fundamentals-level services, shared responsibility, pricing models).
- [ ] Computer History: Bell Labs, Claude Shannon, Apple, Microsoft, Linux, IBM; ≥ 6 questions each.

### App quality
- [ ] Unit tests for `Question.recordAnswer` (wrong, first correct, due correct, early correct), `GameState`, `Level`, `LearningPath.path`, `QuestionBank.streak/dailySet`.
- [ ] Unit test: all question prompts unique; all `Subject` cases have ≥ 1 question.
- [ ] Add a CI workflow (`.github/workflows/ci.yml`) that builds and runs unit tests on pull requests (needs a macOS runner with a matching Xcode/SDK; (needs owner) confirm deployment target).
- [ ] Accessibility pass: Dynamic Type, VoiceOver labels on question views, color-contrast check.
- [ ] iPad / wide-screen layout check (sidebar adaptable tab bar is already in place).

### Features
- [ ] Algorithm visualizations in Learn (step through sorting/searching on a small array).
- [ ] Per-subject stats screen (accuracy over time, mastered count).
- [ ] Import/export of user-created questions (JSON share sheet).
- [ ] Local notifications for due reviews and streak reminders.

## Done
- [x] Learn tab redesign: Continue card, totals, category chips, subject grid; path screen with a trail between levels, unit cards and a level preview sheet; question prompt card in quizzes.
- [x] +156 algorithm questions (718 total): Sorting 21, Searching 21, Graphs 21, Big O 18, Code Design 18 (Python), and two new subjects, Data Structures (30) and Recursion & DP (27). About 40 more levels across the algorithm paths.
- [x] Deeper learning paths: three difficulty units per subject, timed unit reviews, mastery challenge.
- [x] Every question labelled with `difficulty` 1–3; bank sorted by subject then difficulty; optional `ref` "read more" links (W3Schools pages checked to exist).
- [x] New subjects: Java (30), Prolog (26), Lean 4 (8), Scanners & Parsers (20, from the owner's homework in `references/`).
- [x] +218 questions: Sorting 22, Searching 18, Graphs 20, Big O 18, Python 20, Logic 10, Discrete Math 10, Racket 16, plus the new subjects.
- [x] Initial app: Today / Learn / Practice / My Stuff, 4 question formats, 344 questions, spaced repetition, XP/levels/streaks.
- [x] Repo documentation, README and Claude workflow (this PR).

## Needs owner
- Which language(s) for code-design questions beyond Python/TypeScript?
- Target iOS version: project says 27.0; installed simulators are 26.x.
