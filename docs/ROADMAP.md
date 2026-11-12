# Roadmap

Claude works top-down through **Next up**, ticking items as they ship. Add items freely; keep them small enough to finish in one commit or two. Mark anything that needs a human decision with `(needs owner)`.

## Next up

### Algorithms (top priority)
- [ ] Audit current algorithm coverage (Big O 31, Sorting 34, Searching 27, Graphs 31, Code Design 12) against the Educative "must-know algorithms" list in `qustions.txt`; write the gap list to `docs/CONTENT_GAPS.md`.
- [ ] Sorting: bubble, selection, insertion, merge, quick, heap, counting. Add Code Builder + Fill the Blank for each, with best/avg/worst time and space in explanations.
- [ ] Searching: linear, binary (iterative + recursive), BFS/DFS as search, two pointers, sliding window.
- [ ] Graphs: BFS, DFS, Dijkstra, topological sort, union-find, cycle detection, MST (Kruskal/Prim).
- [ ] Big O: loops, nested loops, recursion, amortized, space complexity, "which is faster for n = …".
- [ ] Code Design: TypeScript variants alongside Python (add a `typescript` subject or tag; (needs owner) which).
- [ ] Dynamic programming and recursion/backtracking questions (new subject under Algorithms).
- [ ] Hash tables, stacks/queues, trees/heaps/tries (new "Data Structures" subject, Algorithms category).

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
- [x] Deeper learning paths: three difficulty units per subject, timed unit reviews, mastery challenge.
- [x] Every question labelled with `difficulty` 1–3; bank sorted by subject then difficulty; optional `ref` "read more" links (W3Schools pages checked to exist).
- [x] New subjects: Java (30), Prolog (26), Lean 4 (8), Scanners & Parsers (20, from the owner's homework in `references/`).
- [x] +218 questions: Sorting 22, Searching 18, Graphs 20, Big O 18, Python 20, Logic 10, Discrete Math 10, Racket 16, plus the new subjects.
- [x] Initial app: Today / Learn / Practice / My Stuff, 4 question formats, 344 questions, spaced repetition, XP/levels/streaks.
- [x] Repo documentation, README and Claude workflow (this PR).

## Needs owner
- Which language(s) for code-design questions beyond Python/TypeScript?
- Target iOS version: project says 27.0; installed simulators are 26.x.
