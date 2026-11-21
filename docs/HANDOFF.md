# 인수인계 — 2026-11-21 계획 018 실행 뒤

이 파일은 다른 컴퓨터의 새 세션이 읽고 이어 가기 위한 것이다. 사용자가 "계획 계속 진행해줘"라고 하면 이 파일의 "1. 바로 다음에 할 일"부터 시작한다. 이어 받은 세션은 일을 마칠 때마다 이 파일을 지금 상태로 고치거나, 더 필요 없으면 지운다.

- 브랜치: `stage2-day-loop-v2`
- 계획 016·017은 커밋했다(`9f07935`, 원격에는 올리지 않았다). **계획 018의 변경은 커밋되지 않았다**(작업 트리에만 있다). 다른 컴퓨터에서 이어 받으려면 커밋하고 올려야 한다. 원격에는 계획 015까지 있다.
- 멈춘 때의 상태: 돌고 있는 하위 에이전트가 없고, 중간에 끊긴 코드 수정도 없다.

## 1. 바로 다음에 할 일

**사용자의 지시를 기다린다.** 계획 018(2단계 점검 — 겹친 누름, 저장의 쓰기, 헷갈리는 표기)까지 실행했다. 사용자 지시는 "2단계 전체 작업에 대해서 확인해보면서 위험하게 느껴지거나 최적화 할 수 있는 부분이 있는지 찾고 니가생각하기에 올바른 방향으로 수정해줘"였다. 보고서는 `docs/reports/018-stage2-checkup.md`다.

사용자가 정할 것(보고서 4번):

1. playtester로 018을 확인할지(사용자가 요청할 때만 띄운다). 목록은 `docs/reports/018-stage2-checkup.md`의 "playtester에게 맡길 확인" 1~12번과 "가리는 순서"다. 테스트의 기대값은 `ALL PASS 63/63`이다.
2. 겹친 누름의 두 값(0.4초, 0.6초), 폐점의 소지금 줄, 평판 줄의 자리, 계획 019(동작을 바꾸지 않는 정리 5건)를 할지.
3. 2단계 완료 판정과 3단계(스타일 바이블)로 넘어갈지(CLAUDE.md 9장. 사용자가 정한다).
4. 018의 커밋.

playtester가 오류를 보고하면: 018 보고서의 "가리는 순서"로 가리고, 고칠 것이 범위·규칙을 바꾸지 않는 오류면 고쳐서 보고한다. 범위나 규칙이 바뀌면 CLAUDE.md 11장의 수정 절차를 따른다(계획 018은 검토 1회를 썼다).

## 2. 실행 확인

- **계획 018은 아직 아무도 실행하지 않았다.** 바꾼 파일: `scripts/title.gd`, `scripts/day_ui.gd`, `scripts/commission/counter.gd`, `scripts/economy/settlement.gd`, `scripts/economy/closing.gd`, `scripts/save_store.gd`, `tests/safety_tests.gd`(새 파일, T60~T62), `tests/run_tests.gd`(한 줄), `tests/day_smoke.gd`(주석 한 줄).
- **계획 015·016·017은 2026-11-20 playtester가 확인했다. 실패한 항목은 없다**(`ALL PASS 60/60`, 스모크 OK, 게임 창의 확인 전부 통과). 결과는 `docs/reports/017-client-lines.md` 끝에 있다. 확인하지 못한 것 둘(015-9의 뒷부분, 이네스의 성공 판)도 거기에 있다. 아래 목록은 그 확인이 덮은 파일이다. 메인은 테스트와 게임을 직접 실행하지 않는다(아래 4번).

- 015: `scripts/economy/economy_rules.gd`, `scripts/economy/day_state.gd`, `scripts/commission/counter.gd`, `scripts/economy/settlement.gd`, `data/economy_rules.tres`, `tests/haggle_tests.gd`(T55)
- 016: `scripts/save_store.gd`(새 파일), `scripts/economy/day_state.gd`, `scripts/game_session.gd`, `scripts/title.gd`, `scripts/commission/counter.gd`, `scripts/economy/closing.gd`, `tests/save_tests.gd`(T56~T58), `tests/run_tests.gd`, `tests/day_smoke.gd`
- 017: `scripts/commission/commission.gd`, `scripts/economy/day_state.gd`(`settle()`의 두 줄), `scripts/economy/settlement.gd`, `scripts/commission/counter.gd`(`_refresh_haggle()`의 두 줄), `data/commissions/`의 일곱 `.tres`(더한 줄 26), `tests/client_line_tests.gd`(T59), `tests/run_tests.gd`(한 줄)
- 통과하면 테스트의 마지막 줄이 `ALL PASS 60/60`이다. 새 테스트 파일 셋은 한 번도 실행되지 않았다. 파싱 오류가 있으면 러너가 거기서 멈춘다.
- 계획 011~014는 2026-11-20에 playtester가 확인했다(`ALL PASS 55/55`, 스모크 `RESULT: OK`).

## 3. 사용자가 보류했거나 아직 답하지 않은 결정

값은 전부 지금 그대로 두고 있다. 사용자가 다시 말하기 전에는 건드리지 않는다.

- 계획 012 보고서 4번: 승리의 값(+1), 별에 따른 하루 결투 수, 궂은일을 맡는 값, 별이 차는 속도, 토마소를 못 해냈을 때의 합. 사용자가 "보류"라고 했다.
- 계획 013 보고서 4번: 기본 보수 덧붙임의 크기(±20%), 낮은 별의 깎임.
- 계획 014 보고서 4번: 100점 조건이 팁에도 걸리는 것, +30%와 의뢰인의 값.
- 계획 015 보고서 4번의 넷과 디자인 검토자의 의견 셋.
- 계획 016 보고서 4번: 하루를 다시 했을 때의 주사위, 읽을 수 없는 저장의 백업, 화면의 글과 자리, 하루를 다시 하는 길. ("새로 시작한다"를 빠르게 두 번 눌렀을 때는 계획 018이 고쳤다: 0.6초.)
- 계획 017 보고서 4번: 글 26줄의 문장, 성향 한 줄을 의뢰인별로 쓸지, 거절의 까닭, 정산의 글을 더 잘게 가를지, 이미 있던 21줄. (커밋은 016·017을 한 번에 했다.)
- 계획 018 보고서 4번: 겹친 누름의 두 값(0.4초·0.6초), 폐점의 소지금 줄의 뜻, 정산·폐점의 평판 줄의 자리, 계획 019를 할지, 018의 커밋.
- playtester가 올린 것(`docs/reports/014-counter-haggle.md` 끝): 정산과 폐점의 평판 줄이 패널 밖에 놓이는 것과 폐점의 소지금 표기(`소지금 -18 → -78`)는 018 보고서 4번으로 옮겼다. `치료비 -0`은 018이 고쳤다. T53의 이름은 맞는 값이었다(고치지 않았다).
- `docs/plans/013-playtester.md`(사용자의 파일)의 번호 013이 `013-reputation-base-pay-and-fail-scale.md`와 겹친다. 정리할지 답을 받지 못했다.
- 사용자가 아직 플레이하지 않은 체크리스트: 013 보고서의 Q, 014의 R, 015의 S, 016의 T, 017의 U, 018의 V.

## 4. 작업 규칙 (사용자가 2026-11-20에 정한 것)

원래 컴퓨터와 계획 016을 실행한 컴퓨터의 메모리에는 들어 있다. 다른 컴퓨터의 세션은 여기서 읽는다.

- **메인 에이전트는 테스트와 게임을 직접 실행하지 않는다.** `tests/run_tests.ps1`, `tests/run_smoke.ps1`, 헤드리스 Godot, `play.ps1` 전부다. 모델과 상관없다.
- **실행 확인은 사용자가 요청할 때만 `playtester` 에이전트에게 맡긴다.** 스스로 띄우지 않는다. `playtester`는 Opus 5.5로만 돈다. 호출할 때 모델과 effort 인자는 생략해 에이전트 정의를 따른다(CLAUDE.md 11장). Opus 5.5로 돌 수 없으면 멈추고 까닭을 보고한다.
- 세션 모델이 Fable 5.2일 때는 어떤 방식으로도 테스트를 돌리지 않는다. Opus 5.5만 돌릴 수 있다. 세션이 Opus 5.5여도 메인은 직접 돌리지 않는다(위 규칙. 계획 017은 세션 도중 Opus 5.5로 바뀐 뒤에도 그렇게 했다).
- 그래서 계획의 완료 기준은 코드 읽기, Grep, 값 대조, 손 계산으로 잡고, 실행이 필요한 확인은 보고서의 "playtester에게 맡길 확인" 목록으로 적는다. 작업 보고(CLAUDE.md 10장)의 2번에는 돌리지 않은 확인을 "확인 못 한 것"으로 적는다.
- 스크립트를 실행 없이 고칠 때는 계획 012~016의 "공통 규칙"(기계적 확인 다섯 가지)을 따른다: 들여쓰기 Grep(탭만), 같은 함수 안의 이름 겹침, `:= .*\.get\(`와 `:= .*\[`의 타입 추론, 서식 문자열의 자리 수와 `%%`, `@warning_ignore("integer_division")`의 위치.
- playtester는 게임·테스트·스모크를 띄우는 명령마다 `$env:BRAVI_SAVE_PATH = "user://bravi_playtest_save.json"`을 같은 줄에서 건다(사용자의 실제 저장 `bravi_save.json`을 건드리지 않게. 계획 016).
- 사용자가 "NNN 계획 보고서"라고 하면 `docs/reports/`의 그 번호 파일을 그대로 보여 준다(예: "004 계획 보고서"는 `docs/reports/004-day-loop-skeleton.md`).
- 이 프로젝트를 만든 컴퓨터(Windows)에는 쓸 수 있는 Python이 없었다. 계산이 필요하면 셸이나 손 계산으로 했다.
- 계획 하나의 검토는 2회가 상한이다(CLAUDE.md 11장). 하위 에이전트가 큰 편집 도중 응답이 끊긴 적이 있어, planner에게 편집을 작게 나눠 하라고 부탁해 왔다.

## 5. 커밋에 넣지 않은 것

- `.codex/`와 `AGENTS.md`: 사용자의 파일이고 원래 컴퓨터에만 있다.
- playtester가 남긴 실행 로그와 화면 캡처: 저장소 밖의 임시 폴더에 있다.
