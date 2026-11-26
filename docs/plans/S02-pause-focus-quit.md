# 계획 S02: 일시정지 · 창 포커스 · 게임 종료

- 버전: v1 (2026-11-27. 검토 전. HEAD `9b6cb61`, S01 끝, `ALL PASS 97/97`)
- 개발 단계: CLAUDE.md 9장의 단계와 **별개인 사용자 지시 작업**(설정·편의 갈래 S01~S04의 둘째). 9장의 단계를 넘기지도 닫지도 않는다. 차례는 S01 계획의 표 그대로다(S04 뒤에 5단계).
- 근거:
  - 사용자 지시(2026-11-26) 가운데 S02의 몫: "4. 일시정지·Alt+Tab — Esc를 누르거나 창 포커스를 잃으면 결투 시간과 상대 동작이 함께 멈춤 / 돌아와서 '계속'을 누른 클릭이 공격으로 들어가면 안 됨", "5. … 일시정지 화면에서 조작 / 화면 / 소리를 열 수 있게"(일시정지 쪽), "6. 게임 종료 — 타이틀에 게임 종료 버튼 / 영업 중에 나갈 때는 '이어서 하면 오늘 아침부터 시작합니다'처럼 돌아올 시점을 알려줄 것", "[자동] 일시정지 해제 클릭이 공격으로 처리되지 않는지". 사용자 "다음 진행"(2026-11-27).
  - S01이 넘긴 것: 설정 화면 `SettingsScreen.open(parent: Control, settings)` · `closed` · 덮개 `PROCESS_MODE_ALWAYS` · 시간은 `Time.get_ticks_msec()`만. 헤짐(033b 결정 498)이 다른 판 위에 뜬 설정 판의 글에 닿지 않는지를 S02의 찍기로 본다. 검토 전 물음 둘(연습 결투의 Esc, 하루 결투의 "처음 화면으로").
  - 지금 코드(읽음, HEAD `9b6cb61`):
    - **판의 시계는 코어의 `time` 하나다**(`duel_core.gd` 머리 주석): 예비 동작·회수·빈틈·제한 시간(`rules.time_limit`)·엉킴(`_bind_at(time)`)·방심(`brain.complacency(time)`)·막기 쿨다운이 모두 `core.tick(delta)` 안에서만 흐른다. 입력은 받은 순간의 `core.time`으로 걸린다.
    - `duel_scene.gd`: `_physics_process` → `advance(delta)`(조준 갱신 + `core.tick` + 결과 패널). `advance`는 테스트·스모크·찍기가 직접 부르는 걸음이다. `_process`는 표시 시각 보간과 `_update_views(delta)`(부드러운 이동·번쩍임). `_input`은 가상 마우스(`--bravi-virtual-mouse`). `_unhandled_input`: 하루 모드는 `retry`·`back`을 듣지 않고 `ui_accept`로 끝난 판을 넘긴다. 연습은 `back`(Esc)이면 현재 씬일 때 의뢰 선택으로 간다. 막기는 `guard` 누름·뗌 이벤트로 `core.set_guard(bool)`.
    - 결투 씬의 층: `Background`(−2), HUD의 `Back`(−1, 필사본 `Panel` 다섯 — `PanelContainer`가 아니라 헤지지 않는다), `HUD`(1), `ResultPanel`(5). 결투에는 트윈·타이머가 없다.
    - 입력 지도(`project.godot`): attack 좌클릭, guard 우클릭, W·S, R `retry`, Esc `back`(그리고 내장 `ui_cancel`), F1 `debug_toggle`.
    - 하루 중 나가는 길: 카운터 "오늘은 그만"(한 번 누르면 처음 화면, 아래에 늘 `QuitNote` "오늘 한 일은 남지 않는다 — 이어서 하면 오늘 아침부터다"), 폐점 "처음 화면으로"(들어설 때 내일 아침을 적었다 — `SAVED_NOTE` "저장했다 — 끄고 다시 켜도 %d일차 아침부터 이어진다"), 정산은 나가는 버튼이 없다. 결투에서는 창 닫기뿐이다. 카운터·정산·폐점은 Esc를 듣지 않는다. 창 닫기(X·Alt+F4)는 Godot 기본(바로 꺼짐).
    - 저장(5장, `game_session.gd`): 세이브는 늘 "다음에 열 날의 아침"이다(새 1일차를 열 때와 폐점에 들어설 때·살 때 적는다). 그래서 하루 중(카운터·결투·정산)에 끄면 그날 아침부터, 폐점에서 끄면 다음 날 아침부터다.
    - 이미 있는 겹친 누름 막기: `Ui.ARRIVAL_GUARD_MSEC` 400(화면이 열린 직후의 누름을 삼킨다, 계획 018), 처음 화면의 `NEW_GAME_LOCK_MSEC` 600. 둘 다 정적 함수에 시각을 넣어 시험한다(T60).
    - 처음 화면(`title.gd`): 아래 줄 `Help` | `Settings` 각 195(사이 10. 저장 없음 y 534 높이 54, 저장 있음 y 582 높이 50). 버튼 수 저장 없음 4 · 저장 있음 5.
    - 기존 테스트 중 바뀌는 기대: T24(`scene_tests.gd` 248~251행 — Esc를 보내도 씬이 그대로이고 바로 R이 새 판), 스모크(`day_smoke.gd` 472~476행 — 하루 결투의 Esc가 씬을 바꾸지 않는다), T58(`save_tests.gd` 399·408·420행 버튼 수 4·4·5), `day_tests.gd` 527행(`== 4`), T75(`manuscript_tests.gd` 22·23행 `FRESH_BUTTONS`·`SAVED_BUTTONS`), `save_tests.gd` 453행(`QuitNote`가 "아침"을 담는다 — 그대로 통과).
    - 도움말 글(`DuelHud.HELP_RETRY` " · R 다시 하기 · Esc 의뢰 선택", 하루 모드에서는 지운다). 처음 화면의 도움말이 이 글을 쓴다.
  - 번호: 결정은 **507부터**(`DECISIONS.md`의 마지막 506), 테스트는 **T98부터**(`run_tests.gd` 마지막 T97). 실행 때 다시 본다.

### 넘지 않는 선

- 메인은 Godot·테스트·게임을 실행하지 않는다. 자동 확인은 verifier(`tests/verify.ps1`). 코드 쓰기는 Sonnet 하위 에이전트, 메인은 diff를 읽는다. 편집은 80줄 안쪽으로 나누고 HANDOFF 4번의 기계적 확인 다섯을 지킨다. `.ps1`은 ASCII(지금 꼴 그대로).
- 고치지 않는 것: 판정 코드(`scripts/duel/duel_core.gd`, `scripts/ai/`), `data/`, `scripts/save_store.gd`, `scripts/settings.gd`, `scripts/ui/settings_screen.gd`, `scripts/duel/beeper.gd`, 테마 `.tres`와 `scripts/ui/`의 StyleBox, 세이브의 형식. `get_tree().paused`를 쓰지 않는다(결정 507).
- 범위 밖: 키 바꾸기와 조작 탭(S03), 화면 모드와 화면 탭(S04), 기권(결투를 진 것으로 치고 정산으로 가는 길 — 새 규칙이다), 멈춘 동안의 소리 줄이기, 처음 화면의 Esc.

## 목표와 범위

**확인할 결과**:

1. 결투 중(판이 끝나기 전) Esc를 누르거나 창이 포커스를 잃으면 판이 멈추고 멈춤 화면이 뜬다. 멈춘 동안 `core.time`·상대의 상태와 그 끝 시각·엉킴 게이지·방심 게이지·제한 시간·내 상태가 그대로이고, 상대·내 칼의 그림도 움직이지 않는다. 포커스가 돌아와도 저절로 풀리지 않는다.
2. "계속"(또는 Esc)으로 돌아오면 0.4초 동안 판이 멈춘 채 "다시 시작한다"가 뜨고 그동안의 좌클릭은 공격이 되지 않는다. "계속"을 누른 클릭과 더블클릭의 둘째 누름이 공격으로 들어가지 않는다. 우클릭은 돌아온 순간 지금 쥔 상태에 맞춰진다(멈춘 동안 뗐으면 막기가 풀린다).
3. 멈춤 화면에 계속 / 설정 / 나가기가 있다. 설정은 S01의 설정 화면을 그 위에 열고, Esc는 설정 화면만 닫는다. 나가기는 하루 결투면 "처음 화면으로"(아래에 "이어서 하면 N일차 아침부터 시작한다 — 오늘 한 일은 남지 않는다"), 연습이면 "연습 고르기로"(Q1·Q2의 답에 따라 — 아래).
4. 처음 화면에 "게임 종료"가 있고 누르면 꺼진다. 하루 중(카운터·결투·정산, 그리고 저장이 안 된 폐점)에 창 닫기 단추나 Alt+F4를 누르면 확인 창이 "이어서 하면 N일차 아침부터 시작한다"를 보이고 "끈다 / 돌아간다"를 묻는다. 하루 밖(처음 화면·연습)과 저장된 폐점에서는 바로 꺼진다. 카운터의 `QuitNote`가 날 번호를 적는다.
5. 판정·데이터 그대로: `scripts/duel/duel_core.gd`·`scripts/ai/`·`data/`의 `git diff` 0줄. `ALL PASS 99/99`, 스모크 OK, 가져오기 오류 0, UI 찍기 16 → 20(Q3 "나"면 21), 새 장의 헤짐이 글·버튼에 닿지 않는다(`wearhit` 0).

재미는 바뀌지 않는다(판의 규칙과 시간은 그대로이고, 멈춤은 판 밖의 일이다).

## 설계 결정

507. **멈춤은 결투 씬의 깃발로 한다**(`get_tree().paused`를 쓰지 않는다):
     - `duel_scene.gd`에 `var paused := false`(읽기용)와 `pause(reason: StringName) -> bool`, `resume() -> void`. 깃발이 서 있으면 `_physics_process`가 `advance`를 부르지 않고, `_process`가 표시를 갱신하지 않고, `_input`이 조준을 바꾸지 않는다(가상 마우스의 자리는 받아 둔다). `_unhandled_input`은 멈춤 화면이 열린 동안 결투의 액션을 하나도 듣지 않는다.
     - `advance(delta)`는 깃발을 보지 않는다: 테스트·스모크·찍기가 부르는 직접 걸음이다. 멈춤을 보는 것은 엔진이 부르는 `_physics_process`·`_process`다.
     - 까닭: 판의 모든 시계가 `core.time` 하나라 tick을 부르지 않으면 판 전체가 멈춘다. 트리 전체를 멈추면 테스트 러너(SceneTree 스크립트, 한 프레임에 동기로 돈다)·찍기 도구(`ui_shots.gd`의 `_process`)·씬 바꾸기(멈춘 채 다음 씬으로 가면 그 씬도 멈춘다)를 따로 챙겨야 한다. 되돌리기는 쉽다(깃발 자리를 `get_tree().paused`로 바꾸면 된다).
     - 지킬 것: 결투 씬에 스스로 시간을 흘리는 노드(트윈, 타이머, 5단계의 음악 등)를 더할 때는 이 깃발을 보게 한다. 지금은 없다.
     - `start_duel()`(R 다시 하기)은 멈춤과 돌아오기 대기를 모두 지운다.
508. **멈추는 때와 풀리는 때**:
     - 멈춘다: (가) `back`(Esc)이 왔고 판이 끝나지 않았다(`not core.ended`). (나) `_notification`의 `NOTIFICATION_APPLICATION_FOCUS_OUT` 또는 `NOTIFICATION_WM_WINDOW_FOCUS_OUT`이 왔고 판이 끝나지 않았다(둘 다 와도 한 번 — `pause`는 이미 멈췄으면 거짓을 돌려주고 아무것도 하지 않는다). (다) 하루 중 창 닫기 요청(결정 512의 `pause_for_close()`).
     - 판이 끝난 뒤(결과 패널)는 멈추지 않는다: 연습의 Esc는 지금처럼 의뢰 선택으로, 하루의 Esc는 듣지 않고 Space·Enter로 넘긴다. 포커스를 잃어도 아무 일이 없다.
     - 포커스가 돌아와도 풀지 않는다(`FOCUS_IN`은 듣지 않는다). 풀리는 것은 "계속"과 멈춤 화면의 Esc뿐이다.
     - 돌아오기 대기(결정 509) 중에 포커스를 잃거나 Esc를 누르면 다시 멈춤 화면이 뜬다.
     - 연습의 Esc가 일시정지를 여는지는 **Q1**(권하는 답 "가")이고, "다"면 연습에서는 (가)를 빼고 (나)만 둔다.
509. **돌아오기 — "계속"의 클릭이 공격이 되지 않는 길**:
     - (1) 버튼이 클릭을 먹는다: 멈춤 화면의 덮개는 `MOUSE_FILTER_STOP`이고 "계속"은 테마의 `Button`(기본 `ACTION_MODE_BUTTON_RELEASE`)이라 그 클릭의 누름과 뗌이 결투 씬의 `_unhandled_input`에 닿지 않는다.
     - (2) 대기: "계속"을 누르면 멈춤 화면을 닫고 `RESUME_HOLD_MSEC` **400**(실시간 `Time.get_ticks_msec()`. 계획 018의 400과 같은 까닭 — 더블클릭의 둘째 누름) 동안 판을 멈춘 채 둔다. 그동안 화면 가운데에 "다시 시작한다"(28) 한 줄만 뜨고 어둡게 덮은 것은 걷힌다. 대기가 끝나는지는 정적 `hold_over(hold_until_msec, now_msec) -> bool`로 정한다(T60의 꼴). `_physics_process`가 대기의 끝을 보고 깃발을 내린다. 임시 값, 되돌리기 쉽다.
     - (3) 대기 동안 `attack` 누름은 버린다(`swallowed_attacks`를 하나 올린다). 막기·간격(W·S)·R·F1은 그대로 받는다: 코어의 시각이 멈춰 있으니 멈춘 그 순간에 누른 것과 같다(판이 다시 흐르기 직전에 막기를 올려 둘 수 있다 — 멈추기 전과 같은 조건이다).
     - (4) 막기 다시 맞추기: 멈춤 화면을 닫는 순간 `core.guard_held`가 `Input.is_action_pressed(&"guard")`와 다르면 `core.set_guard(그 값)`을 부른다. 멈춘 동안 우클릭을 뗐으면 막기가 풀리고, 쥔 채 멈췄다가 쥔 채 돌아오면 막기가 이어진다(새로 누른 것이 아니다 — `guard_enter_time`이 그대로). 창이 포커스를 잃을 때 엔진이 눌린 상태를 놓아 주는지는 창에서만 보인다(V2-3, R2). 놓아 주면 Alt+Tab 뒤의 막기는 풀려 있다.
     - `duel_scene.gd`의 `var resume_hold_msec := RESUME_HOLD_MSEC`와 대기 끝 시각 `_hold_until_msec`는 테스트가 고칠 수 있다.
510. **멈춤 화면** `scripts/ui/pause_menu.gd`(`class_name PauseMenu`, `extends CanvasLayer`, 코드로 짓는다):
     - `static func open(host: Node, exit_text: String, exit_note: String) -> PauseMenu`: `layer` **10**(결과 패널 5 위), `process_mode = PROCESS_MODE_ALWAYS`, 안에 뿌리 `Control`(`PRESET_FULL_RECT`, `MOUSE_FILTER_STOP`, 앵커는 붙이기 전에 — 결정 502의 까닭). 열 때마다 만들고 닫으면 지운다(설정 화면과 같은 꼴).
     - 꼴: 화면 전체에 어두운 `ColorRect`(잉크 `Ui.INK`, 알파 0.6 — 멈춘 판이 비친다), 가운데 판 `Ui.add_panel(Rect2(440, 170, 400, 380))`, 제목 "멈춤"(28), 버튼 셋 340×54: `PauseResume` "계속"(초점), `PauseSettings` "설정", `PauseExit`(글은 `exit_text`. 빈 글이면 만들지 않는다), 그 아래 `PauseExitNote`(16, `Ui.DIM`, 줄바꿈, `exit_note`가 빈 글이면 없다).
     - 신호 `resumed`, `exit_pressed`. Esc(`ui_cancel`)는 `resumed`와 같다. 처리 차례: Esc를 받으면 **뷰포트를 먼저 쥐고 `set_input_as_handled()` 뒤에** 닫는다(결투 씬의 `back`이 같은 누름으로 다시 멈추지 않게).
     - 설정: `SettingsScreen.open(뿌리 Control, /root/Settings)`, `closed`에서 `PauseSettings`에 초점. 설정 화면이 열린 동안 Esc는 설정 화면이 먹는다(뒤에 붙은 노드가 먼저 받는다). `/root/Settings`가 없으면 버튼을 흐리게(`disabled`) 둔다.
     - 결투의 나가기: 하루 결투 = "처음 화면으로" + `quit_note`(결정 511), 누르면 `end_day_play()` → `go_to_title()`(현재 씬일 때만). 연습 = "연습 고르기로", 노트 없음, 누르면 의뢰 선택(현재 씬일 때만). 어느 쪽도 씬을 바꾸기 전에 깃발을 내릴 필요가 없다(결정 507). 하루 결투의 버튼이 있는지와 확인을 한 번 더 받는지는 **Q2**(권하는 답 "가": 버튼 하나, 아래 글을 늘 보인다 — 카운터의 "오늘은 그만"과 같은 꼴).
     - 카운터·정산·폐점의 Esc: **Q3**. "나"(권함)면 같은 `PauseMenu`를 제목 "잠깐"으로 연다 — 대기도 깃발도 없고(그 화면은 시간이 흐르지 않는다), 나가기는 "처음 화면으로" + `quit_note`, 계속·Esc는 닫기만 한다. 열린 직후의 누름을 삼키는 그 화면의 `_input`(`swallow_arrival_press`)은 그대로다.
511. **돌아올 날의 글** (`game_session.gd`):
     - `func resume_day() -> int`: 세이브 파일에 적힌 `day`(정수가 아니거나 파일이 없거나 저장이 꺼져 있으면 0). 파일이 진실이다(쓰기 실패를 따로 셈하지 않는다).
     - `static func quit_note(day: DayState, resume_day: int) -> String`: 폐점이고 `resume_day == day.day_number + 1` → `"이어서 하면 %d일차 아침부터 시작한다 — 오늘 산 것까지 적혀 있다"`. 그 밖에 `resume_day > 0` → `"이어서 하면 %d일차 아침부터 시작한다 — 오늘 한 일은 남지 않는다"`. 0 → `"적힌 아침이 없다 — 다음에는 새로 시작한다"`. 말씨는 게임의 "-다"(사용자 예시의 뜻 그대로).
     - 카운터의 `QUIT_NOTE`를 `"오늘 한 일은 남지 않는다 — 이어서 하면 %d일차 아침부터다"`로 바꾸고 `resume_day()`를 넣는다(세션이 없거나 0이면 지금 글 "… 오늘 아침부터다"). 자리·크기는 그대로.
512. **창 닫기** (`game_session.gd`, 새 `scripts/ui/quit_confirm.gd`):
     - `_ready`에서 `get_tree().set_auto_accept_quit(false)`. `_notification(NOTIFICATION_WM_CLOSE_REQUEST)` → `handle_close_request(get_tree().current_scene)`의 답이 `QUIT`이면 `quit_game()`.
     - `func handle_close_request(scene: Node) -> int`(`enum CloseAction { QUIT, CONFIRM }`): 하나라도 맞으면 `QUIT` — 장면이 없다, `day == null`(처음 화면·연습·의뢰 선택), 폐점이고 `resume_day() == day.day_number + 1`(이미 적혔고 폐점 화면이 그렇게 알린다), **확인 창이 이미 떠 있다**(두 번째 닫기는 바로 끈다 — 처리에 탈이 나도 창을 닫을 길). 그 밖에는 장면에 `pause_for_close`가 있으면 부르고(결투가 멈춤 화면을 연다) `QuitConfirm.open(scene, quit_note(day, resume_day()))`를 붙이고 `CONFIRM`.
     - `QuitConfirm`(`extends CanvasLayer`, `layer` **20**, `PROCESS_MODE_ALWAYS`): 어둡게 덮기, 판 `Rect2(390, 220, 500, 280)`, 제목 "게임을 끈다"(28), 글 `quit_note`(18, 줄바꿈), 버튼 `QuitYes` "끈다" · `QuitNo` "돌아간다"(초점) 각 200×54. Esc = 돌아간다. 신호 `confirmed`·`cancelled`. `confirmed` → `GameSession.quit_game()`. 돌아가면 확인 창만 닫힌다(결투는 멈춤 화면에 남는다).
     - `func quit_game() -> void`: `get_tree().quit()`. 끌 때 적을 것은 없다(세이브는 아침에 이미 있고, 설정은 설정 화면을 닫을 때 적는다).
513. **처음 화면의 "게임 종료"** (`title.gd`): 아래 줄을 셋으로 — `Help` · `Settings` · `QuitGame`("게임 종료") 각 126, 사이 11(합 400, 자리 y·높이는 그대로). 버튼 수 저장 없음 4 → 5, 저장 있음 5 → 6. 누르면 `Ui.current_session(self)`의 `quit_game()`(현재 씬이 아니면 아무것도 하지 않는다 — 테스트). 확인 창은 없다: 처음 화면은 하루 밖이라 잃는 것이 없다. 글이 126에 들지 않으면(T75가 잡는다) 셋 다 글 크기 18로 내린다. 임시 결정, 되돌리기 쉽다.
514. **안내 글** (`duel_hud.gd`): `HELP_RETRY`를 " · R 다시 하기"로 줄이고 늘 붙는 `HELP_PAUSE` " · Esc 멈춤"을 더한다(하루 모드에서도 남는다. Q1 "다"면 연습은 " · Esc 의뢰 선택"을 그대로 둔다). 처음 화면의 도움말이 이 글을 쓴다. CLAUDE.md 3장 조작 표에 "Esc — 멈춤(계속·설정·나가기)" 한 줄.
515. **실행 확인용 기록** (`event_log.gd`): `on_event`에 선택 인자 `extra := {}`를 더해 판 요약 줄에 합친다. 결투 씬이 `pauses`(그 판에서 멈춘 횟수), `pause_drift`(멈춘 순간과 다시 흐른 순간의 `core.time` 차의 가장 큰 값, 기대 0), `swallowed_attacks`를 넘긴다. playtester가 창에서 세지 않고 `BRAVI_EVENT_LOG`로 읽는다(CLAUDE.md 11장).
516. **T98 "멈춤", T99 "나가기와 끄기"**(새 `tests/pause_tests.gd`, `tests/run_tests.gd`에 한 줄): 작업 6.

## 작업 목록

차례대로 한다. Q1~Q4의 답을 받은 뒤 시작한다.

**작업 0. 시작 상태**
- 할 일: `git status`가 깨끗한지, HEAD, `run_tests.gd`의 마지막 T 번호, `DECISIONS.md`의 마지막 결정 번호를 `%TEMP%\bravi-S02\head.txt`에. 다르면 이 계획의 번호를 그다음으로 바꿔 쓴다(뜻은 그대로).
- 완료 확인: 파일이 있다.

**작업 1. 결투의 멈춤** (Sonnet. 결정 507~509·514·515)
- 대상: `scripts/duel/duel_scene.gd`(깃발, `pause`·`resume`·`pause_for_close`, `_notification`, 대기, 막기 다시 맞추기, `_unhandled_input`의 `back`, `start_duel`이 지우기), `scripts/duel/duel_hud.gd`(두 상수와 `help_text`의 한 줄), `scripts/duel/event_log.gd`(`extra`).
- 완료 확인(메인, diff): `duel_core.gd`·`scripts/ai/`의 diff 0, `get_tree().paused`가 어디에도 없다, `advance()`가 깃발을 보지 않는다, 대기의 끝이 정적 `hold_over`로 정해진다, 대기 중 버리는 것이 `attack` 누름 하나뿐이다, 기계적 확인 다섯.

**작업 2. 멈춤 화면** (Sonnet. 결정 510)
- 대상: 새 `scripts/ui/pause_menu.gd`. 결투 씬이 연다(작업 1과 이어 붙인다).
- 완료 확인(메인, diff): `layer` 10·`PROCESS_MODE_ALWAYS`·앵커를 붙이기 전에, Esc 처리에서 `set_input_as_handled`가 닫기보다 앞이다, 설정은 `SettingsScreen.open`을 그대로 부른다(`settings_screen.gd`의 diff 0), 테마 `.tres`·`day_ui.gd`의 diff 0, `_process`·`Timer`를 쓰지 않는다.

**작업 3. 나가기의 글과 창 닫기** (Sonnet. 결정 511·512)
- 대상: `scripts/game_session.gd`(`resume_day`, `quit_note`, `CloseAction`, `handle_close_request`, `quit_game`, `_ready`의 한 줄, `_notification`), 새 `scripts/ui/quit_confirm.gd`, `scripts/commission/counter.gd`(`QUIT_NOTE`와 그 줄).
- 완료 확인(메인, diff): `save_game`·`load_saved_day`·`go_to_*`의 diff 0, `handle_close_request`가 스스로 끄지 않는다(끄는 것은 `_notification`과 `confirmed`뿐 — 테스트가 부를 수 있다), `QUIT` 조건 넷이 결정 512와 같다.

**작업 4. 처음 화면** (Sonnet. 결정 513)
- 대상: `scripts/title.gd`(`_add_help_button`을 세 칸으로, `QuitGame`, 머리 주석의 버튼 수).
- 완료 확인(메인, diff): 다른 버튼의 자리·크기 줄이 그대로.

**작업 5. 카운터·정산·폐점의 Esc** (Sonnet. 결정 510의 Q3. **Q3이 "나"일 때만**. "가"면 건너뛰고 BACKLOG에 한 줄)
- 대상: `scripts/commission/counter.gd`, `scripts/economy/settlement.gd`, `scripts/economy/closing.gd` 각각에 `_unhandled_input`의 `ui_cancel` → `PauseMenu.open(self, "처음 화면으로", quit_note)`(이미 열렸으면 아무것도 하지 않는다), 나가기는 그 화면의 지금 `_quit` 꼴(정산에는 새로 — `end_day_play` → `go_to_title`, 현재 씬일 때만).
- 완료 확인(메인, diff): 세 화면의 다른 줄 그대로, 열린 직후 누름 삼키기(`_input`) 그대로.

**작업 6. 테스트** (Sonnet. 새 `tests/pause_tests.gd`, `tests/run_tests.gd`에 한 줄. 기존 테스트의 기대값)
- 기존 기대값 고치기:
  - T24(`scene_tests.gd` 248~251행): Esc → `paused` 참과 `PauseMenu`가 있다 → Esc 한 번 더 → 멈춤 화면이 없다(대기 중) → R → 새 판(대기가 지워졌다, `paused` 거짓). Q1 "다"면 지금 그대로.
  - 스모크(`day_smoke.gd` 472~476행): 하루 결투의 Esc → 씬은 그대로이고 `PauseMenu`가 뜬다 → Esc → 닫힌다. 그 뒤의 Space 확인과 봇의 `advance` 걸음은 그대로(대기 중에도 Space·`advance`가 막히지 않는다 — 결정 507·509).
  - T58(`save_tests.gd` 399·408·420행) 4·4·5 → 5·5·6과 `QuitGame`. `day_tests.gd` 527행 `== 4` → `== 5`(실패 글 "4개" → "5개"). T75(`manuscript_tests.gd` 22·23행) `Help`·`Settings` 126 폭과 `QuitGame` 줄, 그리고 `_check_text`·`_check_buttons`가 멈춤 화면(연습 결투 위)과 확인 창을 한 번씩 지나게 한다(새 검사 함수는 만들지 않는다 — S01이 설정 덮개를 넘긴 꼴).
- **T98 "멈춤: 판의 시간·상대가 같이 멈추고, '계속'의 클릭은 공격이 되지 않고, 막기는 쥔 상태에 맞춘다"** — 연습 결투(`Plain.of(바르톨로)`, 시드 1, `mouse_aim_enabled` 거짓)를 root 아래에 붙인다. 입력은 T24의 `_send*` 꼴(실제 입력 경로).
  1. 멈춤: 1.0초 걸은 뒤 `core.time`, `brain.state`·`brain.state_end`, `bind_gauge()`, `complacency()`, `player_state`, `record`의 사건 수, HUD 시간 글을 적는다. Esc → `paused` 참, `PauseMenu` 하나, `PauseResume`에 초점. `_physics_process(0.5)`·`_process(0.016)`을 스무 번씩 → 적은 값이 모두 같다. 덮개의 빈 곳 좌클릭, W → 사건 수 그대로. `get_tree().paused`가 내내 거짓.
  2. "계속"의 클릭: 마우스를 `PauseResume`의 가운데(뷰포트 → 창 좌표)로 옮겨 누르고 뗀다 → 멈춤 화면이 없고 `paused` 참(대기), `ATTACK_START` 없음, `player_state` READY. 곧바로 좌클릭(더블클릭의 둘째) → `swallowed_attacks` 1, `ATTACK_START` 없음. `_hold_until_msec`를 0으로 당기고 `_physics_process(1/60)` → `paused` 거짓, `core.time`이 1/60만큼 흘렀다. 좌클릭 → WINDUP(공격이 다시 된다). 정적 `hold_over`: 끝 직전 거짓, 끝 그때 참. 헤드리스의 64×64 창에서 실제 클릭이 버튼에 닿지 않으면(지금까지 GUI 버튼을 실제 입력으로 누른 테스트가 없다) 그 한 단계만 `pressed.emit()` 뒤에 같은 자리의 누름·뗌 이벤트를 보내는 꼴로 바꾸고 보고서 3번에 적는다 — 버튼이 클릭을 먹는지는 V2-2가 본다.
  3. 막기: 우클릭 누름(GUARD) → Esc → 우클릭 뗌(멈춘 동안 `core.guard_held`는 참 그대로) → Esc(돌아오기) → `guard_held` 거짓, READY. 다시: 우클릭 누름 → `guard_enter_time` 적기 → Esc → Esc → GUARD 그대로, `guard_enter_time` 같다.
  4. 포커스: 새 판에 `notification(NOTIFICATION_APPLICATION_FOCUS_OUT)` → 멈춤 화면. `NOTIFICATION_APPLICATION_FOCUS_IN` → 그대로 멈춤. 다른 새 판에 `NOTIFICATION_WM_WINDOW_FOCUS_OUT` → 멈춤. 두 알림이 잇달아 와도 `PauseMenu`는 하나. 대기 중의 포커스 잃음 → 멈춤 화면이 다시 뜬다.
  5. 끝난 판: `core.ended`가 될 때까지 걸은 뒤 Esc·포커스 잃음 → `paused` 거짓, 멈춤 화면 없음.
  6. 나가기의 꼴: 연습 → `PauseExit` "연습 고르기로", `PauseExitNote` 없음. 하루 결투(결투 단계의 `DayState`를 넣은 씬) → "처음 화면으로", 노트가 `quit_note`와 같다. 하루 결투의 R은 멈춤 화면이 열린 동안에도 대기 중에도 새 판을 만들지 않는다. (Q2 "다"면 하루 결투에 `PauseExit`가 없다.)
  7. 설정: `PauseSettings` → 멈춤 화면 아래에 `SettingsScreen`. `ui_cancel` → 설정만 닫히고 멈춤 화면과 `paused`가 남고 초점이 `PauseSettings`. 자동 로드가 없으면 T97-9의 대역을 쓴다.
  8. R(연습, 대기 중) → 새 판, `paused` 거짓.
- **T99 "나가기와 끄기: 돌아올 날의 글, 창 닫기의 확인, 처음 화면의 게임 종료"** — 테스트 세이브 `user://bravi_test_save_S02.json`을 쓰는 새 `GameSession`(트리 밖, `save_path`를 넣는다), 끝에 파일을 지운다.
  1. `quit_note`: 3일차 카운터·`resume_day` 3 → "3일차 아침부터"와 "남지 않는다". 3일차 폐점·4 → "4일차"와 "적혀 있다". 3일차 폐점·3(쓰기 실패) → "3일차"와 "남지 않는다". 0 → "적힌 아침이 없다".
  2. `resume_day`: 3일차 아침의 `saved_state()`를 적으면 3, 파일이 없으면 0, `save_path`가 비면 0, `{"day": "x"}`이면 0.
  3. `handle_close_request`: `day` 없음 → QUIT(아무것도 붙지 않는다). 카운터 단계 + root에 붙인 빈 `Control` → CONFIRM, 그 아래 `QuitConfirm` 하나, 글에 "3일차". 한 번 더 → QUIT. `QuitNo`(또는 `ui_cancel`) → 확인 창이 닫히고 `cancelled`. `QuitYes` → `confirmed`(끄지는 않는다 — 신호만 본다). 폐점 + `resume_day` = 날+1 → QUIT. 하루 결투 씬을 장면으로 → 결투가 멈춤 화면을 열고 확인 창이 그 위(`layer` 20 > 10). 돌아간다 → 멈춤 화면이 남는다.
  4. 처음 화면: 저장 없음·있음 모두 `QuitGame` "게임 종료"가 있고, 누르면 아무 일도 없다(현재 씬이 아니다 — 러너가 계속 돈다).
  5. 카운터의 `QuitNote`: 세션이 없으면 "오늘 아침부터다"(지금 글), `QUIT_NOTE`에 `%d`가 하나.
  6. (Q3 "나"일 때) 카운터·정산·폐점에 `ui_cancel` → `PauseMenu`(제목 "잠깐"), 한 번 더 → 닫힘. 정산의 `PauseExit`가 있고 노트가 `quit_note`.
- 완료 확인: 기계적 확인 다섯. 기존 테스트의 diff가 위의 기대값과 덮개 넘기기뿐(검사 줄을 지우지 않았다).

**작업 7. 찍기** (Sonnet. `tests/ui_shots.gd`, `tests/run_ui_shots.ps1`)
- 새 장: `pause-practice`(연습 결투, 깃털 자르기, 교전 대기의 멈춤), `pause-day`(하루 결투의 멈춤 — 처음 화면으로와 노트), `pause-settings`(`pause-day` 위의 설정 화면), `quit-confirm`(카운터 위의 확인 창). Q3 "나"면 `menu-counter`(카운터의 "잠깐"). 장 수 16 → 20(21). `title`·`title-save` 장은 아래 줄이 셋으로 바뀐다.
- 새 줄 `wearhit,<장>,<수>`: 장마다, 헤진 `PanelContainer`의 자름 상자(판 안 좌표 → 전역)와 그 판의 보이는 자손 `Label`·`Button`의 전역 사각형이 겹치는 수. `run_ui_shots.ps1`은 S02의 새 장에서 0이 아니면 실패로 판정하고, 나머지 장은 판정하지 않고 줄만 남긴다(033b의 장을 이 계획이 다시 판정하지 않는다). `$count`와 6·7행 머리 주석(ASCII).
- 완료 확인(메인, diff): 장 목록과 `wearhit` 줄, 판정 줄 하나, `run_ui_shots.ps1`이 ASCII.

**작업 8. verifier의 확인** — V1을 넘긴다. 실패하면 로그의 줄로 가려 범위·규칙을 바꾸지 않는 오류만 고쳐(Sonnet) 다시 맡긴다. 통과하면 커밋한다.
- 메인이 읽는 장(1280): `pause-day`·`pause-settings`·`quit-confirm`·`title`. 버튼 글이 판·칸 안에 들고 노트가 잘리지 않는지, 어둡게 덮은 아래로 멈춘 판이 보이는지, `wearq` 줄로 멈춤 화면이 뜰 때 헤지는 판이 어떻게 바뀌는지(HUD의 판은 `Panel`이라 헤지지 않는다 — 바뀌는 것은 새 판들뿐인지).

**작업 9. playtester의 확인** — **Q4가 "가"일 때만**. V2를 넘긴다("나"면 보고서 2번에 사용자가 해 볼 목록으로 싣는다).

**작업 10. 문서와 커밋**
- `docs/DECISIONS.md` "계획 S02"(507~516과 실행 중에 정한 것, Q1~Q4의 답), `CLAUDE.md`(3장 조작 표의 Esc 한 줄, 5장 "지금 만든 범위"에 멈춤·게임 종료·창 닫기의 확인 한 마디, 8장 폴더에 `scripts/ui/pause_menu.gd`·`quit_confirm.gd`, 9장 설정 갈래 줄에 S02), `docs/HANDOFF.md` 1번(다음은 S03), 보고서 `docs/reports/S02-pause-focus-quit.md`(10장 형식).
- 완료 확인: `DECISIONS.md`에 `^507\.`~`^516\.`이 하나씩, `git status`가 깨끗하다.

## 맡길 확인

- **V1 (verifier, 작업 7 뒤)** `tests/verify.ps1 -Shots "$env:TEMP\bravi-S02\after"` → `VERIFY: OK`, `ALL PASS 99/99`(오류·경고 0), 스모크 OK, 가져오기 오류 0, 장 수 상대 57·UI **20**(Q3 "나"면 21)·패턴 38, 새 장의 `wearhit` 0, `fit select` 그대로. 실행 전후로 `bravi_settings.json`·`bravi_playtest_settings.json`·`bravi_save.json`이 생기거나 바뀌지 않았고(S01 V1의 꼴), 테스트 파일 `bravi_test_save_S02.json`이 남지 않았다.
- **V2 (playtester, Q4 "가")** 창에서만 보이는 것. 띄우는 명령마다 `$env:BRAVI_SAVE_PATH = "user://bravi_playtest_save.json"; $env:BRAVI_SETTINGS_PATH = "user://bravi_playtest_settings.json"; $env:BRAVI_EVENT_LOG = "<임시 폴더>\events.jsonl"`. 판의 수는 기록 줄의 `pauses`·`pause_drift`·`swallowed_attacks`로 읽는다(창에서 세지 않는다).
  1. 하루 1일차 첫 결투 중 Alt+Tab으로 다른 창 → 돌아오기: 멈춤 화면이 떠 있고, 떠나기 전과 돌아온 뒤의 화면(남은 시간, 상대의 자세)이 같다. 기록 줄 `pause_drift` 0.
  2. "계속"을 더블클릭: 내 칼이 예비 동작으로 가지 않고, 잠깐("다시 시작한다") 뒤에 판이 흐르고, 그 뒤의 좌클릭은 공격이 된다. 기록 줄 `swallowed_attacks` 1 이상.
  3. 우클릭을 쥔 채 Alt+Tab, 쥔 채 돌아와 Esc로 계속: 막기가 풀려 있는지 이어지는지를 그대로 적는다(R2. 어느 쪽이든 실패로 치지 않고 보고서에 싣는다).
  4. 결투 중 창의 닫기 단추: 확인 창에 "1일차 아침부터", "돌아간다" → 멈춤 화면 → 계속 → 판이 이어진다. 카운터에서 Alt+F4 → 확인 창 → "끈다" → 창이 닫힌다 → 다시 켜면 처음 화면이 "이어서 한다 — 1일차 아침부터".
  5. 처음 화면의 "게임 종료" → 꺼진다. 연습 결투 중 닫기 단추 → 확인 창 없이 꺼진다.
  6. 멈춤 → 설정 → 슬라이더를 끌고 돌아간다 → 계속: 판이 이어진다(설정 판의 글이 헤짐에 가리지 않는다).

## 위험

- **R1 창이 닫히지 않는다**(`auto_accept_quit`을 끈 뒤 처리에 탈이 나면): 두 번째 닫기는 늘 바로 끈다, 장면이 없거나 하루 밖이면 바로 끈다(결정 512). T99-3이 길을 보고 V2-4·5가 실제 창을 본다.
- **R2 포커스를 잃을 때 엔진의 눌린 상태**: 엔진이 Alt+Tab에서 눌린 버튼을 놓아 주는지에 따라 쥔 채 돌아온 막기가 달라진다. 결정 509 (4)는 엔진이 말하는 상태에 맞출 뿐이라 어느 쪽이든 판이 어긋나지 않는다(멈춘 동안 시간이 흐르지 않는다). V2-3이 실제를 적는다.
- **R3 Esc 하나가 두 번 처리된다**(멈춤 화면이 닫히고 같은 누름으로 결투가 다시 멈춤): 멈춤 화면이 처리됨 표시를 닫기보다 먼저 하고(결정 510), 결투의 `_unhandled_input`은 멈춤 화면이 열린 동안 듣지 않는다. T98-1·3·T24가 실제 Esc로 본다.
- **R4 기존 테스트의 기대값**: T24·스모크·T58·`day_tests`·T75가 바뀐다(작업 6에 줄 번호). 검사 줄은 지우지 않는다.
- **R5 헤짐의 몫이 바뀐다**: 멈춤 화면·설정·확인 창의 판이 화면의 UI 창 수에 들어 몫(30%)이 바뀐다. 결투의 HUD 판은 `Panel`이라 헤지지 않으므로 바뀌는 것은 새 판뿐이고, 그 글은 `wearhit`가 본다(작업 7). 카운터 위의 확인 창은 카운터의 판의 헤짐을 바꿀 수 있다 — 어둡게 덮인 아래라 받아들이고 `wearq` 줄로 남긴다.
- **R6 대기 0.4초가 답답하다**: 값 하나다. 사용자의 손으로 본다(보고서 4번).

## 검토 전에 물을 것 (메인이 선택 창으로)
- **답 받음(2026-11-27, 선택 창)**: Q1 "가 — 멈춤 화면으로", Q2 "가 — 허락, 한 번에", Q3 "나 — 같은 창을 잠깐으로"(작업 5를 하고 찍기 21장), Q4 "가 — playtester가 한 번"(V2·작업 9).


**Q1. 연습 결투의 Esc** (지금은 누르면 바로 의뢰 선택으로 간다)

| 보기 | 뜻 | 답에 따라 달라지는 것 |
|---|---|---|
| **가(권함)** | Esc는 하루와 같이 멈춤 화면을 연다. 의뢰 선택은 멈춤 화면의 "연습 고르기로" | 결정 508 (가), 510의 연습 나가기, 514의 " · Esc 멈춤", T24 고침 |
| 나 | Esc 한 번은 멈춤, 멈춘 채 Esc 한 번 더면 바로 의뢰 선택 | 멈춤 화면의 Esc가 "계속"이 아니게 된다(하루와 연습의 Esc가 다르다). 결정 510의 Esc 줄, T98-3의 돌아오기를 "계속" 버튼으로 |
| 다 | 연습은 지금대로(Esc = 바로 의뢰 선택). 포커스를 잃을 때만 멈춘다 | 결정 508에서 연습의 (가)를 뺀다, 514는 연습에 " · Esc 의뢰 선택"을 남긴다, T24 그대로 |

**Q2. 하루 결투의 멈춤 화면에서 "처음 화면으로"** (그날의 결투와 그날 한 일을 잃고 그날 아침부터 다시 — 지금은 결투 중에 나갈 길이 창 닫기뿐이다)

| 보기 | 뜻 | 답에 따라 달라지는 것 |
|---|---|---|
| **가(권함)** | 허락한다. 버튼 아래에 "이어서 하면 N일차 아침부터 시작한다 — 오늘 한 일은 남지 않는다"를 늘 보이고 한 번 누르면 간다(카운터의 "오늘은 그만"과 같은 꼴) | 결정 510 그대로 |
| 나 | 허락하되 누르면 확인 창(결정 512의 `QuitConfirm`과 같은 꼴, "처음 화면으로 간다 / 돌아간다")을 한 번 더 | `QuitConfirm`의 버튼 글을 인자로, T98-6에 확인 단계 |
| 다 | 허락하지 않는다. 하루 결투의 멈춤 화면은 계속·설정뿐이고 나갈 길은 창 닫기(확인 창)다 | 결정 510의 하루 나가기를 빼고, T98-6은 `PauseExit` 없음을 본다 |

**Q3. 카운터·정산·폐점에서 Esc** (이 화면들은 시간이 흐르지 않아 멈출 것은 없다. 다만 지금은 하루 중에 설정을 열 길이 결투의 멈춤 화면뿐이다)

| 보기 | 뜻 | 답에 따라 달라지는 것 |
|---|---|---|
| **나(권함)** | 같은 창을 제목 "잠깐"으로 연다: 계속 · 설정 · 처음 화면으로(+ 돌아올 날의 글) | 작업 5를 한다, 찍기 21장, T99-6 |
| 가 | 결투에서만. 세 화면의 Esc는 지금처럼 아무것도 하지 않는다 | 작업 5를 건너뛰고 BACKLOG에 한 줄, 찍기 20장 |

**Q4. 창에서만 보이는 확인**(실제 Alt+Tab, 창 닫기 단추·Alt+F4, 실제 더블클릭 — V2)

| 보기 | 뜻 | 답에 따라 달라지는 것 |
|---|---|---|
| **가(권함)** | playtester(Opus)로 한 번 확인한다(V2의 여섯) | 작업 9를 한다 |
| 나 | 사용자가 직접 해 보고 답한다 | 작업 9를 건너뛰고 V2를 보고서 2번의 "직접 해 보실 것"으로 |

- planner가 임시로 정한 것(되돌리기 쉽다): 씬의 깃발로 멈추기(507), 돌아오기 대기 400밀리초와 대기 중에 좌클릭만 버리기(509), 막기는 엔진이 말하는 쥔 상태에 맞추기(509), 창 닫기의 두 번째 누름은 바로 끄기와 저장된 폐점은 바로 끄기(512), 처음 화면의 "게임 종료"는 확인 없이(513), 세 칸 126·11(513), 글의 말씨(511), 층 10·20(510·512).

## 계획 뒤의 차례

S02 보고 뒤 사용자가 "다음 진행"이라 하면 S03(키·마우스 버튼 바꾸기)을 쓴다. S03에 넘기는 것:
- 예약 키: Esc는 `back`과 `ui_cancel`(멈춤·덮개 닫기)이라 바꿀 수 있는 넷(공격·막기·전진·후퇴)에 줄 수 없다. 멈춤 화면의 "설정"이 조작 탭도 연다(`SettingsScreen.TABS`의 한 줄이면 된다).
- 결정 509의 "대기 중 버리는 것은 `attack` 누름" — 키를 바꿔도 액션 이름으로 보므로 그대로 듣는다. 막기 다시 맞추기도 `Input.is_action_pressed(&"guard")`라 바꾼 버튼을 따른다.
- playtester를 부를 때 `BRAVI_SETTINGS_PATH`를 확인용 파일로(S01에서 넘김, V2에서 먼저 쓴다).
