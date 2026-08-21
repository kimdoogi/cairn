# 골든셋 테스트 규약

외부 API·프로토콜·포맷 변환을 다루는 프로젝트용. 출처: `kimdoogi/AIgateway` (어댑터 4방향 골든셋).

## 원칙

- **골든셋이 "완성"의 정의다.** 어댑터/변환기는 골든셋이 붙기 전까지 완성이 아니다. 하네스는 변환기와 동시 또는 선행으로 만든다 (나중에 만들면 이미 깨진 걸 정답으로 굳힌다).
- **테스트에 네트워크 금지.** 실 API 호출은 녹화 시점에만. 테스트는 픽스처 재생만 한다. 라이브 호출은 opt-in 스모크로 분리.
- **녹화는 사람이 아니라 하네스가 한다.** 손으로 만든 픽스처는 실제 wire와 미묘하게 다르고, 그 차이가 정확히 버그가 숨는 자리다.

## 구조

```
tools/capture/
  cases.ts       # 케이스 정의 = 데이터 테이블 (프로바이더별 분기문 금지, 구성값으로 표현)
  capture.ts     # 실 호출 → 새니타이즈 → fixtures/ 저장
  sanitize.ts    # 키·토큰·id·계정 식별자 제거 (+ 자체 테스트 필수)
  replay.ts      # 스트림 청크 → 파서 재생
  fixtures.ts    # 읽기 헬퍼
fixtures/<provider>/<case>.<model>.<YYYY-MM-DD>.json        # 메타 + 요청 + 응답 바디
fixtures/<provider>/<case>.<model>.<YYYY-MM-DD>.chunks.txt  # 스트림 원문 청크
```

## 테스트

디렉토리를 스캔해 케이스를 자동 발견한다 — **새 녹화는 코드 수정 없이 골든셋에 편입된다.**

```ts
const cases = discoverCases();                       // fixtures/<provider> 스캔
it("픽스처가 존재한다", () => expect(cases.length).toBeGreaterThan(0));  // 하네스 소급 방지
for (const name of cases) it(name, () => {
  const { meta, chunks } = readFixture(provider, name)!;
  if (meta.status !== 200) return expect(mapHttpError(meta.status, meta.body)).toMatchSnapshot();
  if (meta.stream)        return expect(replay(chunks!)).toMatchSnapshot();
  expect(transformResponse(meta.body)).toMatchSnapshot();
});
```

방향은 4종을 모두 덮는다: ① 요청 방향(내부표현 → wire), ② 응답 방향(wire → 내부표현, 스트림은 재생), ③ 인바운드 재합성(내부표현 → 호환 포맷), ④ 크로스 왕복(A 픽스처 → B wire → 원문 복원).

## 케이스 고르기

- 품질이 아니라 **포맷**을 검증한다 → 같은 포맷을 쓰는 가장 싼 모델로 녹화. 포맷이 다른 기능만 비싼 모델로 소량.
- **에러 케이스를 적극 수집한다** — 4xx는 대개 무과금인데 회귀 검출력은 제일 높다.
- 유도 불가 케이스(429·타임아웃·절단)는 `manual` 플래그로 기본 실행에서 빼고, 기회가 오면 이름 지정해 녹화.
- 케이스에 기대 status를 적어두고 **불일치는 실패가 아니라 경고**로 낸다 — 그게 "외부 API가 바뀌었다"는 신선도 신호다.

## 지켜야 할 것

- 새니타이저는 자체 테스트를 갖는다. 시크릿이 픽스처에 한 번 들어가면 히스토리에서 지우기 어렵다.
- 픽스처 파일명에 녹화 날짜를 박는다 — 언제 찍은 진실인지가 곧 신뢰도다.
- 스냅샷 diff를 눈으로 승인하기 전에는 `-u`로 갱신하지 않는다. 스냅샷 자동 갱신은 골든셋을 종이호랑이로 만든다.
- 녹화 중 발견한 외부 API 변경·실측 제약은 problem log에 남기고 스펙 문서에 반영한다.
