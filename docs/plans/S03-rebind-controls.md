# 계획 S03: 키·마우스 버튼 바꾸기

- 버전: v3 (2026-11-27. 1회차 디자인 APPROVE · 기술 REVISE T1~T3 반영과 디자인 비차단 하나. v2: 사용자 답 Q1 "다"·Q2 "가"·Q3 "나". v1: HEAD `123c015`, S02 끝, `ALL PASS 99/99`)
- 개발 단계: CLAUDE.md 9장의 단계와 **별개인 사용자 지시 작업**(설정·편의 갈래 S01~S04의 셋째). 9장의 단계를 넘기지도 닫지도 않는다. 차례는 S01 계획의 표 그대로다(S04 뒤에 5단계).
- 근거:
  - 사용자 지시(2026-11-26) "설정·편의 기능 추가" 가운데 S03의 몫: "1. 키·마우스 버튼 변경 — 공격(기본 좌클릭)·방어(기본 우클릭)·전진(W)·후퇴(S)를 다시 지정, 기본값으로 되돌리기, 같은 키를 두 번 지정하면 알림, 도움말에 바뀐 키가 보인다", "5. 설정 메뉴 — 처음 화면과 일시정지에서 조작 탭을 연다, 설정은 영업 세이브와 따로", "[자동] 설정 저장/불러오기가 영업 세이브와 분리, 중복 키". 범위 밖: 글자 크기, 고대비, 화면 모드(S04). 조준(마우스 위치)은 다시 지정하지 않는다. 사용자 "다음 진행"(2026-11-27).
  - 검토 전 답(2026-11-27, 선택 창): **Q1 "다" — 겹치면 받고 다른 쪽은 비운다**, **Q2 "가" — 키보드 키 + 마우스 버튼 다섯, 휠 없음**, **Q3 "나" — 창 확인은 사용자가 직접**(playtester를 부르지 않는다).
  - S01이 둔 자리(결정 500·502, S01 계획 91행): `Settings`의 `controls` 갈래, 모르는 갈래·칸을 지우지 않는 읽기·쓰기, `changed(section, key)` 신호, 설정 화면 `TABS`의 한 줄(메서드 이름 + `call`), "시작할 때 InputMap에 거는 `apply_controls()`, 도움말 글(`DuelHud.help_text`)이 InputMap의 이름을 읽게".
  - S02가 넘긴 것(S02 계획 227~231행): Esc는 `back`·`ui_cancel`(멈춤·덮개 닫기)이라 바꿀 수 있는 넷에 줄 수 없다. 멈춤 화면의 "설정"이 조작 탭도 연다(`TABS`의 한 줄이면 된다). 대기 중 버리는 것은 액션 `attack`의 누름이고, 막기 다시 맞추기는 `Input.is_action_pressed(&"guard")`라 바꾼 버튼을 따른다.
  - BACKLOG S02-1~3은 S03에 닿지 않는다(S02-2는 창 도구의 일이고 이 계획은 창 도구를 쓰지 않는다. S02-3 "러너가 프레임을 넘기지 않는다" — 이 계획은 `call_deferred`를 쓰지 않아 테스트가 실제 길을 탄다).
  - 지금 코드(읽음, HEAD `123c015`):
    - 입력 지도(`project.godot` [input]): `attack` 마우스 1, `guard` 마우스 2, `step_forward` physical 87(W), `step_back` physical 83(S), `retry` physical 82(R), `back` physical 4194305(Esc), `debug_toggle` physical 4194332(F1). 모두 `device -1`, 수식키 없음. 화면 넘기기는 엔진의 `ui_accept`(Space·Enter·KP Enter), 덮개 닫기는 `ui_cancel`(Esc). T0(`project_tests.gd` 11~44행)이 이 지도를 본다.
    - 액션을 읽는 곳은 `duel_scene.gd`뿐이다: `_unhandled_input`(298~332행)의 `is_action_pressed`/`is_action_released`(echo는 기본값으로 거른다), `_begin_hold`(202~211행)의 `Input.is_action_pressed(&"guard")`. 대기 중에는 `attack` 누름만 버리고(`_swallowed_attacks`) 막기·간격·R·F1은 받는다(결정 509 (3)). 그 밖의 화면은 `ui_accept`·`ui_cancel`·`back`만 듣는다.
    - 키 이름이 든 글: `DuelHud.HELP_TEXT`(40행 "좌클릭 공격 · 우클릭 막기 … · W/S 간격" + R·Esc·F1), `HELP_BIND`(20행 "S로 먼저 물러난다"), `HELP_LUNGE`(15행 "S로 물러나 멀리에서 좌클릭"). `help_text()`는 정적이고 처음 화면의 도움말(`title.gd` `help_groups`, 131~140행)만 화면에 쓴다(결투 화면에는 안내가 없다, 결정 323). 도움말 덮개는 처음 열 때 한 번 짓고 다시 쓴다(`_build_help`/`_show_help`, 175~203행) — 키를 바꾼 뒤에 열어도 옛 글이 남는다. 결투 HUD의 기록 줄(`on_event`, 461~468행, 세 줄)은 `reset()`으로 비운다. F1 디버그 글의 "지금 좌클릭이 런지"(529행)는 `lunge_tests.gd` 753행이 본다. "Space / Enter" 글(`title.gd` 18행, `duel_scene.gd` 16행)은 `ui_accept`라 바뀌지 않는다.
    - `Settings`(`scripts/settings.gd`): `normalize`는 `audio`만 고르고 나머지 갈래를 그대로 둔다. `_ready`가 `path`를 정하고 읽은 뒤 `apply_audio()`. 자동 로드 차례는 `Settings` → `GameSession`.
    - 설정 화면(`scripts/ui/settings_screen.gd`): 판 `Rect2(240, 110, 800, 480)`, 탭 버튼 140×44(`"Tab" + 갈래.capitalize()`), 몸 `TabBody`(VBox, 사이 16), 닫기 `SettingsClose`, Esc는 `_unhandled_input`으로 닫는다. 멈춤 화면(`pause_menu.gd`)과 처음 화면이 `SettingsScreen.open(parent, /root/Settings)`으로 연다.
    - 테스트의 격리: 러너(`run_tests.gd` 78~84행)와 UI 찍기(`ui_shots.gd` 46~49행)가 자동 로드 `Settings`의 `path`를 비워 쓰기만 끈다 — **읽은 값은 그대로 걸려 있다**. 스모크(`day_smoke.gd`)는 `Settings`를 건드리지 않는다. `verify.ps1`은 `BRAVI_SETTINGS_PATH`를 `user://bravi_playtest_settings.json`으로 둔다. 그래서 S03 뒤에 이 파일이나 플레이어의 파일에 바꾼 키가 있으면 자동 로드가 InputMap에 그 키를 걸고 T0·T24·T98·스모크의 실제 입력(`_send_key(KEY_W)`, 좌클릭 등)이 다른 동작으로 들어간다 — 결정 523이 막는다.
    - T97-6(`settings_tests.gd`)은 `"controls": {"attack": "x"}`가 다시 적어도 같은 값으로 남는지 본다 — S03 뒤에는 `attack`이 아는 칸이라 읽을 때 고쳐진다(작업 5에서 기대값을 바꾼다).
  - 번호: 결정은 **517부터**(`DECISIONS.md`의 마지막 516), 테스트는 **T100부터**(마지막 T99). 실행 때 다시 본다.

### 넘지 않는 선

- 메인은 Godot·테스트·게임을 실행하지 않는다. 자동 확인은 verifier(`tests/verify.ps1`). playtester는 부르지 않는다(Q3 "나"). 코드 쓰기(`.gd`·`.ps1`·테스트)는 Sonnet 하위 에이전트, 메인은 diff를 읽는다. 편집은 80줄 안쪽으로 나누고 HANDOFF 4번의 기계적 확인 다섯을 지킨다. `.ps1`은 ASCII.
- 고치지 않는 것: 판정 코드(`scripts/duel/duel_core.gd`, `scripts/ai/`), `data/`, `project.godot`(입력 지도의 처음 값은 그대로 — 처음 값의 원본이다), `scripts/save_store.gd`, `scripts/game_session.gd`, 영업 세이브의 형식, 테마 `.tres`와 `scripts/ui/`의 StyleBox, `pause_menu.gd`, `quit_confirm.gd`, F1 디버그 글, `tools/`, `.claude/agents/`.
- 범위 밖: 조준(마우스 위치), 예약 키(Esc·R·F1·Space·Enter) 자체를 바꾸기, 키 조합(Ctrl+W 같은), 한 동작에 키 둘, 일부러 동작을 비우는 버튼(비는 것은 겹칠 때뿐이다), 게임패드, 화면 모드(S04), 글자 크기·고대비.

## 목표와 범위

**확인할 결과**:

1. 설정 화면에 "조작" 탭이 있다(처음 화면과 멈춤·잠깐 창 양쪽에서). 공격·막기·전진·후퇴의 줄마다 지금의 키 이름(좌클릭·우클릭·W·S)이 버튼에 보이고, 누르면 "누를 키나 버튼을 기다린다", 다음에 누른 키보드 키나 마우스 버튼(좌·우·가운데·옆 둘)이 그 동작이 된다. Esc나 판 안의 다른 버튼을 누르면 기다림이 취소되고(다른 버튼은 그대로 눌린다), 좌클릭을 주려면 기다리는 그 칸이나 빈 곳을 누른다. "처음 값으로"가 넷을(비어 있는 것까지) 되돌린다.
2. 다른 동작이 쓰는 키를 주면 받고, 그 동작은 **비고** 알림이 뜬다("겹쳤다 — 막기: 좌클릭 · 공격은 이제 비었다"). 빈 동작은 버튼에 "없음"으로 보이고, 하나라도 비어 있는 동안 탭에 경고가 늘 떠 있다. 예약 키(Esc 멈춤, R 다시 하기, F1 디버그, Space·Enter 화면 넘기기)는 받지 않고 그 까닭을 알린다. 넷은 늘 "서로 다르거나 비어 있다".
3. 바꾼 키는 곧바로 걸린다: 결투의 멈춤 화면에서 바꾸고 "계속"하면 새 키로 공격·막기·이동이 되고, 빈 동작은 어떤 입력에도 일어나지 않는다. 바꾼 뒤에도 "계속"의 클릭과 더블클릭의 둘째 누름은 어떤 동작도 되지 않고, 대기 중의 공격 누름(새 키)은 버려진다. 바꾸는 순간 쥐고 있던 버튼 때문에 막기가 붙어 버리지 않는다.
4. 처음 화면의 도움말이 바뀐 키 이름으로 나온다(첫 줄의 공격·막기·간격, 엉킴·런지 줄의 후퇴·공격). 처음 값이면 첫 줄은 지금 글과 같다. 빈 동작은 "—"로 쓰고 첫 줄 끝에 "비어 있는 동작: 공격 — 설정의 조작 탭에서 준다"가 붙는다. 빈 동작이 있으면 결투가 시작할 때 HUD의 기록 줄에 같은 글이 한 번 뜬다. 어디서도 막지는 않는다.
5. 바꾼 키(와 빈 동작)는 `bravi_settings.json`의 `controls`에 적혀 다시 켜도 남고, 가게를 새로 시작해도 그대로다(영업 세이브와 따로 — S01 그대로). 깨진·모르는·겹친·예약된 값은 처음 값으로 읽고 오류 줄이 없으며, 조작 탭이 "읽을 수 없는 조작을 처음 값으로 돌렸다"를 한 번 알린다. 빈 값은 깨진 값이 아니다.
6. 테스트·찍기·스모크는 플레이어의 설정과 상관없이 처음 값의 키로 돌고 어떤 설정 파일도 적지 않는다. 판정·데이터 그대로: `duel_core.gd`·`scripts/ai/`·`data/`·`project.godot`의 `git diff` 0줄. `ALL PASS 101/101`, 스모크 OK, 가져오기 오류 0, UI 찍기 22 → 24, 새 장의 `wearhit` 0.

재미는 바뀌지 않는다(규칙·시간·조준은 그대로이고, 어느 입력이 어느 동작인지만 바뀐다).

## 설계 결정

517. **조작의 부호·이름·예약** — 새 `scripts/controls.gd`(`extends RefCounted`, `class_name` 없음. 쓰는 쪽은 `const Controls := preload(...)`), 정적 함수만:
     - `ACTIONS := [&"attack", &"guard", &"step_forward", &"step_back"]`, 이름 `LABELS`: 공격 · 막기 · 전진 · 후퇴, 그리고 알림에 쓰는 `TOPICS`: 공격은 · 막기는 · 전진은 · 후퇴는(이름이 넷으로 정해져 있어 토씨를 표로 둔다).
     - **부호**(파일과 비교에 쓴다): `"mouse:<button_index>"` · `"key:<physical_keycode>"` · **빈 글 `""` = 없음**. `code_of(event) -> String`: 마우스 버튼이면 허용된 번호만(Q2 "가": 1 좌클릭, 2 우클릭, 3 가운데 클릭, 8 옆 버튼 1, 9 옆 버튼 2), 키면 `physical_keycode`(**0이면 못 쓰는 입력** — `keycode`로 대신 적으면 `event_of`가 그 수를 물리 키로 지어 실제 누름에 맞지 않는다. 진짜 키보드의 누름은 늘 물리 키를 가진다), 수식키 상태는 버린다. 휠(4~7)·`KEY_META`·echo 누름·그 밖은 빈 글(= 못 쓰는 입력. 기다림에서는 "없음"으로 받지 않는다 — 결정 520).
     - `event_of(code) -> InputEvent`: 부호에서 새 이벤트(키는 `physical_keycode`만, 마우스는 `button_index`만, `device = -1`, 수식키 없음 — `project.godot`의 꼴과 같다). 수식키를 담지 않는 까닭: Shift 같은 수식키를 키로 줄 때 뗌 이벤트가 그 액션에 맞지 않아 막기가 풀리지 않는 일을 막는다. 빈 글이나 못 읽는 부호면 null. `is_valid(code)`: 빈 글이거나 `event_of`가 null이 아니다.
     - `name_of(code) -> String`: 마우스는 위의 한국어 이름, 키는 `OS.get_keycode_string(physical_keycode)`("W", "Shift", "Up", "Kp 1" …), 빈 글은 "없음". 자판 배열에 따른 이름(`DisplayServer.keyboard_get_label_from_physical`)은 헤드리스에서 오류 줄을 낼 수 있어 쓰지 않는다 — 물리 자리의 미국식 이름이다(한국 자판은 같은 자리다). 임시 결정, 되돌리기 쉽다.
     - `default_code(action)`: `ProjectSettings.get_setting("input/<action>")`의 첫 이벤트의 부호(처음 값의 원본은 `project.godot` 하나).
     - **예약**: `RESERVED := {&"back": "멈춤", &"ui_cancel": "멈춤", &"retry": "다시 하기", &"debug_toggle": "디버그", &"ui_accept": "화면 넘기기"}`. `reserved_use(code) -> String`: 그 액션들의 InputMap 이벤트(키는 `physical_keycode`와 `keycode` 둘 다로 견준다 — 엔진의 `ui_accept`는 `keycode`로 적혀 있다) 가운데 같은 것이 있으면 쓰임의 이름, 없으면 빈 글. 예약은 **받지 않는다**(Q1 "다"에서도): 바꿀 수 없는 동작을 비울 수는 없고, Esc·Space를 공격에 주면 멈춤·결과 넘기기가 같은 누름에 함께 걸린다. S04가 화면 전환 키를 더하면 이 목록에 한 줄.
     - `apply_codes(codes: Dictionary, changed: Array = ACTIONS)`: 넷 각각 `InputMap.action_erase_events` → 부호가 비어 있지 않으면 `action_add_event(event_of(code))`. **액션 자체는 지우지 않는다**(빈 동작도 액션은 남아 `is_action_pressed`·`action_release`가 오류 없이 거짓을 돌려준다). 그 뒤 `changed`의 동작(받은 동작과 비운 동작)만 `Input.action_release(action)` — 바꾸지 않은 동작을 쥐고 있던 손은 그대로 둔다. 놓아 주는 까닭: 바꾸는 순간 쥐고 있던 버튼(예: 막기를 쥔 채 멈추고 막기를 G로 바꾸면 옛 우클릭의 뗌이 더는 막기에 맞지 않는다)의 액션 상태가 눌린 채 남으면 돌아올 때 `_begin_hold`가 막기를 붙인다.
     - `action_name(action) -> String`: InputMap의 첫 이벤트의 `name_of`(이벤트가 없으면 "없음"). `help_name(action)`: 같되 빈 동작은 "—"(도움말에 쓴다, 결정 521). `empty_actions() -> Array`: 이벤트가 없는 동작들.
518. **`Settings`의 `controls` 갈래**(`scripts/settings.gd`):
     - 파일의 꼴: `"controls": {"attack": "mouse:1", "guard": "mouse:2", "step_forward": "key:87", "step_back": "key:83"}`. 빈 동작은 `""`. `version`은 1 그대로(칸을 더할 뿐이고 S01의 읽기가 모르는 갈래를 남긴다).
     - 읽기(`normalize`에 한 갈래): 넷마다 — 칸이 **없으면 처음 값**(고친 것이 아니다), `""`이면 **없음**(유효하다, 고친 것이 아니다), 문자열이고 `event_of`가 읽히고 예약이 아니면 그 값, 그 밖(숫자, 못 읽는 부호, 허용 밖 버튼, 예약)은 처음 값. 그 뒤 **비어 있지 않은 값끼리** 겹친 것이 있으면 넷 모두 처음 값(어느 쪽이 맞는지 모르므로. 빈 칸 둘 이상은 겹침이 아니다). 못 읽는·예약된·겹친 값을 고쳤으면 `controls_repaired`를 참으로(조작 탭이 한 번 알린다, 결정 520). `controls` 안의 모르는 칸(`"dodge"` 등)은 그대로 남긴다(S01 규칙).
     - `var controls: Dictionary`(넷의 부호). `_ready`에서 `apply_audio()` 다음에 `apply_controls()`(= `Controls.apply_codes(controls)`). 자동 로드가 `GameSession` 앞이라 첫 화면 전에 걸린다.
     - `set_control(action, code) -> Dictionary`: 결과 `{"result": …, "other": …, "use": …}`. `&"same"`(이미 그 값, 아무것도 안 함) · `&"invalid"`(못 쓰는 입력, 빈 글 포함 — 비우는 길은 겹침뿐이다) · `&"reserved"`(`use`에 쓰임) · `&"bound"` · `&"cleared"`(`other`에 비운 동작 — Q1 "다": 그 동작이 쓰던 키를 이 동작이 받고 그 동작은 `""`). `bound`·`cleared`이면 `_dirty`, `apply_controls(바뀐 동작들)`(결정 517의 `changed`), 바뀐 동작마다 `changed.emit(&"controls", action)`.
     - `reset_controls() -> bool`: 넷을 처음 값으로(빈 동작도. 이미 모두 처음 값이면 거짓, 아무것도 안 함).
     - 쓰기: 조작을 한 번도 바꾸지 않았고 읽은 파일에 `controls`가 없으면 `controls`를 적지 않는다(음량만 바꾼 사람의 파일에 처음 값이 박히지 않게). 그 밖에는 넷(빈 것은 `""`)을 적고 모르는 칸을 합친다.
     - `detach_for_run() -> void`: `path`를 비우고(쓰기 꺼짐 — S01과 같다) `controls`를 처음 값으로 두고 `apply_controls()`, `controls_repaired`를 끈다(플레이어 파일의 고친 알림이 찍기의 조작 탭에 뜨지 않게). `_dirty`는 켜지 않는다. 결정 523이 쓴다.
519. **겹침과 빈 동작**(Q1 "다", 사용자 답 2026-11-27):
     - 다른 동작이 쓰는 키를 주면 **받고, 그 동작은 빈다**. 알림 "겹쳤다 — 막기: 좌클릭 · 공격은 이제 비었다"(키 이름 뒤에 토씨가 없고, 동작 이름의 토씨는 `TOPICS` 표). 넷은 늘 "서로 다르거나 비어 있다".
     - 빈 동작은 결투에서 어떤 입력에도 일어나지 않는다(InputMap에 이벤트가 없다). 빈 동작에 키를 주면(겹치지 않으면) `bound`, 다른 동작의 키를 주면 다시 `cleared`.
     - **막지 않고 알린다**(권하는 것, planner 결정): 탭을 닫을 때도 결투에 들어갈 때도 막거나 확인을 받지 않는다. 알리는 곳은 셋 — (1) 조작 탭의 늘 떠 있는 경고(결정 520), (2) 도움말 첫 줄 끝(결정 521), (3) 결투가 시작할 때 HUD 기록 줄 한 번(결정 521). 근거: 막으면 사실상 Q1 "나"(받지 않음)가 되어 사용자가 고른 "받고 비운다"를 되돌린다. 빈 동작을 고칠 길(키를 주거나 "처음 값으로")은 같은 탭에 늘 있고, 결투 중에도 멈춤 → 설정으로 바로 닿는다. 닫을 때 확인 창을 더 띄우면 키 하나를 바꿀 때마다 한 번 더 누르게 된다. 되돌리기 쉽다(닫기에 확인을 붙이는 것은 그 자리 한 곳).
520. **조작 탭**(`scripts/ui/settings_screen.gd`):
     - `TABS`에 `[&"controls", "조작", &"_build_controls"]` 한 줄. 열면 지금처럼 첫 탭("소리")이 고른 탭이다.
     - 몸(사이 8): 넷의 줄 — 이름 `Label`(24, 폭 160) + 버튼 `Bind_<action>`(240×42, 글 20, 지금 키 이름 또는 "없음" — 빈 동작이면 글 색 `Ui.ACCENT`). 그 아래 한 줄에 `ControlsReset` "처음 값으로"(220×42)와 흐린 글 `ControlsHint`(16, `Ui.DIM`, 줄바꿈, 폭 320) "조준은 마우스 위치 그대로다 · Esc·R·F1·Space·Enter는 쓸 수 없다". 그 아래 알림 `ControlsNote`(18, 줄바꿈, 폭 560, 빈 글이면 숨김)와 경고 `ControlsEmptyWarn`(18, `Ui.ACCENT`, 비어 있는 동작이 없으면 숨김) "비어 있는 동작: 공격 · 전진 — 결투에서 쓸 수 없다". 판(높이 480) 안에 들지 않으면 흐린 글을 뺀다(보고서 3번) — 판의 크기는 바꾸지 않는다.
     - **기다림**: `Bind_<action>`을 누르면 그 버튼 글이 "누른다…", 알림 "공격에 쓸 키나 마우스 버튼을 누른다 — 좌클릭은 이 칸이나 빈 곳에서. Esc나 다른 버튼은 취소". 다음 입력은 화면의 `_input`이 받는다(GUI보다 먼저 — 잡은 누름이 아래 버튼에 닿지 않게) 그리고 잡은 것은 `set_input_as_handled()`:
       - 마우스 움직임·뗌은 지나간다. 단 **잡은 누름의 뗌**은 먹는다(키·버튼 하나를 기억해 둔다).
       - 기다림을 시작한 뒤 `Ui.ARRIVAL_GUARD_MSEC`(400) 안의 누름은 먹고 버린다(`Ui.is_arrival_press` 그대로 — 버튼을 더블클릭한 둘째 누름이 좌클릭으로 잡히지 않게). 시작 시각 `_capture_msec`는 테스트가 고칠 수 있다.
       - **다른 버튼 위의 좌클릭**(디자인 검토 1회차 비차단, 받음): 누른 자리가 설정 화면 안의 보이는 다른 버튼(다른 `Bind_*`, 탭, `ControlsReset`, `SettingsClose` — 화면의 `BaseButton` 자손 가운데 기다리는 그 `Bind_` 밖, `get_global_rect().has_point(event.position)`. 설정 화면이 놓이는 층은 모두 변환이 없다)이면 기다림을 취소하고 **그 누름을 먹지 않는다** — GUI가 받아 그 버튼이 평소처럼 눌린다(닫기는 닫히고, 탭은 바뀌고, 다른 `Bind_`는 그 동작의 기다림을 연다). 알림은 지운다. 까닭: 잘못 누른 `Bind_`에서 마음을 바꿔 닫기·탭을 누르는 가장 흔한 클릭이 좌클릭으로 잡혀 Q1 "다"로 공격을 비우던 함정을 막고, 취소와 그 버튼의 일을 한 번에 한다. 겹침 정책은 그대로다. 좌클릭을 주는 길은 기다리는 그 칸이나 빈 곳(버튼이 아닌 곳)이다. 오른쪽·가운데·옆 버튼은 어디서 눌러도 잡는다(버튼은 왼쪽만 받는다).
       - Esc(`ui_cancel`) → 취소, 알림 "그대로 두었다". 설정 화면은 닫히지 않는다(같은 누름을 먹어 설정 화면·멈춤 화면의 Esc가 받지 않는다).
       - 그 밖의 누름 → `code_of`. 빈 글이면 알림 "쓸 수 없는 입력이다 — 다른 것을 누른다"(기다림 그대로). 예약이면 "쓸 수 없는 키다 (R · 다시 하기) — 다른 것을 누른다"(기다림 그대로). 아니면 `set_control` → `same` "그대로 두었다", `bound` 알림 없음, `cleared` 결정 519의 알림. 넷의 버튼 글과 경고를 다시 쓰고 기다림을 끝내고 `settings.save()`(음소거 토글과 같은 때, 결정 505).
       - 탭을 바꾸거나 화면이 닫히면 기다림을 취소한다(위의 "다른 버튼"의 길도 이것을 지난다). 기다리는 동안 Enter·Space는 예약이라 초점 버튼을 누르지 않는다(알림만). 빈 동작이 있어도 닫기는 막지 않는다(결정 519).
     - `ControlsReset` → `reset_controls()`, 알림 "처음 값으로 되돌렸다"(이미 처음 값이면 "이미 처음 값이다"), 경고가 숨는다, `save()`.
     - `controls_repaired`가 참이면 탭을 처음 지을 때 알림 "읽을 수 없는 조작이 있어 처음 값으로 돌렸다"를 띄우고 그 표시를 끈다.
     - 열기만 하면 `changed`·`_dirty`가 생기지 않는다(S01 결정 500의 꼴 그대로).
521. **안내 글의 키 이름**(`scripts/duel/duel_hud.gd`, `scripts/duel/duel_scene.gd`, `scripts/title.gd`):
     - `HELP_TEXT`(상수)를 틀 `HELP_CONTROLS := "%s 공격 · %s 막기 (떼고 있다가 고리가 띠에 들어올 때 누르면 패리) · 마우스 위치로 방향·높이 · %s/%s 간격"`으로 바꾸고 `help_text()`가 `Controls.help_name`으로 채운다. 뒤의 R·Esc·F1과 둘째 줄은 그대로. 처음 값이면 첫 줄이 지금 글과 글자 하나까지 같다.
     - 빈 동작: 이름 자리는 "—"("— 공격", "W/— 간격"), 그리고 첫 줄 끝(F1 뒤)에 `HELP_EMPTY` " · 비어 있는 동작: 공격·전진 — 설정의 조작 탭에서 준다"(빈 것이 없으면 붙지 않는다). "없음"이 아니라 "—"인 까닭: "없음 공격"·"물러나(없음)"보다 자리가 비었다는 것이 바로 보이고, 끝의 한 줄이 무엇이 비었는지 말한다. 동작 이름 뒤에 토씨를 붙이지 않는다.
     - 키 이름 뒤에도 토씨를 붙이지 않는다(이름의 받침에 따라 "로/으로"가 갈려 "좌클릭로"가 된다). 그래서 두 줄의 말을 고친다: `HELP_BIND` " · 밀착은 엉킴이 차면 밀려난다 — 차기 전에 먼저 물러난다(%s)", `HELP_LUNGE` "방심한 상대(칼끝을 내린다)에게는 물러나(%s) 멀리에서 %s — 런지%s · 예비 동작 중에는 뛰어들지 않는다". 테스트가 보는 조각("엉킴이 차면 밀려난다", "런지", "예비 동작", "한 판에 한 번")은 남는다. 임시 결정, 되돌리기 쉽다.
     - 처음 화면의 도움말은 **열 때마다 새로 짓는다**(`_show_help`가 옛 `HelpScreen`을 떼고 `_build_help`). 결정 323의 "열기 전에 노드가 늘지 않는다"는 그대로다.
     - **결투의 알림 한 줄**: `DuelHud.add_note(text)`(기록 줄에 한 줄을 넣는다 — `on_event`의 꼴, 세 줄을 넘으면 밀려난다). `start_duel()`이 HUD를 비운 뒤 `Controls.empty_actions()`가 비어 있지 않으면 "비어 있는 동작: 막기 — 설정의 조작 탭에서 준다"를 넣는다(하루·연습 모두). 처음 값이면 아무 줄도 없다(기존 판의 기록 그대로). 판의 기록(`core.record`)·사건 기록에는 넣지 않는다.
     - 결투 화면·연습 고르기 화면의 다른 글에는 키 이름이 없다(읽음). F1 디버그 글의 "좌클릭"은 그대로 둔다(디버그, `lunge_tests` 753행).
522. **멈춤 대기와 바꾼 키**(`scripts/duel/duel_scene.gd`, 결정 509를 넓힌다):
     - 바꾼 키는 InputMap에 바로 걸리므로 멈춤 화면에서 바꾸면 "계속" 뒤의 판에 곧바로 쓰인다. 따로 할 일은 없다. 빈 동작은 액션이 남아 있고 이벤트가 없을 뿐이라 대기·다시 맞추기가 그대로 돈다(막기가 비면 `Input.is_action_pressed(&"guard")`가 거짓 → 막기가 풀린다).
     - 대기 중 버리는 것: (가) 액션 `attack`의 누름 — 어느 키든(지금대로, `_swallowed_attacks`). (나) **왼쪽 마우스 버튼의 누름과 뗌** — 넷 가운데 무엇에 묶였든 코어에 넘기지 않는다. 까닭: "계속"을 누르는 버튼은 늘 왼쪽이다. 막기나 이동을 왼쪽에 주면 더블클릭의 둘째 누름이 막기(그리고 곧바로 뗌 — 막기 쿨다운)나 걸음이 되던 길을 막는다. 기본 묶음에서는 (가)와 같아 S02의 동작이 바뀌지 않는다.
     - 대기가 끝날 때(`_end_hold`) 한 번 더 `core.guard_held`를 `Input.is_action_pressed(&"guard")`에 맞춘다(다를 때만): (나)로 버린 왼쪽 막기를 쥔 채 대기를 넘기면 그때 막기가 된다. 기본 묶음에서는 대기 중의 우클릭이 이미 코어에 들어가 있어 다를 일이 없다(T98 그대로).
523. **테스트는 처음 값의 키로 돈다**:
     - 러너(`run_tests.gd`)·UI 찍기(`ui_shots.gd`)가 자동 로드 `Settings`에 `path`를 비우던 줄을 `detach_for_run()`(메서드가 있을 때. 없으면 지금처럼 `path`만)으로 바꾼다. 러너의 찍는 줄: `RUNNER 설정: 오토로드 Settings 있음, path '…'를 비우고 조작을 처음 값으로`.
     - 스모크(`day_smoke.gd`)가 시작할 때 같은 `detach_for_run()`을 부른다(지금은 `Settings`를 건드리지 않는다 — 실제 키를 보내는 길이다).
     - **결투 씬을 띄우는 다른 찍기와 판 통계도 같은 세 줄**(자동 로드가 있고 메서드가 있으면 `detach_for_run()`): `pattern_shots.gd`·`stage_shots.gd`·`hand_shots.gd`, 그리고 `opponent_shots.gd`·`client_shots.gd`·`duel_stats.gd` 가운데 `DuelScene`이나 결투 씬 경로를 쓰는 것(작업 4가 `Grep`으로 가린다). 까닭(기술 검토 1회차 비차단, 받음): 결정 521 뒤에는 `start_duel`이 InputMap을 읽어 빈 동작이면 HUD 기록 줄을 넣으므로, 플레이어의 파일에 따라 패턴 장의 기록 줄이 달라진다.
     - 새 `Settings` 인스턴스를 붙이거나 `set_control`을 부르는 테스트(T97·T100·T101)는 끝에 자동 로드가 있으면 그 `detach_for_run()`, 없으면 `Controls.apply_codes(처음 값)`으로 InputMap을 되돌린다(`InputMap.load_from_project_settings()`는 쓰지 않는다 — 엔진 내장 액션까지 다시 읽어 넷 밖을 건드린다). 자동 로드의 값을 바꾼 단계(T101-4·5의 멈춤 화면이 `/root/Settings`를 연다)는 자동 로드의 `controls`까지 되돌려야 하므로 `detach_for_run()`이 맞다.
524. **T100 "조작의 부호·예약·읽기", T101 "조작 바꾸기: 겹치면 비우기, 탭, 실제 입력, 멈춤, 안내"**(새 `tests/controls_tests.gd`, `run_tests.gd`에 한 줄): 작업 5.

## 작업 목록

차례대로 한다. 검토 전 물음의 답은 받았다(Q1 "다", Q2 "가", Q3 "나").

**작업 0. 시작 상태**
- 할 일: `git status`가 깨끗한지, HEAD, `run_tests.gd`의 마지막 T 번호, `DECISIONS.md`의 마지막 결정 번호를 `%TEMP%\bravi-S03\head.txt`에. 다르면 이 계획의 번호를 그다음으로 바꿔 쓴다(뜻은 그대로).
- 완료 확인: 파일이 있다.

**작업 1. 부호와 `Settings`의 갈래** (Sonnet. 결정 517·518·519)
- 대상: 새 `scripts/controls.gd`, `scripts/settings.gd`(`normalize`의 한 갈래, `controls`·`controls_repaired`, `apply_controls`·`set_control`·`reset_controls`·`detach_for_run`, `save`의 `controls`, `_ready`의 한 줄).
- 완료 확인(메인, diff): `project.godot`·`save_store.gd`·`game_session.gd`의 diff 0, `audio`의 읽기·쓰기 줄이 그대로, `event_of`가 수식키 없이 `device -1`로 짓는다, `apply_codes`가 액션을 지우지 않고(`action_erase_events`만) 빈 부호에 이벤트를 더하지 않고 바뀐 동작만 놓아 준다(`Input.action_release`), `code_of`가 `physical_keycode` 0인 키를 빈 글로 돌려주고 `keycode`로 대신하지 않는다, 겹침 검사가 빈 값을 빼고 본다, `detach_for_run`이 `controls_repaired`를 끈다, 예약 비교가 `physical_keycode`와 `keycode` 둘 다다, `set_control`의 빈 글이 `invalid`다, 기계적 확인 다섯.

**작업 2. 결투·도움말** (Sonnet. 결정 521·522)
- 대상: `scripts/duel/duel_hud.gd`(`HELP_CONTROLS`·`HELP_EMPTY`·`HELP_BIND`·`HELP_LUNGE`와 `help_text`의 채우기, `add_note`), `scripts/duel/duel_scene.gd`(`start_duel`의 빈 동작 알림, 대기 중 왼쪽 버튼 버리기, `_end_hold`의 막기 맞추기), `scripts/title.gd`(`_show_help`가 다시 짓는다).
- 완료 확인(메인, diff): `duel_core.gd`·`scripts/ai/`의 diff 0, 처음 값에서 `help_text`의 첫 줄이 옛 `HELP_TEXT`와 같은 글이 되는 짜임(틀 + 이름 넷, 빈 것 없으면 `HELP_EMPTY` 없음), 토씨가 이름 뒤에 없다, `add_note`가 `core.record`·사건 기록을 건드리지 않는다, `_unhandled_input`에서 대기 밖의 길이 그대로, 디버그 글 그대로.

**작업 3. 조작 탭** (Sonnet. 결정 519·520)
- 대상: `scripts/ui/settings_screen.gd`(`TABS` 한 줄, `_build_controls`, 기다림의 `_input`, 알림·경고, 탭 바꿈·닫힘의 취소).
- 완료 확인(메인, diff): 소리 탭의 줄이 그대로, 기다림의 `_input`이 `set_input_as_handled`를 부르는 갈래와 지나가는 갈래(움직임, 잡지 않은 뗌, 다른 버튼 위의 좌클릭 — 이때는 취소만 하고 먹지 않는다)가 결정 520과 같다, `Ui.is_arrival_press`를 쓴다, 닫기에 빈 동작 검사가 없다(결정 519), `_process`·`Timer`·`call_deferred`를 쓰지 않는다, 테마 `.tres`·`day_ui.gd`의 diff 0.

**작업 4. 테스트의 격리** (Sonnet. 결정 523)
- 대상: `tests/run_tests.gd`(끄기 블록과 찍는 줄, 머리 주석 한 마디), `tests/ui_shots.gd`(47~49행), `tests/day_smoke.gd`(시작할 때 한 블록), 결투 씬을 띄우는 찍기·통계(결정 523의 목록 — `Grep "DuelScene|duel\.tscn" tests/*_shots.gd tests/duel_stats.gd`로 가린 것)의 시작에 한 블록.
- 완료 확인(메인, diff): 파일마다 diff가 그 블록뿐, `GameSession` 끄기 줄이 그대로, 가린 목록을 보고서 1번에 적는다.

**작업 5. 테스트** (Sonnet. 새 `tests/controls_tests.gd`, `tests/run_tests.gd`에 한 줄, 기존 기대값 둘. 테스트 설정 파일은 `user://bravi_test_settings_S03.json`, 인스턴스는 `path`를 넣은 뒤 트리에 붙인다(S01 결정 500), 끝에 파일을 지우고 InputMap을 처음 값으로 되돌린다(결정 523))
- 기존 기대값:
  - T97-6(`settings_tests.gd`): `"controls": {"attack": "x"}` → `"controls": {"dodge": "x"}`로 바꾸고, 다시 적은 뒤 `controls.dodge`가 "x"로 남는지를 본다(아는 칸 `attack`은 이제 고쳐 읽는다 — 그 몫은 T100-3).
  - T75(`manuscript_tests.gd` 144~147행): 설정 화면을 연 뒤 `TabControls`를 눌러 조작 탭도 `_check_text`·`_check_buttons`를 지나게 한다(새 검사 함수는 만들지 않는다. 버튼 크기 표에 `Bind_*` 240×42·`ControlsReset` 220×42).
- **T100 "조작의 부호·예약·읽기"**:
  1. 부호: `project.godot`의 넷의 이벤트 → `mouse:1`·`mouse:2`·`key:87`·`key:83`, `default_code`가 같다. `event_of`↔`code_of`가 되돌아온다. 이름: 좌클릭·우클릭·가운데 클릭·옆 버튼 1·옆 버튼 2·W·S, `name_of("")` "없음". `event_of("")` null, `is_valid("")` 참, `is_valid("key:abc")` 거짓. 휠 위·아래, `KEY_META`, echo 누름, 키 0 → `code_of` 빈 글. **`keycode = KEY_J`·`physical_keycode = 0`인 누름 → 빈 글**(기술 T2 — 물리 키 없는 이벤트는 못 쓴다). Shift를 쥔 채 누른 J → `key:74`이고 `event_of`의 이벤트에 수식키가 없다.
  2. 예약: Esc → "멈춤", R → "다시 하기", F1 → "디버그", Space·Enter·KP Enter → "화면 넘기기", W·J·좌클릭 → 빈 글.
  3. 읽기(`Settings.normalize`와 새 인스턴스): `controls` 없음 → 처음 값, `controls_repaired` 거짓. `{"attack": "key:74"}` → J와 나머지 처음 값, 거짓(빠진 칸은 고친 것이 아니다). **`{"guard": ""}` → 막기 없음, 거짓. `{"attack": "", "guard": ""}` → 둘 다 없음, 거짓(빈 칸끼리는 겹침이 아니다). `{"attack": "mouse:2", "guard": ""}` → 공격 우클릭·막기 없음, 거짓.** `"attack": 5`·`"attack": "key:abc"`·`"attack": "mouse:4"` → 그 칸만 처음 값, 참. `"attack": "key:4194305"`(Esc) → 처음 값, 참. `{"attack": "key:83"}`(후퇴와 겹침) → 넷 모두 처음 값, 참. 모르는 칸 `"dodge"` 남음. 깨진 JSON → 처음 값, 오류 줄 없음.
  4. 분리(S01 T97-3의 꼴): 조작을 바꿔 적은 뒤 테스트 세이브(`user://bravi_test_save_S03.json`)의 바이트가 그대로이고 세이브에 `controls`가 없다. 세이브를 새 1일차로 덮어쓰고 지워도 설정 파일의 `controls`가 그대로다.
  5. 쓰기: 음량만 바꿔 적은 파일에 `controls`가 없다. 조작을 바꿔 적으면 넷이 있고, 새 인스턴스가 읽으면 InputMap의 `attack`이 J 하나다. 막기가 빈 채 적으면 `"guard": ""`이고, 새 인스턴스가 읽으면 InputMap의 `guard` 이벤트가 0개이고 액션은 있다(`InputMap.has_action`).
  6. 격리: 자동 로드 `/root/Settings`가 있으면 `path`가 빈 글이고 `controls`가 처음 값이고 InputMap의 넷이 처음 값이다(러너가 `detach_for_run`을 불렀다).
- **T101 "조작 바꾸기: 겹치면 비우기, 탭, 실제 입력, 멈춤, 안내"**:
  1. `set_control`: 공격 → J `bound`, `changed(&"controls", &"attack")` 한 번, InputMap 공격 = J. 막기 → J `cleared`·`other` 공격, 공격 = `""`(InputMap 이벤트 0개), `changed` 둘. 공격 → Esc `reserved`·`use` "멈춤", 아무것도 바뀌지 않음, `_dirty` 그대로. 공격 → `""` `invalid`. 같은 값 `same`. 빈 공격 → K(빈 키) `bound`. 넷이 각 단계 뒤 "서로 다르거나 비어 있다". `apply` 뒤 넷의 `Input.is_action_pressed`가 모두 거짓(빈 공격에서도 오류 줄 없음). `reset_controls` → 빈 것까지 처음 값, 다시 부르면 거짓.
  2. 탭(테스트 인스턴스, 처음 값에서): 열고 `TabControls`를 눌러도 `changed` 없음·파일 없음, `ControlsEmptyWarn` 숨음. `Bind_attack` → 버튼 글 "누른다…", 알림이 보인다. `_capture_msec`를 지금으로 두고 J 누름 → 버려지고(400 안) 기다림 그대로. `_capture_msec`를 1000 당기고: R → 알림에 "다시 하기", 기다림 그대로. 휠 → "쓸 수 없는 입력", 그대로. Esc → "그대로 두었다", 설정 화면이 남아 있다(`SettingsScreen`이 그대로 트리에).
     - **실제 버튼 위의 클릭**(기술 T1 (가)): 화면을 `_layout_now`(`pause_tests.gd` 136행의 꼴)로 놓은 뒤 버튼의 가운데를 뷰포트 → 창 좌표로 바꿔 누름·뗌을 보낸다(T24·T98의 `_send_mouse_*` 꼴).
       - 양성 대조: 기다림 밖에서 `ControlsReset`의 가운데를 클릭 → 알림 "이미 처음 값이다"(버튼이 눌렸다). 닿지 않으면(헤드리스 창에서 클릭이 버튼에 닿지 않는 때 — `pause_tests.gd` 235행의 INFO 꼴) `INFO T101 [2] 실제 클릭이 버튼에 닿지 않음 — 아래 셋은 건너뛰고 R3는 사용자 몫`을 찍고 아래 (가)~(다)를 건너뛴다(실패로 치지 않는다. 보고서 2번의 "직접 해 보실 것"에 R3 한 줄을 더한다).
       - (가) 같은 칸: `Bind_guard` → `_capture_msec` 당기고 `Bind_guard`의 가운데를 클릭 → 막기 = 좌클릭으로 잡혔고 알림 "겹쳤다 — 막기: 좌클릭 · 공격은 이제 비었다", **기다림이 끝나 있다**(잡은 누름이 새어 GUI에 닿았다면 뗌에서 `Bind_guard`가 눌려 기다림이 다시 열린다 — 이 단언이 그것을 잡는다), `Bind_guard` 글 "좌클릭"·`Bind_attack` 글 "없음", `ControlsEmptyWarn`이 보이고 "공격"을 담는다, 파일에 `"attack": ""`.
       - (나) 다른 버튼: `ControlsReset` → 처음 값. `Bind_attack` → `_capture_msec` 당기고 `ControlsReset`의 가운데를 클릭 → 기다림이 취소되고 `ControlsReset`이 눌렸다(알림 "이미 처음 값이다"), 공격 그대로 좌클릭, `changed` 없음. `Bind_attack` → 당기고 `TabAudio`의 가운데 → 취소되고 소리 탭(`VolumeSlider`가 있다). `TabControls` → `Bind_attack` → 당기고 `SettingsClose`의 가운데 → 취소되고 화면이 닫혔다.
       - (다) 빈 곳: 다시 열고 `Bind_guard` → 당기고 판 안의 버튼이 아닌 자리(제목 줄) 클릭 → 막기 = 좌클릭, 공격 빔, 기다림 끝.
     - 우클릭은 기다리는 동안 다른 버튼 위에서 눌러도 잡힌다(`Bind_attack` → `ControlsReset` 위 우클릭 → 공격 = 우클릭, 막기 빔). `SettingsClose` → 닫힌다(빈 동작이 있어도 막지 않는다). 다시 열고 조작 탭 → 경고가 보인다. `ControlsReset` → 처음 값, 알림, 경고 숨음. `controls_repaired`가 참인 인스턴스로 열면 조작 탭에 "읽을 수 없는 조작" 알림, 두 번째 열면 없다.
  3. 실제 입력(연습 결투 `Plain.of(바르톨로)`, 시드 1, `mouse_aim_enabled` 거짓, T24의 `_send*` 꼴): 공격 → J, 막기 → G, 전진 → Up(방향키 — GUI 이동 키가 결투에서 먹히지 않는지), 후퇴 → K. J → WINDUP. 좌클릭 → 사건 없음(공격이 아니다). G 누름 → GUARD, G echo 누름 → `guard_enter_time` 그대로, G 뗌 → 막기 풀림. Up을 보내기 전에 `_tree.root.gui_get_focus_owner() == null`을 단언한다(기술 T1 (나). 아니면 실패 글에 초점 가진 노드의 경로를 적는다 — 그 노드가 결투 씬 밖(다른 묶음이 남긴 노드)이면 테스트의 정리 문제이고 방향키를 예약으로 돌리지 않는다, R4). Up → 한 단계 전진, K → 후퇴. W·S → 아무 일 없음. 그다음 공격을 비운 판(막기 → J로 `cleared`): J → GUARD, 좌클릭·J 어느 것도 WINDUP이 되지 않음, 오류 줄 없음.
  4. 멈춤과 바꾸기(같은 판, 처음 값으로 돌린 뒤 전진만 Up으로): 우클릭 누름(GUARD) → Esc(멈춤) → `PauseSettings` → `TabControls` → `Bind_guard` → `_capture_msec` 당기고 G → **곧바로 InputMap의 `guard`가 G 하나**(기술 비차단, 받음) → `SettingsClose` → 우클릭 뗌(이제 막기가 아니다) → Esc(계속). `core.guard_held` 거짓, `Input.is_action_pressed(&"guard")` 거짓(막기가 붙지 않았다). 대기 중 좌클릭 → `ATTACK_START` 없음, `swallowed_attacks` +1(공격은 아직 좌클릭). 대기를 당겨 끝낸 뒤 G → GUARD. **이 판(멈춤 → 설정 → 닫기 → 계속을 지난 판)에서 `gui_get_focus_owner() == null`을 단언하고 Up → 한 단계 전진**(기술 T1 (나) — 게임의 길에서 초점이 남지 않는지).
  5. 왼쪽 버튼의 대기(결정 522 (나)): 막기 → 좌클릭(공격 `cleared`) → 공격 → J로 둔 판. Esc → Esc(대기) → 좌클릭 누름·뗌 → `guard_held` 거짓, 사건 수 그대로. J → `swallowed_attacks` +1. 좌클릭 누름(쥔 채) → 대기를 당겨 `_physics_process` 한 번 → `guard_held` 참(대기 끝의 맞추기). 막기가 빈 판에서 Esc → 우클릭 누름 → Esc → 대기 끝 → `guard_held` 거짓, 오류 줄 없음. 기본 묶음에서 대기 중 우클릭 누름 → 지금처럼 GUARD(T98 그대로). 4·5는 멈춤 화면이 자동 로드 `/root/Settings`를 바꾸므로(없으면 T97-9의 대역) 끝에 그 `detach_for_run()`으로 되돌린다(결정 523).
  6. 안내: 처음 값에서 `help_text`의 첫 줄이 옛 글 "좌클릭 공격 · 우클릭 막기 (떼고 있다가 고리가 띠에 들어올 때 누르면 패리) · 마우스 위치로 방향·높이 · W/S 간격 · R 다시 하기 · Esc 멈춤 · F1 디버그"와 같고 "비어 있는 동작"이 없다. 공격 J·전진 Up·후퇴 K → "J 공격", "Up/K 간격", 엉킴 줄 "물러난다(K)", 런지 줄 "물러나(K) 멀리에서 J". 공격을 비우면 → "— 공격", 런지 줄 "멀리에서 —", 첫 줄 끝 "비어 있는 동작: 공격 — 설정의 조작 탭에서 준다". 처음 화면(저장 없음): 도움말을 열어 "좌클릭 공격" → 닫고 공격을 J로 → 다시 열면 "J 공격"(다시 지었다), `HelpScreen`은 하나. 결투: 처음 값의 `start_duel` 뒤 HUD 기록 글에 "비어 있는 동작"이 없다. 막기를 비운 뒤 `start_duel` → 기록 글에 "비어 있는 동작: 막기", `core.record`의 사건 수는 처음 값의 판과 같다(0).
- 완료 확인: 기계적 확인 다섯. 기존 테스트의 diff가 위의 기대값 둘과 덮개 넘기기뿐(검사 줄을 지우지 않았다).

**작업 6. 찍기** (Sonnet. `tests/ui_shots.gd`, `tests/run_ui_shots.ps1`)
- 새 장: `settings-controls`(저장 없는 처음 화면에서 설정 → 조작 탭, 처음 값), `settings-controls-empty`(그 위에서 `Bind_guard` → 좌클릭으로 공격이 빈 모습 — 알림·"없음"·경고가 함께 뜬 가장 긴 꼴). 장을 찍은 뒤 자동 로드의 `reset_controls()`(쓰기는 꺼져 있다). 장 수 22 → 24, `$count`와 6·7행 머리 주석(ASCII). 새 장은 `wearhit` 판정 목록(S02의 새 장 판정)에 든다.
- 완료 확인(메인, diff): 장 목록 두 줄, 판정 목록, `run_ui_shots.ps1`이 ASCII.

**작업 7. verifier의 확인** — V1을 넘기고, 통과하면 메인이 격리 파일을 적고 V1b를 넘긴 뒤 그 파일을 지운다. 실패하면 로그의 줄로 가려 범위·규칙을 바꾸지 않는 오류만 고쳐(Sonnet) 다시 맡긴다. 통과하면 커밋한다.
- 메인이 읽는 장(1280): `settings-controls`·`settings-controls-empty`·`help`. 넷의 줄·처음 값으로·흐린 글·알림·경고가 판 안에 들고 잘리지 않는지("없음"이 빈 자리로 읽히는지), 탭 둘이 한 줄에 서는지, 도움말 첫 줄이 지금과 같은지.

**작업 8. 문서와 커밋**
- `docs/DECISIONS.md` "계획 S03"(517~524와 실행 중에 정한 것, Q1~Q3의 답), `CLAUDE.md`(3장 조작 표 아래 "공격·막기·전진·후퇴의 키·버튼은 설정의 조작 탭에서 바꾼다(예약: Esc·R·F1·Space·Enter. 다른 동작의 키를 주면 그 동작은 빈다 — 탭·도움말·결투 시작이 알린다)" 한 줄, 5장 "지금 만든 범위"의 설정에 조작 탭 한 마디, 8장 폴더에 `scripts/controls.gd`, 9장 설정 갈래 줄에 S03), `docs/HANDOFF.md` 1번(다음은 S04), 보고서 `docs/reports/S03-rebind-controls.md`(10장 형식. 2번에 아래 "직접 해 보실 것").
- 완료 확인: `DECISIONS.md`에 `^517\.`~`^524\.`이 하나씩, `git status`가 깨끗하다.

## 맡길 확인

- **V1 (verifier, 작업 6 뒤)** `tests/verify.ps1 -Shots "$env:TEMP\bravi-S03\after"` → `VERIFY: OK`, `ALL PASS 101/101`(오류·경고 0), 스모크 OK, 가져오기 오류 0, 장 수 상대 57·UI **24**·패턴 38, 새 장의 `wearhit` 0, 로그에 `RUNNER 설정: … 조작을 처음 값으로` 한 줄. 실행 **전후**로 `user://`의 `bravi_settings.json`·`bravi_playtest_settings.json`·`bravi_save.json`이 생기거나 바뀌지 않았고(S01 V1의 꼴, verifier는 읽기만 한다), 테스트 파일 `bravi_test_settings_S03.json`·`bravi_test_save_S03.json`이 남지 않았다.
- **V1b 격리의 시험 (verifier, V1 뒤. 기술 T3)**: 따로 둔 격리 파일 `user://bravi_iso_settings_S03.json`을 **메인이** V1b를 맡기기 전에 적는다 — 내용 `{"version": 1, "controls": {"attack": "key:74", "guard": "", "step_forward": "key:4194320", "step_back": "key:75"}}`(공격 J, 막기 없음, 전진 Up, 후퇴 K). 자리는 S01 V1이 쓴 프로젝트의 `user://` 폴더(`%APPDATA%\Godot\app_userdata\` 아래 프로젝트 이름의 폴더). 사용자의 `bravi_settings.json`·확인용 `bravi_playtest_settings.json`은 건드리지 않는다.
  - verifier의 명령 하나: `$env:BRAVI_SETTINGS_PATH = 'user://bravi_iso_settings_S03.json'; powershell -ExecutionPolicy Bypass -File tests/verify.ps1 -Only tests,smoke,ui,pattern`(`verify.ps1` 30행은 이미 정해진 환경 변수를 그대로 쓴다) → `VERIFY: OK`, `ALL PASS 101/101`, 스모크 OK. 이 파일의 키가 걸린 채로도 테스트·스모크·찍기가 처음 값으로 돈다(결정 523).
  - verifier는 명령과 읽기 전용 전후 비교만 한다: 격리 파일의 바이트가 전후 같다(테스트가 적지 않았다), V1의 세 파일도 전후 같다.
  - V1b 보고를 받은 뒤 **메인이** 격리 파일을 지운다. 작업 7의 커밋 전에 지운 것을 확인한다(`user://`는 저장소 밖이다).
- **창의 확인은 사용자가 직접 한다**(Q3 "나". playtester를 부르지 않는다) — 보고서 2번 "직접 해 보실 것":
  1. 설정 → 조작에서 공격을 다른 키(예: J)로, 그다음 전진에 후퇴의 키(S)를 준다: 후퇴가 "없음"이 되고 알림과 경고가 뜨는가. 도움말에 "J 공격", "S/— 간격"과 "비어 있는 동작: 후퇴"가 보이는가.
  2. 연습 결투에서 J가 공격, 좌클릭은 아무 일 없음, S가 전진이고 후퇴는 어떤 키로도 안 되는가. 결투가 시작할 때 기록 줄에 "비어 있는 동작: 후퇴"가 뜨는가.
  3. 게임을 끄고 다시 켜도 바꾼 키와 빈 후퇴가 남는가.
  4. 결투 중 멈춤 → 설정 → 조작 → 처음 값으로 → 계속: 좌클릭 공격·W/S가 바로 돌아오는가. "계속"을 더블클릭해도 공격이 나가지 않는가.
  5. 마음에 드는 키(예: 막기를 Shift나 옆 버튼)로 한 판: 쥐고 떼는 손맛이 마우스와 같은가, 쓸 수 없는 키의 알림과 "없음"이 알아보기 쉬운가.
  6. 기다리는 동안 "돌아간다"나 "소리" 탭을 누르면 기다림만 취소되고 그 버튼이 눌리는가(아무 키도 바뀌지 않는가), 좌클릭을 주려면 그 칸을 다시 누르면 되는 것이 알림 글로 알 만한가. (T101-2의 양성 대조가 INFO로 건너뛰었으면 보고서에 "자동으로 못 본 것"이라 함께 적는다 — R3.)

## 위험

- **R1 테스트가 플레이어의 키로 돈다**: 결정 523(러너·스모크·결투를 띄우는 찍기·통계가 `detach_for_run`)과 V1b(따로 둔 격리 파일 — 빈 막기까지 — 을 `BRAVI_SETTINGS_PATH`로 건 실행)가 본다. 격리 파일은 메인이 적고 지우며, 사용자·확인용 설정 파일은 어느 단계도 적지 않는다. 새 `Settings` 인스턴스를 붙이거나 `set_control`을 부르는 테스트는 끝에 InputMap을 되돌린다 — 되돌리지 않으면 뒤의 T98(`pause_tests`, `controls_tests`·`settings_tests` 뒤에 돈다)이 바뀐 키로 돈다. T100-6이 러너의 격리를 본다.
- **R2 눌린 액션 상태가 남는다**(바꾸는 순간 쥐고 있던 버튼): `apply_codes`가 넷을 놓아 준다(결정 517). T101-1·4가 본다.
- **R3 기다림의 입력이 새어 나간다**(잡은 좌클릭이 아래 버튼을 누르거나, 잡은 Esc가 설정 화면·멈춤 화면을 닫음): 화면의 `_input`이 GUI보다 먼저 먹고 잡은 누름의 뗌도 먹는다(결정 520). T101-2가 잡은 좌클릭을 **실제 버튼(`Bind_guard`) 위로** 보내 기다림이 다시 열리지 않는지로 본다 — 새면 실패한다. 헤드리스에서 클릭이 버튼에 닿지 않으면 양성 대조가 INFO로 알리고 이 확인은 사용자의 "직접 해 보실 것" 6으로 간다. 다른 버튼 위의 좌클릭이 취소하고 그 버튼을 누르는 것(디자인 비차단)도 같은 자리에서 본다.
- **R4 GUI의 이동 키가 결투에서 먹힌다**(방향키·Tab을 동작에 줄 때 초점 가진 Control이 있으면): 결투 화면에는 초점을 가질 Control이 없다(HUD는 Label·Panel이다). T101-3(새 판)과 T101-4(멈춤 → 설정 → 닫기 → 계속을 지난 판)가 Up을 보내기 전에 `gui_get_focus_owner() == null`을 단언하고 실패하면 그 노드를 적는다. 그 노드가 **결투 씬이나 멈춤·설정 화면의 것**(게임의 길)일 때만 그 키들을 예약에 더하는 쪽으로 고치고(결정 517의 목록 한 줄, 보고서 3번), 러너에 남은 다른 묶음의 노드면 테스트의 정리를 고친다.
- **R5 키 이름이 자판 배열을 따르지 않는다**: 물리 자리의 미국식 이름이다(결정 517). 한국 자판에서는 같고, 다른 배열은 BACKLOG로.
- **R6 도움말 말씨가 바뀐다**: 엉킴·런지의 두 줄이 "S로 물러난다" → "물러난다(S)"로 바뀌고, 빈 동작은 "—"로 쓴다(결정 521). 디자인 검토와 `help` 장, 사용자의 "직접 해 보실 것" 1로 본다.
- **R7 대기의 넓힘이 S02를 바꾼다**: 기본 묶음에서 결정 522의 (나)는 (가)와 같고 대기 끝의 맞추기는 다를 일이 없다 — T98이 그대로 통과해야 한다.
- **R8 빈 동작으로 판을 치를 수 없게 된다**(막기나 공격이 빈 채 하루 결투에 들어감): 막지 않는 것은 사용자의 Q1 답을 따른 결정이다(결정 519). 알림 셋(탭의 경고, 도움말, 결투 시작의 기록 줄)과 멈춤 → 설정의 길로 판 안에서 고칠 수 있다. 사용자의 "직접 해 보실 것" 2에서 기록 줄이 눈에 띄는지 보고, 약하면 그 한 곳(결투 시작)에 더 센 표시를 붙인다(되돌리기 쉽다).
- **R9 창에서 아무도 실제 키를 눌러 보지 않은 채 보고한다**(Q3 "나"): 실제 입력 경로는 T101-2~5가 `Input.parse_input_event`로 지나고, 창에서만 보이는 것(진짜 키보드의 물리 키, 다시 켜기)은 보고서 2번에 사용자 몫으로 분명히 적는다.

## 검토 전에 물을 것

- **답 받음(2026-11-27, 선택 창)**: Q1 "다 — 받고 다른 쪽은 비운다"(권함은 "가"였다), Q2 "가 — 키보드 키 + 마우스 버튼 다섯, 휠 없음", Q3 "나 — 사용자가 직접"(작업 8a·8과 playtester를 뺐다).

| 물음 | 고른 답 | 계획에 미친 것 |
|---|---|---|
| Q1 같은 키를 다른 동작에 줄 때 | 다 — 받고 다른 쪽은 비운다 | 빈 부호 `""`, 결정 518의 읽기(빈 값은 유효), 결정 519(막지 않고 셋에서 알림), 520의 "없음"·경고, 521의 "—"·`HELP_EMPTY`·결투 기록 줄, T100-3·5, T101-1~6의 빈 동작 줄, 장 `settings-controls-empty`, R8 |
| Q2 줄 수 있는 입력 | 가 | 결정 517 그대로 |
| Q3 창에서만 보이는 확인 | 나 | 작업 8a·8을 빼고 "직접 해 보실 것" 다섯, R9, `tools/`·`.claude/agents/`를 고치지 않음 |

- planner가 임시로 정한 것(되돌리기 쉽다): 부호의 꼴 `mouse:N`/`key:N`/`""`과 물리 키(517), 키 이름은 미국식 물리 이름(517), 예약은 받지 않고 쓰임을 알림(517), 겹친 파일은 넷 모두 처음 값이고 빈 칸은 겹침이 아님(518), 조작을 바꾸지 않은 파일에는 `controls`를 적지 않음(518), 빈 동작은 막지 않고 셋에서 알림(519), 기다림의 400밀리초와 Esc 취소, 다른 버튼 위의 좌클릭은 취소하고 그 버튼이 눌림(520, v3), 토씨 없는 두 줄의 말과 빈 자리 "—"(521), 대기 중 왼쪽 버튼 버리기와 끝의 막기 맞추기(522).

## 계획 뒤의 차례

S03 보고 뒤 사용자가 "다음 진행"이라 하면 S04(화면 모드 · 창 크기)를 쓴다. S04에 넘기는 것:
- 화면 전환 키(예: F11, Alt+Enter)를 더하면 `Controls.RESERVED`에 그 액션 한 줄(결정 517) — 바꾼 키와 겹치는 파일은 읽을 때 처음 값으로 돌아간다(결정 518).
- `display` 갈래도 `controls`처럼 "바꾸지 않았으면 적지 않는다"를 따를지(결정 518).
- 찍기·테스트는 `detach_for_run`(결정 523)에 화면 설정도 처음 값으로 두는 몫을 더한다 — 찍기 도구는 1280×720 창으로 돈다(S01 확장 자리 표).
- S04의 [플레이] 확인(여러 창 크기의 커서와 조준칸)은 S01 표에서 playtester 몫이었다 — Q3 "나"가 S04에도 이어지는지는 S04의 검토 전에 묻는다.

## 검토 대응 기록

- v1 → v2(검토 전, 사용자 답 반영): 근거·"검토 전에 물을 것"에 답 받음 줄, 결정 517(빈 부호 `""`·`TOPICS`·`is_valid`·`help_name`·`empty_actions`, `apply_codes`가 액션을 지우지 않음, 예약은 Q1 "다"에서도 받지 않음), 518(빈 값은 유효, 겹침 검사는 빈 값을 뺌, `set_control`의 `swapped` → `cleared`와 빈 글 `invalid`, 처음 값으로가 빈 것도), 519(맞바꾸기 → 받고 비우기, 막지 않고 셋에서 알림과 근거), 520(버튼의 "없음", `ControlsEmptyWarn`, 줄 높이 46 → 42·사이 10 → 8, 흐린 글을 처음 값으로 줄에, 닫기를 막지 않음), 521(빈 자리 "—", `HELP_EMPTY`, `add_note`와 결투 시작의 기록 줄), 522(빈 동작에서 대기·맞추기), 523(`set_control`을 부르는 테스트도 되돌림), 목표 1~5, 작업 1~3·5·6의 완료 확인과 빈 동작 줄, T100-1·3·5와 T101-1~6, 장 `settings-controls-swap` → `settings-controls-empty`, V1의 격리 파일에 빈 막기, 작업 8a·8(창 도구 `J`, playtester)과 V2를 빼고 V3과 합쳐 "직접 해 보실 것" 다섯, 작업 9 → 8, R6 보탬·R8·R9 새로, 넘지 않는 선에 playtester 없음과 `tools/`·`.claude/agents/`, S04에 넘기는 것 한 줄. 검토는 아직 없다.
- v2 → v3(1회차: 디자인 APPROVE · 기술 REVISE):
  - **T1 (기술, 실패할 수 없는 두 확인)**: 수용. (가) T101-2를 다시 짰다 — `_layout_now` 뒤 실제 버튼의 가운데로 보내고, 기다림 밖의 `ControlsReset` 클릭으로 양성 대조, 닿지 않으면 INFO와 사용자 몫("직접 해 보실 것" 6). 잡은 좌클릭을 `Bind_guard` 위로 보내 "기다림이 다시 열리지 않음"을 본다(새면 실패). (나) T101-3·T101-4에 `gui_get_focus_owner() == null` 단언과 실패 글의 노드 경로, T101-4(멈춤 → 설정 → 닫기 → 계속을 지난 판)에 Up. R3·R4를 그에 맞춰 고침(R4의 고침은 게임의 길의 노드일 때만).
  - **T2 (기술, 물리 키 없는 키)**: 수용(첫째 통과 조건 — 못 쓰는 입력). 결정 517 `code_of`, 작업 1의 완료 확인, T100-1의 `keycode = KEY_J`·`physical_keycode = 0` 사례.
  - **T3 (기술, 격리의 시험을 맡을 쪽)**: 수용. "맡길 확인"에 V1b — 따로 둔 `user://bravi_iso_settings_S03.json`을 메인이 적고 지우고, verifier는 `BRAVI_SETTINGS_PATH`를 건 `verify.ps1 -Only tests,smoke,ui,pattern` 한 명령과 읽기 전용 전후 비교만. V1의 전후 비교에 `bravi_playtest_settings.json`을 다시 넣음. 작업 7, R1.
  - 기술 비차단 넷: 모두 받음 — `detach_for_run`이 `controls_repaired`를 끔(결정 518), 결투를 띄우는 찍기·통계도 detach(결정 523, 작업 4), T101-4·5의 되돌림을 자동 로드의 `detach_for_run()`으로와 캡처 직후 "guard = G 하나" 단언(결정 523, T101-4·5), `apply_codes`는 바뀐 동작만 놓아 줌(결정 517·518).
  - 디자인 비차단(기다리는 동안의 좌클릭 함정): 받음. 결정 520 — 다른 버튼 위의 좌클릭은 기다림을 취소하고 먹지 않아 **그 버튼이 눌린다**(취소와 그 버튼의 일을 한 번에), 좌클릭을 주는 길은 그 칸이나 빈 곳, 알림 글 고침. 목표 1, T101-2 (가)~(다), "직접 해 보실 것" 6.
