---
description: Take the next unchecked item from docs/ROADMAP.md and carry it through
---

1. Read `docs/ROADMAP.md`. If on `main`, create a `claude/<topic>` branch first.
2. Take the first unchecked item under "Next up" that isn't marked `(needs owner)`.
3. Implement it with tests and doc updates; verify (see `CLAUDE.md`); commit.
4. Tick it in the roadmap (move to "Done") in the same commit.
5. Repeat with the next item until the list is empty, a decision is needed, or ~5–8 items are done. Then run `/open-pr`.
