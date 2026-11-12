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
| `difficulty` | int | no | `1` foundations, `2` core, `3` advanced. Decides which unit of the subject's path the question lands in. If missing: multipleChoice/match = 1, fillBlank = 2, buildCode = 3. |
| `ref` | string | no | "Read more" URL shown after answering. Use only URLs that were checked to exist. If missing, the subject's `referenceURL` (in `Subject.swift`) is used. |

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
- Algorithms: `bigO`, `sorting`, `searching`, `graphs`, `dataStructures`, `recursion`, `codeDesign`
- Homework: `discreteMath`, `python`, `java`, `bash`, `zsh`, `racket`, `prolog`, `lean4`, `parsing`
- Cybersecurity: `cyber`, `nmap`, `metasploit`, `cve`, `knockd`, `netcat`
- Certifications: `scrum`, `securityPlus`, `aws`, `azure`
- History: `history`

Adding a new subject means editing `Subject.swift` (case, `category`, `displayName`, `icon`, `tagline`) and nothing else; views iterate `Subject.allCases`.

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

The file is kept sorted by subject (in `Subject` order), then `difficulty`; add new questions next to their peers.

`references/` holds the owner's homework (Prolog, Racket, a Python scanner/parser). It is not committed; the Prolog, Racket and Scanners & Parsers questions are based on it.

`qustions.txt` is the owner's running topic list. The owner's terminal tutor tracks (`~/Code/claude/tutor/tracks/`, TOML lessons for Racket and zsh) were imported as `blank` exercises only; `predict` exercises still need their outputs computed before import.

## Reference links

The owner asked for W3Schools as a reference. Write questions in your own words (don't copy their text) and link to the matching page with `ref`. These pages were checked to exist on 2026-11-11 (prefix `https://www.w3schools.com/`):

- Python: `python/python_lists.asp`, `python_dictionaries.asp`, `python_functions.asp`, `python_classes.asp`, `python_strings.asp`, `python_tuples.asp`, `python_sets.asp`, `python_try_except.asp`, `python_file_handling.asp`, `python_lambda.asp`, `python_iterators.asp`
- Java: `java/java_variables.asp`, `java_data_types.asp`, `java_strings.asp`, `java_arrays.asp`, `java_methods.asp`, `java_classes.asp`, `java_constructors.asp`, `java_modifiers.asp`, `java_inheritance.asp`, `java_polymorphism.asp`, `java_abstract.asp`, `java_interface.asp`, `java_arraylist.asp`, `java_hashmap.asp`, `java_try_catch.asp`, `java_for_loop.asp`
- Algorithms: `dsa/dsa_algo_bubblesort.php`, `dsa_algo_selectionsort.php`, `dsa_algo_insertionsort.php`, `dsa_algo_quicksort.php`, `dsa_algo_mergesort.php`, `dsa_algo_countingsort.php`, `dsa_algo_linearsearch.php`, `dsa_algo_binarysearch.php`, `dsa_theory_graphs.php`, `dsa_algo_graphs_traversal.php`, `dsa_algo_graphs_dijkstra.php`, `dsa_algo_mst_kruskal.php`, `dsa_algo_mst_prim.php`, `dsa_theory_hashtables.php`, `dsa_data_stacks.php`, `dsa_data_queues.php`, `dsa_ref_dynamic_programming.php`
- Section home pages: `python/default.asp`, `java/default.asp`, `bash/index.php`, `dsa/index.php`, `typescript/index.php`, `cybersecurity/index.php`, `aws/index.php`, `git/default.asp`

Don't guess other URLs. Check a new one with `curl -s -o /dev/null -w "%{http_code}" -L <url>` first. W3Schools has no Prolog, Lean or Racket pages.
