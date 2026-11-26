# 계획 S01: 설정의 저장 기반 · 설정 화면 · 음량

- 버전: v3 (2026-11-26. 1회차 검토 — 디자인 APPROVE · 기술 REVISE(T1·T2) — 의 대응. HEAD `4017592`, 033b 끝, `ALL PASS 96/96`)
- 개발 단계: CLAUDE.md 9장의 단계와 **별개인 사용자 지시 작업**(설정·편의 갈래 S01~S04의 첫째). 9장의 단계를 넘기지도 닫지도 않는다. 차례(사용자 답 2026-11-26): **033b를 W-5까지 끝낸 뒤 S01~S04, 그 뒤 5단계**(Q-A·Q-B).
- 번호의 꼴: `S` + 두 자리. `NNN`은 9장 단계의 차례(028~038b, 다음은 033b 끝의 W-5 뒤 5단계)를 뜻하므로 그 줄에 끼우지 않는다. 결정 번호(`docs/DECISIONS.md`)와 테스트 번호(T)는 하나의 줄을 같이 쓴다(겹치지 않게).
- 근거:
  - 사용자 지시(2026-11-26) "설정·편의 기능 추가": 1 키·마우스 버튼 변경, 2 화면 모드·해상도, 3 음량(슬라이더 하나와 음소거, 움직일 때 막기 소리), 4 일시정지·Alt+Tab, 5 설정 메뉴·저장(타이틀과 일시정지 양쪽, 영업 세이브와 따로), 6 게임 종료. 범위 밖: 글자 크기, 고대비 — "나중에 붙이기 쉬운 구조인지만 tech-reviewer가 확인". [자동] 설정 저장이 영업 세이브와 분리, 중복 키, 일시정지 해제 클릭. [플레이] 창 크기·전체 화면에서 커서와 조준칸.
  - 지금 코드(읽음, HEAD `8e89883`. v3에서 `4017592` 기준으로 다시 본 줄: `tests/run_tests.gd` 66~73행, `tests/day_tests.gd` 527행, `tests/run_ui_shots.ps1` 6·7·29행, `scripts/economy/day_state.gd` 397행, `scripts/duel/beeper.gd` 69~71행):
    - `scripts/save_store.gd`: 경로와 Dictionary만 아는 JSON 읽기·쓰기(임시 파일에 적고 바꿔 끼움, 깨진 파일은 빈 Dictionary). 영업 세이브는 `GameSession.SAVE_PATH = "user://bravi_save.json"`, 테스트·확인용 덮어쓰기 `BRAVI_SAVE_PATH`(`tests/verify.ps1` 28행이 비어 있으면 `user://bravi_playtest_save.json`으로 둔다).
    - 자동 로드는 `GameSession` 하나(`project.godot`). 오디오 버스 배치 파일이 없다(Master 하나).
    - 소리: `scripts/duel/beeper.gd`(결투 씬의 노드, 사건별 사인파 `TONES`, `block` = 520 Hz 0.06초, 재생은 비공개 `_play(key)`, 플레이어 넷은 기본 버스 Master). 결투 밖에는 소리가 없다.
    - 처음 화면 `scripts/title.gd`: 저장 없음 — Proceed 400×84(440,360) · Practice 400×54(440,470) · Help 400×54(440,534) · 안내 글(600) · SaveUnreadable(636). 저장 있음 — Continue 480×84(400,330) · SaveInfo(422) · NewGame 400×50(462) · Practice 400×50(522) · Help 400×50(582) · 안내 글(642) · NewGameWarning(676). 도움말은 처음 열 때 만드는 덮개 `HelpScreen`(`MOUSE_FILTER_STOP`, `ui_cancel`로 닫음, 닫기 버튼에 초점).
    - 처음 화면을 보는 테스트: T58(`tests/save_tests.gd` 399·408·420행, 버튼 수 3·3·4), `tests/manuscript_tests.gd` 22·23행(`FRESH_BUTTONS`·`SAVED_BUTTONS`의 크기), `tests/day_tests.gd` 527행(버튼 수 `== 3`), `tests/ui_shots.gd`(장 15: `title`·`title-save`·`help` …)와 그 판정 `tests/run_ui_shots.ps1`(29행 `$count = 15`, 6·7행 머리 주석).
    - 영업 세이브의 칸(`DayState.saved_state()`, `day_state.gd` 397행): `version`·`day`·`money`·`owned`·`reputation`·`dice_seed`. `version`은 세이브에도 있다.
    - 테스트 러너(`tests/run_tests.gd` 66~73행)는 자동 로드 `GameSession`의 `save_path`를 비워 저장을 끈다. 트리 밖에서 만든 `GameSession`도 `save_path`가 빈 글이라 저장이 꺼져 있다(T57의 다). Settings에는 아직 이런 장치가 없다 — 결정 500이 같은 꼴을 둔다.
    - `Beeper._play`는 `_players`가 비어 있으면(`_ready` 전) `% 0`으로 런타임 오류다(69~71행).
    - 테마 `assets/ui/manuscript_theme.tres`는 `Panel`·`PanelContainer`·`Button`만 꾸민다. `HSlider`의 꼴은 없다(Godot 기본 회색). 033b가 이 테마와 `scripts/ui/`의 StyleBox를 바꾼다 — S01은 그 뒤에 시작하므로 그린 판·버튼 위에 짓는다.
    - 033b v3의 헤진 가장자리(033b 결정 498): 테마의 `PanelContainer` 가운데 짧은 변이 160 이상인 판은 판마다 정해진 자리가 헤지거나 찢긴다(글이 놓이지 않는 바깥 띠에만). S01의 설정 판(`Ui.add_panel`, 800×480)도 이 규칙을 받는다 — S01은 고칠 것이 없고, `settings` 장에서 보인다(작업 6). `ui_shots.gd`는 033b 뒤에 장마다 `wear,` 줄을 낸다.
    - 결투의 Esc는 `back` 액션(연습: 의뢰 선택으로, 하루: 듣지 않음) — S02의 일이다.
  - 결정은 **500부터**(033b가 488~499), 테스트는 T97부터(033b가 T96). 실행 때 `DECISIONS.md`·`run_tests.gd`의 마지막 번호를 다시 보고 그다음을 쓴다.

### 넘지 않는 선

- 메인은 Godot·테스트·게임을 실행하지 않는다. 자동 확인은 verifier(`tests/verify.ps1`). 코드 쓰기(`.gd`·`.ps1`·`.tscn`·테스트)는 Sonnet 하위 에이전트, 메인은 diff를 읽는다. 편집은 80줄 안쪽으로 나누고 HANDOFF 4번의 기계적 확인 다섯을 지킨다. 한글이 든 `.ps1`은 UTF-8 BOM(`verify.ps1`은 ASCII만 — 지금 꼴 그대로).
- 고치지 않는 것: 판정 코드(`scripts/duel/duel_core.gd` 등, `scripts/ai/`), `data/`, 영업 세이브의 형식과 `save_store.gd`, `GameSession`, 테마 `.tres`와 `scripts/ui/`의 StyleBox(033b의 것), `day_ui.gd`. **예외**: `scripts/duel/beeper.gd`에 공개 함수 하나(결정 504).
- 범위 밖(이 계획): 일시정지·포커스·게임 종료(S02), 키 바꾸기와 조작 탭(S03), 화면 모드와 화면 탭(S04), 글자 크기·고대비(만들지 않는다 — "확장 자리"만), 소리의 갈래 나누기(음악·효과음 — 5단계).

## 설정 갈래의 계획 목록 (S01~S04)

| 차례 | 계획 | 범위 | [자동] 확인 | [플레이] 확인 |
|---|---|---|---|---|
| 1 | **S01 설정의 저장 기반 · 설정 화면 · 음량** (이 계획) | 설정 파일(영업 세이브와 따로)과 자동 로드 `Settings`, 설정 화면의 틀(탭 목록), 소리 탭(음량 슬라이더·음소거·막기 소리 미리 듣기), 처음 화면의 "설정" | T97: 설정과 세이브의 분리, 새로 시작해도 남음, 깨진 파일, 버스 값 | 사용자가 소리를 듣는다(창의 playtester는 소리를 못 듣는다) |
| 2 | S02 일시정지 · 창 포커스 · 게임 종료 | 결투에서 Esc·포커스 잃음 → 일시정지(판의 시간·상대가 같이 멈춤), 일시정지 화면(계속 / 설정 / 나가기), "계속"의 클릭이 공격으로 들어가지 않음(막기 누름 상태도 다시 맞춤), 처음 화면의 "게임 종료", 영업 중에 나갈 때 "이어서 하면 N일차 아침부터"(창 닫기 단추·Alt+F4 포함). 연습 결투의 Esc(지금 바로 의뢰 선택으로)가 일시정지 화면의 한 버튼으로 옮겨 간다 | 일시정지 해제 클릭 ≠ 공격, 멈춘 동안 `core.time`·상대 상태 그대로, 돌아올 날의 글 | Alt+Tab 뒤 돌아오기(창에서만 보이는 것) |
| 3 | S03 키·마우스 버튼 바꾸기 | 조작 탭: 공격·막기·전진·후퇴 넷을 키 또는 마우스 버튼으로, 처음 값으로 되돌리기, 겹침 알림(예약된 Esc·R 등과의 겹침 포함), InputMap에 적용, 도움말과 결투 안내에 바뀐 이름 | 겹침을 잡는다, 저장·불러오기, InputMap, 도움말의 글 | 실제 키로 바꿔 한 판 |
| 4 | S04 화면 모드 · 창 크기 | 화면 탭: 창 / 테두리 없는 전체 화면, 창 크기 목록(모니터보다 큰 것은 뺀다), 전체 화면은 모니터 해상도. UI 기준 1280×720 그대로(남는 곳은 검은 띠) | 검은 띠가 있는 여러 화면비에서 화면 점 → 조준칸 셈이 맞다 | 여러 창 크기와 전체 화면에서 커서와 조준칸(사용자 지시의 [플레이], playtester) |

차례의 까닭(사용자 추천 순서를 그대로 둔다):
- S01이 먼저: 나머지 셋이 모두 설정 파일과 설정 화면 위에 선다.
- S02가 둘째: 시간이 흐르는 결투에서 Alt+Tab으로 판을 잃는 것이 가장 아픈 불편이다. 그리고 S03이 막아야 할 예약 키(Esc = 일시정지)와 "다시 돌아온 입력을 거르는 길"을 S02가 정한다.
- S03이 셋째: S02의 일시정지 화면에서도 조작 탭을 연다.
- S04가 마지막: 지금도 창은 `canvas_items` 늘이기 · 비율 유지라 조준은 뷰포트 좌표로 셈한다(`duel_scene.gd` `_update_aim_from_mouse`). 그래서 어긋날 위험이 가장 낮고, 비싼 [플레이] 확인(playtester)을 갈래 끝에 한 번 쓴다.
- S04 뒤에 5단계(사운드)의 첫 계획(Q-B "가").

## 목표와 범위

**확인할 결과**:

1. 처음 화면(저장 있음·없음 둘 다)에 "설정"이 있고, 누르면 설정 화면이 덮인다. 설정 화면에는 탭 줄(이 계획에서는 "소리" 하나)과 음량 슬라이더·음소거 버튼·닫기가 있다. Esc와 닫기 버튼으로 닫히고 초점이 "설정" 버튼으로 돌아온다.
2. 슬라이더를 움직이면 막기 소리가 짧게 난다(빠르게 끌어도 0.12초에 한 번까지, 홈을 한 번 누르면 한 번). 화면을 열기만 하면 소리가 나지 않는다. 음소거면 나지 않는다. 음량과 음소거가 결투의 모든 소리에 걸린다(Master 버스).
3. 설정은 `user://bravi_settings.json`에 영업 세이브와 따로 적힌다. 가게를 새로 시작해도(세이브를 덮어써도, 지워도) 설정은 그대로이고, 게임을 다시 켜면 그 값이 처음부터 걸린다. 깨진 설정 파일은 처음 값으로 돌아가고 오류 줄이 없다.
4. 테스트와 찍기는 어떤 설정 파일도 적지 않는다: `tests/verify.ps1`은 확인용 경로(`BRAVI_SETTINGS_PATH`)를 쓰고, 그 아래의 러너·찍기는 자동 로드 `Settings`의 쓰기를 끈다(`path`를 비운다). 그래서 `run_tests.ps1`·`run_ui_shots.ps1`을 따로 돌려도 플레이어의 파일이 바뀌지 않는다. 설정 화면은 열고 닫기만 하면 적지 않는다.
5. 판정·데이터 그대로: `scripts/ai/`·`data/`와 `scripts/duel/`의 `beeper.gd` 밖 `git diff` 0줄. `ALL PASS 97/97`(033b의 T96 뒤 — 번호가 밀렸으면 그 수), 스모크 OK, 가져오기 오류 0, UI 찍기 15 → 16(새 `settings`).

재미는 바뀌지 않는다. 판정은 테스트와 사용자의 귀다.

## 설계 결정

500. **설정 파일과 자동 로드 `Settings`**:
     - 새 `scripts/settings.gd`(`extends Node`, `class_name` 없음)를 `project.godot`의 자동 로드에 `Settings`로 **`GameSession` 앞에** 넣는다(첫 화면 전에 값이 걸린다). 다른 스크립트는 `/root/Settings`로 찾는다(`GameSession`과 같은 꼴, 없으면 처음 값).
     - 경로 `SETTINGS_PATH := "user://bravi_settings.json"`, 덮어쓰기 `SETTINGS_ENV := "BRAVI_SETTINGS_PATH"`. 읽기·쓰기는 `save_store.gd` 그대로(새 저장 코드 없음). 영업 세이브와 파일·환경 변수·코드가 모두 다르다: `GameSession`은 설정을 모르고 `Settings`는 세이브를 모른다.
     - 파일의 꼴: `{"version": 1, "audio": {"volume": 100, "muted": false}}`. 칸은 **갈래(section)별 Dictionary**다: `audio`(S01), `controls`(S03), `display`(S04), `view`(글자 크기·고대비 — 만들지 않는다, 확장 자리).
     - 읽기: `normalize(raw: Dictionary) -> Dictionary`(정적)가 아는 칸만 고르고 범위를 맞춘다(음량은 0~100으로 자르고 걸음 5에 `snapped`, 숫자가 아니면 처음 값, `muted`가 bool이 아니면 거짓). **모르는 갈래와 칸은 그대로 남긴다**(나중 계획이 쓴 칸을 앞 판의 게임이 지우지 않는다). `version`이 없거나 1보다 크면 그대로 읽고 아는 칸만 쓴다. 다시 적을 때 `version`은 읽은 값과 1 가운데 큰 쪽(뒤 판이 쓴 파일을 1로 내려 적지 않는다).
     - **경로를 정하는 때**(`title.gd`의 `saved` 꼴): `var path := ""`. `_ready`에서 **`path`가 빈 글일 때만** `BRAVI_SETTINGS_PATH`(비어 있지 않으면) 또는 `SETTINGS_PATH`로 채우고 그 파일을 읽는다. 밖에서 넣은 `path`는 덮어쓰지 않는다. 테스트는 `load("res://scripts/settings.gd").new()`에 `path`를 넣은 **뒤에** 트리에 붙인다.
     - 쓰기: `save() -> bool`. 바뀐 것이 없으면 적지 않는다(`_dirty`). **`_ready` 뒤에 `path`가 빈 글이면 적지 않는다**(쓰기가 꺼진 상태 — `GameSession.save_path`를 비우는 꼴과 같다). 러너와 찍기가 자동 로드를 이렇게 끈다(작업 5·4).
     - 설정 화면이 처음 값을 넣을 때는 `set_value_no_signal`·`set_pressed_no_signal`로 넣고 신호는 그 뒤에 잇는다: 열기만 해서는 `changed`·미리 듣기·`_dirty`가 생기지 않는다(T97-8의 가).
     - 신호 `changed(section: StringName, key: StringName)`: 값이 바뀔 때마다. 지금 듣는 곳은 설정 화면뿐이고, S03·S04·확장 자리가 같은 길을 쓴다.
     - `tests/verify.ps1`: `BRAVI_SAVE_PATH`의 줄 옆에 `if (-not $env:BRAVI_SETTINGS_PATH) { $env:BRAVI_SETTINGS_PATH = 'user://bravi_playtest_settings.json' }`와 머리 주석 한 줄(ASCII). `play.ps1`은 고치지 않는다(사용자의 설정을 쓴다).
501. **음량의 값과 거는 길**:
     - `volume` 0~100(슬라이더 걸음 5), 처음 값 **100**(지금 결투의 소리 크기 그대로 — 지금 플레이어에게 아무것도 바뀌지 않는다). `muted` 처음 값 거짓.
     - `apply_audio()`: Master 버스(색인 `AudioServer.get_bus_index("Master")`)에 `set_bus_volume_db(linear_to_db(volume / 100.0))`(0이면 −80), `set_bus_mute(muted)`. 시작할 때 `_ready`에서 한 번, 값이 바뀔 때마다.
     - 곡선은 진폭 그대로(50 = −6 dB). 작게 느껴지면 값 하나(제곱 곡선)로 바꾼다 — 사용자의 귀로 본다(보고서 2번). 임시 결정, 되돌리기 쉽다.
     - 5단계에서 음악·효과음 버스가 생기면 그 둘을 Master 아래에 두고 이 슬라이더는 Master로 남는다(갈래별 슬라이더는 5단계에서 정한다).
502. **설정 화면** `scripts/ui/settings_screen.gd`(`extends Control`, 코드로 짓는다 — 도움말의 덮개 꼴):
     - `static func open(parent: Control, settings: Node) -> Control`: 덮개(`PRESET_FULL_RECT`, `MOUSE_FILTER_STOP`, 벽은 `Ui.add_background`), 가운데 판 `Ui.add_panel(Rect2(240, 110, 800, 480))`, 제목 "설정"(28), **탭 줄**, 탭의 몸, 닫기 버튼 "돌아간다"(200×54, (540, 636) — 도움말과 같은 자리). 신호 `closed`.
     - 탭은 **목록 하나**로 짓는다: `const TABS: Array` = `[[&"audio", "소리", &"_build_audio"]]` — 셋째 칸은 짓는 메서드의 **이름**이고 `call(name, 몸)`으로 부른다(`const`에 메서드 Callable은 담을 수 없다). S03은 `[&"controls", "조작", …]`, S04는 `[&"display", "화면", …]`을 이 목록에 한 줄씩 더한다. 탭 버튼은 테마의 `Button`(토글, `ButtonGroup`) — 새 꼴이 필요 없다. 탭이 하나여도 줄은 보인다(갈래의 자리를 보인다).
     - 소리 탭: 이름 줄 "음량" + 값 "100"(오른쪽), `HSlider`(0~100, 걸음 5, 폭 560 높이 32, 이름 `VolumeSlider`), 토글 버튼 `MuteButton`("소리를 끈다" ↔ "소리를 켠다", 280×50), 음소거 중이면 흐린 글 한 줄 "소리를 끈 상태다 — 미리 듣기도 나지 않는다". 슬라이더는 초점이 있을 때 키보드 ←→도 받는다(Godot 기본).
     - 슬라이더의 꼴: 테마를 고치지 않고(033b) 이 스크립트 안에서 `add_theme_stylebox_override`로 `slider`(잉크 `Ui.INK` 4화소 줄, `StyleBoxFlat`), `grabber_area`·`grabber_area_highlight`(`Ui.ACCENT`), 손잡이 아이콘 `grabber`·`grabber_highlight`(코드로 만든 지름 20의 원 `ImageTexture`, 잉크 테두리에 양피지 속)를 건다. 033b가 끝난 테마의 판·버튼과 같이 놓여 어색하면 판 없이 보고서에 장으로 싣고 BACKLOG에 둔다(그린 손잡이는 이 계획 밖).
     - 닫기: 닫기 버튼, `ui_cancel`(Esc). 닫을 때 `settings.save()`. 연 쪽은 `closed`에서 초점을 되돌린다.
     - **일시정지 아래에서도 돈다**(S02를 위해): 덮개의 `process_mode = PROCESS_MODE_ALWAYS`, 시간 재기는 `Time.get_ticks_msec()`만(타이머·`_process`의 delta를 쓰지 않는다).
     - 처음 열 때 만든다(도움말과 같은 까닭, 결정 323: 열기 전 화면의 노드가 늘지 않는다).
503. **처음 화면의 "설정"**(`scripts/title.gd`): 도움말 버튼 자리를 둘로 나눈다 — `Help` 195 폭 · `Settings` 195 폭, 사이 10(저장 없음: y 534 높이 54, 저장 있음: y 582 높이 50). 다른 자리·크기는 그대로. 버튼 수가 저장 없음 3 → 4, 저장 있음 4 → 5. 누르면 `SettingsScreen.open(self, /root/Settings)`, 닫히면 `Settings` 버튼에 초점. 덮개가 열린 동안 Esc는 덮개가 먹는다(도움말과 같은 꼴). 머리 주석의 "버튼은 셋"을 고친다.
     - S02가 "게임 종료"를 더할 자리는 S02가 정한다(이 계획은 비워 두지 않는다).
504. **막기 소리 미리 듣기**: `beeper.gd`에 공개 `func play(key: StringName) -> void` 하나를 더한다 — `_players`가 비었거나(`_ready` 전) `TONES`에 없는 키면 아무것도 하지 않고, 아니면 `_play`. 판정과 결투의 사건 처리는 그대로다. 설정 화면이 `Beeper.new()`를 자식으로 붙여 `play(&"block")`. 슬라이더의 `value_changed`마다 부르되 직전 소리에서 **120밀리초 안이면 거르고 "거른 값이 있다"(`_preview_pending`)를 켠다**(끌 때 소리가 쌓이지 않게). 소리가 나면 그 표시를 끈다. `drag_ended`에는 **그 표시가 켜져 있을 때만** 한 번 낸다(마지막 값을 들려주되, 홈을 한 번 누를 때 `value_changed`와 `drag_ended`가 함께 나서 "탁탁" 두 번 울리지 않게). 음소거면 부르지 않는다. 세는 칸 `preview_count`(테스트가 본다 — 헤드리스는 소리를 들을 수 없다).
505. **적는 때**: `drag_ended`, 음소거 토글, 화면 닫기에서 `save()`(바뀐 것이 있을 때만). 키보드로 슬라이더를 옮긴 값은 닫을 때 적힌다. 값을 걸기(`apply_audio`)는 바뀔 때마다 바로.
506. **T97 "설정 파일"**(새 `tests/settings_tests.gd`, `tests/run_tests.gd`에 한 줄): 작업 5.

## 확장 자리 (만들지 않는다 — tech-reviewer가 붙이기 쉬운지 본다)

| 나중 일 | 붙일 자리 | 이 계획이 미리 해 두는 것 | 그때 고칠 곳(지금 고치지 않는다) |
|---|---|---|---|
| 조작 탭(S03) | `Settings`의 `controls` 갈래, 설정 화면 `TABS`의 한 줄 | 모르는 갈래를 지우지 않는 읽기·쓰기, `changed` 신호, 탭 목록 | 시작할 때 InputMap에 거는 `apply_controls()`, 도움말 글(`DuelHud.help_text`)이 InputMap의 이름을 읽게 |
| 화면 탭(S04) | `display` 갈래, `TABS`의 한 줄 | 위와 같음, 설정은 첫 화면 전에 걸린다(자동 로드 차례) | `apply_display()`(창 모드·크기), 찍기 도구가 설정을 무시하고 1280×720으로 도는지 |
| 일시정지에서 열기(S02) | `SettingsScreen.open(parent, settings)` | 덮개가 `PROCESS_MODE_ALWAYS`, 시간은 `Time.get_ticks_msec()`만 | 일시정지 화면의 "설정" 버튼 |
| **글자 크기** | `view.text_scale`(예: 1.0 / 1.15 / 1.3) | 갈래 칸을 남기는 꼴과 `changed` 신호뿐이다. 글 크기는 한 곳을 지나지 않는다: `day_ui.gd`의 `add_label`·`add_wrapped`·`add_button`·`add_title`(117·135행 근처) 밖에서 `scripts/commission/commission_select.gd`가 `add_theme_font_size_override`를 11곳(41~285행), `scripts/duel/result_panel.gd` 93행, `scripts/duel/duel_hud.gd` 618행이 직접 건다 | **먼저 할 일**: 글 크기를 한 함수(예: `Ui.font_px(size)`)로 모으고 위의 직접 거는 곳을 그 함수로 옮긴다. 그 뒤에 배율을 곱한다. 함께 볼 것: T75가 보는 글자 크기 아홉 단계(배율을 곱한 값이 그 목록 밖으로 나간다), 연습 화면 맞춤의 여유 4화소(`fit,select` 1248 문턱), T91의 칸 폭, 033b 헤짐의 바깥 띠(글이 판 가장자리에서 16 안쪽이라는 전제 — 033b 결정 498). 붙이기가 쉽지 않다 — 한 계획을 따로 둔다 |
| **고대비 표시** | `view.high_contrast`(bool) | 갈래 칸, `changed` 신호로 화면이 다시 그릴 수 있다 | 막기 고리·조준칸의 색이 그리는 곳에 직접 적혀 있다(`duel_scene.gd` 220~235행 `_draw`의 칸 테두리, `opponent_view.gd` 589~619행, `duel_hud.gd`의 색 상수). **먼저 할 일**: 그 색을 한 곳(팔레트 상수 + 고대비 사본)으로 모은다. 이 계획은 판정·뷰 코드(`scripts/duel/`)를 `beeper.gd` 밖에서 건드리지 않아 옮기지 않는다 |
| 소리 갈래(5단계) | `audio`에 `music`·`sfx` 칸 | Master에만 거는 `apply_audio` | 버스 배치 파일, 갈래별 슬라이더 |

## 작업 목록

차례대로 한다. **시작 조건**: 033b의 작업 9가 커밋된 뒤(Q-A "가"). W-5의 답과 상관없이 033b가 끝나면 시작한다 — W-5가 "고칠 것이 있다"면 그 작은 계획(033c 등)이 먼저인지 메인이 사용자에게 묻는다.

**작업 0. 시작 상태**
- 할 일: `git status`가 깨끗한지, HEAD와 `run_tests.gd`의 마지막 T 번호, `DECISIONS.md`의 마지막 결정 번호를 `%TEMP%\bravi-S01\head.txt`에. 번호가 위 셈(T97·500)과 다르면 이 계획의 번호를 그다음으로 바꿔 쓴다(뜻은 그대로). 033b 뒤의 테마(`Panel`·`PanelContainer`가 따로, `PanelContainer`에 `wear`)와 `ui_shots.gd`의 `wear,` 줄을 확인해 근거와 다르면 적는다.
- 완료 확인: 파일이 있다.

**작업 1. `Settings`와 설정 파일** (Sonnet. 결정 500·501·505)
- 대상: 새 `scripts/settings.gd`, `project.godot`(자동 로드 한 줄, `GameSession` 앞), `tests/verify.ps1`(환경 변수 한 줄과 머리 주석 한 줄).
- 완료 확인(메인, diff): `project.godot`의 바뀐 줄이 `[autoload]`의 한 줄뿐, `verify.ps1`이 ASCII, `save_store.gd`·`game_session.gd`의 diff 0, 기계적 확인 다섯.

**작업 2. 미리 듣기 함수** (Sonnet. 결정 504)
- 대상: `scripts/duel/beeper.gd`에 `play(key)` 하나.
- 완료 확인: `beeper.gd`의 diff가 새 함수(주석 한 줄 포함 6줄 안 — 빈 `_players`와 모르는 키를 건너뛰는 줄 포함)뿐, `on_event`·`_play`·`TONES`·`_make_tone` 그대로.

**작업 3. 설정 화면** (Sonnet. 결정 502·504·505)
- 대상: 새 `scripts/ui/settings_screen.gd`.
- 완료 확인(메인, diff): 탭이 `TABS` 목록 한 줄(메서드 이름 + `call`)로 지어진다, 처음 값을 `set_value_no_signal`·`set_pressed_no_signal`로 넣고 신호를 그 뒤에 잇는다, `drag_ended`의 소리가 `_preview_pending`에 걸려 있다, 테마 `.tres`·`day_ui.gd`의 diff 0, 덮개의 `process_mode`, `_process`·`Timer`를 쓰지 않는다, 기계적 확인 다섯.

**작업 4. 처음 화면** (Sonnet. 결정 503)
- 대상: `scripts/title.gd`. 테스트의 기대값:
  - `tests/save_tests.gd`(T58의 버튼 수 3·3·4 → 4·4·5와 `Settings` 이름).
  - `tests/manuscript_tests.gd`(`FRESH_BUTTONS`·`SAVED_BUTTONS`의 `Help` 크기 195 폭과 새 `Settings` 줄 — 값만). 그리고 T75의 `_check_text`·`_check_buttons`가 **설정 화면을 한 번 지나게** 한다(저장 없는 처음 화면에서 연 덮개 — 글자 크기 아홉 단계와 빠진 글자를 본다. 새 검사 함수는 만들지 않고 기존 두 함수에 덮개 노드를 넘긴다).
  - `tests/day_tests.gd` 527행: 처음 화면의 버튼 수 `== 3` → `== 4`(와 실패 글 "3개" → "4개").
  - `tests/ui_shots.gd`: 장 `settings`(저장 없는 처음 화면에서 `Settings`를 눌러 연 모습, `help` 장 다음). 시작할 때 자동 로드 `Settings`가 있으면 `path`를 비운다(쓰기를 끈다 — `run_ui_shots.ps1`을 따로 돌려도 플레이어의 파일을 적지 않게).
  - `tests/run_ui_shots.ps1`: 29행 `$count = 15` → `16`, 6·7행 머리 주석의 15·"fifteen" → 16·"sixteen"(ASCII 그대로).
- 완료 확인(메인, diff): `title.gd`에서 `Help` 버튼 자리와 새 버튼 밖의 자리·크기 줄이 그대로, 테스트의 diff가 위의 기대값·새 장·`Settings` 끄기·T75의 덮개 넘기기뿐(검사 줄을 지우지 않았다), `run_ui_shots.ps1`이 ASCII.

**작업 5. T97** (Sonnet. 새 `tests/settings_tests.gd`, `tests/run_tests.gd`에 두 곳. 테스트는 `path`를 `user://bravi_test_settings.json`으로 **넣은 뒤 트리에 붙인** 새 `Settings` 인스턴스를 쓰고(결정 500), 끝에 그 파일을 지우고 Master 버스를 자동 로드의 값으로 되돌린다)
- `tests/run_tests.gd`: `TEST_FILES`에 한 줄, 그리고 66~73행의 `GameSession` 끄기 옆에 같은 꼴의 블록 — 자동 로드 `Settings`가 있으면 `path`를 비우고 `RUNNER 설정: 오토로드 Settings 있음, path '…'를 비움`(없으면 `… 없음`)을 찍는다. 머리 주석 9행에 한 마디.
- **T97 "설정 파일: 영업 세이브와 따로, 새로 시작해도 남고, 깨지면 처음 값"**:
  1. 처음 값과 경로: 파일이 없으면 `volume` 100·`muted` 거짓, `save()`가 파일을 만들지 않는다(바뀐 것 없음). 붙인 뒤에도 `path`가 넣은 값 그대로다(`_ready`가 덮어쓰지 않는다). `path`를 비운 인스턴스는 값을 바꿔도 `save()`가 거짓이고 아무 파일도 만들지 않는다(쓰기 꺼짐). 자동 로드 `/root/Settings`가 있으면 그 `path`가 빈 글이다(러너가 껐다).
  2. 적고 읽기: 음량 40·음소거 참으로 바꿔 `save()` → 새 인스턴스로 읽으면 40·참. 파일의 JSON에 `version` 1과 `audio`가 있다.
  3. **분리**: `Settings.SETTINGS_PATH` ≠ `GameSession.SAVE_PATH`, `SETTINGS_ENV` ≠ `SAVE_ENV`. 테스트 세이브 파일(`user://bravi_test_save_S01.json`)에 `DayState.saved_state()`를 적고, 설정을 바꿔 적은 뒤 세이브 파일의 바이트가 그대로다. 세이브의 Dictionary에 `audio` 칸이 없고, 설정의 Dictionary에 세이브의 칸(`day`·`money`·`owned`)이 없다(`version`은 양쪽 다 있으므로 보지 않는다 — `day_state.gd` 397행).
  4. **새로 시작해도 남음**: 테스트 세이브를 새 1일차로 덮어쓰고(가게를 새로 시작하는 길과 같은 `saved_state()` 쓰기), 이어서 세이브를 지운 뒤에도 설정 파일의 바이트와 새 인스턴스로 읽은 값(40·참)이 그대로다.
  5. 깨진 파일: 설정 파일에 `{not json`을 적으면 처음 값, 오류 줄 없음(테스트 끝의 오류 0이 본다). `{"audio": {"volume": 170, "muted": "yes"}}` → 100·거짓. `{"audio": {"volume": 37}}` → 35(걸음 5의 가장 가까운 값. 반올림 규칙은 `snapped`) — 결정 501.
  6. 모르는 칸을 남김: `{"version": 1, "audio": {...}, "view": {"text_scale": 1.3}, "controls": {"attack": "x"}}`을 읽고 음량을 바꿔 적으면 `view`·`controls`가 같은 값으로 남는다. `"version": 2`인 파일을 읽고 바꿔 적으면 `version`이 2 그대로다.
  7. 버스: 음량 40·음소거 참을 건 뒤 Master의 `get_bus_volume_db`가 `linear_to_db(0.4)` ±0.01, `is_bus_mute` 참. 음량 0 → −80 이하.
  8. 설정 화면(테스트 인스턴스는 처음 값, 테스트 설정 파일 없음에서 시작):
     - 가. **열기만 하면 아무것도 생기지 않는다**: `SettingsScreen.open(부모, 테스트 인스턴스)` 직후 `preview_count` 0, 인스턴스의 `changed`가 한 번도 나지 않았다. 아무것도 바꾸지 않고 닫기 → `closed` 신호, 테스트 설정 파일이 생기지 않았다.
     - 나. 다시 연 화면에 `VolumeSlider`·`MuteButton`·`SettingsClose`와 탭 버튼 하나("소리")가 있다. 슬라이더 값을 60으로 → 인스턴스의 값 60, `preview_count` 1. 곧바로(120밀리초 안) 65 → 그대로 1. `drag_ended.emit(true)` → 2(거른 값이 있었다), 파일에 65. 한 번 더 `drag_ended.emit(true)` → 그대로 2(거른 값 없음).
     - 다. 음소거를 켜고 70 → 늘지 않는다. 닫기 → 파일에 마지막 값 70·참.
  9. 처음 화면: `Settings`를 누르면 `SettingsScreen`이 생기고, `ui_cancel`로 닫히면 초점이 `Settings` 버튼에 있다. 저장 있는 화면에서도 열린다.
- 완료 확인: 기계적 확인 다섯. `run_tests.gd`의 diff가 `TEST_FILES`의 한 줄, `Settings` 끄기 블록, 머리 주석 한 마디뿐.

**작업 6. verifier의 확인** — "맡길 확인"의 V1을 한 번에 넘긴다. 실패하면 로그의 줄로 가려 범위·규칙을 바꾸지 않는 오류만 고쳐(Sonnet) 다시 맡긴다. 통과하면 커밋한다.
- 메인이 읽는 장: `settings`·`title`·`title-save` 셋(1280). 슬라이더·탭·버튼이 판 안에 있고 글이 잘리지 않았는지, 도움말·설정 두 버튼의 글이 195 폭에 드는지. 거슬리는 꼴(슬라이더가 테마와 따로 논다)은 보고서 3번에 장 경로와 함께 적는다.
- 헤짐(033b 결정 498)은 S01에서 볼 것이 없다: 처음 화면은 UI 창이 하나라 헤지는 몫이 0이어서 `settings` 장의 설정 판은 늘 깨끗하다. "헤짐이 탭·슬라이더에 닿지 않는지"는 설정 판이 다른 판 위에 뜨는 S02(일시정지에서 열기)의 확인으로 넘긴다(계획 뒤의 차례).

**작업 7. 문서와 커밋**
- `docs/DECISIONS.md` "계획 S01"(500~506과 실행 중에 정한 것, 그리고 Q-A·Q-B의 답), `CLAUDE.md`(5장 "지금 만든 범위"에 설정 화면·음량·설정 파일 한 마디, 8장 폴더에 `scripts/settings.gd`·`scripts/ui/settings_screen.gd`, 9장 아래에 "설정 갈래(사용자 지시 2026-11-26, 단계와 별개): S01 … — S01~S04 뒤에 5단계(사용자 답 2026-11-26)" 한 줄), `docs/HANDOFF.md` 1·3번(다음은 S02 — 사용자 "다음 진행" 뒤), 보고서 `docs/reports/S01-settings-and-volume.md`(10장 형식. 2번에 "사용자가 들어 볼 것: 설정 → 슬라이더를 끌면 막기 소리, 음소거면 무음, 다시 켜도 값이 남는다, 결투의 소리가 같이 줄어든다").
- 완료 확인: `DECISIONS.md`에 `^500\.`~`^506\.`이 하나씩(번호가 밀렸으면 그 번호), `git status`가 깨끗하다.

## 맡길 확인 (verifier)

- **V1** (작업 5 뒤) `tests/verify.ps1 -Shots "$env:TEMP\bravi-S01\after"` → `VERIFY: OK`, `ALL PASS 97/97`(오류·경고 0. 번호가 밀렸으면 그 수), 스모크 OK, 가져오기 오류 0, 장 수 상대 57·UI **16**·패턴 38. 로그에 `RUNNER 설정: 오토로드 Settings 있음, path '…'를 비움` 한 줄.
- **V1의 설정 파일 검사**: 실행 **전후**로 프로젝트의 `user://` 폴더(`%APPDATA%\Godot\app_userdata\` 아래 프로젝트 이름의 폴더)에서 `bravi_settings.json`과 **`bravi_playtest_settings.json` 둘 다** 있음·크기·마지막 쓴 시각을 적고, 둘 다 생기거나 바뀌지 않았다(전에 없으면 뒤에도 없다). 테스트 파일 `bravi_test_settings.json`·`bravi_test_save_S01.json`이 뒤에 남아 있지 않다.
- playtester는 부르지 않는다: 화면 넘김과 자리는 V1의 테스트·장이 보고, 소리는 창의 playtester가 들을 수 없다. 소리는 사용자가 듣는다(보고서 2번).

## 위험

- **R1 테스트가 플레이어의 설정을 바꾼다**: 세 겹으로 막는다. (1) 러너와 찍기가 자동 로드 `Settings`의 `path`를 비워 쓰기를 끈다(작업 4·5). (2) 설정 화면은 열기만 해서는 `_dirty`가 켜지지 않는다(결정 500의 `set_*_no_signal`, T97-8의 가). (3) `verify.ps1`은 확인용 경로를 쓴다. T97은 `path`를 넣은 뒤 붙인 인스턴스만 바꾸고 `_ready`는 그 `path`를 덮어쓰지 않는다(T97-1). `run_tests.ps1`·`run_ui_shots.ps1`을 혼자 돌리면 자동 로드가 플레이어의 파일을 읽지만 적지는 않는다. V1이 두 설정 파일의 전후를 본다.
- **R2 Master 버스의 값이 테스트 사이에 샌다**: T97 끝에 자동 로드의 값으로 되돌린다. 다른 테스트는 소리를 판정하지 않는다.
- **R3 슬라이더가 필사본 UI와 따로 논다**: 기본 회색을 지운 잉크 줄과 원 손잡이로 덮는다(결정 502). 그린 손잡이·홈은 이 계획 밖 — 장으로 보이고 BACKLOG.
- **R4 끌 때 소리가 쌓이거나 끊긴다**: 120밀리초 거르기와 `drag_ended`의 한 번(거른 값이 있었을 때만 — 홈을 한 번 누를 때 두 번 울리지 않게). Beeper의 목소리 넷이 돌아가며 울린다. 귀로 보는 것은 사용자(보고서 2번).
- **R5 자동 로드 차례**: `Settings`가 `GameSession` 앞이어야 첫 화면 전에 음량이 걸린다. `project.godot`의 diff와 T97의 7(시작 값이 걸린 버스)이 본다.
- **R6 033b와의 겹침**: Q-A "가"로 033b가 다 끝난 뒤에 시작하므로 같은 파일을 함께 고치는 일은 없다. 033b의 V0 | V1 비교가 끝난 뒤라 처음 화면 장·UI 장 수(15 → 16)를 바꿔도 033b의 판에 닿지 않는다. 033b가 테마를 떼어 둔 꼴(`Panel`·`PanelContainer`)이 근거와 다르면 작업 0에서 적는다.

## 검토 전에 물을 것 (메인이 선택 창으로)

Q-A와 Q-B — 답 받음(아래). 이 계획의 안(음량 처음 값 100, 탭 하나부터, 처음 화면의 두 칸 나누기, 적는 때)은 planner의 임시 결정이고 되돌리기 쉽다.

## 사용자 결정 필요

**Q-A. 033b(그린 질감, 실행 중)와의 차례** — **답 받음(2026-11-26): 가 "033b(와 033c)를 먼저 끝낸다"**. 그래서 S01의 시작 조건은 033b 작업 9의 커밋이고, 새 화면은 033b의 그린 판·버튼 위에 처음부터 지어져 S01의 찍기에서 함께 보인다. 033b는 그대로다(S01의 몫을 끼우지 않는다).

| 보기 | 차례 | 답에 따라 달라지는 것 |
|---|---|---|
| **가(고름)** | 033b를 W-5까지 끝내고 S01~S04 | 033b 그대로. S01의 시작 조건이 033b 작업 9의 커밋 |
| 나 | 033b의 판 U2까지 끝내고, W-5를 묻기 전에 S01~S04 | (고르지 않음) |
| 다 | 033b를 지금 멈추고 S01부터 | (고르지 않음) |

**Q-B. W-5가 "5단계로"일 때 S02~S04와 5단계의 차례** — **답 받음(2026-11-26): 가 "S01~S04를 다 하고 5단계"**. 5단계의 소리 일이 S01의 음량(Master) 위에 선다. CLAUDE.md 9장에 "설정 갈래 끝 뒤 5단계" 한 줄(작업 7).

| 보기 | 차례 | 답에 따라 달라지는 것 |
|---|---|---|
| **가(고름)** | S01~S04를 다 끝내고 5단계의 첫 계획 | 9장 표에 "설정 갈래 끝 뒤 5단계" 한 줄 |
| 나 | S01만 하고 5단계, S02~S04는 5단계 사이사이 | (고르지 않음) |
| 다 | 5단계를 먼저, S는 그 뒤 | (고르지 않음) |

- 실행 중: 없음(사용자의 귀로 보는 것은 보고서 2번에 두고, 고칠 말이 오면 값 하나로 고친다 — 곡선, 거르는 120밀리초, 처음 값).
- planner가 임시로 정한 것(되돌리기 쉽다): 번호 꼴 `S01`, 자동 로드 `Settings`와 파일 꼴(500), 음량 0~100·처음 값 100·진폭 곡선(501), 탭 목록·슬라이더를 스크립트 안에서 꾸밈(502), 처음 화면의 두 칸 나누기(503), 120밀리초 거르기(504), 적는 때(505).

## 계획 뒤의 차례

S01 보고 뒤 사용자가 "다음 진행"이라 하면 S02(일시정지 · 창 포커스 · 게임 종료)를 쓴다(Q-B "가": S04까지 마친 뒤 5단계). S02의 검토 전 물음이 될 것(미리 적어 둔다): 연습 결투에서 Esc가 지금처럼 바로 의뢰 선택으로 가는 대신 일시정지 화면을 여는 것(보기: 일시정지 화면의 "연습 고르기로" 버튼으로 옮긴다 / Esc 두 번이면 나간다), 하루 결투의 일시정지에서 "처음 화면으로"를 허락하는지(그날의 결투를 잃고 그날 아침부터 — 지금은 결투 중에 나갈 길이 창 닫기뿐이다).

S02~S04에 넘기는 것:
- S02: 설정 판이 다른 판(결투 HUD·일시정지 판) 위에 뜰 때 헤짐(033b 결정 498)이 탭·슬라이더에 닿지 않는지를 찍기로 본다(작업 6에서 넘김).
- S03·S04: playtester가 창에서 설정을 바꾸게 되면 `BRAVI_SETTINGS_PATH`를 확인용 파일(`user://bravi_playtest_settings.json`)로 두고 부른다(플레이어의 키·화면 설정을 바꾸지 않게).

## 검토 대응 기록

- v1 → v2(검토 전): Q-A·Q-B의 답을 적음, 결정 번호 498~504 → 500~506(033b v3가 498·499를 씀), 근거에 033b 헤짐의 규칙과 설정 판 한 줄, 작업 0·6에 033b 뒤의 확인 한 줄, 확장 자리 "글자 크기"에 헤짐의 바깥 띠 전제, R6을 "가" 기준으로. 검토는 아직 없다.
- v2 → v3(1회차: 디자인 APPROVE · 기술 REVISE):
  - **T1** (가) 결정 500 "경로를 정하는 때"(빈 `path`일 때만 환경 변수·기본 경로, 밖에서 넣은 값은 그대로, `_ready` 뒤 빈 `path`는 쓰기 꺼짐)와 "처음 값은 `set_*_no_signal`", 작업 5 머리(`path`를 넣은 뒤 붙임)·T97-1. (나) T97-8의 가(열면 `preview_count` 0·`changed` 없음, 그대로 닫으면 파일 없음). (다) 둘 다 했다: 작업 5의 `run_tests.gd` `Settings` 끄기 블록과 작업 4의 `ui_shots.gd` 끄기, V1의 "설정 파일 검사"(`bravi_settings.json`·`bravi_playtest_settings.json` 전후). 목표 4·R1을 맞춰 고침.
  - **T2** (1) T97-3: 세이브에 `audio` 없음, 설정에 `day`·`money`·`owned` 없음, `version`은 보지 않음. 근거에 세이브의 칸 한 줄. (2) 작업 4에 `day_tests.gd` 527행 `== 3` → `== 4`, 근거의 528 → 527. (3) 작업 4에 `run_ui_shots.ps1` `$count` 16과 6·7행 주석(ASCII).
  - 차단 밖으로 받은 것(비차단 제안): 결정 502 `TABS`의 메서드 이름 + `call`, 결정 504 `play()`의 빈 `_players` 건너뛰기와 `drag_ended`의 소리를 거른 값이 있을 때만(T97-8의 나), 결정 500 `version`을 내려 적지 않기(T97-6), 작업 4 T75가 설정 덮개를 지남, 작업 6 헤짐 확인을 S02로, 확장 자리 "글자 크기"·"고대비" 줄을 고쳐 적음, 계획 뒤의 차례에 S02·S03·S04로 넘기는 것.
