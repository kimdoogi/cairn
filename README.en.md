# cairn

A tool that drops a **record-keeping structure** into a project: work journal · problem log · decisions (ADR) · concepts · experiments, plus a consistency checker.
Not just for coding — research, writing, planning and study work use the same structure.

[![npm](https://img.shields.io/npm/v/@doogi/cairn)](https://www.npmjs.com/package/@doogi/cairn)
[![license](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

한국어: [README.md](README.md)

> A cairn is a stack of stones on a trail, left so the next person doesn't lose the path.

## Why

Working with an agent, the code piles up but the context doesn't. When the session ends, *why it was built this way*, *what that error was*, and *what was tried and abandoned* are gone. The next session's agent doesn't know any of it and repeats the same dead ends.

cairn writes that context to disk, so that you in three weeks — and the next agent — can **pick up the work from the wiki alone**.

- **problem log** — symptom, reproduction, cause, fix, prevention. Including the attempts that failed and the approaches dropped. That part is the most expensive to rediscover.
- **decisions (ADR)** — with the rejected alternatives and the reason. A decision that exists only in conversation does not exist.
- **journal + log** — dated work notes and a one-line summary each. The entry point for recovering context.
- **check.sh** — a machine catches the rot: broken links, missing frontmatter, pages not listed in the index, colliding numbers.

## Install

**Claude Code** — as a plugin:

```
/plugin marketplace add kimdoogi/cairn
/plugin install cairn@cairn
```

**Any other agent** — from the project root:

```bash
npx @doogi/cairn init
```

If the project has a `package.json`, `go.mod`, `pom.xml`, `Cargo.toml`, `pyproject.toml`, `src/` and so on, the **code-project rules** (documents win, `P-NNN` in fix commits, golden sets) are added on top; otherwise only the general rules are written. Choose explicitly with `--profile=dev|general`, and the language with `--lang=en|ko` (defaults to `$LANG`).

## What you get

```
wiki/
├── index.md          current state · page listing · next number   ← start of every session
├── log.md            one line per day (append-only)
├── check.sh          consistency checker
├── journal/          2026-08-21-<slug>.md   dated work notes
├── problems/         P-001-<slug>.md        problem → fix
├── decisions/        D-001-<slug>.md        ADR
├── concepts/         <slug>.md              what you understood
├── experiments/      E1-<slug>.md           attempts and measurements
├── howto/            runbooks
└── _templates/       templates for the five page types
```

…plus a rules block written into the rules file of every agent it detects:

| Agent | File |
|---|---|
| Codex · opencode · Amp etc. | `AGENTS.md` (cross-agent standard, always written) |
| Claude Code | `CLAUDE.md` |
| Gemini CLI | `GEMINI.md` |
| Cursor | `.cursor/rules/cairn.mdc` |
| GitHub Copilot | `.github/copilot-instructions.md` |
| Windsurf | `.windsurf/rules/cairn.md` |
| Cline | `.clinerules/cairn.md` |
| Kiro | `.kiro/steering/cairn.md` |

Pick with `--agents=cursor,codex`, or write them all with `--all`. The block is wrapped in `<!-- cairn:start -->` markers, so **re-running updates only that block** and leaves rules you wrote yourself alone. Existing `wiki/` files are never overwritten (unless `--force`).

## Using it

Once installed, the rules live in the agent's own rules file, so **the agent does this on its own**. There is almost nothing for you to memorize.

| When | What happens | If it doesn't, say |
|---|---|---|
| Session start | Reads `index.md` → `log.md` → in-progress journals before working | "read the wiki first" |
| Error / blocker | Creates `problems/P-NNN-*.md` right away | "log that as a problem" |
| A choice is made | Writes `decisions/D-NNN-*.md` | "record that decision as an ADR" |
| Session end | Finishes the journal → one line in `log.md` → updates `index.md` | "write up today's work in the wiki" |

## Checking

```bash
bash wiki/check.sh                 # check only
bash wiki/check.sh --write-index   # regenerate index lists + next number from disk, then check
```

Catches missing frontmatter, broken relative links, pages missing from the index, **duplicate numbers**, and a stale "next number". Exit code 0/1, so it drops straight into CI:

```yaml
- run: bash wiki/check.sh
```

The checker is copied in with the wiki, so it runs on a CI runner that has never heard of cairn.

## Working with several people

All three failure modes come from hand-maintaining shared state.

| Problem | Fix |
|---|---|
| `log.md` append conflicts | `wiki/log.md merge=union` in `.gitattributes` — written by `init`. Both sides' lines survive |
| `index.md` conflicts | Don't hand-write the list sections. On conflict, regenerate with `--write-index`. Humans only write the few "current state" lines |
| Number collisions (two `P-001`) | `check.sh` catches duplicates. Renumber on merge and fix the references with `grep -rn` |

Two conventions: **put the wiki in the same PR as the code** (the record gets reviewed; a separate PR always slips), and **one journal file per person** (`2026-08-21-alex-<slug>.md` — different files never conflict).

## Golden sets

For projects that touch external APIs, protocols or format conversion, use the convention in `skills/cairn/references/goldenset.md`.

Record real responses through a sanitizer into `fixtures/` → tests **replay fixtures only** (no network) → compare snapshots → new recordings join the set by directory scan. Until the golden set exists, the converter isn't done.

## Layout

| Path | What |
|---|---|
| `skills/cairn/SKILL.md` | The skill — install procedure, session loop, recording rules |
| `skills/cairn/template/wiki/`, `wiki.en/` | The wiki skeleton that gets copied, plus the five templates |
| `skills/cairn/template/check.sh` | The consistency checker (one copy, both languages) |
| `skills/cairn/template/rules-core*.md` | The general workflow block injected into agent rules files |
| `skills/cairn/template/rules-dev*.md` | Extra rules for code projects (documents win, commit convention, golden sets) |
| `cli/cairn.js` | The npm installer — agent detection and block injection. Zero dependencies |

## Origin

Generalized from the wiki system in [java-heavy-traffic](https://github.com/kimdoogi/java-heavy-traffic) and the documentation and golden-set practice in [AIgateway](https://github.com/kimdoogi/AIgateway).

## License

MIT
