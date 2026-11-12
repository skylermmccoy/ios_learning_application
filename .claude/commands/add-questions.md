---
description: "Add quiz questions. Usage: /add-questions <subject> [count]"
argument-hint: <subject> [count]
---

Add questions for: $ARGUMENTS

1. Resolve the subject to a `Subject` raw value (see `docs/QUESTION_FORMAT.md`). Default count: 15.
2. Delegate to the `question-writer` agent (split across several in parallel if the count is large or multiple subjects are requested).
3. Run the `build-verifier` agent (JSON validity + `starterQuestionsAreValid`).
4. Update question counts in `README.md` and commit.
