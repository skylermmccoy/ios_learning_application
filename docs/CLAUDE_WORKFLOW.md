# Claude Code workflow

The goal: the owner only has to look at a pull request. Claude does the rest.

## Flow

```
owner gives a task (or Claude takes the next ROADMAP item)
        │
        ▼
claude/<topic> branch ─▶ implement + tests + docs ─▶ verify ─▶ commit
        │                                                         │
        └──────── next unchecked ROADMAP item ◀───────────────────┘
        │ (when batch is done or blocked)
        ▼
.claude/pr-body.md  ─▶  /open-pr  ─▶  PR against main  ─▶  owner reviews & merges
```

## What's in `.claude/`

| Path | Purpose |
| --- | --- |
| `settings.json` | Denies pushing to `main`, force-push and PR merging; registers the Stop hook. |
| `scripts/open-pr.sh` | Pushes the current `claude/*` branch and opens (or updates) the PR. Idempotent. |
| `commands/open-pr.md` | `/open-pr`: write the PR body, run the script, report the URL. |
| `commands/next-task.md` | `/next-task`: take the next unchecked ROADMAP item. |
| `commands/add-questions.md` | `/add-questions <subject> [n]`: author and validate new questions. |
| `agents/question-writer.md` | Writes accurate questions in the right JSON format. |
| `agents/swift-reviewer.md` | Read-only review of Swift changes before the PR. |
| `agents/docs-keeper.md` | Keeps `docs/` and README in sync with code. |
| `agents/build-verifier.md` | Runs build and tests and reports faithfully. |
| `pr-body.md` (git-ignored) | The PR description Claude writes before opening the PR. |

## Continuing to work

`CLAUDE.md` tells Claude to keep pulling items from `docs/ROADMAP.md` ("Next up") until the list is empty, a decision is needed from the owner, or the batch is large enough to review. Anything that needs the owner goes under **Needs owner** in the PR. The owner can add items to the roadmap (or to `qustions.txt`) at any time; those are picked up next run.

## The PR safety net

A `Stop` hook runs `scripts/open-pr.sh` whenever Claude finishes a turn. It does nothing unless **all** are true: the branch matches `claude/*`, it has commits ahead of `origin/main`, and the `origin` remote is reachable. It then pushes the branch and creates the PR if none exists (or refreshes the body from `.claude/pr-body.md` if one does). It never commits uncommitted changes. It warns about them.

## Authentication

- **Git push** uses SSH (`git@github.com:skylermmccoy/ios_learning_application.git`).
- **PR creation** uses the `gh` CLI. The script uses the token for the `skylermmccoy` account (`gh auth token --user skylermmccoy`) because the other logged-in account (`skyler-mm`) has no write access to this repo. If you log out of that account, run `gh auth login` again.

## Guardrails

- No pushes to `main`, no merging, no force-pushes (enforced in `settings.json` deny rules).
- The owner is the only one who merges.
- Claude states what it did *not* verify in the PR rather than implying success.

## Recommended GitHub settings (owner, one-time)

Protect `main`: Settings → Branches → require a pull request before merging. That makes the PR the only way in even if a rule above is bypassed.
