# 계획 038b: 장부 줄 둘 — 폐점의 소지금은 아침부터, 정산의 분모는 칠 수 있는 결투

- 버전: v1 (검토 전)
- 개발 단계: CLAUDE.md 9장 **4단계(아트 교체) 진행 중**. 038 결정 480의 차례(038 → **038b** → 033b → 033b 끝에서 W-5). 단계를 넘는 일은 없다.
- 근거:
  - 사용자 지시(2026-11-26) "계속 진행해줘" — 038 보고서 5번의 1.
  - 038 판 W-4 "둘 다 038b에서"(2026-11-26): **018-F7 가**(폐점의 `소지금 X → Y`에서 X를 그날 아침의 소지금으로, 줄의 꼴은 그대로), **018-F19 나**(정산 머리 줄의 분모를 칠 수 있는 결투 수로, 돌려보낸 날의 마지막이 `2/2`. 018-F5의 카운터 "오늘 남은 결투"와 같은 뜻). 보기의 글은 038 작업 5의 W-4 두 줄, 후보의 식은 `docs/BACKLOG.md` 018-F7·018-F19.
  - 지금 코드:
    - 폐점 `scripts/economy/closing.gd` 94행 `"%d → %d" % [summary["money_before"], summary["money_after"]]`. `money_before`는 `scripts/economy/day_state.gd` `_enter_closing`의 `before := money`(수입을 더한 뒤, 지출 전).
    - 그날 소지금이 바뀌는 곳은 `finish_duel`의 `money += total` 하나다(구매 `buy`는 폐점에서만, `_begin_day`는 돈을 건드리지 않는다). 그래서 `money_before − income`이 그날 아침의 소지금이고, `money_after − profit`과 같은 값이다(`after = before − expenses`, `profit = income − expenses`).
    - 정산 `scripts/economy/settlement.gd` 72~73행 `"%d일차 · 오늘의 결투 %d/%d 정산" % [day.day_number, day.results.size(), rules.duels_per_day]`.
    - 카운터 `scripts/commission/counter.gd` 94행 `mini(shown_duels_left, shown_waiting + 1)`(018-F5).
  - **저장 형식은 바뀌지 않는다**: `saved_state()`는 `version, day, money, owned, reputation, dice_seed`이고 `money`가 곧 그 날 아침의 소지금이다. `restore()`는 `money`를 넣은 뒤 `_begin_day()`를 부르고, 아침 소지금은 폐점에 들어설 때 메모리의 값(`before − income`)으로 셈하므로 저장에 새 칸이 필요 없다. `SAVE_VERSION`·`save_tests.gd`는 그대로, 옛 저장도 그대로 읽힌다.
  - 테스트: `오늘의 결투`를 글로 보는 테스트는 0건(Grep). 폐점의 소지금 줄을 글로 보는 테스트도 없다. `money_before`의 뜻은 T31(`day_tests.gd` 359행 `== 152`)과 스모크(`day_smoke.gd` 431행)가 보므로 **바꾸지 않는다**. 새 칸은 018의 T62(`tests/safety_tests.gd` `t62_labels`, "헷갈리던 표기")에 더한다 → 테스트 수 **95 그대로**.
  - UI 찍기(`tests/ui_shots.gd`): `pair-closing`은 시작 소지금 0(`data/economy_rules.tres`)의 셋을 끝낸 폐점이라 줄이 `0 → Y`로 바뀐다. `pair-settle`은 손님 셋·결투 셋에서 하나를 치른 정산이라 머리 줄은 고친 뒤에도 `1/3`이다(돌려보낸 손님이 없는 날). 장 수 15 그대로.
  - 결정 번호 483~487.

### 넘지 않는 선

- 메인은 테스트·게임을 실행하지 않는다(확인은 verifier). 코드는 Sonnet 하위 에이전트가 쓰고 메인은 diff만 본다. 그림 생성 없음. playtester는 부르지 않는다(글 두 줄이고 흐름·입력이 바뀌지 않는다).
- 고치는 게임 파일은 `day_state.gd`·`closing.gd`·`settlement.gd` 셋, 테스트는 `safety_tests.gd`·`day_tests.gd` 둘. 카운터·저장·데이터·찍기 도구는 고치지 않는다.
- 범위 밖: 정산의 `소지금` 줄(그때의 소지금 그대로), 폐점 장부의 다른 줄, 칼 수리비(5장 "아직 없는 것"), 033b.

## 목표와 범위

폐점의 소지금 줄이 "오른쪽 − 왼쪽 = 오늘의 손익"으로 읽히고, 손님을 돌려보내 결투를 다 치를 수 없는 날의 마지막 정산 머리 줄이 `n/n`으로 끝난다.

**확인할 결과**:

1. 폐점의 `소지금` 줄의 왼쪽이 그날 아침의 소지금이고, 오른쪽 − 왼쪽이 `오늘의 손익`과 같다(T62 마, T31). 다친 날·다치지 않은 날·의뢰 0건의 날 모두.
2. 정산 머리 줄의 분모가 `min(결투 자리, 오늘 치른 결투 + 문밖 손님)`이다: 손님 셋·결투 셋에서 하나를 돌려보낸 날은 `1/2` → `2/2`, 돌려보내지 않은 날은 `1/3` … `3/3` 그대로, 손님이 결투보다 많은 날도 분모가 결투 자리를 넘지 않는다(T62 바).
3. `money_before`·저장 형식·다른 테스트의 기대는 그대로다. `VERIFY: OK`, `ALL PASS 95/95`, UI 찍기 15장.
4. `pair-closing` 장의 소지금 줄이 `0 → Y`이고 장부 줄에서 넘치지 않는다. `pair-settle` 장의 머리 줄이 `1/3`이다(메인이 읽는다).

## 설계 결정

483. **폐점의 소지금 줄은 요약의 새 칸 `money_start`를 쓴다**(018-F7 가): `_enter_closing`에서 `"money_start": before - income`을 더하고(`reputation_start`와 같은 이름 꼴), `closing.gd` 94행의 왼쪽을 `summary["money_start"]`로. `money_before`는 뜻과 값을 그대로 둔다(T31·스모크). 화면에서 빼기를 하지 않고 요약에 두는 까닭: 장부 숫자의 원본을 한 곳(DayState)에 두고, T31이 화면 없이 값을 본다. 정의상 `money_after − profit`과 같아 사용자가 고른 "오른쪽 − 왼쪽 = 손익"이 늘 성립한다. `closing_summary()`의 머리 주석 목록에 `money_start(그날 아침의 소지금)`를 더한다. 저장은 바뀌지 않는다(근거). planner 임시 — 되돌리기 쉽다: 키 하나와 한 줄.
484. **정산 머리 줄의 분모는 `mini(rules.duels_per_day, day.results.size() + day.waiting_count())`**(018-F19 나, BACKLOG의 식 그대로): `rules`는 그 함수가 이미 쓰는 `day.effective_rules()`. 카운터의 018-F5(`mini(duels_left, waiting + 1)`)와 같은 뜻이다 — 정산에서는 지금 손님이 이미 `results`에 들었으므로 `+1`이 없다. 그래서 하루 중에 돌려보내면 분모가 그만큼 준다(예: 1번째를 돌려보낸 날 `1/2`·`2/2`, 1번째를 치르고 2번째를 돌려보낸 날 `1/3` → `2/2`). 카운터의 "오늘 남은 결투"도 돌려보낸 뒤 같은 때 준다(T62 가). 분모는 오르지 않는다(돌려보낸 손님은 그날 다시 오지 않는다). 함수는 새로 만들지 않는다(쓰는 곳이 하나).
485. **테스트는 T62에 두 칸, T31에 한 줄**(작업 3): 수 95 그대로. T62의 이름에 "폐점의 소지금, 정산의 분모"를 더한다.
486. **판은 열지 않는다**: 사용자가 W-4에서 보기(가·나)를 골랐고, 바뀌는 것은 글 두 줄의 숫자뿐이며 자리·크기·흐름이 그대로다. 메인이 `pair-closing`·`pair-settle` 두 장을 읽고(작업 4), 보고서 1번에 두 줄의 전후 글(예: `소지금 152 → 72` → `0 → 72`, 돌려보낸 날 `2/3` → `2/2`)과 장 경로, 결정 484의 "하루 중에 분모가 준다"를 적는다. 사용자가 보고서를 읽고 다르면 다음 지시로 연다(되돌리기는 결정 483·484의 한 줄씩).
487. **커밋은 두 번**: 계획(검토 뒤), 코드·테스트·문서(verifier 통과 뒤).

## 작업 목록

**작업 0. 시작 상태** (메인): HEAD를 `%TEMP%\bravi-038b\head.txt`에. 완료 확인: 한 줄이 `322c486`이거나 그 뒤, `git status` 깨끗(이 계획 파일 밖).

**작업 1. 폐점의 소지금 줄** (Sonnet. `scripts/economy/day_state.gd`, `scripts/economy/closing.gd`. 결정 483)
- `_enter_closing`의 `_summary`에 `"money_start": before - income` 한 칸, `closing_summary()` 머리 주석의 키 목록에 `money_start` 한 낱말. `closing.gd` 94행의 첫 값만 `summary["money_start"]`로.
- 완료 확인: `git diff`가 그 세 곳뿐이다. `money_before`가 든 줄은 바뀌지 않았다. `rg money_start scripts`가 세 줄(요약, 주석, 폐점).

**작업 2. 정산 머리 줄의 분모** (Sonnet. `scripts/economy/settlement.gd`. 결정 484)
- 72~73행의 셋째 값만 `mini(rules.duels_per_day, day.results.size() + day.waiting_count())`로. 글의 꼴(`"%d일차 · 오늘의 결투 %d/%d 정산"`)은 그대로.
- 완료 확인: `git diff`가 그 값 하나뿐이다.

**작업 3. 테스트** (Sonnet. `tests/safety_tests.gd`, `tests/day_tests.gd`. 결정 485. 아래 밖은 건드리지 않는다)
- `safety_tests.gd` T62:
  - 이름: "헷갈리던 표기: 카운터의 남은 결투, 폐점의 0, 폐점의 소지금, 정산의 분모". 머리 주석 2행은 그대로.
  - **다**(다치지 않은 날, `_rules(70, 60, 20, 250)`, 결과 셋 45·58·49)에 한 줄: `_ledger(closing, "Money", "Value") == "250 → 342"`이고 `_ledger(closing, "Profit", "Value") == "+92"`.
  - **라**(다친 날, 같은 규칙)에 한 줄: `Money`의 Value가 `"250 → 322"`.
  - **마**(새 칸, 의뢰 0건의 날): `DayState.new(_d._rules(70, 60, 20, 250), DayData.new())`는 곧 폐점이다 — `Money`의 Value가 `"250 → 190"`, `Profit`이 `"-60"`. (T35 `broke`의 꼴. 시작 소지금 250으로 0과 가른다.)
  - **바**(새 칸, 정산 머리 줄): `_d._label_text(settlement, "Header")`로 본다. (ㄱ) `DayState.new(_d._duel_rules(3), _d._three_fixed())`: 돌려보내기 → 맡아 끝냄(`accept`·`finish_duel(_d._record(DT.EndReason.CONDITION))`) → 정산 머리 줄에 `"오늘의 결투 1/2"` → `proceed` → 맡아 끝냄 → `"오늘의 결투 2/2"`이고 `Proceed` 버튼의 글이 "가게를 닫는다". (ㄴ) 같은 하루에서 돌려보내지 않고 셋을 치르면 `1/3`·`2/3`·`3/3`. (ㄷ) `_duel_rules(2)`와 `_three_fixed()`(손님이 결투보다 많다): `1/2`·`2/2`(분모가 3이 되지 않는다). 화면은 칸마다 `free()`.
- `day_tests.gd` T31: 359행 뒤에 한 줄 — `summary.get("money_start") == 0`이고 `summary.get("money_after") - summary.get("money_start") == summary.get("profit")`.
- 완료 확인: `git diff --stat`이 작업 1·2의 세 파일과 이 두 파일뿐이다. T62의 다·라·마·바와 T31의 줄이 위 숫자를 담는다. 테스트 목록의 수가 그대로다(`list`에 새 항목 없음).

**작업 4. verifier(V1)** — `tests/verify.ps1 -Shots "$env:TEMP\bravi-038b\v"`를 맡긴다.
- 기대: `VERIFY: OK`, `ALL PASS 95/95`, 스모크 OK, UI 찍기 15장(다른 찍기의 장 수는 038 V1과 같다), `pair-closing.png`·`pair-settle.png`의 경로.
- 실패하면 로그의 줄로 가려, 이 계획의 다섯 파일 안에서 결정 483·484를 바꾸지 않는 것만 고친다. 그 밖이 걸리면 멈추고 보고한다.
- 메인은 `...\v\ui\pair-closing.png`(소지금 줄이 `0 → Y`, 장부 줄 안에 든다)와 `...\v\ui\pair-settle.png`(머리 줄 `1/3`, 자리 그대로) 두 장만 읽는다.
- 완료 확인: verifier의 결과 줄과 두 장을 읽은 한 줄씩이 `%TEMP%\bravi-038b\v1.txt`에.

**작업 5. 문서와 커밋** (메인)
- `docs/DECISIONS.md` 새 절 "계획 038b"(483~487), `docs/BACKLOG.md`(018-F7·018-F19를 "닫힌 것"으로 한 줄씩 — "038b 결정 483/484"), `CLAUDE.md` 9장(038b 한 마디), `docs/HANDOFF.md` 1번(다음은 033b — 그림 생성 장 수를 계획 때 먼저 여쭌다), 보고서 `docs/reports/038b-ledger-lines.md`(결정 486의 전후 글과 장 경로).
- 완료 확인: `DECISIONS.md`에 `^483\.`~`^487\.`이 하나씩. BACKLOG의 "사용자가 먼저 정할 것" 절에 018-F7·018-F19가 없다. `git status` 깨끗.

## 위험

- **R1 숨은 기대**: 정산 머리 줄이나 폐점 소지금 줄의 글을 보는 곳이 테스트 밖(찍기의 라벨 글, 스모크의 출력)에 있을 수 있다. Grep에서는 없었다 — 걸리면 작업 4의 가름.
- **R2 분모가 하루 중에 준다**(결정 484): `1/3` 뒤에 `2/2`가 오는 날이 생긴다. 카운터가 같은 때 같은 수를 보이므로 뜻은 맞는다고 보고, 보고서 1번에 적어 사용자가 읽게 한다(결정 486).

## 사용자에게 물을 것 (검토 전)

- 없다. W-4의 답(F7 가 · F19 나)이 범위·규칙·완료 기준을 정했다. 저장 형식은 바뀌지 않는다(근거).

## 사용자 결정 필요

- 실행 중: 없다(판을 열지 않는다 — 결정 486).
- planner가 임시로 정한 것: 요약의 새 칸 `money_start`(483), 판을 열지 않음(486).
- 이 계획 밖(033b 끝): "4단계 완료 기준 충족 — 다음 단계(5. 사운드) 진행 여부"(038 결정 480).

## 계획 뒤의 차례

1. **033b(그린 질감)** — 4단계 안(038 Q2 "가"). 그림 생성 장 수를 계획 때 먼저 여쭌다. 계획 파일은 planner부터.
2. 033b 끝에서 W-5.
