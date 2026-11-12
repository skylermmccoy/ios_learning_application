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

A card needs at least one of `body`, `code`, `bullets`.

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
| CCNA 200-301 Official Cert Guide | Networking / CCNA (planned subject) |
| A Mind at Play (Soni, Goodman) | Computer History: Claude Shannon |
| Practical Electronics for Inventors | Electronics (planned subject) |
| Machine Learning with PyTorch and Scikit-Learn | Machine learning (planned subject) |

### Websites the owner asked for (secondary)

- https://www.w3schools.com/ (DSA, Python, cybersecurity sections)
- https://www.khanacademy.org/computing/computer-science/algorithms
- https://www.geeksforgeeks.org/
- https://medium.com/
- https://www.nist.gov/ and https://www.comptia.org/en-us/ (security and certification subjects)

Some of these block automated reading. Use what opens and report the rest in the PR. W3Schools returns 403 to plain `curl`; check its pages with `-A "Mozilla/5.0"` or WebFetch.
