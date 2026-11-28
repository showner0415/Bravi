# 계획 053 보고서: 여덟째 상대 코르넬리아 — 공격의 칸 "가림 줄", 고유 검술 "송곳 가림"

계획 `docs/plans/053-eighth-opponent-cornelia.md` v2. 결정 825~845. 검토 라운드 2 — 디자인 APPROVE, 기술 T1 · T2 해소(2회차의 신규 T3는 메인이 하는 0m · 11m 절차에 대한 것이었고, 그 덩이가 053 전에 `7d9827b`로 커밋되어 절차가 불필요해져 닫음). 실행은 하위 에이전트가 했고 Godot · 테스트는 실행하지 않았다.

## 1. 한 일

- 공격의 칸 `AttackData.cover_columns`(`scripts/ai/attack_data.gd`), 열거 `Forecast.SPIKE_COVERED`(`duel_types.gd`).
- 코어(`duel_core.gd`): `covered_at` · `covered_dirs`, `spike_live` · `covers_now` · `lunge_spiked_now`, `_verdict` · `_foresee`의 끝 인자 `direction := -1`(회수 갈래 맨 앞의 한 줄), `_resolve_strike`가 길이 끝나 회수가 시작되면 가림을 세우고 `STRIKE`에 `cover`, `_judge_attack`의 `SPIKE_COVERED` 갈래(막힘 · 대가 없음 · `brain.start_idle`로 빈틈 닫힘 · `ATTACK`에 `spiked`). 뇌(`opponent_brain.gd`)는 0줄. `duel_record.gd` 설명 줄.
- 표시: `scripts/duel/cover_marks.gd`(새, `CoverMarks`), `duel_scene.gd`(노드를 코드로 붙임 · 미리보기 테두리), `opponent_view.gd`(`FORECAST_COLORS` · "송곳에 걸렸다" · 귀띔 "송곳 — 빈 줄: …"), `duel_hud.gd`(`FORECAST_WORD` · `FORECAST_NOTE` · `LUNGE_AIM_SPIKE` · `HELP_COVER` · 제 도우미 `has_cover` · 기록 글), `commission_select.gd`(막는 법의 한 줄), `beeper.gd`(`spike` 1560Hz, `ATTACK`의 맨 앞), `duel_summary.gd`(`covers` 열쇠와 길 글의 "#").
- 데이터: `data/opponents/opponent_08.tres`(빌린 몸 `bartolo_art.tres`, 단 여섯, 길 아홉, 녹청빛).
- 도구: `tests/duel_bots.gd`(`cover_read_fn` · `_read_cover`), `tests/duel_stats.gd` · `tests/run_duel_stats.ps1`(`-Aim last` · `-Spike` · `cover,` 줄), `tests/event_digest.gd` · `tests/run_event_digest.ps1`(07을 코드 전 커밋 `0ed7175`에 넣었고, 08은 끝 커밋에서 verifier가 `-Write`).
- 테스트: 새 `tests/cover_tests.gd`(T162) · `tests/eighth_opponent_tests.gd`(T163~T165), `tests/run_tests.gd`의 `TEST_FILES`, 고침 — `style_tests.gd`(상수 · 기대 행 · `_check_cover` · `_sig_text` · `_reading_amount` · `_row` · `marked`), `pattern_cell_tests.gd`(여덟째), `stage6_tests.gd`(`ART_PENDING`).
- 문서: DECISIONS 825~845, CLAUDE.md 3장(송곳 가림 · 고유 검술 · 단 · 둘째 표지) · 5장 · 9장, HANDOFF, BACKLOG(053-H01 · 053-1), 이 보고서.

## 2. 확인한 것 / 못 한 것

- 직접 실행하지 않았다(Godot · 테스트 · 게임). 코드는 읽고 맞추기만 했다.
- verifier 결과(메인이 `duel_hud.gd` `_describe`의 들여쓰기 한 칸을 고친 뒤 — 첫 시도는 그 파스 오류로 가져오기에서 막혔다): 가져오기 오류 0, 테스트 164/165(T162의 "[마] 버티기" 줄만 실패 — 아래 3번에서 고침), smoke · counter OK, UI 46장 OK. **V0 장 견줌**: 패턴 찍기 1~6단 61 · 88 · 109 · 139 · 181 · 205장과 상대 찍기 일곱 57 · 57 · 62 · 57 · 57 · 57 · 57장이 코드 전과 SHA까지 모두 같다(코르넬리아의 새 장만 더해짐: 패턴 10 · 16 · 19 · 25 · 31 · 37장, 상대 찍기 57장 OK). **봇 통계 V0**: 인자 없는 줄 · verify 13단계 모두 바탕과 글자까지 같다(코르넬리아 줄만 더해짐). 골든 32줄(앞 28줄 그대로, 08의 4줄만 더함, 두 번 같음, T134 2/2).
- V2(결정 838a 참고): (가) 판당 맞음 3.0 · 3.1 · 3.4 · 3.2 · 3.2 · 3.4, 승 22 · 23 · 11 · 22 · 20 · 13 — 2→3단 −12(기본 겹찌르기, 고칠 값 없음 → BACKLOG 053-2), 5→6단 −7(고유 벽 → 6단에서 ⓘ를 뺌, 결정 835a), 1→6단 −9. (나) `-Delay 0` 40.8 · 39.6 · 43.2 · 42.6 · 40.4 · 41.8초, 시간 초과 0, 4→5단 −2.2초(기본 단, 적고 둠). `-Delay 0.25` 시간 초과 1 · 2 · 2 · 1 · 12 · 10, `-Delay 0.5` 3 · ? · 3 · 2 · 12 · 11(5 · 6단이 1단 + 4 초과 — 5단은 기본이라 적고 둠, 6단은 고침 뒤 다시 잰다). (다) 1단 승 22 ✓. (라) ① `-Aim last` 62.6초 · `-Spike 1` 84.0초(1.34배 ✓), 걸린 몫 0.67 ✓. ② 닿은 몫 단마다 1.00(6단 0.5만 0.99), 걸림 0 ✓. 겹침의 몫: 1단 2/3, 2·3단 3/5, 4·5단 5/7, 6단 6/8(고침 뒤).
- 고침 뒤 재측정(결정 838b): `cover_tests,eighth_opponent_tests,style_tests` 9/9(T162 통과 — 합 165/165), `practice_screen_tests,pattern_cell_tests,stage6_tests` 8/8, 패턴 찍기 6단 239장 hint 겹침 0. 6단 (가) 64.6초 · 패배 37 · 승 13(뺀 뒤에도 13 — 효과 없음) · 시간 초과 10, cover 닿은 몫 0.99 · 걸림 0. (나) `-Delay 0` 41.5초 · 승 30, `-Delay 0.25` 78.5초 · 승 20 · 시간 초과 10, `-Delay 0.5` 79.8초 · 승 20 · 시간 초과 10, 닿은 몫 1.00 · 걸림 0. 5단 (가) 64.9초 · 승 20 · 시간 초과 7.
- 골든: 08의 4줄을 다시 써 32줄, 앞 28줄 그대로 — verifier 결과(메인이 결과를 보고 고친다).

## 3. 계획과 다르게 한 곳

- **작업 0m · 11m(남의 덩이 치우기)는 하지 않았다**: `duel_hud.gd`의 `help_text` 변주 훑기 `flat`과 `run_tests.ps1`의 `-Only` 배열이 이미 `7d9827b`로 커밋되었다(결정 843). `has_cover`는 계획대로 제 도우미다.
- `spike` 음은 1760Hz가 아니라 **1560Hz**다(디자인 비차단 — 1760은 패리 880의 옥타브라 "잘 받았다"로 들릴 수 있다). `TONES`와 H01의 음 표에 없음을 Grep으로 확인했다.
- 작업 1(골든을 07까지)은 메인이 먼저 돌려 커밋했고(`0ed7175`) 나머지 작업은 한 번에 이어서 했다. V0은 `opponent_08.tres`가 이미 폴더에 있는 트리에서 돈다 — 찍기 · 통계의 일곱 상대 줄과 장만 `before-*`와 견준다(여덟째의 장 · 줄은 새것이다).
- 봇의 `_read_cover`는 "넷의 누르는 자리"가 아니라 받아치는 조준을 정하는 두 자리(`counter_fn`의 결과 · `whiff_fn`의 결과)에서 부른다. 늦춘 받아치기와 따라붙기는 그 조준을 이어받으니 같은 결과다(가림은 회수가 끝나기 전에는 바뀌지 않는다).
- T162 (사)는 실제 런지 상황을 짜지 않고 `_verdict`를 직접 불러(회수의 런지가 가운데 줄로 걸림 · 대기의 런지는 안 걸림 · 가운데가 열린 회수의 런지는 닿음) 규칙을 굳혔다(결정 829).
- 요약의 `openings`는 걸린 공격을 "늦음"으로 센다(막힘이고 피함이 아니라서). 코르넬리아의 줄에서만 나타나고 판정에는 쓰이지 않는다.
- `opponent_08.tres`는 굴리엘모(`opponent_07.tres`)의 포즈 · 큰 베기 · 판정 줄을 옮겨 생성 스크립트로 만들었다(스크립트는 저장소에 없다).
- 6단 고침 1회 — 효과 없음, 적고 둔다(결정 838b). 실행 뒤 고침 둘: 6단의 벽에 ⓘ(네 번 두드림의 둘째 길)를 뺐다(결정 835a, `opponent_08.tres`에서 자원 넷 삭제 · T163 표 · CLAUDE.md 3장). T162 "[마] 버티기"는 첫 예비 동작보다 막기를 먼저 쥐는 판으로 바꿨다(키 봇은 막기와 예비 동작이 같은 틱이라 버티기가 서지 않는다).
- 걸림 후 `brain.start_idle`은 새 대기 길이를 뽑느라 `rng`를 한 번 쓴다(가림이 걸린 판에서만, 결정 828).

## 4. 사용자가 결정해야 할 것

없다(메인이 대신 고름). 판 W2-C(6단이 벽인가 — 5→6단 승 20 → 13과 5 · 6단 반응 봇의 시간 초과, 걸리면 빈틈이 닫힌다 · 표지 · 소리 · 남은 손 · 런지 · 기본 검술 · 녹청빛 · 단의 길 · 인물)는 사용자가 나중에 본다 — HANDOFF 3번.

## 5. 다음 작업 제안

053b(코르넬리아의 그림 — 몫 6장, 판 S0의 더한 확인, T161 `ART_PENDING` 비우기) → 054 의뢰인 그림 셋 → 056 → 057 → 058. H01은 결정 844의 ㉮~㉱로 053 위에 올린다.
