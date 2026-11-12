# Question format

Built-in questions live in `app/Data/starter_questions.json`, a JSON array decoded into `StarterQuestion` (`app/Data/QuestionBank.swift`).

## Common fields

| Field | Type | Required | Meaning |
| --- | --- | --- | --- |
| `subject` | string | yes | A `Subject` raw value, e.g. `"bigO"`, `"securityPlus"`. See the list below. |
| `kind` | string | no | `multipleChoice` (default), `fillBlank`, `buildCode`, `match`. |
| `prompt` | string | yes | The question text. |
| `code` | string | no | Snippet shown in a monospaced block. |
| `explanation` | string | yes | Shown after answering. Say *why*, not just *what*. |

## Per kind

**multipleChoice**: `choices` (2–4 strings) and `answer` (0-based index of the correct choice).

```json
{"subject": "bigO", "prompt": "Binary search on a sorted array is…", "choices": ["O(1)", "O(log n)", "O(n)", "O(n²)"], "answer": 1, "explanation": "Each step halves the search space."}
```

**fillBlank**: `code` (or `prompt`) contains `___`; `answers` lists every accepted string. Whitespace and smart quotes are ignored when comparing.

```json
{"subject": "python", "kind": "fillBlank", "prompt": "Complete the loop", "code": "for i in ___(5):", "answers": ["range"], "explanation": "range(5) yields 0–4."}
```

**buildCode**: `answers` is the correct tile order (≥ 2 tiles); `extras` are decoy tiles.

**match**: `answers[i]` (code) pairs with `extras[i]` (output). Both arrays must be the same length.

## Subject raw values

- Critical thinking: `logic`, `fallacy`, `patterns`, `factOpinion`
- Algorithms: `bigO`, `sorting`, `searching`, `graphs`, `codeDesign`
- Homework: `discreteMath`, `python`, `bash`, `zsh`, `racket`
- Cybersecurity: `cyber`, `nmap`, `metasploit`, `cve`, `knockd`, `netcat`
- Certifications: `scrum`, `securityPlus`, `aws`, `azure`
- History: `history`

Adding a new subject means editing `Subject.swift` (case, `category`, `displayName`, `icon`) and nothing else; views iterate `Subject.allCases`.

## Authoring rules

1. **Bump `QuestionBank.seedVersion`** when the JSON changes, or installed apps won't reload it.
2. `bankKey` = `prompt + code`. Editing either creates a "new" question and resets its progress; fix typos in `explanation`/`choices` freely, change prompts deliberately.
3. Prompts must be unique within the file (they key the daily set and the seeding sync).
4. Exactly one defensible correct answer. Avoid trick wording and "all of the above".
5. Make distractors plausible: common misconceptions, not silly options.
6. For code: prefer short snippets that run as written. State the language in the subject, not the prompt.
7. For algorithms (the owner's priority): include complexity (best/avg/worst, time/space) in explanations, and favor Code Builder / Fill the Blank for implementing the algorithm.
8. Never invent facts for certifications or history; if unsure, leave it out and note it in the PR.
9. Run the tests: `starterQuestionsAreValid` checks indices, blanks, tile counts and pair lengths.

## Importing from other sources

`qustions.txt` is the owner's running topic list. The owner's terminal tutor tracks (`~/Code/claude/tutor/tracks/`, TOML lessons for Racket and zsh) were imported as `blank` exercises only; `predict` exercises still need their outputs computed before import.
