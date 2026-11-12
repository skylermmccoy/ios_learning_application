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

- Levels hold 5 questions (`levelSize`).
- Questions are sorted easy → hard by format: Quick Pick, Match-Up, Fill the Blank, Code Builder; then built-in before user-made, then bank order. Later levels therefore contain harder formats.
- A final level with fewer than 3 questions is merged into the previous one.
- Stars = hearts left when the level is finished (1–3). One `LevelProgress` per subject + level.
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
