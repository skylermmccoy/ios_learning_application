# Lesson (teaching note) format

Teaching notes live in `app/Data/lessons.json`, a JSON array decoded into `TeachingNote` (`app/Models/Lesson.swift`). A note teaches one **topic** of one subject. Questions point at a note with their `topic` field; a lesson on the path shows the notes for the topics its questions contain, as swipeable cards, before the questions start.

## Note

| Field | Type | Required | Meaning |
| --- | --- | --- | --- |
| `subject` | string | yes | A `Subject` raw value. |
| `topic` | string | yes | Kebab-case id, unique within the subject, e.g. `"bubble-sort"`. Questions use the same string. |
| `title` | string | yes | Short lesson name shown on the path, e.g. `"Bubble sort"`. Keep it under about 22 characters. |
| `cards` | array | yes | 3–6 cards, in reading order. |
| `sources` | array | yes | Where the material was checked: `{"title": "...", "url": "https://..."}`. `url` is optional (omit for books). At least one. |

The order of notes in the file is the teaching order: inside a unit of a subject's path, lessons follow it.

## Card

| Field | Type | Required | Meaning |
| --- | --- | --- | --- |
| `title` | string | yes | 2–5 words, e.g. `"The idea"`, `"Step by step"`, `"In Python"`, `"What it costs"`. |
| `body` | string | no | 1–4 plain sentences (aim for under 320 characters). |
| `code` | string | no | Monospaced block: Python, or a small trace/diagram. At most about 12 lines and 34 characters per line so it fits a phone. |
| `bullets` | array of strings | no | 2–5 short facts. |

| `visual` | object | no | A diagram drawn by the app. One per card. See **Visuals** below. |

A card needs at least one of `body`, `code`, `bullets`, `visual`. **Almost every card should have a `visual`** (or `code`): a card that is only prose is the exception. When a card has a visual, keep `body` under about 220 characters and let the picture carry the idea.

## Visuals

`visual` is an object with a `type`, the fields for that type, and an optional `caption` (one line, up to 90 characters). The app draws it natively (`app/Components/CardVisualView.swift`), in the subject's colour, in light and dark mode. Indices are 0-based. Run `python3 .claude/scripts/validate_lessons.py <file>` to check a file against these limits.

| `type` | Use it for | Fields |
| --- | --- | --- |
| `bars` | An array of numbers: sorting passes, search ranges | `values` (2–12 numbers ≥ 0), `labels` (optional strings, default the values), `highlight` (indices in the subject colour), `done` (indices in green), `pointers` (`{"lo": 0, "hi": 5}`, names up to 4 characters) |
| `cells` | A row of boxes: arrays of text, bits, queues, memory, linked lists | `items` (1–10 strings, up to 7 characters each), `highlight`, `done`, `pointers`, `indices` (true shows 0, 1, 2… under the boxes), `arrows` (true draws → between boxes) |
| `flow` | Steps in order, top to bottom with arrows: a handshake, a pipeline, a process | `steps` (2–6 strings, up to 30 characters), `highlight` |
| `stack` | Layers with no arrows, top first: network layers, a call stack | `layers` (2–7 strings, up to 30 characters), `highlight` |
| `graph` | Nodes and edges: graphs, networks, state machines | `nodes` (2–10 of `{"id", "x", "y", "label"}`; `x` and `y` from 0 to 1 with (0,0) top left; `label` optional, up to 8 characters, default the id), `edges` (`{"from", "to", "label"}`; label optional, up to 5 characters), `directed` (true draws arrowheads), `highlight` (node ids), `highlightEdges` (`[["A", "B"]]`) |
| `tree` | Trees, laid out automatically: BSTs, heaps, tries, recursion trees, parse trees | `root` (`{"label", "children"}`; a `null` child keeps an empty slot so a lone right child stays on the right), `highlight` (labels). Up to 15 nodes, 5 levels, labels up to 5 characters |
| `table` | Rows and columns: truth tables, DP grids, cost comparisons, query results | `headers` (optional), `rows` (1–8 rows of up to 6 cells, all the same length, cells up to 16 characters), `highlight` (`[[row, col]]`), `highlightRows` |
| `plot` | Lines on axes: growth rates, a charging curve, a sine wave | `series` (1–5 of `{"label", "points": [[x, y], …]}`, 2–30 points each), `xLabel`, `yLabel`, `yMax` (clip tall curves) |
| `timeline` | Dated events, oldest first | `events` (2–7 of `{"when", "what"}`; `when` up to 10 characters, `what` up to 60) |
| `icons` | A few named ideas side by side: roles, the CIA triad, kinds of fallacy | `items` (2–6 of `{"symbol", "label"}`; `symbol` is an SF Symbol from the allowed list in the validator, `label` up to 16 characters) |
| `compare` | Two things side by side | `left` and `right` (`{"title", "points"}`; title up to 16 characters, 1–4 points of up to 36 characters) |
| `frames` | A step-through: the learner taps Next to advance | `frames` (2–8 visuals of one type, not `frames`), each with its own `caption` saying what changed |

```json
{"title": "One pass", "body": "Compare neighbours and swap when the left one is bigger.",
 "visual": {"type": "frames", "frames": [
   {"type": "bars", "values": [5, 1, 4, 2], "highlight": [0, 1], "caption": "5 > 1, so swap"},
   {"type": "bars", "values": [1, 5, 4, 2], "highlight": [1, 2], "caption": "5 > 4, so swap"},
   {"type": "bars", "values": [1, 4, 5, 2], "highlight": [2, 3], "caption": "5 > 2, so swap"},
   {"type": "bars", "values": [1, 4, 2, 5], "done": [3], "caption": "The largest item is in place"}]}}
```

Rules for visuals:

1. A visual must be correct. Compute traces, tables and plotted points with a script; don't draw them by eye.
2. Pick the type that shows the idea, not decoration. Use `frames` wherever something changes step by step.
3. The caption says what to look at. Don't repeat the card title.
4. Draw your own example. Never redraw a figure, table or worked example from a book.

## Writing rules

1. Own words only. Sources are for checking facts and for the "Sources" links, not for copying text.
2. A note must teach what its questions ask. Read the questions tagged with the topic and make sure each answer can be worked out from the cards (without giving the exact question away).
3. Typical shape: the idea in plain words → a worked example or trace → the code → what it costs and when to use it.
4. Every algorithm states time and space complexity (best/average/worst where they differ).
5. Every Python snippet must run as written.
6. Link only pages that were opened or returned HTTP 200. Never guess URLs.
7. Topics should hold 3–10 questions of the subject. Every question in a subject that has notes gets a `topic`.

## Sources

**The owner's books in `references/` come first** (not committed; extract with `build/extract_books.py` into `build/books/`). Cite as title + chapter with no URL, e.g. `{"title": "Grokking Algorithms (Bhargava, 2016), ch. 4"}`. Teach the same ideas in your own words and with your own examples: never copy or closely paraphrase the book's text, figures, exercises or code, and never reuse a practice-test book's questions.

| Book in `references/` | Use for |
| --- | --- |
| Grokking Algorithms (Bhargava) | Big O, Sorting, Searching, Graphs, Data Structures, Recursion & DP |
| NIST SP 800-115 | Security testing techniques (Security Basics, Nmap, Security+) |
| Penetration Testing Handbook (Molla) | Nmap, Metasploit, Netcat, Security Basics |
| The Web Application Hacker's Handbook | Web application security (planned subject) |
| CompTIA A+ Core 1 / Core 2 practice tests | CompTIA A+ (planned subjects; objectives only) |
| CCNA 200-301 Official Cert Guide (the file holds Vol. 1 only) | Network Protocols, Servers & Services |
| A Mind at Play (Soni, Goodman) | Claude Shannon & Information |
| Practical Electronics for Inventors | Circuits, Electronic Components, Digital Logic |
| Machine Learning with PyTorch and Scikit-Learn | Machine learning (planned subject) |

### Websites the owner asked for (secondary)

- https://www.w3schools.com/ (DSA, Python, cybersecurity sections)
- https://www.khanacademy.org/computing/computer-science/algorithms
- https://www.geeksforgeeks.org/
- https://medium.com/
- https://www.nist.gov/ and https://www.comptia.org/en-us/ (security and certification subjects)

Some of these block automated reading. Use what opens and report the rest in the PR. W3Schools returns 403 to plain `curl`; check its pages with `-A "Mozilla/5.0"` or WebFetch.
