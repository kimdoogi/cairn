#!/usr/bin/env node
// cairn — install the wiki record-keeping structure into a project, for any coding agent.
//
//   npx @doogi/cairn init            create wiki/ + write rules into detected agent files
//   npx @doogi/cairn check           run the wiki consistency checker
//
// Claude Code users can install the plugin instead (/plugin marketplace add kimdoogi/cairn).
// Pure stdlib, no runtime deps.

'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const PKG_ROOT = path.join(__dirname, '..');
const SKILL = path.join(PKG_ROOT, 'skills', 'cairn');
const TEMPLATE = path.join(SKILL, 'template');
const START = '<!-- cairn:start -->';
// A project counts as "dev" when one of these sits at the root — it gets the extra code rules.
const CODE_MARKERS = ['package.json', 'go.mod', 'pom.xml', 'build.gradle', 'build.gradle.kts',
  'Cargo.toml', 'pyproject.toml', 'requirements.txt', 'Gemfile', 'composer.json', 'Makefile', 'src'];
const END = '<!-- cairn:end -->';

// Each target: where its rules file lives, and how we know the agent is in play.
// AGENTS.md is the cross-agent standard (Codex, opencode, Amp, Jules, …) — always written.
const TARGETS = [
  { id: 'agents',  file: 'AGENTS.md',                        always: true },
  { id: 'claude',  file: 'CLAUDE.md',                        detect: ['CLAUDE.md', '.claude'], home: '.claude' },
  { id: 'codex',   file: 'AGENTS.md',                        detect: ['.codex'], home: '.codex' },
  { id: 'gemini',  file: 'GEMINI.md',                        detect: ['GEMINI.md', '.gemini'], home: '.gemini' },
  { id: 'cursor',  file: '.cursor/rules/cairn.mdc',          detect: ['.cursor'], mdc: true },
  { id: 'copilot', file: '.github/copilot-instructions.md',  detect: ['.github'] },
  { id: 'windsurf',file: '.windsurf/rules/cairn.md',         detect: ['.windsurf'] },
  { id: 'cline',   file: '.clinerules/cairn.md',             detect: ['.clinerules'] },
  { id: 'kiro',    file: '.kiro/steering/cairn.md',          detect: ['.kiro'] },
];

function die(msg) { console.error(`cairn: ${msg}`); process.exit(1); }

function parseArgs(argv) {
  const out = { cmd: 'init', dir: process.cwd(), agents: null, all: false, force: false, profile: 'auto', writeIndex: false };
  for (const a of argv) {
    if (a === 'init' || a === 'check' || a === 'help') out.cmd = a;
    else if (a === '--all') out.all = true;
    else if (a === '--force') out.force = true;
    else if (a === '--write-index') out.writeIndex = true;
    else if (a === '-h' || a === '--help') out.cmd = 'help';
    else if (a === '-v' || a === '--version') out.cmd = 'version';
    else if (a.startsWith('--agents=')) out.agents = a.slice(9).split(',').map(s => s.trim()).filter(Boolean);
    else if (a.startsWith('--dir=')) out.dir = path.resolve(a.slice(6));
    else if (a.startsWith('--profile=')) {
      out.profile = a.slice(10);
      if (!['auto', 'dev', 'general'].includes(out.profile)) die(`unknown profile: ${out.profile}`);
    }
    else die(`unknown argument: ${a}`);
  }
  return out;
}

const HELP = `cairn — a record-keeping structure any coding agent can follow.

  npx @doogi/cairn init [options]   create wiki/ and write the workflow rules
  npx @doogi/cairn check [--write-index]   run wiki/check.sh

Options:
  --dir=<path>        project root (default: cwd)
  --agents=a,b        write rules only for these: ${TARGETS.map(t => t.id).join(', ')}
  --profile=P         auto (default) | dev (adds code-project rules) | general
  --all               write rules for every known agent
  --force             overwrite existing wiki files

Claude Code: /plugin marketplace add kimdoogi/cairn && /plugin install cairn@cairn`;

// ── rules payload ──────────────────────────────────────────────────────────
function resolveProfile(root, want) {
  if (want !== 'auto') return want;
  return CODE_MARKERS.some(m => fs.existsSync(path.join(root, m))) ? 'dev' : 'general';
}

function rulesBody(profile) {
  const read = f => fs.readFileSync(path.join(TEMPLATE, f), 'utf8').trim();
  return profile === 'dev' ? `${read('rules-core.md')}\n\n${read('rules-dev.md')}` : read('rules-core.md');
}

// wiki/log.md is append-only, so two branches always collide on the last line.
// git's union driver keeps both sides — the one-line fix for concurrent work.
function gitAttributes(root) {
  if (!fs.existsSync(path.join(root, '.git'))) return null;
  const file = path.join(root, '.gitattributes');
  const line = 'wiki/log.md merge=union';
  const cur = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';
  if (cur.includes(line)) return 'unchanged';
  fs.writeFileSync(file, cur ? `${cur.trimEnd()}\n${line}\n` : `${line}\n`);
  return cur ? 'appended' : 'created';
}

function block(target, body) {
  const head = target.mdc
    ? `---\ndescription: cairn — wiki-first work log, problem log and ADR workflow\nalwaysApply: true\n---\n\n`
    : '';
  return `${head}${START}\n\n${body}\n\n${END}\n`;
}

function writeRules(root, target, body) {
  const file = path.join(root, target.file);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  const text = block(target, body);
  if (!fs.existsSync(file)) { fs.writeFileSync(file, text); return 'created'; }
  const cur = fs.readFileSync(file, 'utf8');
  const s = cur.indexOf(START), e = cur.indexOf(END);
  if (s !== -1 && e !== -1) {                       // already installed → refresh in place
    const next = cur.slice(0, s) + text.slice(text.indexOf(START)) + cur.slice(e + END.length + 1);
    if (next === cur) return 'unchanged';
    fs.writeFileSync(file, next);
    return 'updated';
  }
  fs.writeFileSync(file, `${cur.trimEnd()}\n\n${text}`);
  return 'appended';
}

function pickTargets(root, opts) {
  if (opts.agents) {
    return opts.agents.map(id => {
      const t = TARGETS.find(x => x.id === id);
      if (!t) die(`unknown agent: ${id}`);
      return t;
    });
  }
  if (opts.all) return TARGETS;
  const home = os.homedir();
  const picked = TARGETS.filter(t =>
    t.always ||
    (t.detect || []).some(p => fs.existsSync(path.join(root, p))) ||
    (t.home && fs.existsSync(path.join(home, t.home))));
  // AGENTS.md covers codex — don't report the same file twice.
  const seen = new Set();
  return picked.filter(t => (seen.has(t.file) ? false : seen.add(t.file)));
}

// ── wiki ───────────────────────────────────────────────────────────────────
function installWiki(root, force) {
  const dest = path.join(root, 'wiki');
  const existed = fs.existsSync(dest);
  fs.cpSync(path.join(TEMPLATE, 'wiki'), dest, { recursive: true, force, errorOnExist: false });
  fs.chmodSync(path.join(dest, 'check.sh'), 0o755);
  if (existed && !force) return { dest, status: 'merged (existing files kept)' };
  const today = new Date().toISOString().slice(0, 10);
  const project = path.basename(root);
  for (const rel of ['index.md', 'log.md', 'howto/wiki-workflow.md']) {   // not _templates/ — placeholders stay
    const f = path.join(dest, rel);
    fs.writeFileSync(f, fs.readFileSync(f, 'utf8').replace(/YYYY-MM-DD/g, today).replace(/<프로젝트>/g, project));
  }
  return { dest, status: existed ? 'merged' : 'created' };
}

function check(root, writeIndex) {
  const script = path.join(root, 'wiki', 'check.sh');
  if (!fs.existsSync(script)) die(`no wiki/check.sh under ${root} — run "cairn init" first`);
  const r = spawnSync('bash', writeIndex ? [script, '--write-index'] : [script], { stdio: 'inherit' });
  if (r.error) die('bash not found — run: bash wiki/check.sh (Git Bash / WSL on Windows)');
  process.exit(r.status === null ? 1 : r.status);
}

// ── main ───────────────────────────────────────────────────────────────────
const opts = parseArgs(process.argv.slice(2));
if (opts.cmd === 'help') { console.log(HELP); process.exit(0); }
if (opts.cmd === 'version') { console.log(require(path.join(PKG_ROOT, 'package.json')).version); process.exit(0); }
if (!fs.existsSync(opts.dir)) die(`no such directory: ${opts.dir}`);
if (opts.cmd === 'check') check(opts.dir, opts.writeIndex);

const wiki = installWiki(opts.dir, opts.force);
console.log(`wiki/  ${wiki.status}`);
const profile = resolveProfile(opts.dir, opts.profile);
const attrs = gitAttributes(opts.dir);
if (attrs) console.log(`.gitattributes  ${attrs}  (wiki/log.md merge=union)`);
const body = rulesBody(profile);
for (const t of pickTargets(opts.dir, opts)) console.log(`${t.file}  ${writeRules(opts.dir, t, body)}  (${t.id})`);
console.log(`profile: ${profile}${profile === 'dev' ? ' (code-project rules included)' : ''}`);
console.log(`
next:
  1. fill in wiki/index.md — project name, current state
  2. write the first journal: wiki/journal/${new Date().toISOString().slice(0, 10)}-<slug>.md
  3. move existing design decisions into wiki/decisions/D-001-*.md
  4. verify: bash wiki/check.sh   (index 갱신은 --write-index)`);
