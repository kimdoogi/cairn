# cairn

프로젝트에 **기록이 남는 구조**를 딸각 설치하는 도구. 작업 일지 · 문제 기록 · 결정 기록(ADR) · 개념 정리 · 실험 기록 + 정합성 체커.
코딩뿐 아니라 리서치·집필·기획·학습 작업에도 그대로 쓴다.

[![npm](https://img.shields.io/npm/v/@doogi/cairn)](https://www.npmjs.com/package/@doogi/cairn)
[![license](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

English: [README.en.md](README.en.md)

> cairn(케언) — 길 위에 돌을 쌓아 다음 사람이 길을 잃지 않게 하는 표식.

## 왜

에이전트와 일하면 코드는 쌓이는데 맥락은 안 쌓인다. 세션이 끝나면 "왜 이렇게 짰는지", "그때 그 에러가 뭐였는지", "뭘 시도했다 버렸는지"가 통째로 사라진다. 다음 세션의 에이전트는 그걸 모른 채 같은 삽질을 반복한다.

cairn은 그 맥락을 파일로 떨어뜨린다. 몇 주 뒤의 나와 다음 세션의 에이전트가 **위키만 읽고 이어서 일할 수 있게**.

- **problem log** — 증상·재현·원인·해결·재발 방지. 실패한 시도와 버린 접근도 남긴다. 이게 제일 값비싼 기록이다.
- **ADR** — 기각한 대안과 그 이유까지. 구두로만 존재하는 결정은 없는 결정이다.
- **journal + log** — 날짜별 작업과 한 줄 요약. 세션 복구의 진입점.
- **check.sh** — 기록이 썩는 걸 기계가 잡는다. 링크 깨짐, frontmatter 누락, index 미등록, 번호 꼬임.

## 설치

**Claude Code** — 플러그인:

```
/plugin marketplace add kimdoogi/cairn
/plugin install cairn@cairn
```

**그 외 에이전트** — 프로젝트 루트에서:

```bash
npx @doogi/cairn init
```

프로젝트에 `package.json`·`go.mod`·`pom.xml`·`Cargo.toml`·`pyproject.toml`·`src/` 같은 게 있으면 **코드 프로젝트 규칙**(문서 우선, 커밋에 `P-NNN`, 골든셋)이 추가로 붙고, 없으면 범용 규칙만 붙는다. `--profile=dev|general`로 직접 고를 수도 있다.

## 생기는 것

```
wiki/
├── index.md          현재 상태 · 전체 페이지 목록 · 다음 번호   ← 세션 시작점
├── log.md            날짜별 한 줄 요약 (append-only)
├── check.sh          정합성 체커
├── journal/          2026-08-21-<슬러그>.md   날짜별 작업 기록
├── problems/         P-001-<슬러그>.md        문제 → 해결
├── decisions/        D-001-<슬러그>.md        ADR
├── concepts/         <슬러그>.md              학습한 개념
├── experiments/      E1-<슬러그>.md           측정·실험
├── howto/            런북
└── _templates/       위 5종 템플릿
```

그리고 감지된 에이전트의 규칙 파일에 워크플로우 블록이 들어간다:

| 에이전트 | 파일 |
|---|---|
| Codex · opencode · Amp 등 | `AGENTS.md` (범용 표준, 항상 씀) |
| Claude Code | `CLAUDE.md` |
| Gemini CLI | `GEMINI.md` |
| Cursor | `.cursor/rules/cairn.mdc` |
| GitHub Copilot | `.github/copilot-instructions.md` |
| Windsurf | `.windsurf/rules/cairn.md` |
| Cline | `.clinerules/cairn.md` |
| Kiro | `.kiro/steering/cairn.md` |

`--agents=cursor,codex`로 골라 쓰고 `--all`로 전부 쓴다. 위키·규칙 언어는 `--lang=ko|en`(기본값은 `$LANG`에서 자동). 블록은 `<!-- cairn:start -->` 마커로 감싸므로 **재실행하면 그 블록만 갱신**되고 직접 쓴 규칙은 그대로 남는다. 기존 `wiki/` 파일도 덮어쓰지 않는다 (`--force` 제외).

## 쓰는 법

깔고 나면 규칙이 에이전트 규칙 파일에 박히므로 **에이전트가 알아서 한다.** 사람이 외울 건 거의 없다.

| 언제 | 무슨 일이 일어나나 | 안 하면 이렇게 시킨다 |
|---|---|---|
| 세션 시작 | `index.md` → `log.md` → 진행 중 journal 순으로 읽고 시작 | "위키 읽고 시작해" |
| 에러·막힘 | `problems/P-NNN-*.md` 즉시 생성 | "방금 그거 problem으로 남겨" |
| 설계 선택 | `decisions/D-NNN-*.md` 작성 | "이 결정 ADR로 남겨" |
| 세션 종료 | journal 마무리 → `log.md` 한 줄 → `index.md` 갱신 | "오늘 작업 위키에 정리해" |

## 점검

```bash
bash wiki/check.sh                 # 점검만
bash wiki/check.sh --write-index   # index 목록·다음 번호를 파일 스캔으로 재생성 후 점검
```

frontmatter 누락, 깨진 상대 링크, index에 등록 안 된 고아 페이지, **번호 중복**, index "다음 번호" 역전을 잡는다. 종료 코드 0/1이라 CI에 그대로 넣으면 된다.

```yaml
- run: bash wiki/check.sh
```

체커는 위키와 함께 복사되므로 cairn이 안 깔린 CI 러너에서도 돈다.

## 여러 명이 작업할 때

정합성이 깨지는 지점 셋은 전부 "중앙 상태를 손으로 관리"해서 생긴다.

| 문제 | 해결 |
|---|---|
| `log.md` append 충돌 | `.gitattributes`의 `wiki/log.md merge=union` — init이 자동으로 넣는다. 양쪽 줄이 다 남는다 |
| `index.md` 충돌 | 목록 섹션은 손으로 쓰지 않는다. 충돌하면 `--write-index`로 재생성. 사람이 쓰는 건 "현재 상태" 몇 줄뿐 |
| 번호 충돌 (`P-001` 둘) | `check.sh`가 중복을 잡는다. 머지 시 재번호하고 `grep -rn`으로 참조를 함께 고친다 |

관습 둘: **위키를 코드와 같은 PR에 넣는다** (기록이 리뷰에 걸린다. 별도 PR로 빼면 반드시 밀린다). **journal은 사람마다 별개 파일** (`2026-08-21-doogi-<슬러그>.md` — 파일이 다르면 충돌 자체가 없다).

## 골든셋

외부 API·프로토콜·포맷 변환을 다루는 프로젝트라면 `skills/cairn/references/goldenset.md`의 규약을 함께 쓴다.

실 응답을 새니타이저에 통과시켜 `fixtures/`에 녹화 → 테스트는 **픽스처 재생만**(네트워크 금지) → 스냅샷 비교 → 새 녹화는 디렉토리 스캔으로 자동 편입. 골든셋이 붙기 전까지 어댑터는 완성이 아니다.

## 구성

| 경로 | 내용 |
|---|---|
| `skills/cairn/SKILL.md` | 스킬 본문 — init 절차, 세션 루프, 기록 규칙 |
| `skills/cairn/template/wiki/`, `wiki.en/` | 복사되는 위키 뼈대 + 템플릿 5종 (한국어·영어) |
| `skills/cairn/template/check.sh` | 정합성 체커 (한 벌로 두 언어 모두 처리) |
| `skills/cairn/template/rules-core*.md` | 에이전트 규칙 파일에 주입되는 범용 워크플로우 블록 |
| `skills/cairn/template/rules-dev*.md` | 코드 프로젝트에 덧붙는 규칙 (문서 우선·커밋 규약·골든셋) |
| `skills/cairn/references/goldenset.md` | 골든셋 규약 |
| `cli/cairn.js` | npm 설치기 — 에이전트 감지 + 블록 주입. 의존성 0 |

## 출처

[java-heavy-traffic](https://github.com/kimdoogi/java-heavy-traffic)의 wiki 체계와 [AIgateway](https://github.com/kimdoogi/AIgateway)의 문서·골든셋 운영을 일반화했다.

## 라이선스

MIT
