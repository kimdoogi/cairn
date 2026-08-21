---
name: cairn
description: 프로젝트에 기록 체계(journal/problems/decisions/concepts/experiments/howto + index + log)와 골든셋 테스트 규약을 설치하고 유지한다. 코딩뿐 아니라 리서치·집필·기획·학습 작업에도 쓴다. Installs and maintains a project record-keeping wiki (work journal, problem log, ADRs, concepts, experiments) for coding and non-coding work alike. Use when the user says "cairn", "위키 만들어", "기록 체계 깔아", "llm-wiki", "작업 기록 남기게 해줘", "wiki init", "골든셋 테스트 도입", "set up a project wiki", "add ADRs", "keep a work log"; 또는 위키가 있는 프로젝트에서 세션을 시작·종료할 때(작업 기록·problem 기록·결정 기록·index/log 갱신), 위키 정합성 점검(cairn check·번호 충돌·index 재생성)이 필요할 때.
---

# cairn — 기록이 남는 작업 구조

목적: 몇 주 뒤에 위키만 읽고 "무엇을 왜 어떻게 했고 뭐가 문제였는지"를 재구성할 수 있게 만든다.
코드 프로젝트가 출발점이지만 대상은 작업 일반이다 — 리서치, 집필, 기획, 학습에도 그대로 쓴다.
근거 사례: `kimdoogi/java-heavy-traffic`(wiki/), `kimdoogi/AIgateway`(docs/ + 골든셋).

## 1. 설치 (`cairn init`)

이 SKILL.md가 있는 폴더가 `$SKILL_DIR`이다. 프로젝트 루트에서:

```bash
cp -R "$SKILL_DIR/template/wiki" ./wiki
```

그다음 (에이전트가 직접):

1. `wiki/index.md`의 `<프로젝트>` 자리와 "현재 상태", 각 페이지의 `date`를 실제 값으로 채운다.
2. **규칙 주입** — `$SKILL_DIR/template/rules-core.md`를 프로젝트의 에이전트 규칙 파일에 붙여넣는다. 코드 프로젝트면 `rules-dev.md`도 이어 붙인다. 붙이는 파일은 그 프로젝트가 쓰는 것 전부: `CLAUDE.md`, `AGENTS.md`(Codex·opencode 등 범용 표준), `GEMINI.md`, `.cursor/rules/cairn.mdc`, `.github/copilot-instructions.md`, `.windsurf/rules/cairn.md`, `.clinerules/cairn.md`, `.kiro/steering/cairn.md`. 이미 내용이 있으면 아래에 덧붙이고, `<!-- cairn:start -->` / `<!-- cairn:end -->` 마커로 감싼다 (나중에 그 블록만 갱신할 수 있게).
3. git 저장소면 `.gitattributes`에 `wiki/log.md merge=union` 한 줄을 넣는다 (append 충돌 자동 해소).
4. 첫 journal(`wiki/journal/YYYY-MM-DD-wiki-setup.md`)을 만들어 왜 이 체계를 깔았는지 적고, `wiki/log.md`에 한 줄 append.
5. 이미 정해진 결정이 있으면 `D-001`부터 옮겨 적는다 (구두로만 존재하는 결정 = 없는 결정).
6. `bash wiki/check.sh --write-index`로 index 목록을 채우고 점검. CI가 있으면 `bash wiki/check.sh`를 워크플로우에 넣는다.

npm 경로(`npx @doogi/cairn init`)는 1~3번과 6번을 자동으로 한다.

**프로필** — 코드 프로젝트(`package.json`·`go.mod`·`pom.xml`·`Cargo.toml`·`pyproject.toml`·`src/` 등이 있으면)는 `rules-dev.md`까지, 그 외(리서치·집필·기획·학습)는 `rules-core.md`만. cairn은 코딩 전용이 아니다 — 문제·결정·시도의 기록은 어떤 작업에나 같은 값을 한다.

선택 디렉토리 — 필요할 때만 만든다: `wiki/research/`(선행 조사), `wiki/specs/`(스펙 원본), `wiki/plan/`(실행 계획). `wiki/`를 `docs/`로 불러도 된다 (이름만 다르고 규약은 동일 — 체커도 따라간다).

## 2. 세션 루프와 기록 규칙

원본은 `$SKILL_DIR/template/rules-core.md`(+ 코드 프로젝트면 `rules-dev.md`)다. 설치하면 그 내용이 프로젝트 규칙 파일에 들어가므로 매 세션 자동으로 걸린다. **이 파일에 다시 옮겨 적지 않는다** — 두 벌이 되면 반드시 어긋난다.

요약: 읽기(index → log → 진행 중 journal) → journal 생성 → 작업 중 발생 즉시 기록(problem/decision/concept/experiment) → 종료 시 journal 마무리 → log 한 줄 → index 갱신.

## 3. 점검 (`cairn check`)

```bash
bash wiki/check.sh                 # 점검만
bash wiki/check.sh --write-index   # index 목록·다음 번호 재생성 후 점검
```

잡는 것: frontmatter 누락, 깨진 상대 링크, index 미등록 고아 페이지, **번호 중복**(동시 작업 충돌), index "다음 번호" 역전. 종료 코드 0/1이라 CI에 그대로 넣는다. 체커는 위키와 함께 복사되므로 cairn이 안 깔린 러너에서도 돈다.

## 4. 여러 명이 작업할 때

정합성이 깨지는 지점은 셋 다 "중앙 상태를 손으로 관리"해서 생긴다.

- **`log.md` 충돌** — `.gitattributes`의 `wiki/log.md merge=union`이 양쪽 줄을 다 남긴다. 각 줄에 날짜가 있어 순서가 섞여도 무해하다.
- **`index.md` 충돌** — 목록 섹션은 손으로 쓰지 않는다. 충돌하면 `--write-index`로 재생성하면 끝. 사람이 쓰는 건 "현재 상태" 몇 줄뿐.
- **번호 충돌** — 두 브랜치가 같은 `P-001`을 잡을 수 있다. `check.sh`가 중복을 잡으므로 머지 시 재번호하고 `grep -rn`으로 참조를 함께 고친다. 팀이 커지면 번호를 버리고 날짜 기반 파일명으로 간다.

관습 둘: **위키를 코드와 같은 PR에 넣는다**(기록이 리뷰에 걸린다. 별도 PR로 빼면 반드시 밀린다). **journal은 사람마다 별개 파일**(`2026-08-21-doogi-<슬러그>.md` — 파일이 다르면 충돌 자체가 없다).

## 5. 골든셋 테스트

외부 API·프로토콜·포맷 변환을 다루는 프로젝트면 [references/goldenset.md](references/goldenset.md)를 읽고 캡처 하네스를 어댑터와 **동시 또는 선행**으로 만든다. 핵심만: 실 응답을 새니타이저 통과 후 `fixtures/`에 녹화 → 테스트는 픽스처만 재생(네트워크 금지) → 스냅샷 비교 → 새 픽스처는 디렉토리 스캔으로 자동 편입.
