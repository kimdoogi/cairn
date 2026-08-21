# cairn

프로젝트에 "기록이 남는 구조"를 딸각 설치하는 Claude Code 플러그인.
llm-wiki(journal / problems / decisions / concepts / experiments / howto + index + log) + CLAUDE.md 워크플로우 규칙 + 위키 정합성 체커 + 골든셋 테스트 규약.

> cairn(케언) — 길 위에 돌을 쌓아 다음 사람이 길을 잃지 않게 하는 표식.

출처: [java-heavy-traffic](https://github.com/kimdoogi/java-heavy-traffic)의 wiki 체계와 [AIgateway](https://github.com/kimdoogi/AIgateway)의 문서·골든셋 운영을 일반화했다.

## 설치

**Claude Code** — 플러그인:

```
/plugin marketplace add kimdoogi/cairn
/plugin install cairn@cairn
```

**그 외 에이전트** (Codex · Cursor · Gemini CLI · Copilot · Windsurf · Cline · Kiro) — 프로젝트 루트에서:

```bash
npx @doogi/cairn init
```

`wiki/`를 만들고, 그 프로젝트에서 감지된 에이전트의 규칙 파일에 워크플로우 블록을 써 넣는다.

| 에이전트 | 쓰는 파일 |
|---|---|
| Codex · opencode · Amp 등 | `AGENTS.md` (범용 표준, 항상 씀) |
| Claude Code | `CLAUDE.md` |
| Gemini CLI | `GEMINI.md` |
| Cursor | `.cursor/rules/cairn.mdc` |
| GitHub Copilot | `.github/copilot-instructions.md` |
| Windsurf | `.windsurf/rules/cairn.md` |
| Cline | `.clinerules/cairn.md` |
| Kiro | `.kiro/steering/cairn.md` |

`--agents=cursor,codex`로 골라 쓰고, `--all`로 전부 쓴다. 블록은 `<!-- cairn:start -->` 마커로 감싸므로 재실행하면 그 블록만 갱신되고 나머지 내용은 그대로 둔다. 기존 `wiki/` 파일도 덮어쓰지 않는다(`--force` 제외).

## 사용

- 새 프로젝트에서 `cairn init` (또는 "위키 체계 깔아줘"): `wiki/` 생성 + CLAUDE.md에 워크플로우 규칙 병합 + 첫 journal 작성.
- 설치 후에는 CLAUDE.md가 매 세션 루프를 강제한다: index/log 읽기 → journal 생성 → 문제·결정 즉시 기록 → index·log 갱신.
- 점검: `bash wiki/check.sh` 또는 `npx @doogi/cairn check` (체커가 위키와 함께 복사되므로 CI에도 같은 줄을 넣으면 된다).

## 왜

코드는 남는데 "무엇을 왜 어떻게 했고 뭐가 문제였는지"는 안 남는다. 세션이 끝나면 에이전트의 맥락도 같이 사라진다.
cairn은 그 맥락을 파일로 떨어뜨려서, 몇 주 뒤의 나와 다음 세션의 에이전트가 위키만 읽고 이어서 일하게 만든다.

- **problem log** — 에러와 막힌 지점을 증상·재현·원인·해결·재발 방지까지. 실패한 시도도 남긴다.
- **ADR** — 기각한 대안과 이유까지. 구두로만 존재하는 결정은 없는 결정이다.
- **journal + log** — 날짜별 작업과 한 줄 요약. 세션 복구의 진입점.
- **골든셋** — 외부 API·포맷 변환을 다루면 픽스처 녹화 → 재생 → 스냅샷이 "완성"의 정의다.

## 구성

| 경로 | 내용 |
|---|---|
| `skills/cairn/SKILL.md` | 스킬 본문 — init 절차, 세션 루프, 기록 규칙 |
| `skills/cairn/template/wiki/` | 그대로 복사되는 위키 뼈대 + `_templates/` 5종 + `check.sh` |
| `skills/cairn/template/CLAUDE.cairn.md` | 프로젝트 CLAUDE.md에 붙이는 워크플로우 규칙 |
| `skills/cairn/references/goldenset.md` | 골든셋(픽스처 녹화 → 재생 → 스냅샷) 규약 |
| `cli/cairn.js` | npm 설치기 — 에이전트 감지 + 규칙 블록 주입 (의존성 0) |

## 라이선스

MIT
