---
description: Write the PR description and open (or update) the pull request for the current claude/* branch
---

1. Make sure you're on a `claude/*` branch (never `main`) and everything is committed (`git status`). Commit leftovers first.
2. Optionally run the `build-verifier`, `swift-reviewer` and `docs-keeper` agents if you haven't, and fix what they find.
3. Write the PR description to `.claude/pr-body.md` using the template in `CLAUDE.md` (Summary, Changes, How I verified, Decisions I made, Needs owner, Review tips). Be honest about anything not run. End it with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.
4. Run `.claude/scripts/open-pr.sh`.
5. Reply with the PR URL and a 2–3 line summary. Do not merge.
