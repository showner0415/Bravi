# 보고서 043: 대련 — 조건 `SPAR`, 사범 아고스티노의 의뢰

- 계획: `docs/plans/043-spar-commission.md` v2. 6단계(콘텐츠)의 여섯째 실행 계획(나눔 `docs/plans/039-stage6-roadmap.md`의 043 줄).
- 근거: 사용자(2026-11-27) "대련해달라는 의뢰(상처 입히면 안된다. 스치기만 가능으로 해서 무장해제 상태까지 3번 가면 성공 …)", "의뢰자가 전투 대상이 돼도 좋다", "개성이 중요하다". 042가 넘긴 것: 대련의 자세 값은 상대 파일에 두지 않고, 의뢰인 그림을 의뢰에 거는 것은 이 계획이다.
- 일하는 방식: 그 세션에서는 묻지 않고 이어 갔고 사용자가 고를 것을 메인이 대신 골랐다(사용자 위임 2026-11-27). 대신 고른 것은 4번.
- 검토: 2회. 1회차 디자인 APPROVE · 기술 REVISE(T1 — `States.put` 뒤 `advance` · `tick`이 끝나지 않는 고리, T2 — `score,` 줄이 감싸개에서 걸러짐) → v2 → 2회차 기술 APPROVE(디자인은 1회차 승인 유지). 비차단 셋을 받았다: `Meter.shown_text()`, 띠 없는 패리 줄 `sparparry`, 끝난 판에서 "치지 마라"를 지우는 `stagger_hint`의 `record.ended`(마지막은 계획에 없던 것을 구현에서 받았다).
- 상태(2026-11-27): 구현 끝, `VERIFY: OK`, `ALL PASS 133/133`.

## 1. 한 일

- **조건 `SPAR`**(`scripts/commission/spar_condition.gd`, 새): `topples_needed` 3 · `partial_scores` 0 · 25 · 50 · `wound_score` 0 · `hold_hint` "치지 마라". `check_end`가 셋째 `STAGGER_START`의 전이 또는 `HIT`에서 판을 끝낸다. 세 번 무너뜨리면 100점, 무너진 상대를 치면(유효타) 0점, 내가 맞은 것은 채점하지 않는다.
- **의뢰의 칸 둘**(`scripts/commission/commission.gd`): `opponent_posture_max` · `opponent_recover_posture`(0이면 상대 그대로)와 `fit_opponent`. `OpponentData.with_posture`(`scripts/ai/opponent_data.gd` — 0 · 0이면 자기 자신). 부르는 곳은 `duel_scene.gd`의 `start_duel` 한 줄. `duel_core.gd` · `opponent_brain.gd`는 0줄이다.
- **화면**(`scripts/duel/duel_hud.gd`, `scripts/duel/opponent_view.gd`, `scripts/commission/commission_condition.gd`): 게이지의 넷째 값과 `Meter.shown_text()`로 "무너뜨림 k/3", 무너짐 갈래의 귀띔 "치지 마라"(`stagger_hint` → `stagger_hint_of`). 무너짐의 색과 소리는 그대로다.
- **데이터**: `data/commissions/spar.tres`(의뢰인 "검술 사범 아고스티노", 상대 `opponent_05`, 자세 3 · 3, 무대 안뜰, 보수 32 · 팁 18, 평판 맡음 0 · 해냄 +4 · 못 해냄 −1, `win` 없음, 눈높이 3, 사연 216자, 한마디 54 · 47 · 50 · 30자, 흥정 33 · 33자, 의뢰인 그림 `agostino.png`), `data/days/day_04.tres`의 첫 자리(목록 8, `base_guests` 5).
- **테스트** `tests/spar_tests.gd` T130~T133(조건의 셈, 상대 맞춤, 화면, 의뢰의 데이터와 하루). 고친 기존 테스트: T21 · T22(의뢰 3 → 4), T72(무대 배정 여덟), T77(의뢰인 그림 표), T78(`second_opponent_tests` — 아고스티노 갈래), T59(한마디 여덟), T37(`day_tests`), `reputation_tests` · `opening_chance_tests`의 목록, T126 ⑦(아고스티노를 거는 의뢰는 `spar.tres` 하나).
- **도구**: 봇 통계 `-Commission <의뢰> -Finisher off`와 `score,` 줄, `verify.ps1 -Stats`에 `spar` · `sparwrong` · `sparparry`, UI 찍기 31장(`counter-spar`, `duel-spar-stagger`, `settle-spar`).
- 문서: `docs/DECISIONS.md` 653~665, `CLAUDE.md` 3 · 4 · 5 · 9장, `docs/BACKLOG.md`(043-1~3), `docs/HANDOFF.md`, 이 보고서.

바꾼 파일: `scripts/commission/spar_condition.gd`(새), `scripts/commission/commission_condition.gd`, `scripts/commission/commission.gd`, `scripts/ai/opponent_data.gd`, `scripts/duel/duel_scene.gd`, `scripts/duel/duel_hud.gd`, `scripts/duel/opponent_view.gd`, `data/commissions/spar.tres`(새), `data/days/day_04.tres`, `tests/spar_tests.gd`(새), `tests/run_tests.gd`, `tests/duel_stats.gd`, `tests/run_duel_stats.ps1`, `tests/verify.ps1`, `tests/ui_shots.gd`, `tests/run_ui_shots.ps1`, 고친 기존 테스트(위), 문서.

## 2. 직접 실행해서 확인한 것 / 확인 못 한 것

확인한 것(verifier가 돌렸다. 메인은 수를 읽었다):

- `VERIFY: OK`(`-Stats` 포함 14단계), `ALL PASS 133/133`, UI 31장, 오류 0. 새 인자 없는 바탕 줄 다섯은 고치기 전과 SHA-256까지 같다.
- **봇 수**(60판, 3일차의 빈틈 0.64, 9칸):

| 봇 | 평균 판 길이 | 끝 | 띠 | 판정 |
|---|---|---|---|---|
| `spar` — 치지 않는 쥐는 봇 | 46.5초 | 100점 60/60, 시간 초과 0 | 35~60초 · 54 이상 · 6 이하 | 넘음 |
| `sparwrong` — 높이 10% 틀리는 봇 | | 100점 40 · 부분 15 · 0점 5(패배 20), 시간 초과 0, 평균 충족도 77.1 | 100점 30 이상 · 시간 초과 12 이하 | 넘음 |
| `sparparry` — 패리 봇(잘하는 손) | 31.1초 | 100점 60/60 | 띠 없음 | 수만 적음 |

  - T132 ①의 실제 데이터 판(씨앗 1~10): 37.8~62.5초, 모두 100점.
  - **값 고침 0번**: 결정 662의 사다리를 밟지 않았다(자세 3 · 3 그대로). 쥐는 봇은 대련에서 맞지 않는다(판당 맞음: 없음).
  - 잘하는 손(패리 봇)은 31.1초로 원칙 1의 아래 끝(30초) 언저리에 선다.

확인 못 한 것:

- **손맛**: 참는 긴장, 무너진 보라색 앞에서 손을 멈추는 맛, 0점의 가혹함, 두 번째 만남부터 참기가 옅어지는가. 판 I.
- **게임 창에서의 흐름**: playtester를 부르지 않았다. 대련 의뢰를 맡아 세 번 무너뜨리고 정산까지 가는 실제 입력의 흐름을 아무도 창에서 보지 않았다.
- 4일차의 첫 손님으로 처음 보는 상대(엇박)와 처음 보는 조건이 함께 오는 짐(049가 7일 일정에서 수로 본다).

## 3. 설계 문서와 다르게 구현한 부분과 이유

- **T131 ③**: 계획의 "첫 피의 4일차 판이 원본 그 객체"는 바르톨로가 4일차에 2단(사본)이라 성립하지 않았다. 1일차 판으로 그 객체임을 보고 4일차는 자세 두 값만 봤다.
- **끝난 판에서 "치지 마라"를 지운다**: `stagger_hint`가 `record.ended`를 본다. 계획에 없던 것을 구현에서 받았다.
- 그 밖의 값과 구조는 계획대로다(값 고침 0번).

## 4. 사용자가 결정해야 할 것

그 세션에서는 묻지 않고 메인이 골랐다. 나중에 직접 보고 뒤집을 수 있는 것(4일차의 첫 손님을 맡거나 연습 화면에서 의뢰 "검술 사범 아고스티노"를 골라 본다. `docs/HANDOFF.md` 3번 "043 판 I"에도 있다):

- **I-1** "무장해제 상태까지 3번"을 "무너짐 세 번"으로 읽었다(039의 판정). R04의 무장 해제가 생기면 세는 이벤트를 바꾼다.
- **I-2** 무너진 상대를 치면 0점이고 판이 끝난다 — 가혹한가. 거꾸로 쳐서 얻을 것이 없어 두 번째 만남부터 참는 긴장이 옅은가. 뒤집는 길: `wound_score`를 20~30으로.
- **I-3** 서로 세 칸, 세 판(자세 3 · 3 — 039의 6 · 3 대신). 잘하는 손이 31.1초라 짧거나 싱거운가. 뒤집는 길: `spar.tres`의 두 칸.
- **I-4** 세 번째 무너짐에서 곧바로 끝난다(결정 654). **I-5** 무너짐의 색과 소리는 그대로이고 "치지 마라"만 뜬다. **I-6** 부분 점수 25 · 50. **I-7** "이겼다"가 없고 "해냈다"가 +4. **I-8** 사연의 틀과 말투, 보수 32 · 18, 4일차의 첫 손님. **I-9** 게이지의 글 "무너뜨림 k/3".

## 5. 다음 작업 제안

- 044(베아트리체 — 속임 베기, 걸음의 칸 `feint`). `docs/plans/039-stage6-roadmap.md`의 044 줄. 계획 파일이 아직 없다 — planner부터. 결정은 666부터, 테스트는 T134부터.
- 047(둘이 함께)과 050(멧돼지 몰이)은 `SparCondition`을 그대로 쓴다. 참기만으로 그 의뢰의 개성을 세우지 않는다(계획 위험 R2의 반대쪽).
- 049(1주차 일정): `day_04`를 다시 짠다, 도움말 화면의 박자 줄, 4일차의 짐.

라운드 수 2, 최종 판정: 디자인 APPROVE(1회차) · 기술 APPROVE(2회차).
