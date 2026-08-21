---
name: cairn
description: 프로젝트에 llm-wiki 기록 체계(journal/problems/decisions/concepts/experiments/howto + index + log)와 골든셋 테스트 규약을 설치하고 유지한다. Installs and maintains a project record-keeping wiki (work journal, problem log, ADRs, concepts, experiments) plus a golden-set testing convention. Use when the user says "cairn", "위키 만들어", "기록 체계 깔아", "llm-wiki", "작업 기록 남기게 해줘", "wiki init", "골든셋 테스트 도입", "set up a project wiki", "add ADRs", "keep a work log", "problem log"; 또는 위키가 있는 프로젝트에서 세션을 시작·종료할 때(작업 기록·problem 기록·ADR 작성·index/log 갱신), 위키 정합성 점검(cairn check)이 필요할 때.
---

# cairn — 기록이 남는 프로젝트 구조

목적: 몇 주 뒤에 위키만 읽고 "무엇을 왜 어떻게 했고 뭐가 문제였는지"를 재구성할 수 있게 만든다.
근거 사례: `kimdoogi/java-heavy-traffic`(wiki/), `kimdoogi/AIgateway`(docs/ + 골든셋).

## 1. 설치 (`cairn init`)

이 SKILL.md가 있는 폴더가 `$SKILL_DIR`이다. 프로젝트 루트에서:

```bash
cp -R "$SKILL_DIR/template/wiki" ./wiki
```

그다음 (에이전트가 직접):

1. `wiki/index.md`의 `<프로젝트>` 자리와 "현재 상태", 각 페이지의 `date`를 실제 값으로 채운다.
2. 프로젝트 루트 `CLAUDE.md`에 `$SKILL_DIR/template/CLAUDE.cairn.md` 내용을 **붙여넣는다**. 이미 CLAUDE.md가 있으면 기존 내용 아래에 "위키 우선 워크플로우" 절만 병합하고, 경로·명령·스택 규칙은 그 프로젝트 것으로 고쳐 쓴다.
3. 첫 journal(`wiki/journal/YYYY-MM-DD-wiki-setup.md`)을 만들어 왜 이 체계를 깔았는지 적고, `wiki/log.md`에 한 줄 append, `wiki/index.md`에 등록한다.
4. 설계 선택이 이미 있으면 `D-001`부터 ADR로 옮겨 적는다 (구두로만 존재하는 결정 = 없는 결정).
5. `bash wiki/check.sh`로 점검. CI가 있으면 이 한 줄을 워크플로우에 넣는다.

선택 디렉토리 — 필요할 때만 만든다: `wiki/research/`(선행 사례·API 인벤토리), `wiki/specs/`(스펙 원본), `wiki/plan/`(실행 계획·DoD). 문서형 프로젝트는 `wiki/`를 `docs/`로 불러도 된다 (이름만 다르고 규약은 동일 — 체커도 따라간다).

## 2. 세션 루프 (설치 후 매 세션)

읽기 → 기록 → 갱신. CLAUDE.md에 박히므로 매 세션 자동으로 걸린다.

1. **시작**: `wiki/index.md` → `wiki/log.md` 최근 줄 → `status: in-progress` journal.
2. **착수**: `_templates/journal.md`로 오늘 journal 생성, 목표·범위를 먼저 적는다.
3. **작업 중, 발생 즉시** (나중에 몰아 쓰지 않는다):
   - 에러·예상 밖 동작·막힘 → `problems/P-NNN-<슬러그>.md`. 증상·재현·실제 출력을 먼저, 해결되면 원인·해결·재발 방지를 채운다. 미해결이면 `status: open`으로 남긴다.
   - 설계·기술 선택 → `decisions/D-NNN-<슬러그>.md` (맥락/선택지/결정/이유/결과). **기각한 대안과 기각 이유를 반드시 남긴다.**
   - 새로 이해한 개념 → `concepts/<슬러그>.md`.
   - 측정·실험 → `experiments/E<N>-<슬러그>.md`. raw 데이터는 `results/`에 두고 링크.
4. **종료**: journal 마무리(한 일·수치·남은 일) → `log.md` 한 줄 append → `index.md` 갱신(새 페이지 등록, 현재 상태·다음 번호).
5. **커밋**: 작업 단위(journal)마다. 문제 해결 커밋 본문에 `P-NNN`을 남긴다. 커밋·푸시는 사용자가 요청할 때만.

## 3. 기록 규칙

- 모든 페이지 상단에 frontmatter(`title/date/status/tags/related`). 템플릿은 `wiki/_templates/`.
- 링크는 상대경로 마크다운 링크. problem ↔ journal ↔ concept ↔ decision ↔ experiment를 적극 연결한다.
- `P-`/`D-` 번호는 `index.md`의 "다음 번호"를 쓰고 재사용하지 않는다.
- 사실만: 실행한 명령, 실제 출력, 측정 수치. 추측은 "가설"로 표시하고 검증 후 갱신.
- **실패도 기록**: 안 된 시도, 버린 접근과 그 이유. 가장 값비싼 기록이다.
- 같은 사실이 여러 문서에 있으면 고칠 때 `grep -rn`으로 전부 찾아 함께 고친다 (증분 수정 잔재가 가장 흔한 부패 경로).
- 재발 방지 규칙이 나오면 problem에서 끝내지 말고 CLAUDE.md/ADR로 승격한다.

## 4. 점검 (`cairn check`)

```bash
bash wiki/check.sh
```

체커는 위키와 함께 복사되므로 스킬 경로를 몰라도 되고, CI에서도 같은 한 줄로 돌아간다. frontmatter 누락, 깨진 상대 링크, index에 등록 안 된 고아 페이지, index "다음 번호" 역전을 잡는다. 종료 코드 0/1. 커밋 전이나 세션 종료 시 돌린다.

## 5. 골든셋 테스트

외부 API·프로토콜·포맷 변환을 다루는 프로젝트면 [references/goldenset.md](references/goldenset.md)를 읽고 캡처 하네스를 어댑터와 **동시 또는 선행**으로 만든다. 핵심만: 실 응답을 새니타이저 통과 후 `fixtures/`에 녹화 → 테스트는 픽스처만 재생(네트워크 금지) → 스냅샷 비교 → 새 픽스처는 디렉토리 스캔으로 자동 편입.
