# 보고서 047: 둘이 함께

- 계획: `docs/plans/047-two-at-the-counter.md` v2. 6단계(콘텐츠), 나눔 039의 047 줄. 결정 747~765, 테스트 T148~T152.
- 검토: 2회. 1회차 디자인 APPROVE · 기술 REVISE(T1 · T2) → v2 → 2회차 디자인 APPROVE · 기술 APPROVE.
- 상태(2026-11-28): 구현 끝, verifier 확인 대기. 구현 에이전트와 메인은 Godot · 테스트 · 게임을 실행하지 않았다.

## 1. 한 일

- **의뢰와 하루의 칸**: `scripts/commission/commission.gd`(`partner` · `sets_flags` · `requires_flags` · `excluded_flags`, `allowed_by`), `scripts/economy/day_data.gd`(`for_flags` — 거를 것이 없으면 그 객체 그대로).
- **`DayState`**(`scripts/economy/day_state.gd`): `flags`(날을 넘는다), `_side`, `current_commission()`의 짝 갈래, `partner_commission()` · `can_switch_side()` · `switch_side()`, `decline()`의 짝 갈래(`declined`에 한 칸 "A · B"), `finish_duel()`의 플래그, `_begin_day()` · `tomorrow_data()`의 거름, 저장의 `"flags"`와 `restore()`의 `_clean_flags`(`flags`를 `_begin_day()`보다 먼저 채운다 — 결정 753). `settlement.gd` · `closing.gd` · `game_session.gd` · `save_store.gd` · `duel_core.gd`의 diff 0줄.
- **카운터**(`scripts/commission/counter.gd`): 상수 여덟, 짝이 있을 때의 `Partner` · `SwitchSide`(`_refresh_haggle()`보다 먼저 만든다) · 두 버튼의 글 · "상대:" 줄의 꼬리, `_on_switch_side()`. 흥정 직후에는 `_refresh_haggle()`이 그 자리에서 `SwitchSide`를 끄고 글을 `SWITCH_LOCKED`로 바꾼다. 짝이 없는 손님의 노드 · 글은 그대로다.
- **의뢰 넷**(`data/commissions/variants/`): `pair_hatter.tres`(베아트리체 · 굴리엘모 상대 · 모자) · `pair_baker.tres`(굴리엘모 · 베아트리체 상대 · 대련 3 · 3) · `after_hatter.tres`(굴리엘모 · 로렌초 상대 · 칼 든 손) · `after_baker.tres`(베아트리체 · 본인 상대 · 티 안 나게 지기). 의뢰인 그림 `beatrice.png` · `guglielmo.png`이 처음으로 걸렸다(그림 0장).
- **하루와 일정**: `data/days/day_06.tres` · `day_07.tres`, `data/day_schedule.tres`(일정이 이레를 돈다).
- **재는 도구**: `tests/duel_stats.gd`(`--finisher=top`), `tests/run_duel_stats.ps1`(머리 주석), `tests/verify.ps1`(`-Stats`에 `pairhat` · `pairhatwrong` · `pairspar` · `pairsparclean` · `afterhand`).
- **테스트**: `tests/pair_tests.gd`(T148~T152, `run_tests.gd`의 `TEST_FILES` 끝), 표를 고친 `client_line_tests`(T59) · `counter_art_tests`(T77) · `stage_tests`(T72) · `reputation_tests` · `day_tests`(T37) · `opening_chance_tests` · `third_opponent_tests`(로렌초를 거는 의뢰) · `sixth_opponent_tests`(T136 ⑥) · `seventh_opponent_tests`(T141 ⑥), `style_tests`(T115의 열쇠 목록 한 줄). UI 찍기 `counter-pair` · `counter-pair-other` · `counter-pair-haggled` · `counter-after-hatter` · `counter-after-baker` · `duel-close-hat`(33 → 39장, `ui_shots.gd` · `run_ui_shots.ps1`).
- **문서**: `docs/DECISIONS.md` 747~765, `CLAUDE.md` 4 · 5 · 9장, `docs/HANDOFF.md`, `docs/BACKLOG.md` 047-1~4, 이 보고서.
- **글자 수**(공백 · 문장부호 포함, 문단 둘): 베아트리체(모자)의 사연 160 + 71(합 232), 한마디 해냄 45 · 부분 43 · 못 해냄 47 · 돌려보냄 39, 흥정의 대답 29 · 33. 굴리엘모(대련)의 사연 154 + 78(합 233), 해냄 43 · 부분 45 · 못 해냄 45 · 돌려보냄 35, 흥정 33 · 32. 굴리엘모(뒷이야기)의 사연 161 + 69(합 231), 해냄 45 · 부분 45 · 못 해냄 44 · 돌려보냄 38, 흥정 23 · 42. 베아트리체(뒷이야기)의 사연 134 + 80(합 215), 해냄 39 · 부분 40 · 못 해냄 42 · 돌려보냄 34, 흥정 32 · 36. 사연은 280 이내, 한마디는 56 이내, 흥정은 44 이내, 숫자 · 큰따옴표 · "치료비" 없음.

## 2. 직접 실행해서 확인한 것 / 확인 못 한 것

구현 에이전트와 메인은 Godot · 테스트 · 게임을 실행하지 않았고, 아래는 verifier의 결과다.

- 가져오기 OK(새 파일 `tests/pair_tests.gd.uid`는 커밋에 넣는다). 테스트 첫 실행 151/152 — T78 실패: `second_opponent_tests.gd`의 의뢰 → 상대 표에 새 의뢰 넷이 없었다. 메인이 표에 넷을 더해(`PAIR_HATTER_PATH` → 굴리엘모, `PAIR_BAKER_PATH` · `AFTER_BAKER_PATH` → 베아트리체, `AFTER_HATTER_PATH` → 로렌초) **152/152**. `verify.ps1 -Only counter` OK(10장, 겹침 0). `UI SHOTS OK 39`.
- V0: 83cf9e7 worktree와 `noble_baker`(`-Finisher low`) · `spar`(`-Finisher off`) 줄이 글자까지 같다.
- V2 1차(값 그대로): pairhat 66.8초 조건 종료 51 · 시간 초과 9 ✗ · pairhatwrong 65.0초 조건 종료 44 · 패배 13 · 시간 초과 3 ✓ · pairspar 76.8초 조건 종료 36 · 시간 초과 24 ✗ · pairsparclean 66.8초 · 50 · 10 · afterhand 68.0초 조건 종료 54 · 시간 초과 6 · 100점 54 ✓(띠의 가장자리).
- 사다리(결정 760 실행 결과): `pair_hatter` 7 · 3 → pairhat 52.1초 조건 종료 59 · 시간 초과 1 · 100점 59 ✓, pairhatwrong 53.4초 · 50 · 패배 9 · 시간 초과 1 ✓. `pair_baker` 3 · 3 → 되찾는 자세 2(pairspar 67.1초 · 53 · 시간 초과 7 ✗, pairsparclean 57.2초 · 56 · 4) → 1(메인이 같은 방향으로 한 칸 더): pairspar 51.5초 조건 종료 58 · 시간 초과 2 · 속은 몫 0.29 ✓, pairsparclean 44.4초 · 60. 최종 모자 7 · 3, 대련 3 · 1. T148~T152 5/5(최종 값), 표 파일 묶음 42/42.
- 메인이 읽은 장: `counter-pair`(베아트리체가 말하고 굴리엘모가 뒤에 흐리게, 버튼 셋, "상대: 굴리엘모 · 치고 빠지기 — 고르지 않은 쪽이 직접 칼을 든다"), `counter-pair-haggled`(버튼이 "값을 불렀다 — 이쪽 편이다"로 꺼짐), `duel-close-hat`(밀착에서 빵 모자 · 깃털이 HUD와 겹치지 않음).
- 확인 못 한 것: 손맛(판 M).

## 3. 설계 문서와 다르게 구현한 부분과 이유

- **UI 찍기 장 수**: 계획의 "M+5"에 결투 장 하나(`duel-close-hat` — 모자를 쓴 굴리엘모의 밀착)를 더해 M+6(39장)이다(작업 7이 허용한 길).
- **`tomorrow_data()` · `_begin_day()`**: `_fallback_data`가 null이어도 거르기에서 죽지 않게 null을 지켰다(기존 동작과 같다).
- **카운터 `_build()`**: 기술 검토의 비차단에 따라 `SwitchSide`를 `_refresh_haggle()` 호출보다 먼저 만든다(흥정한 뒤 새로 연 카운터도 꺼진 채 선다).
- **T148 ③**: 계획의 1일차 손님 목록(거름이 걸리면 `data`가 새 객체가 된다)에 맞춰 시험용 1일차는 거를 것이 없는 둘(A · D)로 만들었다.
- **T78의 빠진 표**: 나는 `second_opponent_tests.gd`를 안 고쳐도 된다고 읽었으나 틀렸다. 메인이 표에 넷을 더했다.
- **값 고침(결정 760의 실행 결과)**: 모자 7 · 3, 대련 3 · 1(둘째 칸은 메인이 대신 고름).
- **039 · 043 · 045의 어긋남(결정 762)**: 045의 넘기는 것("베아트리체를 고르면 상대는 굴리엘모 … 조건 `SPAR`")과 043의 넘기는 것("굴리엘모 쪽의 `SPAR` … 굴리엘모의 치고 빠지기를 따라붙으며 세 번")은 039 표 1번 · 045 근거 절의 모자 줄과 맞지 않았다. 039를 따랐다: `SPAR`는 굴리엘모가 맡기는 쪽이고 그 판의 상대는 베아트리체다. 모자는 베아트리체가 맡기는 쪽이고 상대는 굴리엘모다.

## 4. 사용자가 결정해야 할 것

그 세션에서는 묻지 않고 메인이 골랐다(대련 자세 3 · 1과 모자 7 · 3 포함). 나중에 직접 보고 뒤집을 수 있는 것은 판 M-1~M-11(`docs/HANDOFF.md` 3번 "047 판 M"): 번갈아 듣기의 다시 미끄러짐, 누구 편을 드는지의 고민, 모자 쓴 굴리엘모, 베아트리체와의 대련, 로렌초의 칼 든 손, 의뢰인에게 져 주기(채점은 이네스와 같다), 엇갈림, 귀족과 제빵사의 이음, 일정 이레, 같은 이름이 연습 목록에 둘씩, 두 말투.

## 5. 다음 작업 제안

- 048(버티기와 속편): 굴리엘모의 버티기, 클라라의 맞수 베아트리체, 비토리오의 독촉. T136 · T141 ⑥의 목록에 그 의뢰를 더한다. 의뢰인 열셋째는 049(BACKLOG 047-3). 계획 파일은 아직 없다 — planner부터. 결정은 766부터, 테스트는 T153부터.

라운드 수 2, 최종 판정: 디자인 APPROVE · 기술 APPROVE.
