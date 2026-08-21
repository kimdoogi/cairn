## Wiki-first workflow (every session)

"Work → record → repeat". The work can move fast, but the record must not break. Weeks later, someone must be able to reconstruct *what was done, why, what went wrong, and how it was fixed* from the wiki alone.

1. **Start of session**: read `wiki/index.md` → recent entries in `wiki/log.md` → any journal with `status: in-progress`, then start working.
2. **Start of work**: create `wiki/journal/YYYY-MM-DD-<slug>.md` from `wiki/_templates/journal.md` and write the goal and scope first.
3. **During work** (record as it happens, never in one batch at the end):
   - Problem, blocker, unexpected result → `wiki/problems/P-NNN-<slug>.md`. Write symptom, reproduction and the actual output first; fill in cause, fix and prevention once solved. Leave `status: open` if unresolved.
   - A choice of direction or method → `wiki/decisions/D-NNN-<slug>.md` (context, options, decision, reasoning, consequences — including the rejected alternatives and why).
   - Something newly understood → `wiki/concepts/<slug>.md`.
   - An attempt, measurement or comparison → `wiki/experiments/E<N>-<slug>.md` (hypothesis / setup / results / interpretation). Keep raw data in `results/` and link to it.
4. **End of session**: finish the journal (what was done, results, what's left) → append one line to `wiki/log.md` → update `wiki/index.md` (or run `bash wiki/check.sh --write-index`).
5. **Saving**: save and share in work-sized units (one journal). In a git repo, commit per journal.

## Recording rules

- Every page starts with frontmatter (`title/date/status/tags/related`). Templates live in `wiki/_templates/`.
- Links are relative markdown links. Connect problem ↔ journal ↔ concept ↔ experiment ↔ decision generously.
- `P-`/`D-` numbers come from "Next number" in `wiki/index.md` and are never reused.
- Facts only: what was actually done, actually observed, actually measured or quoted. Mark guesses as hypotheses and update them once checked.
- Record failures too: the attempts that did not work and the approaches that were dropped, with the reason. This is the most valuable part of the record.
- When the same fact lives in several documents, `grep -rn` for all of them and fix them together.
- When a prevention rule falls out of a problem, don't leave it in the problem — promote it into this rules file or a decision.

## Decisions live in documents

- A decision that exists only in conversation does not exist. Once a direction is set, write it into `wiki/decisions/`.
- If you find something that contradicts an existing decision, don't quietly route around it: amend or supersede the decision document and record the discovery as a problem.
- When the session ends, the context is gone. The wiki is what's left.
