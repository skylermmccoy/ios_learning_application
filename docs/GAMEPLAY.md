# Gameplay rules

Source of truth is the code; this describes it. If you change a rule, change both.

## Quiz modes (`QuizMode`)

| Mode | Questions | Timer | Notes |
| --- | --- | --- | --- |
| `daily` | 5 mixed | no | Same set all day (`QuestionBank.dailySet`, stable FNV-1a hash of date + prompt). Drives the streak. |
| `timed` | 10 | yes | Per-question limits below. |
| `practice` | any | no | E.g. your own questions, weak spots. |
| `level` | one level of a path | no | Awards 1–3 stars. |

Timed limits (`QuestionKind.timeLimit`): Quick Pick 20s, Fill the Blank 30s, Code Builder 45s, Match-Up 45s.

## Lives, score, combo (`GameState`)

- 3 lives. A wrong answer costs 1; at 0 the run ends.
- Combo = correct answers in a row; resets on a wrong answer.
- Multiplier = `min(1 + combo / 3, 4)` → x1, x2 (3 in a row), x3 (6), x4 (9+).
- Points per correct answer = `(base + speedBonus) × multiplier`
  - `base` = 100, or 50 if a hint was used
  - `speedBonus` = `timeFraction × 50` in timed mode, else 0
- Points earned count as XP.

## Player level (`Level`)

Level *L* starts at `200 · (L-1) · L` XP: L2 = 400, L3 = 1200, L4 = 2400, L5 = 4000. Titles: 1–2 Novice, 3–4 Apprentice, 5–7 Thinker, 8–11 Logician, 12+ Mastermind.

## Learning path (`LearningPath`)

`LearningPath.path(for:)` turns a subject's questions into an ordered list of `PathLevel`s:

- **Units.** Questions are grouped by `difficulty`: 1 Foundations, 2 Core, 3 Advanced. A unit with fewer than 3 questions joins its neighbour. Questions without a `difficulty` are rated by format (Quick Pick and Match-Up 1, Fill the Blank 2, Code Builder 3).
- **Lessons.** Inside a unit, questions are sorted by format (Quick Pick, Match-Up, Fill the Blank, Code Builder), then built-in before user-made, then bank order, and cut into lessons of 5 (`levelSize`). A last lesson with fewer than 3 questions is merged into the previous one. Lessons are untimed.
- **Unit review.** A unit with two or more lessons ends with a timed review of up to 8 questions (`reviewSize`) spread evenly across the unit.
- **Mastery challenge.** A subject with at least 10 questions and two lessons ends with a timed challenge of 10 questions (`masterySize`) spread across every difficulty.
- Levels unlock in order. A level is passed by finishing it with at least one heart left.
- Progress is stored by position on the path, so adding questions to a subject can shift which levels count as completed.
- Stars = hearts left when the level is finished (1–3). One `LevelProgress` per subject + level.
- `LearningPath.progress(levelCount:records:)` gives levels done, total and stars for a subject (records past the end of the path are ignored). `resumeSubject` picks the subject for the Learn tab's Continue card: the one with the most recently finished level that still has levels left. With nothing in progress the card offers Big O.
- Tapping a level opens a preview sheet (question count, timed or not, hearts, formats from `PathLevel.kindCounts`); the quiz starts from its Start button.
- "Weak subjects": at least 5 answers and under 85% correct, weakest first (max 3). "Weak spots": questions with the highest `timesWrong - timesCorrect`.

## Spaced repetition (`Question.recordAnswer`)

A correct answer queues two more reviews inside a week; a wrong answer brings the question back tomorrow.

| Event | Result |
| --- | --- |
| Wrong | `isMastered = false`, `reviewsLeft = 2`, due tomorrow |
| First correct (not scheduled) | `reviewsLeft = 2`, due in 2 days |
| Correct when due | `reviewsLeft -= 1`; if still > 0 due in 3 days, else cleared and `isMastered = true` |
| Correct before due | Counted in stats but does not advance the schedule |

`QuestionBank.dueForReview` returns questions whose `nextReview` has passed (oldest first). Dates use `startOfDay`.

## Streak

Consecutive days (ending today or yesterday) with a finished **daily** challenge (`QuestionBank.streak`).

## Answer checking

Typed answers (`Question.accepts`) ignore all whitespace and normalize smart quotes; any entry in `answers` is accepted.
