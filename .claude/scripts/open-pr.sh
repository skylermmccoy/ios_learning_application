#!/usr/bin/env bash
# Push the current claude/* branch and open (or refresh) a pull request against main.
# Idempotent and safe to run repeatedly. Never commits, merges, or touches main.
# Always exits 0 so it can run as a Stop hook without blocking Claude.

set -u
cd "${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}" || exit 0

OWNER_ACCOUNT="skylermmccoy"
BASE="main"
BODY_FILE=".claude/pr-body.md"

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" || exit 0
case "$branch" in
  claude/*) ;;
  *) exit 0 ;;   # only act on Claude's own branches
esac

git fetch -q origin "$BASE" 2>/dev/null || { echo "open-pr: cannot reach origin, skipping"; exit 0; }

ahead="$(git rev-list --count "origin/$BASE..HEAD" 2>/dev/null || echo 0)"
[ "$ahead" -gt 0 ] || exit 0   # nothing to review yet

if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  echo "open-pr: warning: uncommitted changes are NOT in the PR; commit them first."
fi

git push -q -u origin "$branch" 2>&1 || { echo "open-pr: push failed"; exit 0; }

# Use the repo owner's gh account; fall back to the active one.
GH_TOKEN="$(gh auth token --user "$OWNER_ACCOUNT" 2>/dev/null || true)"
[ -n "$GH_TOKEN" ] && export GH_TOKEN

if url="$(gh pr view "$branch" --json url,state -q 'select(.state=="OPEN") | .url' 2>/dev/null)" && [ -n "$url" ]; then
  [ -f "$BODY_FILE" ] && gh pr edit "$branch" --body-file "$BODY_FILE" >/dev/null 2>&1
  echo "open-pr: PR updated: $url"
  exit 0
fi

title="$(git log -1 --format=%s "origin/$BASE..HEAD" 2>/dev/null)"
[ "$ahead" -gt 1 ] && title="$(git log --reverse --format=%s "origin/$BASE..HEAD" | head -1)"
if [ -f "$BODY_FILE" ]; then
  body_args=(--body-file "$BODY_FILE")
else
  auto="## Summary
Automated PR from Claude Code (no hand-written description was provided).

## Commits
$(git log --reverse --format='- %s' "origin/$BASE..HEAD")

## How I verified
Not recorded; check the commits and run the build/tests.

🤖 Generated with [Claude Code](https://claude.com/claude-code)"
  body_args=(--body "$auto")
fi

gh pr create --base "$BASE" --head "$branch" --title "$title" "${body_args[@]}" 2>&1 \
  | sed 's/^/open-pr: /'
exit 0
