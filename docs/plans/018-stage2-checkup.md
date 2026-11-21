# 계획 018: 2단계 점검 — 겹친 누름, 저장의 쓰기, 헷갈리는 표기

- 버전: v1
- 개발 단계: CLAUDE.md 9장 2단계 (하루 루프). 2단계의 작업은 계획 016까지였고 017은 사용자의 직접 지시였다. 완료 판정은 사용자가 아직 하지 않았다. 이 계획은 **판정 전의 점검과 손질**이다. 새 기능·새 의뢰·아트·사운드, CLAUDE.md 5장의 "아직 없는 것"(칼 수리비, 부상에 따른 의뢰 수 감소)은 하지 않는다. 단계를 넘지 않는다
- 근거:
  - 사용자 지시(2026-11-20, 원문): "2단계 전체 작업에 대해서 확인해보면서 위험하게 느껴지거나 최적화 할 수 있는 부분이 있는지 찾고 니가생각하기에 올바른 방향으로 수정해줘." 방향은 위임받았다. 무엇을 고치고 무엇을 남길지는 planner가 정했다(아래 "점검 결과").
  - 넘지 않는 선(메인이 전달): 보류 중이거나 답을 받지 못한 값과 결정(`docs/HANDOFF.md` 3번, 계획 012~017 보고서 4번)은 고치지 않고 "사용자 결정 필요"에 올린다. 플레이 규칙(CLAUDE.md 3~6장과 결정들)은 바꾸지 않는다. 설계와 다르게 동작하는 것은 고친다. 사용자의 파일(`docs/plans/013-playtester.md`, `.claude/agents/playtester.md`)은 건드리지 않는다.
  - 실행으로 드러난 것: playtester(2026-11-20, `docs/reports/017-client-lines.md` 끝)는 `ALL PASS 60/60`과 스모크 OK를 확인했고, "새로 시작한다"를 더블클릭(약 90ms)이나 Enter 두 번(약 120ms)으로 누르면 **경고를 볼 틈 없이 가게가 지워진다**는 것과, 남은 손님이 2명인데 머리 줄이 `오늘 남은 결투 3`인 것을 봤다. `--script` 러너에도 오토로드가 뜬다(`RUNNER 저장: 오토로드 GameSession 있음, …`).
  - 결정 150(사용자 답): 저장이 있을 때 "새로 시작한다"는 **두 번 눌러야** 지워진다. 결정 55·63: 정산에서 넘어온 Space가 폐점의 가게와 카운터의 선택을 대신 고르지 않게 한다(포커스로 막았다). 계획 004: 카운터의 버튼은 의뢰인이 들어오는 것을 기다리지 않고 처음부터 눌린다.
  - 엔진: Godot 4.7(`project.godot`). `change_scene_to_file`은 나가는 씬을 곧바로 트리에서 떼고 새 씬을 그 프레임 끝에 붙인다. 입력은 `_input` → GUI → `_unhandled_input` 순서로 간다(`_input`에서 `set_input_as_handled()`하면 버튼에 닿지 않는다).
  - 사용자 규칙: 메인은 Godot을 어떤 방식으로도 실행하지 않는다. 실행 확인은 사용자가 요청할 때 playtester가 한다.
- 번호: 018. 결정 번호는 164부터다(`docs/DECISIONS.md`의 끝이 163).
- 저장소 상태: 계획 016·017의 변경은 커밋되지 않았을 수 있다. 이 계획은 어느 쪽에서도 실행할 수 있게 썼다(작업 0).

## 목표와 범위

**확인할 결과** (메인은 코드 읽기·Grep·값 대조·손 계산으로 확인하고, 실행 확인은 작업 8의 playtester 목록으로 넘긴다)

1. 저장이 있는 처음 화면에서 "새로 시작한다"를 더블클릭하거나 Enter를 연달아 눌러도 가게가 지워지지 않는다. 경고가 뜬 뒤 잠깐(0.6초) 지나 다시 누르면 지워진다(결정 150의 "두 번 눌러야"를 빠른 손에서도 지킨다).
2. 앞 화면에서 빠르게 두 번 누른 것(더블클릭, Space 두 번)의 두 번째가 **다음 화면의 버튼을 누르지 않는다**: 정산의 "다음 의뢰인" → 카운터의 "맡는다", 카운터의 "돌려보낸다" → 다음 손님의 "돌려보낸다", 정산의 "가게를 닫는다" → 폐점의 "다음 날을 연다", 폐점의 "다음 날을 연다" → 카운터의 "맡는다", 결투의 Space → 정산의 "다음". 카운터·정산·폐점은 열린 뒤 0.4초 동안 마우스 버튼과 키를 받지 않는다.
3. 저장을 쓰는 도중에 꺼져도 원래 저장이 깨지지 않는다(옆의 임시 파일에 다 적고 확인한 뒤 바꿔 끼운다).
4. 카운터 머리 줄의 "오늘 남은 결투"가 지금 손님과 문밖 손님을 합친 수를 넘지 않는다. 폐점 장부에 `-0`이 찍히지 않는다.
5. 그 밖의 동작, 값, 규칙은 하나도 바뀌지 않는다. 기존 테스트 60개의 통과 조건이 바뀌지 않고, 새 테스트 셋(T60~T62)을 더해 통과하면 `ALL PASS 63/63`이다. 스모크는 고치지 않고 통과한다(주석 한 줄만 고친다).

**범위 밖**: 보류 중인 값과 결정 전부("사용자 결정 필요"의 끝), 정산·폐점의 평판 줄 자리와 폐점의 소지금 표기의 뜻(사용자 결정 2·3번), 동작을 바꾸지 않는 정리(계획 019의 후보. "규모" 절), `DayState` 갈라내기.

## 점검 결과

planner가 2단계의 스크립트(`scripts/title.gd`, `game_session.gd`, `save_store.gd`, `day_ui.gd`, `scripts/commission/counter.gd`, `scripts/economy/` 전부, `scripts/duel/duel_scene.gd`의 하루 모드)와 데이터(`data/economy_rules.tres`, `reputation_rules.tres`), 테스트(`tests/run_tests.gd`, `day_tests.gd`, `reputation_tests.gd`, `haggle_tests.gd`, `save_tests.gd`, `client_line_tests.gd`, `day_smoke.gd`)를 읽었다. 찾은 것 21. 심각도 높음 2, 중간 1, 낮음 17, 해당 없음 1(F9). 이 계획에서 고치는 것 7(F1~F6, F10), 019 후보 5(F11·F15·F16·F17·F20), 사용자에게 묻는 것 2(F7·F8. 답에 따라 019), 그대로 두는 것 6(F12·F13·F14·F18·F19·F21), 버리는 것 1(F9).

| # | 위치 | 무엇이 문제인가 | 심각도 | 이 계획에서 | 까닭 |
|---|---|---|---|---|---|
| F1 | `scripts/title.gd:113` `_on_new_game` | 첫 누름이 `_armed`만 세우고 두 번째 누름을 곧바로 받는다. 더블클릭·Enter 두 번이면 경고를 읽기 전에 지워진다(playtester가 봤다). 되돌릴 수 없는 손실이다 | 높음 | **고친다** (작업 1, 위험 수정) | 사용자 답 "두 번 눌러야 지워진다"의 뜻은 "실수로는 지워지지 않는다"다. 첫 누름 뒤 0.6초 동안 두 번째 누름을 받지 않는다 |
| F2 | 화면의 버튼 자리: 정산 `Proceed` `(900,590,320,76)` = 카운터 `Proceed` 같은 자리. 폐점 `Proceed` `(868,622,380,76)`은 정산·카운터의 `Proceed`와 `x 900~1220, y 622~666`에서 겹친다. 카운터 `Decline` `(640,600,230,56)`은 다음 손님의 카운터에서도 같은 자리다. 정산은 `Proceed`에 포커스를 둔다(`settlement.gd:130`) | 새 씬은 앞 씬의 누름이 끝난 그 프레임 끝에 붙는다. 더블클릭의 두 번째 누름(약 90ms 뒤)은 새 화면의 같은 자리 버튼을 누른다: 사연을 읽기 전에 손님을 맡고, 다음 손님을 보지도 않고 돌려보내고, 가게를 건너뛴다. 결투 끝의 Space 두 번은 정산을 건너뛴다. 결정 55·63이 키보드에서 막은 것을 마우스와 정산의 포커스가 뚫는다 | 높음 | **고친다** (작업 2, 위험 수정) | 플레이어가 고를 기회를 모르게 잃는다. 카운터·정산·폐점이 열린 뒤 0.4초 동안 마우스 버튼과 키를 삼킨다(`_input`). 테스트가 다른 씬 아래에 붙인 화면과 스모크의 `pressed.emit()`에는 걸리지 않는다 |
| F3 | `scripts/save_store.gd:26` `write` | 원래 파일을 `WRITE`로 열어 바로 덮어쓴다. 쓰는 도중 꺼지면 파일이 깨지고, 다음에 켜면 "읽지 못했다"가 뜨고 가게를 열면 덮어쓴다(가게를 잃는다). 계획 016 위험 6이 "실행 없이 확인하기 어렵다"로 미뤘다 | 중간 | **고친다** (작업 3, 위험 수정) | 이제 playtester가 실행으로 확인할 수 있다. 쓰는 때(폐점에 들어설 때, 살 때마다)가 잦지는 않지만 잃는 것이 가게 전부다 |
| F4 | `scripts/save_store.gd:32` | `store_string`의 결과를 보지 않는다. 디스크가 차서 덜 적혀도 `true`를 돌려주고 폐점에 "저장했다"가 뜬다 | 낮음 | **고친다** (작업 3에 함께) | 임시 파일을 다시 읽어 견주면 같이 풀린다 |
| F5 | `scripts/commission/counter.gd:84` 머리 줄 | `오늘 남은 결투`가 `duels_left()` 그대로라, 남은 손님(지금 + 문밖)이 그보다 적으면 칠 수 없는 결투까지 센다(손님 2명에 `남은 결투 3`. playtester) | 낮음 | **고친다** (작업 4, 표기 버그) | 화면이 거짓을 말한다. 머리 줄에 적는 값만 `min(남은 결투, 문밖 + 1)`로 자른다. `duels_left()`와 `shown_duels_left`, "돌려보내면 …" 안내의 조건은 그대로다(`문밖 < 남은 결투`는 자른 값으로도 같은 참·거짓이다) |
| F6 | `scripts/economy/closing.gd:72~75` | 치료비가 0이면 `치료비   -0  (0회)`가 찍힌다(playtester, 계획 014 보고서 끝). 임대료가 0이면 `-0`, 수입이 0이면 `+0`이다 | 낮음 | **고친다** (작업 5, 표기 버그) | 서식의 부호가 0에 붙은 것이다. 값과 줄은 그대로 두고 0이면 부호 없이 `0`을 적는다 |
| F7 | `scripts/economy/closing.gd:81` `소지금 %d → %d` | 왼쪽 값(`money_before`)은 그날의 수입을 이미 더한 소지금이라 `소지금 -18 → -78`과 `오늘의 손익 +42`를 함께 읽으면 헷갈린다(playtester) | 낮음 | 묻는다 ("사용자 결정 필요" 2번, 019 후보) | 버그가 아니라 무엇을 보여 줄지의 문제이고, `docs/HANDOFF.md` 3번에 답을 받지 못한 항목으로 올라 있다. 권하는 안: 왼쪽을 그날 아침의 소지금으로(그러면 오른쪽 − 왼쪽 = 손익) |
| F8 | `settlement.gd:120~124` `ReputationLine` `(432,512)`, `closing.gd:84~88` `ReputationLedger` `(40,585)` | 평판 줄이 어두운 패널 밖에 놓인다(잘리거나 겹치지는 않는다. playtester) | 낮음 | 묻는다 ("사용자 결정 필요" 3번, 019 후보) | 자리를 패널 안으로 옮기면 정산 장부 패널이 자라 카운터 띠(y 540)에 닿을 수 있다(어림: 한 줄 더하면 안쪽 높이 약 327px > 패널 324 − 여백 32). 화면으로 봐야 정할 수 있고 `HANDOFF.md` 3번의 답 받지 못한 항목이다 |
| F9 | `tests/reputation_tests.gd:37` T53의 이름 | playtester가 "옛 평판 값이 남았다"고 했다 | — | **버린다** | 다시 읽어 보니 이름의 `9 → 10 → 12 → 16 → 13, 손님 3 → 5 → 3 → 7`은 테스트 안의 **날마다 끝의 평판**(353·369·379·392줄)과 그날의 손님 수(341·359·369·384줄)와 같다. 틀린 곳이 없다 |
| F10 | `tests/day_smoke.gd:2` | "오토로드 GameSession이 떠야 하므로 --script 러너로는 볼 수 없다" — 러너에도 오토로드가 뜬다(playtester 확인). 틀린 말이다 | 낮음 | **고친다** (작업 6, 주석만) | 다음 사람이 틀린 전제로 테스트를 짠다. 저장소에서 같은 말을 하는 곳은 이 한 줄뿐이다(`docs/plans/`와 `DECISIONS.md` 782줄은 그때의 기록이라 고치지 않고, 새 줄로 확인을 적는다) |
| F11 | `title.gd` 3곳, `counter.gd` 3곳, `settlement.gd` 2곳, `closing.gd` 4곳 | "`/root/GameSession`을 찾고, 이 씬이 현재 씬일 때만" 가드가 12번 복사돼 있고 꼴이 둘이다(`is_inside_tree()`가 있는 6곳과 없는 6곳). 트리 밖에서 불리면 없는 쪽은 `get_tree()`가 null이라 오류다(지금은 그 길이 없다) | 낮음 | 019 후보 | 동작을 바꾸지 않는 정리다. 작업 2가 같은 파일들을 고치므로, 실패했을 때 어느 변경 탓인지 가르기 쉽게 따로 한다 |
| F12 | `scripts/economy/day_state.gd` (577줄) | 경제의 순수 함수·읽기·흥정·저장·전환이 한 파일에 있다 | 낮음 | 그대로 둔다 | 갈라내면 `DayState.payout`·`settle`·`boosted_*` 등을 부르는 37곳(`counter.gd` 4, 테스트 33)을 실행 없이 바꿔야 한다. 파일 안은 절(`# ---- 순수 함수/읽기/저장/전환`)로 이미 나뉘어 있고 결정 152("갈라내지 않는다")의 까닭이 그대로다. 위험이 이득보다 크다 |
| F13 | 테스트 11개 파일의 `_expect`·`_result`, 4개 파일의 `_rep_rules` | 도우미가 복사돼 있다 | 낮음 | 그대로 둔다 | `_expect`·`_result`는 모든 묶음이 따르는 꼴이라(각 파일이 혼자 읽힌다) 합치면 11개 파일을 실행 없이 고친다. `_rep_rules` 넷은 값이 다르다(`reputation_tests.gd`는 손님 증감 −2~+2와 시작값 인자, 나머지 셋은 증감 0). 같은 것이 아니다 |
| F14 | `day_state.gd:288·296` `effective_rules()`·`settle_rules()` | 부를 때마다 규칙의 사본을 만든다. 카운터 한 번 열 때 약 8번(`_build`의 `duels_left`·`effective_rules`·`can_haggle`, `_refresh_haggle`의 `can_haggle` 둘·`haggle_refused_rules`·`settle_rules`·`haggle_preview_rules`), 흥정 한 번에 약 5번 | 낮음 | 그대로 둔다 | 필드 열다섯의 작은 Resource이고 프레임마다가 아니라 화면을 만들 때와 누를 때만이다. 캐시를 두면 "산 뒤에 다시 센다"(`closing.gd:160`) 같은 곳에서 낡은 값을 읽을 위험이 생긴다 |
| F15 | `day_state.gd:65` `_rng` | `_init`에서 씨앗을 한 번 뽑는 데만 쓰는 멤버다 | 낮음 | 019 후보 | 지역 변수로 충분하다. 동작은 같다 |
| F16 | `economy_rules.gd:15` "지금은 평판(별)이 그날의 사본에만 더한다", `game_session.gd:11` "preload하면 아직 없는 씬 때문에", `reputation_rules.gd:6` "기본값은 그 파일의 눈금과 맞춰 둔 것이다" | 낡은 주석: 흥정도 `base_bonus_percent`에 더한다(015). 씬은 이제 다 있다(문자열로 두는 것은 그대로 옳다: `DECISIONS.md` 171줄의 기록대로 단계 → 씬 경로를 테스트가 오토로드 없이 부른다). `pay_percent`·`day_scale`의 기본값은 일부러 비워 두었다(그 필드의 주석에 까닭이 있다) | 낮음 | 019 후보 | 동작과 상관없다. 이 계획이 고치지 않는 파일들이다 |
| F17 | `counter.gd:9`, `settlement.gd:6` `CLIENT_POS` | 같은 값이 두 곳에 있다 | 낮음 | 019 후보 | `day_ui.gd`로 옮기면 한 곳이다. 동작은 같다 |
| F18 | `economy_rules.gd`의 기본값과 `data/economy_rules.tres` | `full_pay_score` 100 / 80, `haggle_*` 0·빈 표 / 30·표 등 다르다 | 낮음 | 그대로 둔다 | 일부러다: 테스트가 `EconomyRules.new()`로 만든 규칙은 "그 기능이 꺼진 것"으로 움직여야 한다(각 필드의 주석). `ReputationRules`는 `pay_percent`·`day_scale` 둘만 다르고 그 까닭이 필드 주석에 있다(F16의 주석 한 줄만 낡았다) |
| F19 | `settlement.gd:64` 머리 줄 `오늘의 결투 %d/%d` | 손님이 결투 수보다 적은 날에도 `1/3`이다 | 낮음 | 그대로 둔다 | 하루의 결투 자리 수를 적는 줄이라 거짓은 아니다. F5는 "남은" 것을 세는 줄이라 다르다 |
| F20 | `closing.gd:108~115` `SavedNote` | 폐점이 열릴 때 한 번만 만든다. 그 뒤 "살 때의 저장"이 실패해도 "저장했다"가 남는다 | 낮음 | 019 후보 | 쓰기가 실패하는 일은 드물고 `GameSession`이 경고 줄을 찍는다. 작업 3 뒤로는 더 드물다 |
| F21 | `day_state.gd:401~402` `restore` | 손으로 고친 저장의 아주 큰 실수(예: `1e30`)는 `int()`에서 값이 뒤틀린다 | 낮음 | 그대로 둔다 | 날은 `maxi(…, 1)`로 1 이상이 되고, 소지금이 이상해지는 것은 파일을 손으로 고친 경우뿐이다(결정 151이 막으려던 것은 깨진 파일과 모르는 id다) |

## 규모 — 018과 019로 나눈다

- **018(이 계획)**: 동작이 바뀌는 위험 수정과 표기 버그(F1~F6)와 틀린 주석 한 줄(F10). 스크립트 여섯(`title.gd`, `day_ui.gd`, `counter.gd`, `settlement.gd`, `closing.gd`, `save_store.gd`), 테스트 셋(새 파일 하나, `run_tests.gd` 한 줄, `day_smoke.gd` 주석 한 줄). playtester가 게임 창에서 확인할 것이 있다(작업 8).
- **019(후보. 이 계획에서는 쓰지 않는다)**: 동작을 바꾸지 않는 정리 — F11(화면의 세션 가드를 `day_ui.gd`의 도우미 하나로), F15, F16, F17, F20 — 와, 사용자가 고르면 F7·F8.
- 나눈 까닭: (1) 018은 실행해 봐야 하는 변경이다(입력의 시각, 파일의 바꿔 끼우기). 같은 파일들에 12곳의 정리를 섞으면 playtester가 실패를 봤을 때 어느 변경 탓인지 가리기 어렵다. (2) 메인이 실행 없이 한 번에 끝내고 다시 읽어 확인할 크기로 둔다. (3) 019는 018의 실행 확인 뒤에 해도 잃는 것이 없다(위험이 낮은 것뿐이다).
- 두 계획 모두에서 보류 중이라 손대지 않는 것: 승리 +1, 별에 따른 결투 수, 기본 보수 덧붙임 ±20%, 100점 조건이 팁에도 걸리는 것, 흥정의 +30%와 확률표, 성향 한 줄, 하루를 다시 하는 길, 읽을 수 없는 저장의 백업(작업 3은 백업이 아니다. 읽을 수 없는 원래 파일은 지금처럼 읽지 못한 것으로 친다), 처음 화면의 글과 자리.

## 작업 목록

**공통 규칙** (계획 012~017과 같다)

- 메인 에이전트는 Godot을 어떤 방식으로도 실행하지 않는다(`tests/run_tests.ps1`, `tests/run_smoke.ps1`, 헤드리스, `play.ps1` 전부). 확인은 파일 읽기, Grep, `git diff`, 손 계산뿐이다. 실행 확인은 사용자가 요청할 때 playtester가 한다(작업 8의 목록). 작업을 파일 하나씩 끊고, 작업마다 고친 함수를 다시 읽는다.
- 이미 있는 함수의 시그니처는 바꾸지 않는다. 지우는 함수·상수·필드는 없다.
- **새 `class_name`은 만들지 않는다.** 새 테스트 파일은 `extends RefCounted`이고 `preload`로만 불린다. `.uid` 파일은 만들지 않는다(Godot이 만든다).
- 값은 건드리지 않는다: `data/` 아래 파일은 열지 않는다.
- 대조가 어긋나면 값을 맞추지 말고 멈춰서 보고한다.
- 각 작업의 꼬리표: **[위험 수정]** 동작이 바뀐다(설계의 뜻을 지키려고). **[표기 수정]** 화면의 글만 바뀐다. **[동작 불변]** 주석·테스트만.
- **스크립트를 하나 고칠 때마다 확인할 것**(새 테스트 파일도 같다):
  1. 들여쓰기: 고친 `.gd`에서 `^ +\S`를 Grep해 0건이다(탭만 쓴다).
  2. 같은 함수 안의 이름 겹침과 멤버 가리기. 작업마다 적은 이름을 본다. 전역 함수 이름(`sign`, `str`, `min` 등)을 인자·지역 변수 이름으로 쓰지 않는다.
  3. Variant 추론: 고친 파일에서 `:= .*\.get\(`, `:= .*\.call\(`, `:= .*\[`를 Grep한다. 걸린 줄은 `int(...)`·`String(...)`으로 감싸거나 타입을 적는다. 테스트 파일에서 `_d.` 도우미와 `Store.read`의 결과를 받는 줄은 타입을 적는다.
  4. 서식 문자열: `%` 연산자의 자리 수와 인자 수가 같고, 글 안의 `%`는 `%%`다. 작업마다 바뀌는 서식을 적었다.
  5. `@warning_ignore("integer_division")`: 이번 계획에는 새 나눗셈이 없다.

### 작업 0. 시작 전의 기록 [동작 불변]

- `git status --short`와 `git diff --stat`을 적어 둔다(계획 017과 같다). 016·017이 커밋되지 않았으면 이 계획의 변경이 그 위에 섞인다. 작업마다의 완료 확인은 "이 계획이 더한 줄"을 함수 이름으로 가리킨다.
- 끝에서 다시 적어 견준다: 이 계획이 바꾸는 파일은 작업 1~8에 적은 것뿐이다(`data/`, `docs/plans/013-playtester.md`, `.claude/` 변경 없음).

### 작업 1. 처음 화면 — "새로 시작한다"의 두 번째 누름을 잠깐 받지 않는다 [위험 수정] (F1)

- 대상: `scripts/title.gd`
- 무엇:
  - 상수(`NEW_GAME_WARNING` 아래):

    ```
    ## 첫 누름 뒤 두 번째 누름을 받지 않는 시간(밀리초). 더블클릭과 Enter 연타가 경고를 읽기 전에 지우지 않게 한다.
    ## 윈도의 기본 더블클릭 간격(0.5초)보다 길게 잡았다. 임시 값이다(계획 018).
    const NEW_GAME_LOCK_MSEC := 600
    ```

  - 멤버(`_armed` 아래):

    ```
    ## "새로 시작한다"를 처음 누른 때(Time.get_ticks_msec()).
    var _armed_msec := 0
    ```

  - static 함수 하나(`_on_new_game` 위):

    ```
    ## 두 번째 누름을 받는가: 첫 누름(armed_msec)에서 NEW_GAME_LOCK_MSEC가 지났다.
    static func can_confirm_new_game(armed_msec: int, now_msec: int) -> bool:
    	return now_msec - armed_msec >= NEW_GAME_LOCK_MSEC
    ```

  - `_on_new_game`의 첫 갈래와 첫 누름:

    ```
    ## 새로 시작한다: 지금 가게를 지우는 선택이라 두 번 눌러야 한다. 첫 번째는 알리기만 한다(파일은 그대로다).
    ## 첫 누름 직후의 누름(더블클릭, Enter 연타)은 받지 않는다. 잠깐 뒤에 다시 누르면 지운다.
    func _on_new_game() -> void:
    	if _armed:
    		if can_confirm_new_game(_armed_msec, Time.get_ticks_msec()):
    			_open_shop()
    		return
    	_armed = true
    	_armed_msec = Time.get_ticks_msec()
    	_new_game.text = NEW_GAME_ARMED
    	(경고 Label을 만드는 아래 다섯 줄은 그대로)
    ```

- 버튼은 잠그지 않는다(`disabled`를 바꾸지 않고 타이머를 쓰지 않는다). 잠긴 동안의 누름은 아무 일도 하지 않는다. 까닭: 타이머가 없으면 화면이 먼저 사라져도 남는 것이 없고, 테스트 T58의 `NewGame` 버튼 상태가 그대로다.
- 이름: 새 멤버 `_armed_msec`, 새 함수 `can_confirm_new_game`, 새 상수 `NEW_GAME_LOCK_MSEC`가 파일의 이름(`saved`, `save_unreadable`, `_new_game`, `_armed`, `_build_fresh`, `_build_continue`, `_continue`, `_open_shop`, `_practice` 등)과 겹치지 않는다. 인자 `armed_msec`·`now_msec`는 멤버 `_armed_msec`과 이름이 다르다.
- 완료 확인:
  - 손으로 따라간다: 첫 누름(시각 t) → `_armed` 참, `_armed_msec = t`, 글과 경고. 두 번째 누름이 t + 90 → `can_confirm_new_game(t, t + 90)` 거짓 → 아무 일 없음. t + 700 → 참 → `_open_shop()`(현재 씬이 아니면 거기서 돌아온다, 지금과 같다).
  - T58 "라"(`save_tests.gd:425~435`)는 같은 프레임에 두 번 누른다 → 두 번째는 잠금으로 돌아온다 → 화면이 그대로이고 버튼 셋·저장 값 그대로라는 통과 조건이 그대로 참이다(전에는 `_open_shop`의 현재 씬 가드로 돌아왔다).
  - 공통 규칙 다섯 가지. 서식: 바뀐 것이 없다.

### 작업 2. 카운터·정산·폐점 — 열린 직후의 누름을 삼킨다 [위험 수정] (F2)

- 대상: `scripts/day_ui.gd`, `scripts/commission/counter.gd`, `scripts/economy/settlement.gd`, `scripts/economy/closing.gd`
- 무엇:
  - `day_ui.gd` — 상수 하나(`CLIENT_SIZE` 아래)와 static 함수 둘(`add_background` 위, 파일의 다른 도우미보다 앞):

    ```
    ## 화면이 열린 뒤 누름을 받지 않는 시간(밀리초). 앞 화면에서 빠르게 두 번 누른 것(더블클릭, Space 두 번)의
    ## 두 번째가 새 화면의 같은 자리 버튼이나 포커스 버튼을 누르지 않게 한다. 임시 값이다(계획 018).
    const ARRIVAL_GUARD_MSEC := 400
    ```
    ```
    ## 화면이 열린 때(opened_msec)부터 ARRIVAL_GUARD_MSEC가 지나지 않은 때(now_msec)의 마우스 버튼이나 키 입력인가.
    ## 시각은 Time.get_ticks_msec()다(테스트가 직접 넣는다). 마우스 움직임 같은 다른 입력은 거짓이다.
    static func is_arrival_press(event: InputEvent, opened_msec: int, now_msec: int) -> bool:
    	if not (event is InputEventMouseButton or event is InputEventKey):
    		return false
    	return now_msec - opened_msec < ARRIVAL_GUARD_MSEC


    ## 화면의 _input이 부른다: 그 화면이 현재 씬이고 열린 직후의 누름이면 삼킨다(버튼에 닿지 않는다).
    ## 다른 씬 아래에 붙은 화면(테스트)에서는 아무것도 하지 않는다.
    static func swallow_arrival_press(screen: Control, event: InputEvent, opened_msec: int) -> void:
    	if not screen.is_inside_tree() or screen.get_tree().current_scene != screen:
    		return
    	if is_arrival_press(event, opened_msec, Time.get_ticks_msec()):
    		screen.get_viewport().set_input_as_handled()
    ```

  - 세 화면에 같은 꼴로 셋을 더한다.
    - 멤버(파일의 마지막 `var` 아래):

      ```
      ## 화면이 열린 때(Time.get_ticks_msec()). 열린 직후의 누름을 삼키는 데 쓴다(Ui.swallow_arrival_press).
      var _opened_msec := 0
      ```

    - `_ready`의 **첫 줄**: `	_opened_msec = Time.get_ticks_msec()` (잘못 열려 처음 화면으로 돌아가는 갈래보다 앞이다. 그 갈래에서도 해가 없다).
    - `_ready` 바로 아래에 함수 하나:

      ```
      ## 열린 직후의 마우스 버튼·키 입력은 삼킨다(앞 화면의 두 번째 누름이 여기 버튼을 누르지 않게).
      func _input(event: InputEvent) -> void:
      	Ui.swallow_arrival_press(self, event, _opened_msec)
      ```

  - `counter.gd` 174~175줄의 주석("버튼은 의뢰인이 들어오는 것을 기다리지 않고 처음부터 눌린다. …")을 이렇게 바꾼다: "버튼은 의뢰인이 다 들어오기를 기다리지 않는다. 다만 열린 뒤 Ui.ARRIVAL_GUARD_MSEC 동안은 누름을 삼킨다(_input). 어떤 버튼에도 포커스를 두지 않는다(정산에서 넘어온 Space가 사연을 읽기도 전에 대신 고르지 않게)."
- 처음 화면(`title.gd`)에는 넣지 않는다: 그리로 오는 버튼(카운터의 "오늘은 그만" `(40,650)`, 폐점의 "처음 화면으로" `(32,638)`)은 처음 화면의 버튼(x 400~880)과 겹치지 않고, 스모크가 처음 화면에 실제 Enter를 보낸다(`day_smoke.gd:311`, 기다리는 프레임이 둘뿐이다). 결투 씬에도 넣지 않는다: 결투의 입력은 조작이라, 삼키면 판의 첫 0.4초의 규칙이 달라진다(플레이 규칙에 닿는다). "맡는다"의 두 번째 누름은 결투의 첫 좌클릭(공격 한 번)이 될 수 있다 — "위험" 2번.
- 이름: 세 화면의 멤버에 `_opened_msec`이 없다(planner가 읽음: 카운터 `day`, `shown_waiting`, `shown_duels_left`, `shown_reputation`, `_haggle_button`, `_haggle_line`, `_pay_line` / 정산 `day`, `shown_total` / 폐점 `day`, `shown_profit`, `shown`, `shown_money`, `_proceed`, `_money_label`, `_hint`, `_reputation_ledger`, `_buy_buttons`, `_buy_upgrades`). 세 파일에 `_input`이 아직 없다. `day_ui.gd`의 새 이름이 기존 함수(`add_*`, `client_color`, `make_client`, `reputation_text`, `all_text`)와 겹치지 않는다.
- 왜 이렇게 하는가(검토자가 볼 곳):
  - 버튼의 `disabled`를 바꾸지 않으므로 폐점의 "살 수 있는가"(`refresh_shop`)와 흥정의 버튼 상태, 테스트가 보는 `disabled`가 그대로다.
  - 테스트는 화면을 `root`에 붙이고 `pressed.emit()`으로 누른다(`day_tests.gd:497·823·831·846·1175`, `day_smoke.gd:448·544`). 신호는 입력을 지나지 않아 삼켜지지 않는다. 러너(`--script`)의 `current_scene`은 비어 있어 `swallow_arrival_press`가 곧바로 돌아온다. 실제 입력을 보내는 테스트(T24, T32)는 결투 씬에만 보낸다(그때 트리에 남은 카운터·정산·폐점이 있어도 현재 씬이 아니라 삼키지 않는다).
  - 스모크는 카운터·정산·폐점에서 `pressed.emit()`만 쓴다. 실제 키는 결투(R, Esc, Space)와 처음 화면(Enter)과 연습 화면(Esc)에만 보낸다 → 그대로 통과한다.
  - 버튼은 놓을 때 눌린다(Godot의 기본 `ACTION_MODE_BUTTON_RELEASE`). 누름(down)을 삼키면 같은 버튼의 놓음(up)은 아무것도 하지 않는다. 키도 삼킨 누름 뒤의 놓음은 버튼을 누르지 않는다.
  - 0.4초 동안은 정상으로 누른 것도 먹힌다. 화면이 뜨고 0.4초 안에 사연·장부를 읽고 고를 수는 없어 잃는 것이 없다고 본다(되돌리기: 상수를 0으로. "사용자 결정 필요" 1번).
- 완료 확인:
  - Grep `func _input` → `counter.gd`, `settlement.gd`, `closing.gd` 각 1건. Grep `_opened_msec = Time.get_ticks_msec()` → 같은 세 파일 각 1건이고, 그 줄이 `func _ready` 바로 다음 줄이다.
  - Grep `swallow_arrival_press` → `day_ui.gd` 정의 1건, 세 화면의 호출 각 1건.
  - 손으로 따라간다: 정산의 "다음 의뢰인"을 더블클릭 — 첫 놓음(t)에서 `day.proceed()`와 씬 전환, 새 카운터의 `_ready`가 t + 약 16ms에 `_opened_msec`을 잰다. 두 번째 누름이 t + 90 → 경과 약 74 < 400 → 삼킨다 → "맡는다"가 눌리지 않는다. 결투 끝의 Space 두 번(약 120ms) → 정산이 열린 뒤 약 100ms의 Space → 삼킨다.
  - 공통 규칙 다섯 가지. 서식: 바뀐 것이 없다(`counter.gd`의 주석만).

### 작업 3. 저장의 쓰기 — 임시 파일에 다 적고 바꿔 끼운다 [위험 수정] (F3, F4)

- 대상: `scripts/save_store.gd` (부르는 쪽 `game_session.gd`는 고치지 않는다. `read`·`write`·`exists`·`erase`의 시그니처와 뜻이 그대로다)
- 무엇: 파일을 아래로 바꾼다(머리 주석 두 줄 뒤에 한 줄을 더하고, 함수 넷의 몸을 바꾸고, 도우미 셋을 더한다).

  ```
  extends RefCounted
  ## 저장 파일의 읽기와 쓰기. 파일만 안다(무엇이 읽을 수 있는 저장인지는 DayState가 안다).
  ## 깨진 파일은 예상한 입력이다: 오류를 찍지 않고 빈 Dictionary를 돌려준다.
  ## 쓰기는 옆의 임시 파일에 다 적고 다시 읽어 견준 뒤 원래 파일과 바꿔 끼운다(쓰는 도중 꺼져도 원래 파일이 남는다).

  ## 임시 파일의 이름: 원래 경로 뒤에 붙인다.
  const TEMP_SUFFIX := ".tmp"


  ## 파일의 내용. 경로가 비었거나, 파일이 없거나, 열리지 않거나, JSON이 아니거나, 맨 위가 {…}가 아니면 빈 Dictionary다.
  ## 원래 파일이 없고 임시 파일만 있으면(바꿔 끼우는 사이에 꺼졌다) 임시 파일을 읽는다.
  ## 원래 파일이 있으면 그것만 본다(깨졌어도 임시 파일로 대신하지 않는다).
  static func read(path: String) -> Dictionary:
  	if path == "":
  		return {}
  	if FileAccess.file_exists(path):
  		return _parse_file(path)
  	return _parse_file(path + TEMP_SUFFIX)


  ## 적는다. 경로가 비었거나 적지 못했으면 false다.
  ## 임시 파일에 적고 바꿔 끼운다. 그러지 못하면 경고 한 줄을 남기고 전처럼 원래 파일에 바로 적는다.
  static func write(path: String, content: Dictionary) -> bool:
  	if path == "":
  		return false
  	var text := JSON.stringify(content)
  	var temp := path + TEMP_SUFFIX
  	if _write_text(temp, text) and DirAccess.rename_absolute(temp, path) == OK:
  		return true
  	push_warning("저장: 임시 파일을 바꿔 끼우지 못해 바로 적는다: %s" % path)
  	_remove(temp)
  	return _write_text(path, text)


  ## 원래 파일이나 임시 파일이 있는가(읽히는지는 보지 않는다).
  static func exists(path: String) -> bool:
  	return path != "" and (FileAccess.file_exists(path) or FileAccess.file_exists(path + TEMP_SUFFIX))


  ## 원래 파일과 임시 파일을 지운다(테스트의 뒷정리가 쓴다).
  static func erase(path: String) -> void:
  	if path == "":
  		return
  	_remove(path)
  	_remove(path + TEMP_SUFFIX)


  ## 그 파일 하나를 JSON으로 읽는다. 없거나 깨졌으면 빈 Dictionary다. 오류 줄을 찍지 않는다.
  static func _parse_file(file_path: String) -> Dictionary:
  	if not FileAccess.file_exists(file_path):
  		return {}
  	var file := FileAccess.open(file_path, FileAccess.READ)
  	if file == null:
  		return {}
  	var text := file.get_as_text()
  	file.close()
  	# 파싱에 실패해도 엔진이 오류 줄을 찍지 않는 쪽을 쓴다(돌려준 값만 본다).
  	var json := JSON.new()
  	if json.parse(text) != OK:
  		return {}
  	if json.data is Dictionary:
  		var found: Dictionary = json.data
  		return found
  	return {}


  ## 그 파일에 글을 적고 다시 읽어 견준다. 열리지 않거나 덜 적혔으면 false다.
  static func _write_text(file_path: String, text: String) -> bool:
  	var file := FileAccess.open(file_path, FileAccess.WRITE)
  	if file == null:
  		return false
  	file.store_string(text)
  	file.close()
  	return FileAccess.get_file_as_string(file_path) == text


  static func _remove(file_path: String) -> void:
  	if FileAccess.file_exists(file_path):
  		DirAccess.remove_absolute(file_path)
  ```

- 이것이 지키는 것: (1) 임시 파일을 쓰는 도중 꺼짐 → 원래 파일은 손대지 않았다. 다음에 켜면 원래 파일을 읽는다(깨진 임시 파일은 원래 파일이 있으면 보지 않는다). (2) 바꿔 끼우는 사이 꺼짐(Windows의 `rename`은 대상을 먼저 지우고 옮길 수 있다) → 원래 파일이 없고 다 적힌 임시 파일이 남는다 → `read`가 그것을 읽는다. (3) 디스크가 차서 덜 적힘 → 다시 읽은 글이 달라 `false` → 바로 적기도 실패하면 `false` → `GameSession.save_game`이 `saved_day = 0`과 경고 줄(지금 그대로).
- 바꿔 끼우기가 안 되는 환경이면 늘 전처럼 바로 적는다(지금보다 나빠지지 않는다). 그때는 쓸 때마다 경고 줄이 찍혀 playtester가 본다(작업 8의 1번).
- 저장의 형식(`version` 1, 키)은 그대로다. 결정 151의 "읽을 수 없는 저장"의 뜻도 그대로다(원래 파일이 깨졌으면 지금처럼 읽지 못한 것으로 친다. 백업은 하지 않는다 — 보류 중인 "읽을 수 없는 저장의 백업"과는 다른 일이다).
- 이름: 새 이름 `TEMP_SUFFIX`, `_parse_file`, `_write_text`, `_remove`. 인자를 `file_path`로 써 공개 함수의 `path`와 가르고, 전역 이름을 가리지 않는다. 지역 변수 `text`, `temp`, `file`, `json`, `found`.
- 완료 확인:
  - 지금 파일을 부르는 곳이 넷의 이름 그대로인지 Grep: `SaveStore\.(read|write|exists|erase)`(`game_session.gd`)와 `Store\.(read|write|exists|erase)`(`tests/save_tests.gd`). 새 이름(`_parse_file` 등)을 밖에서 부르는 곳이 없다.
  - T57(`save_tests.gd:285~298`)를 손으로 따라간다: "가" 지운 뒤 없음 → `write` → 원래 파일 있음 → 읽은 값 같음. "나" 테스트가 원래 파일에 직접 깨진 글을 적음 → 원래 파일이 있으니 그것만 본다 → 빈 Dictionary(지금과 같다). 빈 경로 셋 → 지금과 같다. 뒷정리 `erase`는 임시 파일까지 지운다.
  - 다른 데서 원래 파일만 직접 보는 곳: `day_smoke.gd`의 `_file_text`(실제 저장 파일이 그대로인지 본다. 스모크는 저장을 끈다 → 영향 없음).
  - 공통 규칙 다섯 가지. 서식: `push_warning`의 `%s` 하나에 인자 하나.

### 작업 4. 카운터 머리 줄 — 남은 결투를 남은 손님 수로 자른다 [표기 수정] (F5)

- 대상: `scripts/commission/counter.gd`의 `_build` 첫 머리(82~85줄)와 멤버 주석(46줄)
- 무엇:

  ```
  	shown_waiting = day.waiting_count()
  	shown_duels_left = day.duels_left()
  	# 머리 줄의 남은 결투는 지금 손님과 문밖 손님을 합친 수를 넘지 않게 적는다(손님이 모자라면 그만큼만 치른다).
  	var duels_to_show := mini(shown_duels_left, shown_waiting + 1)
  	var header := Ui.add_label(self, "%d일차 · 손님 %d/%d (문밖에 %d명) · 오늘 남은 결투 %d · 소지금 %d" % [
  		day.day_number, day.index + 1, day.commission_count(), shown_waiting, duels_to_show, day.money], 22)
  ```

  46줄의 주석: "화면에 내보인 문밖의 손님 수와 오늘 남은 결투 수(계산 그대로. 머리 줄에는 남은 손님 수로 자른 값을 적는다). 내보인 것이 없으면 -1."
- 바뀌지 않는 것: `shown_duels_left`의 값(T39가 `day.duels_left()`와 견준다. `day_tests.gd:1201`), `DeclineNote`의 조건 `shown_waiting < shown_duels_left`(159줄), `DayState.duels_left()`.
- 이름: `duels_to_show`는 `_build`의 다른 지역 변수(`header`, `reputation`, `base`, `pay_percent`, `first_counter`, `guest_text`, `guests`, `client`, `tween`, `bubble`, `dialogue`, `accept`, `hint`, `proceed`, `decline`, `note`, `quit`, `quit_note`)와 멤버와 겹치지 않는다.
- 완료 확인:
  - 손으로: 손님 셋·결투 셋의 첫 카운터 → 문밖 2, 남은 3 → `min(3, 3)` = 3(지금과 같다). 하나를 돌려보낸 뒤 → 문밖 1, 남은 3 → 2(전에는 3). 손님 다섯·결투 셋(T39) → 문밖 4 → 3(같다). 결투 수가 찬 날에는 카운터가 열리지 않는다.
  - `DeclineNote`: 문밖 1 < 남은 3 → 있다(전과 같다. 머리 줄의 2와 함께 "돌려보내면 오늘 결투가 하나 준다"가 2 → 1로 읽힌다).
  - 공통 규칙 다섯 가지. 서식: 자리 여섯(`%d` 여섯)에 인자 여섯, 그대로다.

### 작업 5. 폐점 장부 — 0에 부호를 붙이지 않는다 [표기 수정] (F6)

- 대상: `scripts/economy/closing.gd`
- 무엇:
  - static 함수 하나(`reputation_ledger_text` 위):

    ```
    ## 장부의 금액 한 칸: 0이 아니면 앞에 prefix("+" 또는 "-")를 붙이고, 0이면 부호 없이 "0"이다("-0"을 찍지 않는다).
    static func ledger_amount(value: int, prefix: String) -> String:
    	return "%s%d" % [prefix, value] if value != 0 else "0"
    ```

  - `_build`의 72~75줄:

    ```
    	Ui.add_label(book, "수입   %s" % ledger_amount(int(summary["income"]), "+"), 22)
    	Ui.add_label(book, "임대료   %s" % ledger_amount(int(summary["rent"]), "-"), 22)
    	# 단가는 적지 않는다(결과마다 그때의 단가가 들어 있고, 날마다 달라질 수 있다).
    	Ui.add_label(book, "치료비   %s  (%d회)" % [ledger_amount(int(summary["medical"]), "-"), summary["injuries"]], 22)
    ```

- 바뀌지 않는 것: 값, 줄의 수와 순서, `오늘의 손익`(0이면 지금처럼 `+0`. 금색·붉은색을 가르는 줄이라 그대로 둔다), `소지금 X → Y`(F7, 사용자 결정 2번).
- 이름: `ledger_amount`의 인자를 `sign`이라 하지 않는다(전역 함수 `sign`). 파일의 이름(`refresh_shop`, `reputation_ledger_text`, `_build_shop`, `_buy`, `_save_now`, `_next_day`, `_quit`, `_return_to_title`, 멤버들)과 겹치지 않는다.
- 완료 확인:
  - 손으로: `ledger_amount(0, "-")` = `"0"`, `ledger_amount(20, "-")` = `"-20"`, `ledger_amount(72, "+")` = `"+72"`. 삼항식은 `("%s%d" % [prefix, value]) if value != 0 else "0"`로 묶인다(`%`가 `if … else`보다 먼저다).
  - 치료비가 0인 폐점: `치료비   0  (0회)`. 다친 날(치료비 20): `치료비   -20  (1회)` — 고치기 전과 글자 그대로 같다. 수입이 있는 날의 `수입   +N`, 임대료 60의 `임대료   -60`도 같다.
  - 테스트가 폐점의 이 줄들을 글로 보지 않는다(planner가 `tests/`에서 `수입`·`임대료   `·`치료비   `를 Grep. T33은 정산 화면에서만 `치료비`를 찾는다).
  - 공통 규칙 다섯 가지. 서식: `"%s%d"`에 인자 둘, `"수입   %s"`·`"임대료   %s"`에 하나, `"치료비   %s  (%d회)"`에 둘.

### 작업 6. 틀린 주석 — 러너에도 오토로드가 뜬다 [동작 불변] (F10)

- 대상: `tests/day_smoke.gd` 2줄
- 무엇: `## 하루 통째 스모크. 씬으로 실행한다(오토로드 GameSession이 떠야 하므로 --script 러너로는 볼 수 없다).`를
  `## 하루 통째 스모크. 씬으로 실행한다(tests/run_smoke.ps1). 실제 씬 전환과 오토로드 GameSession을 지난다(--script 러너에도 오토로드는 뜬다 — 2026-11-20 playtester 확인).`로 바꾼다.
- 완료 확인: 이 계획이 `tests/day_smoke.gd`에서 바꾼 것이 이 한 줄뿐이다(016이 커밋되지 않았으면 `git diff`에 016의 줄도 보이므로 작업 0의 기록과 견준다). 저장소의 `scripts/`·`tests/`에서 "러너로는 볼 수 없다", "러너에는 오토로드" Grep이 0건이다.

### 작업 7. 테스트 — 새 테스트 셋(T60~T62)과 기존 테스트 읽기 [동작 불변]

**기존 테스트 파일의 통과 조건은 고치지 않는다**(바뀌는 것은 `run_tests.gd`의 한 줄과 `day_smoke.gd`의 주석 한 줄). 고친 것이 고친 대로 움직이는지는 새 파일이 본다. 입력의 시각과 파일의 바꿔 끼우기는 러너에서 실제로 기다릴 수 없어(모든 테스트가 한 프레임에 돈다), 시각을 인자로 받는 순수 함수(`Ui.is_arrival_press`, `Title.can_confirm_new_game`)와 파일의 결과를 본다. 실제 누름은 playtester가 본다(작업 8).

- 대상: `tests/safety_tests.gd`(새 파일), `tests/run_tests.gd`(`TEST_FILES`의 끝에 `"res://tests/safety_tests.gd",` 한 줄)
- 틀: `tests/haggle_tests.gd`와 같다(`extends RefCounted`, `var _tree: SceneTree`, `var _d := Day.new()`, `list(tree)`에서 `_d.set("_tree", tree)`, `cleanup()`에서 `Store.erase(TEST_PATH)`와 `_d.cleanup()`, `_expect`, `_result`).
- 상수: `Day`(`res://tests/day_tests.gd`), `DT`(`res://scripts/duel/duel_types.gd`), `Session`(`res://scripts/game_session.gd`), `Ui`(`res://scripts/day_ui.gd`), `Title`(`res://scripts/title.gd`), `Closing`(`res://scripts/economy/closing.gd`), `Store`(`res://scripts/save_store.gd`), `TEST_PATH := "user://bravi_test_save_atomic.json"`(T57의 파일과 다르다).
- 도우미(파일 안): `_write_raw(file_path: String, text: String)` — `FileAccess.open(…, WRITE)`로 글을 그대로 적는다(`save_tests.gd`의 `_write_text`와 같은 꼴, 경로를 인자로). `_day_of(saved: Dictionary) -> int` — `int(saved.get("day", 0))`.

**T60 "겹친 누름: 처음 화면의 두 번째 누름, 화면이 열린 직후의 누름"**

| # | 무엇 | 기대 |
|---|---|---|
| 가 | `Ui.is_arrival_press`(열린 때 1000) | `Ui.ARRIVAL_GUARD_MSEC > 0`. 마우스 버튼(눌림) 시각 1000 → 참, `1000 + ARRIVAL_GUARD_MSEC - 1` → 참, `1000 + ARRIVAL_GUARD_MSEC` → 거짓. 키(Space, 눌림) 시각 1100 → 참. 마우스 움직임 시각 1000 → 거짓 |
| 나 | `Title.can_confirm_new_game`(첫 누름 1000) | `Title.NEW_GAME_LOCK_MSEC > 0`. 시각 1000 → 거짓, `1000 + NEW_GAME_LOCK_MSEC - 1` → 거짓, `1000 + NEW_GAME_LOCK_MSEC` → 참 |
| 다 | 세 화면이 삼키는 함수를 가진다 | `Session.COUNTER_PATH`·`SETTLEMENT_PATH`·`CLOSING_PATH`를 `instantiate()`만 하고(트리에 붙이지 않는다. `_ready`가 돌지 않는다) `has_method("_input")`가 참이다. 확인 뒤 `free()` |

- "다"는 작업 2에서 화면 하나를 빠뜨린 것을 잡는다. 붙인 화면이 실제로 삼키지 않는지(현재 씬 가드)는 러너에서 관찰할 길이 없어 넣지 않았다(`Viewport.is_input_handled()`는 앞 테스트의 입력이 남긴 값을 들고 있을 수 있다). 그 가드가 빠지면 생기는 일은 "테스트가 붙인 화면이 실제 입력을 삼키는 것"인데, 실제 입력을 보내는 T24·T32는 결투 씬에만 보낸다.

**T61 "저장의 쓰기: 임시 파일에 적고 바꿔 끼운다"** (파일은 `TEST_PATH`와 `TEST_PATH + Store.TEMP_SUFFIX`만 쓴다. 처음과 끝에 `Store.erase`)

| # | 무엇 | 기대 |
|---|---|---|
| 가 | `Store.write(TEST_PATH, {"version": 1, "day": 4, "money": 10})` | 참. 원래 파일이 있고 임시 파일이 없다. `Store.read`의 날 4 |
| 나 | 같은 경로에 날 5로 다시 쓴다 | 참. 읽은 날 5, 임시 파일 없음 |
| 다 | 바꿔 끼우는 사이에 꺼진 꼴: 원래 파일을 지우고(`DirAccess.remove_absolute(TEST_PATH)`) 임시 파일에 날 6의 JSON을 직접 적는다 | `Store.exists` 참, 원래 파일 없음, `Store.read`의 날 6. 이어서 `Store.write`(날 7) → 참, 원래 파일의 날 7, 임시 파일 없음 |
| 라 | 임시 파일을 쓰다 꺼진 꼴: `Store.write`(날 8) 뒤 임시 파일에 `{{{`를 직접 적는다 | `Store.read`의 날 8(원래 파일만 본다), `Store.exists` 참. 이어서 `Store.write`(날 9) → 참, 날 9, 임시 파일 없음 |
| 마 | 지우기: 원래 파일과 임시 파일을 둘 다 만든 뒤 `Store.erase` | 둘 다 없다. `Store.exists` 거짓, `Store.read` 빈 Dictionary |

**T62 "헷갈리던 표기: 카운터의 남은 결투, 폐점의 0"**

| # | 무엇 | 기대 |
|---|---|---|
| 가 | 카운터 머리 줄. `DayState.new(_d._duel_rules(3), _d._three_fixed())` | 첫 카운터의 `Header`에 `(문밖에 2명)`과 `오늘 남은 결투 3`. `day.decline()` 뒤 다시 붙인 카운터: `Header`에 `(문밖에 1명)`과 `오늘 남은 결투 2`, `shown_duels_left`는 3(= `day.duels_left()`), `DeclineNote`가 있다 |
| 나 | `Closing.ledger_amount` | `(0, "-")` → `"0"`, `(20, "-")` → `"-20"`, `(72, "+")` → `"+72"` |
| 다 | 다치지 않은 날의 폐점. `DayState.new(_d._rules(70, 60, 20, 250), _d._three_fixed())`에서 셋 다 `accept` → `finish_duel(_d._record(DT.EndReason.CONDITION))` → `proceed` | 붙인 폐점의 글(`Ui.all_text`)에 `치료비   0  (0회)`와 `임대료   -60`이 있고 `치료비   -0`이 없다 |
| 라 | 다친 날의 폐점. 같은 규칙의 새 하루에 `_d._run_fixed_day`(셋째가 유효타를 맞는다) | `치료비   -20  (1회)`가 있다(고치기 전과 같은 글) |

- 붙인 화면은 쓰고 나서 `free()`한다.
- **선언 대조**(새 파일을 쓴 뒤. 로드되지 않으면 러너가 거기서 멈춰 나머지도 돌지 않는다):
  - 파일이 쓰는 상수 여덟이 파일 머리에 있다.
  - 부르는 `_d.` 도우미가 `tests/day_tests.gd`에 있다(planner가 확인한 줄): `_duel_rules`(1016), `_three_fixed`(287), `_rules`(76), `_record`(100), `_run_fixed_day`(654), `_spawn_screen`(484), `_label_text`(1180), `_has_node`(1185), `cleanup`(60).
  - 글로 부르는 이름이 스크립트와 같다: 노드 `Header`·`DeclineNote`, 멤버 `shown_duels_left`, 메서드 이름 `_input`, `Ui.ARRIVAL_GUARD_MSEC`·`is_arrival_press`, `Title.NEW_GAME_LOCK_MSEC`·`can_confirm_new_game`, `Closing.ledger_amount`, `Store.TEMP_SUFFIX`, `Session.COUNTER_PATH`·`SETTLEMENT_PATH`·`CLOSING_PATH`.
  - 지역 변수 이름으로 `list`를 쓰지 않는다(파일의 함수 이름이다).
  - `Title`·`Closing`을 `preload`하면 그 스크립트가 로드된다. 둘 다 `extends Control`이고 `const Ui := preload(…)`만 더 부른다(새 의존이 없다).
- 기존 테스트를 **읽어서** 확인한다(planner가 읽은 것):
  - T57(`save_tests.gd:285~298`): 작업 3의 완료 확인대로 그대로 참이다.
  - T58 "라"(`save_tests.gd:425~435`): 작업 1의 완료 확인대로 그대로 참이다.
  - T33·T36·T39(`day_tests.gd`): 화면을 붙이고 `pressed.emit()`으로 누른다 → 삼키는 길에 닿지 않는다. T39의 `shown_duels_left`는 바뀌지 않는다. 폐점의 장부 글은 보지 않는다.
  - T24·T32(실제 입력): 결투 씬에만 보낸다. 그 사이 트리에 카운터·정산·폐점이 붙어 있지 않다(각 테스트가 붙인 화면을 `free()`한다). 붙어 있어도 현재 씬이 아니라 삼키지 않는다.
  - 스모크: 작업 2의 "왜 이렇게 하는가"대로 그대로 통과한다.
  - 통과하면 마지막 줄이 `ALL PASS 63/63`이다(지금 60 + 3).
- 완료 확인(작업 7): 새 파일에 공통 규칙 다섯 가지와 선언 대조. 이 계획이 `run_tests.gd`에 더한 줄이 하나다. 기존 테스트 파일(`day_tests.gd`, `save_tests.gd`, `haggle_tests.gd`, `reputation_tests.gd`, `client_line_tests.gd`)에 이 계획의 변경이 없다.

### 작업 8. 기록과 보고

- `docs/DECISIONS.md`: 2026-11-20 계획 018 절. 사용자 지시 원문, 결정 164~170 한 줄씩(아래 "설계 결정"), 그리고 기록 두 줄: "`--script` 러너에도 오토로드 `GameSession`이 뜬다(2026-11-20 playtester. 016 절의 '확인된 적이 없다'에 대한 답)", "T53의 이름은 맞다(날마다 끝의 평판과 손님 수). 고치지 않았다". "값은 하나도 바꾸지 않았다", "테스트·게임을 실행하지 않았다".
- `CLAUDE.md` 9장 현재 위치: "계획 018(2단계 점검 — 겹친 누름, 저장의 쓰기, 헷갈리는 표기)까지 실행했다. 2단계의 작업은 016까지였고 017·018은 사용자의 직접 지시다. 완료 판정은 사용자가 한다." 다른 장은 고치지 않는다(규칙이 바뀌지 않았다).
- `docs/reports/018-stage2-checkup.md`와 사용자 보고(CLAUDE.md 10장 형식). 1번에 "점검 결과"의 표를 줄여 싣는다(고친 것 / 019 후보 / 묻는 것 / 그대로 둔 것과 까닭). 2번의 "확인 못 한 것"에 실행 전부를 적고 아래 목록을 싣는다.
- `docs/HANDOFF.md`를 지금 상태로: 1번(다음에 할 일: 사용자의 답과 playtester 확인, 019 후보), 2번(018의 파일들이 실행되지 않았다, 기대 `ALL PASS 63/63`), 3번(018의 "사용자 결정 필요"를 더하고, playtester가 올린 것 가운데 `치료비 -0`과 T53은 풀렸다고 적는다. 016 보고서 4번의 "새로 시작한다를 빠르게 두 번 눌렀을 때"는 018이 고쳤다고 적는다).
- **playtester에게 맡길 확인** (명령마다 `$env:BRAVI_SAVE_PATH = "user://bravi_playtest_save.json"`을 같은 줄에서 건다. 계획 016의 0번과 같다):
  1. 테스트: 마지막 줄 `ALL PASS 63/63`, `ERROR`·`SCRIPT ERROR` 0줄. 출력에 `저장: 임시 파일을 바꿔 끼우지 못해`가 있으면 그 줄을 글자 그대로 보고한다(바꿔 끼우기가 이 Windows에서 안 되는 것이다. 실패로 치지 않는다).
  2. 스모크: `DAY SMOKE OK`. 위의 경고 줄이 있는지도 본다.
  3. 처음 화면(저장이 있다): `새로 시작한다`를 **더블클릭** → 글이 `한 번 더 누르면 새로 시작한다`로 바뀌고 붉은 경고가 남는다. 가게는 지워지지 않는다(1초쯤 뒤 `이어서 한다`로 옛 가게가 그대로 열리는지 본다). 다시 처음 화면에서 Tab이나 화살표로 `새로 시작한다`에 포커스를 두고 **Enter 두 번(빠르게)** → 같다. 경고를 본 뒤 1초쯤 지나 한 번 더 누르면 1일차 카운터이고 파일이 1일차다.
  4. 정산의 `다음 의뢰인`을 **더블클릭** → 다음 손님의 카운터가 떠 있고 맡지 않았다(머리 줄의 `손님 2/N`, 결투로 넘어가지 않음). 0.5초쯤 뒤에는 버튼이 평소처럼 눌린다.
  5. 카운터의 `돌려보낸다`를 **더블클릭** → 한 명만 돌려보냈다(다음 카운터의 머리 줄이 한 칸만 넘어가고 `돌려보낸 손님 — …` 줄이 그 손님 하나다).
  6. 결투(하루 모드)가 끝난 뒤 **Space 두 번(빠르게)** → 정산이 떠 있다(카운터나 폐점으로 넘어가지 않음).
  7. 그날의 마지막 정산에서 `가게를 닫는다`를 **더블클릭** → 폐점이 떠 있다(가게를 건너뛰지 않음). 폐점의 `다음 날을 연다`를 **더블클릭** → 다음 날 첫 카운터가 떠 있고 맡지 않았다.
  8. 평소 속도의 플레이(화면을 읽고 누름)에서 버튼이 먹히지 않거나 굼뜨게 느껴진 곳이 있으면 적는다.
  9. 저장 파일: 폐점에 들어선 뒤와 업그레이드를 산 뒤, 사용자 데이터 폴더에 `bravi_playtest_save.json`이 있고 `bravi_playtest_save.json.tmp`가 **없다**. 산 뒤 파일의 `money`·`owned`가 바뀌었다.
  10. 카운터 머리 줄: 2일차 이후 손님을 돌려보내 남은 손님(지금 + 문밖)이 남은 결투보다 적어지면 `오늘 남은 결투`가 남은 손님 수다(예: 문밖 1명이면 `오늘 남은 결투 2`).
  11. 다치지 않은 날의 폐점: `치료비   0  (0회)`. 다친 날은 전과 같은 `치료비   -20  (1회)`.
  - **가리는 순서**: 테스트 파일 로드 오류가 `safety_tests.gd`면 작업 7. T60 "가"는 `day_ui.gd`(작업 2), "나"는 `title.gd`(작업 1), "다"는 세 화면의 `_input`(작업 2). T61은 `save_store.gd`(작업 3). T62 "가"는 `counter.gd`(작업 4), "나"~"라"는 `closing.gd`(작업 5). T57·T58이 새로 실패하면 작업 3·1을 먼저 본다. 게임 창의 3번은 작업 1, 4~8번은 작업 2, 9번은 작업 3, 10번은 작업 4, 11번은 작업 5다. 그 밖의 실패는 016·017의 것일 수 있다(그 보고서의 "가리는 순서").
- 4번(사용자 결정)에는 아래 "사용자 결정 필요"를 싣는다. 5번에는 playtester 확인(018) → 사용자의 답(019 진행 여부, 2단계 완료 판정)을 적는다.
- **플레이 체크리스트 V**(사용자용): (1) 버튼을 두 번 눌러 손님을 잘못 맡거나 돌려보낸 일이 있었는가. (2) 화면이 뜬 직후 버튼이 안 눌려 답답했는가. (3) "새로 시작한다"를 누른 뒤 다시 누르기까지의 사이가 길게, 혹은 짧게 느껴졌는가. (4) 폐점의 장부가 읽기 쉬웠는가(소지금 줄은 "사용자 결정 필요" 2번).
- 완료 확인(작업 8): 보고서 파일이 있고 점검 표, "확인 못 한 것", playtester 목록이 있다. `CLAUDE.md`·`docs/DECISIONS.md`·`docs/HANDOFF.md`에서 이 계획이 바꾼 줄이 위에 적은 것뿐이다(작업 0의 기록과 견준다).

## 설계 결정

번호는 계획 017의 표(155~163)에 잇는다. 전부 planner가 위임으로 정했다(값은 임시).

| # | 결정 | 이유 | 되돌리기 |
|---|---|---|---|
| 164 | 카운터·정산·폐점은 열린 뒤 0.4초(`Ui.ARRIVAL_GUARD_MSEC` 400) 동안 마우스 버튼과 키를 삼킨다. 그 화면이 현재 씬일 때만이다. 계획 004의 "버튼은 처음부터 눌린다"를 그만큼 늦춘다 | 세 화면의 버튼이 같은 자리에 겹쳐 있고 정산은 포커스를 가져, 앞 화면의 두 번째 누름이 고를 기회(맡기, 돌려보내기, 가게)를 대신 써 버린다. 결정 55·63의 뜻("넘어온 입력이 대신 고르지 않는다")을 마우스와 정산까지 넓힌 것이다. 0.4초 안에는 읽고 고를 수 없어 잃는 것이 없다 | 쉬움 — 상수를 0으로 |
| 165 | 저장이 있을 때 "새로 시작한다"의 두 번째 누름은 첫 누름에서 0.6초(`NEW_GAME_LOCK_MSEC` 600)가 지난 뒤에만 받는다. 버튼은 잠그지 않는다 | 결정 150(사용자 답 "두 번 눌러야 지워진다")이 더블클릭·Enter 연타에서 지켜지지 않았다(playtester). 윈도의 기본 더블클릭 간격 0.5초보다 길다 | 쉬움 — 상수를 0으로 |
| 166 | 저장은 옆의 임시 파일(`<경로>.tmp`)에 다 적고 다시 읽어 견준 뒤 원래 파일과 바꿔 끼운다. 바꿔 끼우지 못하면 경고 한 줄과 함께 전처럼 바로 적는다. 원래 파일이 없고 임시 파일만 있으면 그것을 읽는다. `exists`·`erase`는 둘을 함께 본다 | 쓰는 도중 꺼지면 가게 전부를 잃는다(계획 016 위험 6). 덜 적힌 쓰기도 잡는다. 바꿔 끼우기가 안 되는 환경에서도 지금보다 나빠지지 않는다 | 쉬움 — `save_store.gd` 한 파일 |
| 167 | 카운터 머리 줄의 "오늘 남은 결투"는 지금 손님과 문밖 손님을 합친 수를 넘지 않게 적는다. 계산(`duels_left()`)과 "돌려보내면 …" 안내의 조건은 그대로다 | 칠 수 없는 결투를 세어 보여 줬다(playtester). 규칙은 그대로이고 글만 맞춘다 | 쉬움 — 한 줄 |
| 168 | 폐점 장부의 수입·임대료·치료비는 0이면 부호 없이 `0`이다. 손익과 소지금 줄은 그대로다 | `치료비 -0`(playtester). 손익의 `+0`은 색을 가르는 줄이라 두고, 소지금 줄의 뜻은 사용자에게 묻는다 | 쉬움 — 함수 하나 |
| 169 | `DayState`는 갈라내지 않는다(결정 152 그대로). 테스트 도우미는 합치지 않는다. `effective_rules()`의 사본은 캐시하지 않는다 | 실행 없이 37곳·11개 파일을 바꾸는 위험이 이득보다 크다. 사본은 화면을 만들고 누를 때만 몇 번 만든다("점검 결과" F12~F14) | — |
| 170 | 새 테스트 셋(T60~T62, `tests/safety_tests.gd`)을 쓴다. 기존 테스트 파일의 통과 조건은 고치지 않는다. 새 `class_name`은 없다. 동작을 바꾸지 않는 정리(F11·F15·F16·F17·F20)는 계획 019로 미룬다 | 고친 것을 시각을 인자로 받는 순수 함수와 파일의 결과로 본다. 정리를 섞지 않아 실패를 가르기 쉽다 | 쉬움 — 파일 하나와 `TEST_FILES`의 한 줄 |

## 위험

1. **입력을 삼키는 시간이 정상 누름도 먹는다.** 0.4초 안에 누른 것은 아무 일도 하지 않는다. 화면이 늦게 그려지는 컴퓨터에서는 화면이 보이기 전에 시간이 흘러 짧게 느껴질 수도 있다(`_ready`에서 재므로). 대비: 값이 상수 하나다. playtester 8번과 체크리스트 V(2)가 "굼뜨다"를 묻는다. 길게 느껴지면 줄이고, 더블클릭이 뚫리면 늘린다.
2. **"맡는다"의 두 번째 누름은 결투의 첫 좌클릭이 된다.** 결투 씬은 삼키지 않는다(조작이라 규칙에 닿는다). 판 처음의 상대는 경계하고 있어(방심 게이지 0. `opponent_data.gd:47~48`) 런지는 닿지 않는다. 그 밖에는 판이 시작하자마자 누른 공격 한 번과 같다(planner는 그 한 번의 결과를 실행으로 보지 않았다). 이 계획에서는 고치지 않고 보고서에 적는다. 문제가 되면 결투 씬의 처음 몇 프레임의 공격 입력을 무시하는 것을 따로 정한다(규칙이라 사용자 결정).
3. **`DirAccess.rename_absolute`의 Windows 동작은 실행해야 안다.** 대상이 있으면 지우고 옮기는지, 실패하는지는 엔진 판에 달렸다. 대비: 실패하면 전처럼 바로 적고 경고를 남긴다(지금보다 나빠지지 않는다). 지우고 옮기는 사이에 꺼지면 `read`가 임시 파일을 읽는다. playtester 1·2·9번이 경고 줄과 `.tmp`가 남는지를 본다.
4. **실행되지 않은 변경 위에 또 얹는다.** 016·017은 playtester가 확인했지만 커밋되지 않았을 수 있다. 이 계획은 016·017이 고친 파일 다섯(`title.gd`, `counter.gd`, `closing.gd`, `settlement.gd`, `save_store.gd`)과 `day_smoke.gd`·`run_tests.gd`를 다시 고친다. 대비: 작업 0의 기록, 작업마다 고치는 함수를 이름으로 적은 것, playtester의 "가리는 순서". 먼저 커밋하면 `git diff`가 018만 보여 준다("사용자 결정 필요" 6번).
5. **새 테스트 파일이 로드되지 않으면 러너 전체가 멈춘다.** 대비: 작업 7의 선언 대조, `haggle_tests.gd`의 틀, 순수 함수 위주의 짧은 테스트.
6. **T58 "라"가 다른 까닭으로 통과한다.** 전에는 `_open_shop`의 현재 씬 가드로, 이제는 잠금으로 돌아온다. 통과 조건은 같지만, 잠금이 빠져도 T58은 여전히 통과한다. 잠금 자체는 T60 "나"가 본다.

## 실행 전에 물을 것

없다. 고칠 것과 남길 것은 위임으로 정했다. 플레이 규칙과 보류 중인 값은 건드리지 않는다. 화면의 뜻을 바꾸는 두 가지(F7 소지금 줄, F8 평판 줄의 자리)는 고치지 않고 아래에 올렸다.

## 사용자 결정 필요 (실행을 막지 않는다. 보고서 4번에 올린다)

| # | 무엇 | 이 계획이 정한 것 | 답이 다르면 |
|---|---|---|---|
| 1 | 겹친 누름의 두 값 | 화면이 열린 뒤 0.4초, "새로 시작한다"의 두 번째 누름까지 0.6초(결정 164·165). 계획 004의 "카운터의 버튼은 처음부터 눌린다"를 0.4초만큼 바꾼 것이다 | 상수 하나씩이다. 0이면 전과 같다 |
| 2 | 폐점의 소지금 줄(F7) | 그대로 둔다(`소지금 X → Y`의 X는 수입을 더한 뒤의 소지금) | 권하는 안: X를 그날 아침의 소지금으로(그러면 Y − X = 오늘의 손익). 다른 안: 줄을 `소지금 Y`로 줄인다. 019에서 `closing.gd` 한 줄과 요약의 키 하나 |
| 3 | 정산·폐점의 평판 줄의 자리(F8) | 그대로 둔다(패널 밖, 잘리거나 겹치지는 않는다) | 패널 안으로: 정산 장부 패널이 카운터 띠에 닿을 수 있어 패널 높이나 글자 크기를 함께 손봐야 한다. 019에서 하고 playtester가 화면으로 본다 |
| 4 | 계획 019(동작을 바꾸지 않는 정리) | 쓰지 않았다. 후보: 화면의 세션 가드 12곳을 도우미 하나로(F11), `DayState._rng`를 지역 변수로(F15), 낡은 주석 셋(F16), `CLIENT_POS`를 한 곳에(F17), 살 때의 저장이 실패하면 `SavedNote`를 거두기(F20). 2·3번을 고르면 함께 | 하지 않아도 동작에는 차이가 없다. 하려면 018의 실행 확인 뒤가 좋다 |
| 5 | 커밋의 순서 | 정하지 않는다(커밋은 사용자가 지시한다) | 018 전에 016·017을 커밋하면 018의 변경만 따로 보이고, 실패를 가르기 쉽다 |
| 6 | **2단계 완료 기준 충족 — 다음 단계 진행 여부** | 계획 016 보고서 4번의 그대로다. 이 계획은 2단계의 범위를 넓히지 않았고 3단계의 계획을 만들지 않았다. 018의 playtester 확인 뒤에 판정하시기를 권한다 | 판정을 미루면 다음 후보는 019, 보류 중인 값들, CLAUDE.md 5장의 "아직 없는 것"이다 |

보류 중인 것(그대로 둔다): 계획 012의 승리 +1·별에 따른 결투 수·궂은일을 맡는 값·속도·토마소의 0점 합, 계획 013의 기본 보수 덧붙임 크기·낮은 별의 깎임, 계획 014의 100점 조건이 팁에도 걸리는 것·+30%와 의뢰인의 값, 계획 015 보고서 4번의 넷과 design-reviewer의 의견 셋, 계획 016 보고서 4번(주사위, 읽을 수 없는 저장의 백업, 화면의 글과 자리, 하루를 다시 하는 길. "빠르게 두 번 눌렀을 때"는 이 계획이 결정 165로 답했다), 계획 017 보고서 4번, `docs/plans/013-playtester.md`의 번호 겹침.
