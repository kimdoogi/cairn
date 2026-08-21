---
title: "How to use this wiki (human summary)"
date: YYYY-MM-DD
status: live
tags: [howto, process]
related: []
---

## Where to look
| Question | Where |
|---|---|
| Where are we right now? | [index.md](../index.md) "Current state" → last lines of [log.md](../log.md) |
| What went wrong and how was it fixed? | [index.md](../index.md) Problems → `problems/P-NNN-*.md` |
| Why was it built this way? | `decisions/D-NNN-*.md` |
| What did the measurements say? | `experiments/E<N>-*.md` (raw data in `../results/`) |
| What does this concept mean? | `concepts/*.md` |
| How do I run it? | `howto/*.md` |
| What happened on a given day? | `journal/YYYY-MM-DD-*.md` |

## The loop (same as the agent rules)
read (index → log → in-progress journal) → create today's journal → record problems/decisions/concepts/experiments as they happen → finish the journal → append one line to log → update index → commit

## Creating a page
- Copy from `_templates/`, fill the frontmatter, take the number from the index "Next number" and bump it there (or run `bash wiki/check.sh --write-index`).
- Filenames: `P-001-hikari-pool-exhausted.md`, `D-004-gc-choice.md`, `E2-io-bound.md`, `concepts/backpressure.md`, `journal/2026-08-20-skeleton.md`

## Checking
- `bash wiki/check.sh` — frontmatter, links, unlisted pages, duplicate/stale numbers. Put the same line in CI.
- `bash wiki/check.sh --write-index` — regenerate the index lists (this is how you resolve an index.md merge conflict).
- Search: `grep -rn "keyword" wiki/`
- Open the folder as an Obsidian vault for graph view; the links are plain relative markdown so GitHub renders them too.
