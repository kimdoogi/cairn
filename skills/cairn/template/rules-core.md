## 위키 우선 워크플로우 (모든 세션 필수)

"작업 → 기록 → 반복". 일이 진행돼도 기록이 끊기면 안 된다. 나중에 "무엇을 왜 했고 어떤 문제가 있었고 어떻게 풀었는지"를 위키만 보고 재구성할 수 있어야 한다.

1. **세션 시작**: `wiki/index.md` → `wiki/log.md`(최근 항목) → 진행 중(`status: in-progress`) journal 순으로 읽고 현재 상태를 파악한 뒤 시작한다.
2. **작업 시작**: `wiki/journal/YYYY-MM-DD-<슬러그>.md`를 `wiki/_templates/journal.md`로 생성하고 목표·범위를 먼저 적는다.
3. **작업 중** (발생 즉시 기록, 나중에 몰아서 쓰지 않는다):
   - 문제·막힘·예상 밖의 결과 → `wiki/problems/P-NNN-<슬러그>.md`. 증상·재현·실제 관측을 먼저 적고, 해결되면 원인·해결·재발 방지를 채운다. 미해결이면 `status: open`.
   - 방향·방법의 선택 → `wiki/decisions/D-NNN-<슬러그>.md` (맥락, 선택지, 결정, 이유, 결과 — 기각한 대안과 이유 포함).
   - 새로 이해한 것 → `wiki/concepts/<슬러그>.md`.
   - 시도·측정·비교 → `wiki/experiments/E<N>-<슬러그>.md` (가설/설정/결과/해석). raw 데이터는 `results/`에 두고 링크.
4. **작업 종료**: journal에 한 일·결과·남은 일 완성 → `wiki/log.md`에 한 줄 append → `wiki/index.md` 갱신(또는 `bash wiki/check.sh --write-index`).
5. **저장**: 작업 단위(journal)로 저장·공유한다. git이면 journal 단위로 커밋한다.

## 기록 규칙

- 모든 페이지 상단에 frontmatter(`title/date/status/tags/related`) 필수. 템플릿은 `wiki/_templates/`.
- 링크는 상대경로 마크다운 링크. problem ↔ journal ↔ concept ↔ experiment ↔ decision을 적극 연결한다.
- `P-`/`D-` 번호는 `wiki/index.md`의 "다음 번호"를 쓰고 재사용하지 않는다.
- 사실만 기록: 실제로 한 일, 실제 관측·수치·인용. 추측은 "가설"로 표시하고 확인 후 갱신.
- 실패도 기록: 안 된 시도, 버린 접근과 그 이유. 이게 가장 가치 있는 기록이다.
- 같은 사실이 여러 문서에 적혀 있으면 `grep -rn`으로 전부 찾아 함께 고친다.
- 재발 방지 규칙이 나오면 problem에서 끝내지 말고 이 파일이나 decision으로 승격한다.
- 한국어로 작성. 고유명사·명령·수치·원문 인용은 그대로 유지.

## 결정은 문서에 남는다

- 구두로만 존재하는 결정은 없는 결정이다. 방향이 정해지면 `wiki/decisions/`에 남긴다.
- 기존 결정과 어긋나는 걸 발견하면 조용히 우회하지 말고, 결정 문서를 고치거나 `superseded` 처리하고 problem에 기록한다.
- 세션이 끝나면 맥락은 사라진다. 남은 건 위키뿐이다.
