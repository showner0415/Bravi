# 계획 H02 보고서: 타격감을 다시 — 읽고 맞춘 순간에만 멈칫·움찔·소리

계획 `docs/plans/H02-hit-feel-reward.md` v2.1. 결정 920~926b. 가지 `h02-hit-feel`, 작업 트리 `C:\godot\bravi-h02`. 검토 라운드 2 — 디자인 APPROVE · 기술 T7(신규)은 사용자 답 "고쳐서 실행"으로 v2.1에 반영(재검토 없음).

## 1. 한 일

- 새 `scripts/duel/hit_feel.gd`(`HitFeel`): 순간의 표 아홉(`moment_of`), 멈칫 `stop_msec(moment, ev)`, 상대 움찔 `flinch(moment, ev)`. 값은 전부 임시.
- `scripts/duel/duel_scene.gd`: `_stop_ticks_left`(멈칫은 물리 tick으로 세고 `_physics_process`·`_process`가 멈춘다), 멈칫 중 누름(공격·막기·전진·후퇴)이 조준을 갱신하고 멈칫을 끝냄, `TELL_START`의 뿌리 기억 `_hit_root`, `_on_core_event`가 살아 있는 판(`is_physics_processing()`)에서만 멈칫·움찔을 건다. `pause()`·`start_duel()`이 지운다.
- `scripts/duel/opponent_view.gd`: `_base_position`(보간)과 움찔을 나눔, `start_flinch`, 0.15초에 (1 − k)²로 거둠(코어 시각과 `_clock`의 큰 쪽), `TELL_START`·`PATTERN_STEP`·`setup()`에서 지움(`END`에서는 지우지 않음), 미리보기 꼬리표는 움찔 벡터를 뺀 자리.
- `scripts/duel/beeper.gd`: `TONES`의 셋째 칸(둘째 주파수), `graze_dealt`·`graze_taken`·`hit_dealt`·`hit_taken`·`parry`(1400+2100Hz)·`dodge_open`, `on_event(ev, moment)`.
- 테스트: 새 `tests/hit_feel_tests.gd`(T210 값·고르기·소리, T211 멈칫과 움찔, T212 멈칫의 합), `tests/run_tests.gd` 등록.
- 문서: CLAUDE.md 3장(타격감 한 단락)·7장·9장, `docs/DECISIONS.md` 920~926b, `docs/plans/H01-hit-feel.md` 머리("버렸다"), `docs/HANDOFF.md` 1번·3번(판 H02), `docs/BACKLOG.md`(계획 H02에서 미룬 것), 이 보고서.
- 판정 코드 0줄: `duel_core.gd`·`scripts/ai/`·`scripts/commission/`·`data/`의 diff 없음.

## 2. 확인한 것 / 못 한 것

- V0(코드 전 장): 194장. 무대 장 6장은 같은 커밋에서 두 번 찍어도 흔들려 뺐다.
- V1: 가져오기 오류 0, 스모크 OK, 기존 165/165 PASS, T210·T211 PASS, 이벤트 골든(T134) 32줄 같음. T212는 4% 기준에 여덟 상대 모두 걸렸다(4.0~5.6%, 봇은 완벽한 패리). 6%로 바꿔 다시 돌리는 중 — `-Only hit_feel` ALL PASS 3/3 (T212는 6% 기준으로 통과). 합 168/168
- V2: 찍은 장 194장 가운데 흔들리는 무대 장을 뺀 나머지는 전부 해시가 같다(다른 장 5장은 모두 흔들림 목록의 무대 장). 봇 통계 41줄은 글자까지 같다.
- 작업 0의 답: (가) 자리·꼬리표를 읽는 테스트·도구는 모두 물리를 끈 쪽이라 끄는 스위치가 필요 없었다. (나) `event_digest`의 목록이 이미 여덟 상대(053)다. (다) 결정·테스트 번호 겹침 없음.
- 못 한 것: 손맛은 사람이 해야 안다(판 H02). 게임 창 플레이는 하지 않았다.

## 3. 계획과 다르게 구현한 것

- `HitFeel.stop_msec(moment, ev)`에 `ev` 인자가 생겼다(스침 넣음의 칸 수로 50 · 70ms를 가르려고).
- 줄 수가 어림을 조금 넘었다(씬 +27, 뷰 +36).
- T212 기준을 4%에서 6%로(결정 926b — 사용자가 H01의 같은 문제에 "6%로"라 답했고 H02에 그대로 적용).

## 4. 사용자가 결정할 것

- 판 H02(`docs/HANDOFF.md` 3번, H02-1~5). 게임 켜기: `! powershell -ExecutionPolicy Bypass -File C:\godot\bravi-h02\play.ps1`
- 합치기: 판 뒤에 `h02-hit-feel`을 `stage6-content`에 합칠지(계획 작업 8).

## 5. 다음 작업 제안

- 판의 답이 값이면 `hit_feel.gd`·`beeper.gd`의 상수만 고친다(같은 계획, 재검토 없음).
- 답이 꼴이면 H03: 흔들림·불꽃·칼 반동·패턴 가운데의 멈칫·결과 패널 늦추기·비운 순간의 약한 층·금한 유효타의 소리(BACKLOG "계획 H02에서 미룬 것").
