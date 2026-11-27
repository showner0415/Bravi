# 보고서 048: 버티기와 속편

- 계획: `docs/plans/048-hold-and-sequels.md` v2. 6단계(콘텐츠), 나눔 039의 048 줄. 결정 766~781, 테스트 T153~T156.
- 검토: 2회. 1회차 디자인 REVISE(D1 · D2) · 기술 REVISE(T1) → v2 → 2회차 디자인 APPROVE · 기술 APPROVE.
- 상태(2026-11-28): 구현 끝, verifier 확인 대기. 구현 에이전트와 메인은 Godot · 테스트 · 게임을 실행하지 않았다.

## 1. 한 일

- **조건**: `scripts/commission/hold_condition.gd`(새, `HoldCondition` — 받아낸 수를 채운 뒤 이긴다, 먼저 댄 칼 감점. `counted_blocks` · `early_touches` · `reach_time`). 코어 · 뇌 · HUD · `day_state` · `commission` · `counter` 0줄.
- **의뢰 셋**(`data/commissions/variants/`): `close_baker.tres`(굴리엘모 → 브루노 4일차 2단, 받아 주기 10, 자세 7 · 3, 35 · 25) · `rival_milliner.tres`(클라라 → 베아트리체 5일차 1단, 칼 든 팔 · 유효타만, 자세 7 · 3, 40 · 20) · `dun_master.tres`(비토리오 → 아고스티노 6일차 2단, 머리 · 유효타만, 70 · 20, 맡는 값 −3, 플래그 `sparred_master` 필요 · `dunned_master`를 남긴다). 의뢰인 그림 `guglielmo.png` · `clara.png` · `vittorio.png`을 걸었다(그림 0장).
- **대련**: `data/commissions/spar.tres`에 `sets_flags = ["sparred_master"]` 한 줄.
- **하루**: `data/days/day_04.tres`(셋째에 `close_baker`, 아홉), `day_05.tres`(`feather_cut`을 빼고 셋째에 `rival_milliner`, 아홉), `day_06.tres`(`first_blood_usurer`를 빼고 둘째에 `dun_master`, 여덟).
- **재는 도구**: `tests/duel_stats.gd`(`--patient` · `--finisher=arm|head` · `hold,` 줄), `tests/run_duel_stats.ps1`(`-Patient`, `hold,` 줄 통과), `tests/verify.ps1`(`-Stats`에 `hold` · `holdwrong` · `holdrash` · `sleeve` · `dunhead`). `duel_bots.gd` · `plain_opponent.gd` 0줄.
- **테스트**: `tests/hold_tests.gd`(T153~T156, `run_tests.gd`의 `TEST_FILES` 끝), 표를 고친 `client_line_tests`(T59) · `counter_art_tests`(T77) · `stage_tests`(T72) · `reputation_tests` · `day_tests`(T37) · `second_opponent_tests`(T78의 의뢰 → 상대 표) · `fifth_opponent_tests`(아고스티노를 거는 의뢰) · `sixth_opponent_tests`(T136 ⑥). UI 찍기 `counter-close-baker` · `counter-rival-milliner` · `counter-dun-master` · `duel-hold-early` · `duel-hold-full`(39 → 44장, `ui_shots.gd` · `run_ui_shots.ps1`의 `$count`).
- **문서**: `docs/DECISIONS.md` 766~781, `CLAUDE.md` 4 · 5 · 9장(4장에 `HOLD` 줄을 새로 더했고 `CLOSE_WIN` 줄 · 9장의 R04 줄은 고치지 않았다), `docs/HANDOFF.md`, `docs/BACKLOG.md` 048-1~5, 이 보고서.
- **글자 수**(공백 · 문장부호 포함, 문단 둘): 굴리엘모의 사연 141 + 74(합 216), 해냄 44 · 부분 49 · 못 해냄 43 · 돌려보냄 27, 흥정 31 · 42. 클라라의 사연 154 + 79(합 234), 해냄 44 · 부분 43 · 못 해냄 48 · 돌려보냄 29, 흥정 34 · 36. 비토리오의 사연 163 + 57(합 221), 해냄 50 · 부분 49 · 못 해냄 43 · 돌려보냄 30, 흥정 28 · 40. 모두 280 · 56 · 44 안. `HoldCondition.describe()`는 59자(047 `after_hatter`의 조건 글 66자보다 짧다).

## 2. 직접 실행해서 확인한 것 / 확인 못 한 것

구현 에이전트와 메인은 Godot · 테스트 · 게임을 실행하지 않았다. 아래는 verifier의 결과가 오면 채운다.

- 가져오기 OK(새 파일 `scripts/commission/hold_condition.gd.uid` · `tests/hold_tests.gd.uid`는 커밋에 넣는다). 테스트 **156/156**(hold 4 + 29 + 30 + 41 + 25 + 24 + 3). `verify.ps1 -Only counter` OK(10장, 겹침 0). `UI SHOTS OK 44`. 메인이 읽은 장 `duel-hold-early`(최종 값): 게이지 곁 "받아냄 5/10 · 아직입죠"가 잘리지 않고 조건 글이 판 안에 선다.
- V0: 5d36aa9 worktree와 `noble_baker`(`-Finisher low`) · `pair_hatter`(`-Finisher top`) · `spar`(`-Finisher off`) 줄이 글자까지 같다.
- V2 1차(값 그대로): hold 79.4초 조건 종료 40 · 시간 초과 20 ✗ · 채운 판 60(22.3초), holdwrong 패배 41 · 시간 초과 11 · 조건 종료 8 ✗, holdrash 63.6초 · 100점 3 ✓ · 먼저 댄 칼 1.72, sleeve 72.4초 · 조건 종료 43 · 시간 초과 17 ✗, dunhead 43.9초 · 60 · 60 ✓.
- 사다리: `rival_milliner` 자세 7 · 3 → sleeve 60.4초 · 조건 종료 58 · 시간 초과 2 ✓. `close_baker`(시간 초과가 끝내는 마디에서 나서 둘째 줄을 먼저, 메인이 대신 고름) 자세 7 · 3 → hold 69.0초 · 51 · 시간 초과 9 ✗, `blocks_needed` 12 → 10 → hold 63.6초 · 조건 종료 56 · 시간 초과 4 · 100점 56 · 채운 판 60(18.2초) ✓, holdwrong 58.7초 · 패배 32 · 조건 종료 24 ✗ · holdrash 48.8초 · 100점 8 ✗ · 먼저 댄 칼 1.30. 두 번 고쳐 멈춤 — 가장 가까운 값(10 · 7 · 3)으로 두고 판 N-4에 올린다. T153~T156 4/4(최종 값; 참는 봇 41.8~48.1초 100점, 곧장 받아치는 봇 27.4~30.5초 0점).
- 확인 못 한 것: 손맛(판 N).

## 3. 설계 문서와 다르게 구현한 부분과 이유

- **값 고침**: 버티기 받아냄 12 → 10 · 자세 7 · 3, 소매 자세 7 · 3(위 사다리). 띠 밖 둘(holdwrong 조건 종료 24 · holdrash 100점 8)이 남아 049가 다시 잰다(BACKLOG 048-6).
- **`pair_baker` 되찾는 자세**: 계획의 V0 절은 "되찾는 자세 2"라 적었으나 047의 최종 값은 3 · 1이다(`pair_hatter`는 7 · 3). 이 계획의 표에 그 값을 가정한 곳은 없고 문서에는 3 · 1로 옮겼다.
- **UI 찍기의 버티기 화면**: 계획의 `duel-hold-*`는 기존 결투 찍기의 꼴(`_duel` + 기록을 늘린 뒤 `_update_views`, `States.put` · `advance` · `tick` 없음)로 만들었다.
- **T153 ⑦의 화면 줄**: `hold_tests.gd`에서 `States.put`을 쓰지 않고 `_update_views(0.0)`만 불러 게이지 글을 읽는다(계획 지시).
- **먼저 댄 칼의 셈**: 판을 끝내는 유효타는 세지 않는다(N번째 받아냄 앞의 스침만) — 계획 T153 ②의 "받아냄 1 · 스침 1 · 받아냄 2 · 유효타 → 65"와 ①의 "받아냄 0개 뒤 유효타 → 100"을 함께 만족시키는 읽기다.
- **기존 테스트의 표**: T59 `PATHS` · T77 `PORTRAITS` · T72 `ASSIGNED`(열넷 → 열일곱) · T37 두 목록 · `reputation_tests` `COMMISSION_PATHS` · T78의 의뢰 → 상대 `elif`(`close_baker` → 브루노, `dun_master` → 아고스티노, `rival_milliner` → 베아트리체) · `fifth_opponent_tests`(`["spar.tres", "dun_master.tres"]`) · `sixth_opponent_tests`(`+ "rival_milliner.tres"`)를 고쳤다. `second_opponent_tests`의 의뢰 상수를 더했다. 그 밖의 테스트는 폴더 · 일정을 읽어 자동으로 걸린다.

## 4. 사용자가 결정해야 할 것

그 세션에서는 묻지 않고 메인이 골랐다. 띠 밖으로 남은 둘(holdwrong · holdrash)은 판 N-4b와 BACKLOG 048-6에 있다. 나중에 직접 보고 뒤집을 수 있는 것은 판 N-0~N-8(`docs/HANDOFF.md` 3번 "048 판 N"): `STALL` → `HOLD`, 받는 마디의 손맛(열 번), 패리를 둘로 셀까, 4일차에 대련과 받아 주기가 함께, 클라라의 소매, 비토리오의 독촉(머리 · 맡는 값 −3), 끝내지 못한 판의 0점, 하루에서 뺀 둘, 세 말투.

## 5. 다음 작업 제안

- 049(1주차 일정): 의뢰 17 · 의뢰인 12이므로 "토마소가 데려온 손님" 하나가 열여덟째 의뢰와 열셋째 의뢰인을 함께 채운다(BACKLOG 048-3). 4일차의 새 조건 둘(048-1), 굴리엘모의 잇단 등장(R5), 날별 봇 통계에 이 다섯 단계, 도움말의 `HOLD` 줄, "고른 뒤에 오는 고른 쪽"(048-2). 계획 파일은 아직 없다 — planner부터. 결정은 782부터, 테스트는 T157부터.

라운드 수 2, 최종 판정: 디자인 APPROVE · 기술 APPROVE.
