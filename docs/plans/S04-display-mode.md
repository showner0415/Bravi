# 계획 S04: 화면 모드 · 창 크기

- 버전: v3 (2026-11-27. 1회차 디자인 REVISE D1 · 기술 REVISE T1·T2 반영과 비차단 셋. v2: 사용자 답 Q1 "가"·Q2 "가"·Q3 "나". v1: HEAD `91406a2`, S03 끝, `ALL PASS 101/101`)
- 개발 단계: CLAUDE.md 9장의 단계와 **별개인 사용자 지시 작업**(설정·편의 갈래 S01~S04의 넷째, 마지막). 9장의 단계를 넘기지도 닫지도 않는다. S04 뒤는 5단계(사운드)이고, 넘어가는 결정은 사용자가 한다(S01 Q-B "가").
- 근거:
  - 사용자 지시(2026-11-26) "설정·편의 기능 추가" 가운데 S04의 몫: "2. 화면 모드·해상도 — 창 모드 / 테두리 없는 전체 화면, 창 크기, UI 기준 1280×720(16:9 고정, 남는 곳은 검은 띠), 커서와 3×3 조준칸이 일치", "5. 설정 메뉴 — 처음 화면과 일시정지에서 화면 탭, 설정은 영업 세이브와 따로", "[플레이] 여러 창 크기·전체 화면에서 커서와 조준칸이 맞는지 — 사용자 확인 몫". 범위 밖: 글자 크기, 고대비.
  - 검토 전 답(2026-11-27, 선택 창): **Q1 "가" — 창 확인은 사용자가 직접**(playtester를 부르지 않는다), **Q2 "가" — 끌 수 있고 기억하지 않는다**, **Q3 "나" — 단축키는 F11 하나**. 모두 권한 답이다.
  - S01 표(S01 계획 35·41·92행): 창 크기 목록에서 모니터보다 큰 것은 뺀다, 전체 화면은 모니터 해상도, `display` 갈래와 `TABS`의 한 줄, `apply_display()`, "찍기 도구가 설정을 무시하고 1280×720으로 도는지".
  - S03이 넘긴 것(S03 계획 196~200행): 화면 전환 키를 더하면 `Controls.RESERVED`에 한 줄(바꾼 키와 겹치는 파일은 읽을 때 처음 값으로 — 결정 518), `display`도 "바꾸지 않았으면 적지 않는다"를 따를지, 테스트·찍기의 `detach_for_run`(결정 523)에 화면 몫, [플레이] 확인을 누가 할지는 S04 검토 전에 묻는다.
  - S02의 교훈(S02 보고서 3번, 결정 508): 엔진이 알림을 돌리는 동안에는 `add_child`가 막힌다. 창 모드를 바꾸면 포커스·크기 알림이 올 수 있다 — 새 코드는 알림 처리기를 두지 않는다(결정 527).
  - S03의 교훈(S03 보고서 3번, 계획 v3 T1): 테스트는 실제 입력 길(`Input.parse_input_event`)을 타야 한다. 격리 파일은 메인이 적고 지우며 verifier는 읽기만 한다.
  - 지금 코드(읽음, HEAD `91406a2`):
    - `project.godot` [display]: `viewport_width=1280`, `viewport_height=720`, `stretch/mode="canvas_items"`. `stretch/aspect`는 적혀 있지 않아 엔진 기본값 `keep`(남는 곳은 검은 띠), 창은 끌어서 크기를 바꿀 수 있다(`resizable` 기본 참). 창 모드·크기를 바꾸는 코드는 없다.
    - 조준(`duel_scene.gd` 347~354행 `_update_aim_from_mouse`): `get_viewport().get_mouse_position()`(또는 `--bravi-virtual-mouse`일 때 `_input`의 `event.position`, 300행)을 `get_viewport_rect().size`(늘 1280×720)로 나눠 3×3 칸을 고르고 `clampi`로 자른다. 둘 다 엔진이 늘이기 변환을 되돌린 **뷰포트 좌표**다 — 창 크기와 상관없이 맞고, 검은 띠 위의 커서는 가장자리 칸이 된다. 조준칸의 선(`_draw`, 384행)도 뷰포트 크기로 그린다. 창 크기를 듣는 곳은 `duel_scene.gd` 85행 `size_changed → _layout` 하나(뷰포트 크기를 다시 읽을 뿐).
    - 포커스(`duel_scene.gd` 262~270행): 포커스를 잃으면 `_pause_from_focus.call_deferred()`, `pause()`는 이미 멈춘 판에서 거짓을 돌려준다(160행).
    - `Settings`(`scripts/settings.gd`): `_ready`가 `path`를 정하고 `_load` → `apply_audio` → `apply_controls`. `detach_for_run`이 쓰기를 끄고 조작을 처음 값으로. `_write_controls`의 꼴(읽은 파일에 갈래가 있었거나 이 실행에서 바꿨을 때만 적는다).
    - 설정 화면(`scripts/ui/settings_screen.gd`): `TABS` 둘(소리·조작), 판 `Rect2(240, 110, 800, 480)`, 몸 폭 560, 탭 버튼 140×44, 기다림의 `_input`이 예약 키를 "쓸 수 없는 키다 (R · 다시 하기)"로 알린다, `CONTROLS_HINT`(14행)에 예약 키 이름이 적혀 있다.
    - 테스트·찍기: 러너는 `--headless --script res://tests/run_tests.gd`, 찍기는 `res://tests/*_shots.tscn`(헤드리스, 또는 `-Shots`일 때 창으로, 일부는 `--resolution`). `run_ui_shots.ps1`은 `size,` 줄이 1280x720(또는 `-Resolution`)인지 본다 — 창으로 찍을 때 장의 크기는 창의 크기를 따르므로, 찍기에서 설정이 창을 키우면 여기서 걸린다. 헤드리스의 `size,`는 뷰포트 크기라 늘 1280×720이다(창을 보지 않는다). `verify.ps1`은 `BRAVI_SETTINGS_PATH`를 확인용 파일로 둔다. 창 도구 `tools/start-playtest.ps1`은 `BRAVI_SAVE_PATH`만 확인용으로 바꾸고 `BRAVI_SETTINGS_PATH`는 두지 않는다(80~84행) — 지금은 플레이어의 설정 파일로 창이 뜬다.
    - T0(`project_tests.gd` 11~46행)은 입력 액션 일곱의 표를 본다. T97-8 나는 탭 줄이 `TABS.size()`와 같은지 본다(자동으로 셋을 따른다). T101-6은 도움말 첫 줄을 글자 그대로 본다.
  - 번호: 결정은 **525부터**(`DECISIONS.md`의 마지막 524), 테스트는 **T102부터**(마지막 T101). 실행 때 다시 본다.

### 넘지 않는 선

- 메인은 Godot·테스트·게임을 실행하지 않는다. 자동 확인은 verifier(`tests/verify.ps1`). 코드 쓰기(`.gd`·`.ps1`·테스트·`project.godot`의 한 줄)는 Sonnet 하위 에이전트, 메인은 diff를 읽는다. 편집은 80줄 안쪽으로 나누고 HANDOFF 4번의 기계적 확인 다섯을 지킨다. `.ps1`은 ASCII.
- 고치지 않는 것: 판정 코드(`scripts/duel/duel_core.gd`, `scripts/ai/`), `data/`, `project.godot`의 [display](늘이기 설정 그대로 — 결정 530)와 [input]의 기존 일곱, `scripts/save_store.gd`, `scripts/game_session.gd`, 영업 세이브의 형식, 테마 `.tres`와 `scripts/ui/`의 StyleBox, `pause_menu.gd`, `quit_confirm.gd`, 도움말 글(`DuelHud.help_text` — T101-6 그대로), `tools/playtest-window.ps1`, `.claude/agents/`.
- **테스트·찍기·스모크·통계는 진짜 창을 건드리지 않는다**: 플레이어의 파일에 전체 화면·큰 창이 적혀 있어도 창 모드·크기를 바꾸지 않고 Godot이 띄운 창(`project.godot`의 1280×720, 또는 명령의 `--resolution`) 그대로 돈다(결정 531). 하나의 예외는 결정 532 T102-5: **헤드리스에서만** 루트 창의 `size`를 잠깐 바꿔 엔진의 좌표 변환을 재고 되돌린다(진짜 창이 없다).
- 범위 밖: 배타 전체 화면(`MODE_EXCLUSIVE_FULLSCREEN` — 전환 때 화면이 검어지고 Alt+Tab이 전환을 부른다. 사용자 지시는 두 모드다), 모니터 해상도 바꾸기, 모니터 고르기 칸, 수직 동기·프레임 제한, 늘이기 방식 바꾸기(정수 배율 등), 글자 크기·고대비.

## 목표와 범위

**확인할 결과**:

1. 설정 화면에 "화면" 탭이 있다(처음 화면과 멈춤·잠깐 창 양쪽에서). "창" / "전체 화면" 두 버튼과 창 크기 버튼들(1280×720 · 1600×900 · 1920×1080 · 2560×1440 · 3840×2160 가운데 지금 모니터에 들어가는 것)이 보이고, 누르면 곧바로 바뀐다. 전체 화면은 창이 있는 모니터를 덮는 테두리 없는 창이다. 창 크기를 누르면 창으로 돌아가 그 크기로 모니터 가운데에 선다 — 이미 눌린 모습의 버튼도 같다(전체 화면에서 눌린 크기를 누르면 그 크기의 창으로, 끌거나 최대화한 창에서 눌린 크기나 "창"을 누르면 고른 크기로 돌아온다).
2. 어느 크기·모드에서도 그림은 1280×720 기준 그대로 늘고 남는 곳은 검은 띠다. 커서가 가리키는 3×3 조준칸과 결투의 조준이 같다(검은 띠 위의 커서는 가장 가까운 가장자리 칸).
3. F11이 어디서나 창 ↔ 전체 화면을 바꾼다(Q3 "나"). 흐르는 결투에서 누르면 판이 먼저 멈추고 바뀐다. F11은 조작 탭에서 줄 수 없는 키가 된다.
4. 고른 모드·크기는 `bravi_settings.json`의 `display`에 적혀 다시 켜도 남고, 가게를 새로 시작해도 그대로다(영업 세이브와 따로). 바꾸지 않은 사람의 파일에는 `display`가 적히지 않는다. 깨진 값은 처음 값(창 · 1280×720)으로 읽고 오류 줄이 없으며 화면 탭이 한 번 알린다. 적힌 창 크기가 지금 모니터에 들어가지 않으면 들어가는 가장 큰 크기로 열고(파일은 그대로) 화면 탭이 알린다.
5. 테스트·찍기·스모크·통계는 플레이어의 화면 설정과 상관없이 Godot이 띄운 창 그대로 돌고 어떤 설정 파일도 적지 않는다. 판정·데이터 그대로: `duel_core.gd`·`scripts/ai/`·`data/`의 `git diff` 0줄, `project.godot`의 diff는 [input]의 액션 한 개뿐. `ALL PASS 103/103`, 스모크 OK, 가져오기 오류 0, UI 찍기 24 → 25, 새 장의 `wearhit` 0.

재미는 바뀌지 않는다(규칙·시간·조준은 그대로이고, 창의 꼴만 바뀐다). 여러 모니터·진짜 전체 화면에서 커서와 조준칸이 맞는지는 사용자가 직접 본다(Q1 "가", "맡길 확인"의 끝).

## 설계 결정

525. **화면의 셈** — 새 `scripts/display.gd`(`extends RefCounted`, `class_name` 없음. 쓰는 쪽은 `const Display := preload(...)`), 정적 함수만. 창을 건드리지 않는다(테스트가 셈만 본다):
     - `BASE`: `project.godot`의 뷰포트 크기(1280×720)를 `ProjectSettings`에서 읽는다. `MODES := [&"windowed", &"fullscreen"]`, 이름 창 · 전체 화면. `STANDARD_SIZES := [1280×720, 1600×900, 1920×1080, 2560×1440, 3840×2160]`, `DEFAULT_SIZE` 1280×720. 이름 `size_name(v)` "1600×900"(곱셈 기호 `×`).
     - `is_valid_size(v)`: 정확히 16:9(`v.x * 9 == v.y * 16`)이고 폭이 64의 배수이며 640~7680. 목록 밖이어도 이 꼴이면 읽는다(작은 모니터의 대신 크기를 고른 사람의 파일이 고쳐지지 않게).
     - `fits(size, usable, decor) -> bool`: `size + decor`가 모니터의 쓸 수 있는 넓이(작업 표시줄을 뺀 `screen_get_usable_rect`의 크기) 안. `decor`는 창 테두리·제목 줄의 크기(결정 527이 잰다. 못 재면 `DECOR_FALLBACK` 16×40, 임시).
     - `sizes_for(usable, decor) -> Array`: 표준 크기 가운데 들어가는 것. 하나도 들어가지 않으면(예: 1366×768 노트북 — 1280×720 + 제목 줄이 작업 표시줄에 걸린다) **들어가는 가장 큰 16:9 하나**(폭을 64의 배수로 내림, 예 1216×684). **640×360도 들어가지 않는 넓이**(헤드리스의 빈 사각형 0×0, 못 읽은 모니터)면 `[BASE]`(1280×720) 하나 — 셈이 늘 크기 하나 이상을 내고, 창은 엔진이 띄운 크기 그대로가 된다(기술 T2 (2)).
     - `fit_size(want, usable, decor) -> Vector2i`: `want`가 들어가면 그대로, 아니면 `sizes_for`의 가장 큰 것(위의 바닥이면 `BASE`).
     - `LOCKED_USABLE` 2560×1400 · `LOCKED_DECOR` 16×40: 창이 잠긴 실행(결정 531)의 **본보기 모니터**. 잠긴 실행의 셈은 모두 이 값을 쓴다(결정 526·527·531, 기술 T2 (1)).
     - `content_rect(window: Vector2i) -> Rect2`: `canvas_items`·`keep`의 그림 자리 — 배율 `min(W/1280, H/720)`, 가운데 정렬, 나머지는 띠. `to_viewport(point, window) -> Vector2`: 창 좌표 → 뷰포트 좌표(그 역). 엔진의 셈과 1화소 안에서 같아야 한다(T102-5가 잰다).
     - `plan(display, usable, decor) -> Dictionary`: `{"mode", "size"(창일 때 걸 크기), "clamped"(적힌 크기가 들어가지 않아 줄였는가)}`. 전체 화면의 크기는 엔진이 모니터에 맞추므로 `size`는 창으로 돌아갈 때의 값이다.
526. **`Settings`의 `display` 갈래**(`scripts/settings.gd`, 결정 518의 꼴을 따른다):
     - 파일의 꼴: `"display": {"mode": "windowed", "width": 1600, "height": 900}`. `version`은 1 그대로.
     - 읽기(`normalize`에 한 갈래, `clean_display(raw) -> {"display", "repaired"}`): 칸이 없으면 처음 값(고친 것이 아니다). `mode`가 둘 가운데 하나가 아니면 창, `width`·`height`가 수가 아니거나 `is_valid_size`가 거짓이면 1280×720 — 둘 다 `display_repaired` 참(화면 탭이 한 번 "읽을 수 없는 화면 설정을 처음 값으로 돌렸다"). `display` 안의 모르는 칸은 남긴다(S01 규칙).
     - `var display := {"mode": &"windowed", "size": Vector2i(1280, 720)}`, `display_repaired`, `_write_display`(읽은 파일에 `display`가 있었거나 이 실행에서 바꿨다 — S03 결정 518과 같은 까닭: 음량만 바꾼 사람의 파일에 처음 값이 박히지 않게).
     - `set_display_mode(mode) -> bool`, `set_window_size(size) -> bool`, `toggle_fullscreen()`.
       - `set_window_size`는 그 크기를 두고 **모드도 창으로** 둔다(크기 버튼을 누른 것이 바로 보이게. 임시, 되돌리기 쉽다). **크기와 모드를 함께 견준다**: 전체 화면에서 지금 크기의 버튼을 누르면 크기는 같아도 모드가 바뀌므로 바뀐 것이다 — 그 크기의 창으로 돌아가고 `changed(&"display", &"mode")`(크기도 바뀌었으면 `&"size"`도)(디자인 D1).
       - 바뀌면 `_dirty`·`_write_display`, `apply_display()`, 바뀐 칸마다 `changed.emit(&"display", &"mode" 또는 &"size")`, 참.
       - **모드·크기가 모두 같으면 창에 다시 건다**: `apply_display()`만 부르고 거짓 — `_dirty`·`_write_display`·`changed`는 그대로, 파일도 그대로(기술 T1). 까닭: 손으로 끌거나 최대화한 창에서 이미 눌린 "창"이나 크기 버튼을 누르면 고른 크기로 돌아와야 한다(Q2 "가"). `toggle_fullscreen`은 늘 바뀐다.
       - `save()`는 부르는 쪽(탭·F11)이 바로 부른다(음소거 토글과 같은 때, 결정 505. 바뀐 것이 없으면 `save`가 적지 않는다).
     - `available_sizes() -> Array`: 창이 있는 모니터의 `sizes_for`. **창이 잠긴 실행에서는 본보기 모니터**(`LOCKED_USABLE`·`LOCKED_DECOR` → 1280×720 · 1600×900 · 1920×1080) — 찍기의 장이 verifier의 모니터에 따라 달라지지 않게.
     - 쓰기: `_write_display`이면 `mode`·`width`·`height`를 적고 모르는 칸을 합친다. 아니면 `display`를 지운다(`controls`와 같은 꼴).
527. **창에 거는 길**(`Settings.apply_display()`):
     - **곧바로 건다. "적용 → N초 안에 확인하지 않으면 되돌림"은 두지 않는다**(planner 결정): 배타 전체 화면도 해상도 바꾸기도 없어 모니터가 못 쓰게 되는 일이 없고, 크기는 모니터에 들어가는 것만 보이며, 되돌리는 길(같은 탭, F11)이 늘 있다. 임시, 되돌리기 쉽다(탭의 한 자리).
     - 부를 때마다 `_apply_count += 1`(잠겼어도 센다 — 테스트가 "다시 걸었다"를 본다, 기술 T1). `plan`의 모니터는 잠겼으면 본보기 모니터(`LOCKED_USABLE`·`LOCKED_DECOR`), 아니면 창이 있는 모니터의 `screen_get_usable_rect`와 잰 `decor`(기술 T2 (1)).
     - 창이 잠겼으면(결정 531) `plan`을 `last_plan`에 남기고 창은 건드리지 않는다. 아니면 `last_plan`을 남기고 `_window_calls += 1` 뒤 `_apply_plan_to_window(plan)`: 전체 화면이면 `get_window().mode = Window.MODE_FULLSCREEN`(창이 있는 모니터).
     - **`MODE_FULLSCREEN`을 쓴다**(기술 비차단, 판단): Windows에서 이 모드는 엔진이 일부러 가장자리에 1화소 테두리를 남기는 테두리 없는 창이다(엔진이 배타 모드로 다뤄지지 않게 하는 장치). `MODE_EXCLUSIVE_FULLSCREEN`도 모니터 해상도를 바꾸지 않고 테두리가 없지만, Alt+Tab·다른 창으로 갈 때마다 전체 화면 전환이 일어나고(드라이버에 따라 화면이 잠깐 검어진다) 그때 포커스 알림으로 결투가 멈춘다 — 사용자 지시의 "테두리 없는 전체 화면"과 S02의 빠른 Alt+Tab에 맞는 쪽은 앞의 것이다. 1화소 줄이 거슬리면 바꾸는 곳은 `_apply_plan_to_window`의 한 줄이다(사용자 확인 2, R8). 창이면 모드를 창으로 → `size` → `move_to_center()`(창이 있는 모니터의 가운데). 모드를 바꾼 같은 프레임에 크기가 먹지 않으면 다음 프레임에 크기·가운데를 한 번 더 건다(`call_deferred` — 이 함수 안에서만. 창 확인 몫, R5). 이 함수는 15줄 안쪽으로 둔다(자동 확인이 닿지 않는 유일한 곳이다).
     - `decor`는 창 모드일 때 `DisplayServer.window_get_size_with_decorations() - window_get_size()`로 재어 둔다. 전체 화면이나 최대화로 시작했으면 `DECOR_FALLBACK`.
     - 시작: `_ready`의 `apply_controls()` 다음에 `apply_display()`. Godot은 창을 `project.godot`의 1280×720 창으로 먼저 띄우므로, 전체 화면이나 다른 크기를 적어 둔 사람은 켤 때 잠깐 창이 바뀌는 것이 보인다(창 확인 4, R6). 창의 가장 작은 크기 `min_size`를 640×360으로 둔다(끌어서 줄일 때 0에 가까운 창을 막는다. 잠긴 실행에서는 두지 않는다).
     - **알림 처리기를 두지 않는다**(S02의 교훈): 새 코드에 `_notification`이 없다. 창 크기가 바뀌는 것을 듣는 곳은 화면 탭의 "지금" 글 하나이고(결정 529), 거기서는 글만 고치고 노드를 붙이거나 떼지 않는다. 모드를 바꾸는 동안 포커스 알림이 와서 결투가 멈추는 것은 S02 그대로이고(미룬 멈춤) 괜찮다.
     - **손으로 끈 창 크기는 기억하지 않는다**(Q2 "가", 사용자 답 2026-11-27): 창은 지금처럼 끌어서 바꿀 수 있고(검은 띠가 생긴다), 다음에 켜면 고른 크기로 연다. 제목 줄의 최대화 단추도 그대로 쓴다(모드는 "창"으로 남는다). 여러 모니터: 고른 모니터를 적지 않는다 — 전체 화면은 창이 있는 모니터를 덮고, 다음에 켜면 엔진의 기본 자리(주 모니터)에서 연다. 임시, 되돌리기 쉽다(`display`에 칸 하나).
528. **전체 화면 단축키 F11 하나**(Q3 "나", 사용자 답 2026-11-27. Alt+Enter는 넣지 않는다 — Enter가 엔진의 `ui_accept`와 겹쳐 초점 버튼·결과 넘기기가 함께 눌린다):
     - `project.godot` [input]에 `toggle_fullscreen`(physical 4194342 F11, `device -1`, 수식키 없음) 한 줄. 처음 값의 원본은 지금처럼 `project.godot`이다.
     - `Settings._unhandled_input`: `toggle_fullscreen` 누름(echo는 거른다)이면 `toggle_fullscreen()` → `save()` → `set_input_as_handled()`. 자동 로드는 트리의 앞에 있어 `_unhandled_input`을 씬들보다 늦게 받는다 — 지금 F11을 쓰는 씬이 없어 늘 닿는다.
     - **흐르는 결투에서는 먼저 멈춘다**(`duel_scene.gd` `_unhandled_input`, 판이 끝나지 않았고 `paused`가 아니거나 대기 중일 때 `pause(&"display")`, 이벤트는 처리됨으로 표시하지 않아 Settings로 간다): 전환 동안의 몇 프레임과 검은 순간에 맞는 일을 막는다. 멈춘 판·멈춤 화면 위에서는 바로 바뀐다(이미 멈춘 판의 `pause`는 거짓). 멈추는 때(결정 508)에 "F11"이 더해진다. 임시, 되돌리기 쉽다(한 갈래).
     - **예약**: `Controls.RESERVED`에 `&"toggle_fullscreen": "전체 화면"` 한 줄(결정 517). 조작 탭의 기다림에서 F11은 "쓸 수 없는 키다 (F11 · 전체 화면)"이고 기다림의 `_input`이 먹으므로 바뀌지 않는다. `CONTROLS_HINT`를 "조준은 마우스 위치 그대로다 · Esc·R·F1·F11·Space·Enter는 쓸 수 없다"로. 플레이어의 파일에 조작이 F11로 적혀 있으면 읽을 때 그 칸이 처음 값으로 돌아가고 조작 탭이 한 번 알린다(결정 518 그대로).
     - 도움말 글(`DuelHud.help_text`, 처음 화면의 도움말)은 고치지 않는다(T101-6이 첫 줄을 글자 그대로 본다). F11은 화면 탭의 흐린 글이 알린다. 임시.
529. **화면 탭**(`scripts/ui/settings_screen.gd`):
     - `TABS`에 `[&"display", "화면", &"_build_display"]` 한 줄(탭 셋 140×44 + 사이 20 = 440, 판 폭 안).
     - 몸(사이 12): 줄 1 — 이름 `Label` "화면"(24, 폭 160) + 토글 버튼 `DisplayWindowed` "창" · `DisplayFullscreen` "전체 화면"(160×42, 글 20, 한 `ButtonGroup`). 줄 2 — 이름 "창 크기" + `available_sizes()`의 버튼 `Size_<w>x<h>`(104×42, 글 18, 한 `ButtonGroup`, 다섯까지 한 줄 = 560). 고른 크기의 버튼이 눌린 모습이고, 전체 화면에서도 창으로 돌아갈 크기가 눌려 있다 — **그 버튼을 누르면 그 크기의 창으로 돌아간다**(결정 526, 디자인 D1). 적힌 크기가 목록에 없으면(줄인 때) 줄인 크기가 눌린다. 줄 3 — `DisplayNow`(18) "지금: 창 1600×900" / "지금: 전체 화면 2560×1440" / 끌어서 바꾼 창이면 "지금: 창 1440×810 — 끌어서 바꿨다 · 다음에 켜면 1600×900". 잠긴 실행에서는 `last_plan`으로 쓴다(찍기의 장이 고정된다). 줄 4 — `DisplayHint`(16, `Ui.DIM`, 줄바꿈, 폭 560) "F11로도 바꾼다 · 그림은 늘 16:9이고 남는 곳은 검은 띠 · 이 모니터에 들어가지 않는 크기는 뺐다". 줄 5 — `DisplayNote`(18, 줄바꿈, 빈 글이면 숨김): `display_repaired`이면 처음 지을 때 한 번 "읽을 수 없는 화면 설정을 처음 값으로 돌렸다"(그리고 표시를 끈다), `last_plan.clamped`이면 "이 모니터에 1920×1080 창이 들어가지 않아 1600×900으로 열었다".
     - 버튼은 `set_pressed_no_signal`로 지금 값을 넣은 뒤 신호를 잇는다(열기만 해서는 `changed`·`_dirty`가 없다, 결정 500·502). **잇는 신호는 `pressed`**(누를 때마다 온다 — 이미 눌린 토글을 다시 눌러도 닿는다. `toggled`는 쓰지 않는다). 누르면 `set_display_mode`/`set_window_size`(값이 같으면 창에 다시 건다, 결정 526) → `save()` → 탭의 글·눌림을 다시 쓴다.
     - F11 등으로 탭 밖에서 바뀌면: 화면이 `_settings.changed`를 듣고 `display` 갈래면 눌림·글만 다시 쓴다. "지금" 글은 루트 창의 `size_changed`도 듣는다(한 번만 잇고, 글 노드가 없으면 아무것도 안 함, `_close`에서 끊는다). 둘 다 글과 눌림만 고친다(결정 527).
     - 조작 탭의 기다림(결정 520)은 탭을 바꾸면 취소된다 — 그대로.
530. **조준과 검은 띠**: 늘이기 설정(`canvas_items`, `keep`, 1280×720)은 바꾸지 않는다 — 조준·그림이 이미 뷰포트 좌표로 셈한다(근거의 "지금 코드"). 테스트가 게임의 셈을 그대로 부르도록 `_update_aim_from_mouse`의 칸 셈을 정적 `DuelScene.aim_cell(point: Vector2, size: Vector2) -> Vector2i`로 빼고 `_update_aim_from_mouse`가 그것을 부른다(동작은 글자 하나까지 같다 — `int(x / w * 3)`·`clampi`). `project.godot`의 [display]가 지금 값인지는 T102-1이 본다(누가 `expand`로 바꾸면 띠가 사라지고 칸이 넓어진다).
531. **창이 잠긴 실행**(테스트·찍기의 격리, S03 결정 523을 넓힌다):
     - `Settings._ready`가 `window_locked`를 **설정을 읽기 전에** 정한다: `DisplayServer.get_name() == "headless"`이거나 `OS.get_cmdline_args()` 가운데 `res://tests/`로 시작하는 것이 있으면 참(러너 `--script res://tests/run_tests.gd`, 모든 `res://tests/*_shots.tscn`·`day_smoke.tscn`, 편집기에서 테스트 씬을 돌릴 때). 까닭: 러너와 찍기가 `detach_for_run`을 부르는 때는 자동 로드의 `_ready` 뒤라, 그 전에 `_ready`가 창을 전체 화면으로 바꿔 버리면 늦다. 실행 차례에 기대지 않고 명령 줄로 정한다. 게임(`play.ps1`, 창 도구, 편집기의 F5)은 주 씬을 돌려 잠기지 않는다.
     - 잠긴 실행에서는 `apply_display`가 창을 건드리지 않고(`_window_calls` 0), `min_size`도 두지 않는다. 그래서 `--resolution 1920x1080`의 찍기(무대·손)도 그 크기 그대로다.
     - `detach_for_run()`에 화면 몫: `window_locked = true`, `display`를 처음 값으로, `display_repaired` 끔, `last_plan`을 처음 값의 계획으로(본보기 모니터로 센다 — `apply_display`·`available_sizes`와 같은 모니터, 기술 T2 (1)). 창은 건드리지 않는다. `_dirty`는 켜지 않는다. **`_window_calls`·`_apply_count`는 건드리지 않는다**(되돌리면 V1의 `display,1,0`이 실패할 수 없게 된다, 기술 T2 (3)).
     - `ui_shots.gd`가 끝에 `display,<locked 1/0>,<window_calls>`를 한 줄 내고 `run_ui_shots.ps1`이 `display,1,0`이 아니면 실패로 친다(ASCII, 머리 주석 한 줄).
     - 창 도구: `tools/start-playtest.ps1`이 `BRAVI_SAVE_PATH`처럼 `BRAVI_SETTINGS_PATH`가 비었으면 `user://bravi_playtest_settings.json`으로 두고 되돌린다(80~84행의 꼴, 세 줄). S01이 적어 둔 "playtester는 확인용 설정으로"를 도구가 지키게 한다 — 플레이어의 전체 화면 설정이 창 도구의 창(클라이언트 좌표 1280×720을 전제)을 키우지 않게.
532. **T102 "화면 설정: 값·격리·셈", T103 "화면 탭·F11·결투의 멈춤"**(새 `tests/display_tests.gd`, `run_tests.gd`에 한 줄): 작업 5.

## 작업 목록

차례대로 한다. 검토 전 물음의 답은 받았다(Q1 "가", Q2 "가", Q3 "나").

**작업 0. 시작 상태**
- 할 일: `git status`가 깨끗한지, HEAD, `run_tests.gd`의 마지막 T 번호, `DECISIONS.md`의 마지막 결정 번호를 `%TEMP%\bravi-S04\head.txt`에. 다르면 이 계획의 번호를 그다음으로 바꿔 쓴다(뜻은 그대로).
- 완료 확인: 파일이 있다.

**작업 1. 셈과 `Settings`의 갈래** (Sonnet. 결정 525·526·527·531)
- 대상: 새 `scripts/display.gd`, `scripts/settings.gd`(`window_locked`와 그 판정을 `_ready`의 맨 앞에, `normalize`의 한 갈래와 `clean_display`, `display`·`display_repaired`·`_write_display`·`last_plan`·`_window_calls`·`_apply_count`, 본보기 모니터 `LOCKED_USABLE`·`LOCKED_DECOR`(`display.gd`), `set_display_mode`·`set_window_size`·`toggle_fullscreen`·`available_sizes`·`apply_display`·`_apply_plan_to_window`, `_unhandled_input`, `detach_for_run`의 화면 몫, `save`의 `display`).
- 완료 확인(메인, diff): `save_store.gd`·`game_session.gd`의 diff 0, `audio`·`controls`의 읽기·쓰기 줄이 그대로, `window_locked`가 `_load`보다 먼저 정해진다, 잠긴 갈래가 `get_window()`·`DisplayServer.window_set_*`·`min_size`를 부르지 않는다, `_apply_plan_to_window`가 15줄 안쪽이고 `call_deferred`는 그 안에만, `_notification`이 없다, `clean_display`가 빠진 칸을 고친 것으로 치지 않는다, `display.gd`가 창을 건드리는 API를 부르지 않는다, `set_window_size`가 크기와 모드를 함께 견주고 둘 다 같을 때 `apply_display()`만 부른다(`_dirty`·`changed` 없음), `apply_display`가 잠겼을 때 본보기 모니터로 셈하고 `_apply_count`를 늘린다, `detach_for_run`이 `_window_calls`·`_apply_count`를 건드리지 않는다, `sizes_for`가 640×360도 안 들어가는 넓이에서 `[BASE]`, 기계적 확인 다섯.

**작업 2. 단축키·예약·조준의 셈** (Sonnet. 결정 528·530)
- 대상: `project.godot`([input]에 `toggle_fullscreen` 한 블록 — 기존 일곱의 꼴), `scripts/controls.gd`(`RESERVED` 한 줄), `scripts/ui/settings_screen.gd`(`CONTROLS_HINT` 한 줄), `scripts/duel/duel_scene.gd`(`_unhandled_input`에 F11의 멈춤 한 갈래, `aim_cell` 빼기).
- 완료 확인(메인, diff): `project.godot`의 diff가 [input]의 그 블록뿐([display]·기존 액션 그대로), `duel_core.gd`·`scripts/ai/`의 diff 0, `aim_cell`의 셈이 옛 두 줄과 같다, F11 갈래가 `set_input_as_handled`를 부르지 않는다, 멈춘 판(`paused and not _holding`)의 이른 `return`보다 F11 갈래가 뒤에 있어 멈춤 화면 위에서는 판에 아무 일이 없다.

**작업 3. 화면 탭** (Sonnet. 결정 529)
- 대상: `scripts/ui/settings_screen.gd`(`TABS` 한 줄, `_build_display`, `changed`·`size_changed`를 듣는 글 고침, `_close`의 끊기).
- 완료 확인(메인, diff): 소리·조작 탭의 줄이 그대로, 열 때 `set_pressed_no_signal` 뒤에 신호를 잇는다, 모드·크기 버튼이 `pressed`에 이어져 있고 `toggled`가 아니다, 듣는 처리기가 `add_child`·`remove_child`·`queue_free`를 부르지 않는다, `_process`·`Timer`를 쓰지 않는다, 테마 `.tres`·`day_ui.gd`의 diff 0.

**작업 4. 격리의 확인 줄과 창 도구** (Sonnet. 결정 531)
- 대상: `tests/ui_shots.gd`(끝의 `display,` 한 줄), `tests/run_ui_shots.ps1`(그 줄의 판정, 머리 주석), `tools/start-playtest.ps1`(`BRAVI_SETTINGS_PATH` 세 줄).
- 완료 확인(메인, diff): 파일마다 diff가 그 줄들뿐, `.ps1`이 ASCII, `start-playtest.ps1`이 `finally`에서 원래 값으로 되돌린다.

**작업 5. 테스트** (Sonnet. 새 `tests/display_tests.gd`, `tests/run_tests.gd`에 한 줄, 기존 기대값 둘. 테스트 설정 파일 `user://bravi_test_settings_S04.json`, 인스턴스는 `path`를 넣은 뒤 트리에 붙인다(S01 결정 500). 새 인스턴스는 `window_locked`가 참인지 먼저 단언한다(러너는 헤드리스이고 명령 줄에 `res://tests/`가 있다). 끝에 파일을 지우고, 조작을 건드린 단계는 S03 결정 523대로 되돌린다)
- 기존 기대값:
  - T0(`project_tests.gd`): 표에 `["toggle_fullscreen", "key", KEY_F11]` 한 줄.
  - T75(`manuscript_tests.gd` 148행 근처): 조작 탭 다음에 `TabDisplay`도 눌러 `_check_text`·`_check_buttons`를 지나게 한다(버튼 크기 표에 `DisplayWindowed`·`DisplayFullscreen` 160×42, `Size_*` 104×42).
- **T102 "화면 설정: 값·격리·셈"**:
  1. 늘이기: `ProjectSettings`의 뷰포트 1280×720, `stretch/mode` `canvas_items`, `stretch/aspect`가 `keep`(적혀 있지 않으면 기본값). 러너의 자동 로드 `/root/Settings`가 `window_locked` 참, `_window_calls` 0, `path` 빈 글, `display`가 처음 값, `last_plan.size` 1280×720·`clamped` 거짓(본보기 모니터로 셈했다 — 헤드리스의 빈 모니터가 아니다).
  2. 읽기(`normalize`와 새 인스턴스): `display` 없음 → 창·1280×720, 거짓. `{"mode": "fullscreen"}` → 전체 화면·1280×720, 거짓. `{"width": 1216, "height": 684}` → 그 크기, 거짓(목록 밖이어도 16:9·64 배수). `"mode": "exclusive"`·`"mode": 3`·`"width": "1600"`·`1600×1000`(16:9 아님)·`1040×585`(16:9이지만 64 배수 아님)·`320×180`·`8192×4608` → 그 칸만 처음 값, 참. 모르는 칸 `"vsync"` 남음. 깨진 JSON → 처음 값, 오류 줄 없음.
  3. 쓰기·분리: 음량만 바꿔 적은 파일에 `display`가 없다. `set_window_size(1600×900)` 뒤 적으면 `{"mode": "windowed", "width": 1600, "height": 900}`, 새 인스턴스가 읽으면 같은 값이고 `last_plan.size`가 1600×900. 전체 화면으로 바꿔 적고 다시 읽으면 전체 화면이고 크기는 1600×900이 남는다. 테스트 세이브(`user://bravi_test_save_S04.json`)의 바이트가 그대로이고 세이브에 `display`가 없다(S01 T97-3의 꼴). 같은 값(창·1600×900에서 `set_window_size(1600×900)`, `set_display_mode(&"windowed")`)을 다시 넣으면 거짓, `changed` 없음, `_dirty` 거짓, 파일의 바이트 그대로, **`_apply_count` +1**(창에 다시 걸었다 — 기술 T1). 전체 화면·1600×900에서 `set_window_size(1600×900)` → 참, 창·1600×900, `changed(&"display", &"mode")` 하나(크기는 같아 `&"size"` 없음 — 디자인 D1). `detach_for_run()` 앞뒤로 `_window_calls`·`_apply_count`가 같다(기술 T2 (3)). 모든 단계에서 `_window_calls` 0.
  4. 크기 목록·맞춤(셈만): `sizes_for` — 쓸 수 있는 넓이 1920×1040(1080 모니터의 작업 표시줄), `decor` 16×40 → [1280×720, 1600×900](1920×1080은 빠진다). 2560×1400 → 셋. 3840×2120 → 넷. 1366×728 → [1216×684] 하나(대신 크기). 7680×4280 → 다섯. **0×0(헤드리스의 빈 모니터)과 600×300 → [1280×720] 하나, `fit_size(1920×1080, 0×0)` → 1280×720**(기술 T2 (2)). `fit_size(1920×1080, 1920×1040)` → 1600×900이고 `plan.clamped` 참. `available_sizes()`(잠긴 실행) → 1280×720 · 1600×900 · 1920×1080. `size_name` "1600×900".
  5. 좌표(셈): 창 크기 1280×720 · 1600×900 · 1920×1080 · 2560×1440 · 1366×768 · 1280×1024(위아래 띠) · 2560×1080(양옆 띠) · 3440×1440 · 1000×700마다 — `content_rect`가 띠를 맞게 낸다(16:9 창은 띠 0). 9칸의 가운데와 각 칸 경계의 안쪽 3화소 점을 뷰포트 좌표에서 창 좌표로 옮긴 뒤(`content_rect`로) `to_viewport`로 되돌려 `DuelScene.aim_cell`에 넣으면 처음 칸이 나온다. 띠 위의 점(왼쪽 띠의 가운데 높이, 위쪽 띠의 왼쪽 끝)은 가장 가까운 가장자리 칸(0,1)·(0,0).
     - **엔진의 길(헤드리스에서만)**: 먼저 루트 창의 처음 `size`와 `get_screen_transform()`을 담아 둔다(헤드리스의 처음 크기가 1280×720이라고 가정하지 않는다). 창 크기 둘로 잰다 — 1600×1000(나누어떨어지는 배율: 배율 1.25 ± 0.001, 이동 (0, 50) ± 1)과 **1366×768(분수 배율 1.0667, 양옆 띠가 1화소 안쪽 — R2의 반올림을 잰다: 배율과 이동이 `content_rect`와 1화소 안)**. 1600×1000으로 두었는데 변환이 바뀌지 않으면 `INFO T102 [5] 헤드리스 루트 창의 크기가 늘이기에 반영되지 않음 — 엔진의 길은 사용자 몫`을 찍고 건너뛴다(실패로 치지 않는다, 보고서 2번에 적는다). 반영되면: 연습 결투(`Plain.of(바르톨로)`, 시드 1, `_use_virtual_mouse` 참, `mouse_aim_enabled` 참)에 **`Display`의 셈으로 만든 창 좌표**의 마우스 움직임을 `Input.parse_input_event`로 보내(엔진의 변환을 테스트가 쓰지 않는다 — 셈과 엔진이 다르면 잡힌다) 크기마다 9칸의 가운데와 칸 경계 안쪽 3화소 점에서 `core.aim_direction`·`core.aim_height`가 그 칸이고, 띠 위의 점(1600×1000은 위쪽 띠 창 y 20, 1366×768은 왼쪽 끝 x 0)은 가장자리 칸이다. 끝에 루트 창을 **담아 둔 처음 `size`로 되돌리고 `get_screen_transform()`이 담아 둔 것과 같은지** 단언한다(뒤의 묶음이 같은 창을 쓴다). 첫 V1에서 이 길이 돌았으면 INFO 갈래를 실패로 바꾼다(작업 7).
  6. 예약: `Controls.reserved_use("key:4194342")`가 "전체 화면". `{"controls": {"attack": "key:4194342"}}` → 공격만 처음 값, `controls_repaired` 참.
- **T103 "화면 탭·F11·결투의 멈춤"**:
  1. 탭(테스트 인스턴스, 처음 값): 열고 `TabDisplay`를 눌러도 `changed` 없음·파일 없음. `DisplayWindowed`가 눌려 있고 `Size_1280x720`이 눌려 있다, 크기 버튼 셋(잠긴 본보기), `DisplayNow`가 "지금: 창 1280×720", `DisplayNote` 숨음. `Size_1600x900` → `display.size` 1600×900·창, `changed(&"display", &"size")`, 파일에 1600, 버튼 눌림이 옮겨 갔다, "지금: 창 1600×900". `DisplayFullscreen` → 전체 화면, `Size_1600x900`은 눌린 채, "지금: 전체 화면". **전체 화면에서 눌린 `Size_1600x900`을 누른다 → 창·1600×900, `changed(&"display", &"mode")` 하나, 파일이 `"windowed"`로 다시 적혔다, `DisplayWindowed`가 눌린 모습**(디자인 D1). **창·1600×900에서 이미 눌린 `Size_1600x900`과 `DisplayWindowed`를 차례로 누른다 → 누를 때마다 `_apply_count` +1, `changed` 0, 파일의 바이트 그대로**(끌거나 최대화한 창을 되돌리는 길, 기술 T1). 다시 전체 화면으로 두고 `Size_1280x720` → 창·1280×720. `display_repaired`가 참인 인스턴스로 열면 화면 탭에 "읽을 수 없는 화면 설정" 알림, 두 번째 열면 없다. 적힌 크기 1920×1080에 `last_plan.clamped`를 참으로 둔 경우 "들어가지 않아" 알림. 모든 단계에서 `_window_calls` 0.
  2. 실제 클릭: 화면을 `_layout_now`로 놓은 뒤 `Size_1600x900`의 가운데를 뷰포트 → 창 좌표로 바꿔 누름·뗌을 보낸다(S03 T101-2의 꼴, 양성 대조 그대로 — 닿지 않으면 INFO와 사용자 몫) → 창·1600×900. 같은 자리를 **한 번 더 클릭**(묶음 안의 이미 눌린 토글) → `_apply_count` +1, `changed` 0, 버튼은 눌린 채(엔진이 다시 누른 토글에 `pressed`를 보내는지를 실제 길로 본다 — 기술 T1). 전체 화면으로 두고 같은 자리를 클릭 → 창·1600×900(디자인 D1).
  3. F11(실제 입력 길, `Input.parse_input_event`): 처음 화면(저장 없음) 위에서 F11 누름·뗌 → 자동 로드의 `display.mode` 전체 화면, `last_plan.mode` 전체 화면, `_window_calls` 0, 파일 쓰기 없음(잠긴 실행의 `path`는 빈 글). echo 누름 → 바뀌지 않음. 다시 F11 → 창. 설정 화면이 화면 탭으로 열린 채 F11 → 탭의 눌림·"지금" 글이 따라온다. 조작 탭의 기다림 중 F11 → 알림에 "전체 화면", 모드 그대로, 기다림 그대로.
  4. 결투의 멈춤: 연습 결투가 흐르는 중 F11 → `paused` 참, 멈춤 화면이 붙었다, 모드 전체 화면, `pauses` +1. 멈춤 화면 위에서 F11 → 창, `pauses` 그대로. "계속" → 대기 → 대기 중 F11 → 다시 멈춘다(`pause`가 대기를 다시 멈추는 S02 길). 끝난 판에서 F11 → 멈추지 않고 모드만 바뀐다. 끝에 자동 로드의 `detach_for_run()`(모드·조작을 처음 값으로).
- 완료 확인: 기계적 확인 다섯. 기존 테스트의 diff가 위의 기대값 둘뿐(검사 줄을 지우지 않았다).

**작업 6. 찍기** (Sonnet. `tests/ui_shots.gd`, `tests/run_ui_shots.ps1`)
- 새 장 `settings-display`(저장 없는 처음 화면에서 설정 → 화면 탭, 처음 값, 잠긴 본보기의 크기 셋). `settings-controls`·`settings-controls-empty`는 흐린 글에 F11이 더해진 채로 다시 찍힌다. 장 수 24 → 25, `$count`와 머리 주석(ASCII). 새 장은 `wearhit` 판정 목록에 든다.
- 완료 확인(메인, diff): 장 목록 한 줄, 판정 목록, `run_ui_shots.ps1`이 ASCII.

**작업 7. verifier의 확인** — V1을 넘기고, 통과하면 메인이 격리 파일을 적고 V1b를 넘긴 뒤 그 파일을 지운다. 실패하면 로그의 줄로 가려 범위·규칙을 바꾸지 않는 오류만 고쳐(Sonnet) 다시 맡긴다. 통과하면 커밋한다.
- **INFO 갈래 굳히기**: 첫 V1의 로그에 T102-5의 INFO 줄이 없으면(헤드리스에서 엔진의 길이 돌았다) 그 INFO 갈래를 실패로 바꾸고(Sonnet, 한 줄) V1b와 함께 다시 돌린다 — 뒤에 엔진이 바뀌어 길이 끊기면 조용히 건너뛰지 않게. INFO가 찍혔으면 그대로 두고 보고서 2번에 "엔진의 길은 자동으로 못 봤다"를 적는다. T103-2의 INFO도 같다.
- 메인이 읽는 장(1280): `settings-display`, `settings-controls`. 화면 탭의 다섯 줄이 판 안에 들고 잘리지 않는지, 탭 셋이 한 줄에 서는지, 조작 탭의 흐린 글이 F11을 담고도 판 안에 드는지.

**작업 8. 문서와 커밋**
- `docs/DECISIONS.md` "계획 S04"(525~532와 실행 중에 정한 것, Q1~Q3의 답), `CLAUDE.md`(1장 화면 줄에 "설정의 화면 탭: 창 / 테두리 없는 전체 화면, 창 크기. F11" 한 마디, 3장 조작 표에 F11 한 줄과 멈추는 때, 5장 "지금 만든 범위"의 설정에 화면 탭, 8장 폴더에 `scripts/display.gd`, 9장 설정 갈래 줄에 S04 끝), `docs/HANDOFF.md` 1번(설정 갈래 끝 — 다음은 5단계를 사용자에게 묻는다), 보고서 `docs/reports/S04-display-mode.md`(10장 형식. 2번에 아래 "직접 해 보실 것", 4번에 "설정 갈래 S01~S04 끝 — 5단계(사운드) 진행 여부").
- 완료 확인: `DECISIONS.md`에 `^525\.`~`^532\.`이 하나씩, `git status`가 깨끗하다.

## 맡길 확인

- **V1 (verifier, 작업 6 뒤)** `tests/verify.ps1 -Shots "$env:TEMP\bravi-S04\after"` → `VERIFY: OK`, `ALL PASS 103/103`(오류·경고 0), 스모크 OK, 가져오기 오류 0, 장 수 상대 57·UI **25**·패턴 38, UI의 `size,`가 모두 1280x720, `display,1,0` 한 줄, 새 장의 `wearhit` 0. T102-5·T103-2가 INFO로 건너뛰었는지 한 줄. 실행 **전후**로 `user://`의 `bravi_settings.json`·`bravi_playtest_settings.json`·`bravi_save.json`이 생기거나 바뀌지 않았고(verifier는 읽기만 한다), 테스트 파일 `bravi_test_settings_S04.json`·`bravi_test_save_S04.json`이 남지 않았다.
- **V1b 격리의 시험 (verifier, V1 뒤)**: 따로 둔 격리 파일 `user://bravi_iso_settings_S04.json`을 **메인이** 맡기기 전에 적는다 — 내용 `{"version": 1, "display": {"mode": "fullscreen", "width": 1920, "height": 1080}, "controls": {"attack": "key:4194342"}}`(전체 화면, 큰 창, F11에 묶인 공격). 자리는 S03 V1b와 같은 프로젝트의 `user://` 폴더. 사용자·확인용 설정 파일은 건드리지 않는다.
  - verifier의 명령 하나: `$env:BRAVI_SETTINGS_PATH = 'user://bravi_iso_settings_S04.json'; powershell -ExecutionPolicy Bypass -File tests/verify.ps1 -Only tests,smoke,ui,pattern -Shots "$env:TEMP\bravi-S04\iso"` → `VERIFY: OK`, `ALL PASS 103/103`, 스모크 OK, **창으로 찍은 UI 장의 `size,`가 모두 1280x720**(창이 전체 화면·1920×1080으로 바뀌지 않았다), `display,1,0`.
  - verifier는 명령과 읽기 전용 전후 비교만 한다: 격리 파일의 바이트가 전후 같다, V1의 세 파일도 전후 같다. V1b 보고를 받은 뒤 **메인이** 격리 파일을 지우고 커밋 전에 지운 것을 확인한다.
- **창의 확인은 사용자가 직접 한다**(Q1 "가", 사용자 답 2026-11-27. playtester를 부르지 않는다 — 창 도구는 보이지 않는 따로 된 데스크톱에서 돌아 진짜 모니터·전체 화면·여러 모니터를 볼 수 없다) — 보고서 2번 "직접 해 보실 것":
  1. 설정 → 화면에서 창 크기를 1600×900(그리고 들어가면 1920×1080)으로: 창이 그 크기로 모니터 가운데에 서는가. 연습 결투에서 커서를 아홉 칸(옅은 격자선)에 차례로 두면 조준 표시가 커서의 칸과 같은가. 연습 결투 중 Esc → 설정 → 화면에서 크기를 바꾸고 "계속"한 뒤에도 조준이 맞는가. 창을 끌어 바꾼 뒤 이미 눌린 크기 버튼을 누르면 그 크기로 돌아오는가.
  2. 전체 화면: 테두리 없이 모니터를 덮는가. **가장자리(대개 아래나 오른쪽)에 1화소 줄이 보이는가** — Windows의 테두리 없는 전체 화면이 일부러 남기는 줄이다(결정 527). 거슬리면 알려 주세요: 대안은 배타 전체 화면(해상도는 그대로, 줄 없음, 대신 Alt+Tab마다 화면 전환이 일어나 잠깐 검어질 수 있다)이고 바꾸는 곳은 한 줄이다. 전체 화면에서 눌린 크기 버튼을 누르면 그 크기의 창으로 돌아오는가. 16:9가 아닌 모니터면 검은 띠가 생기고, 커서를 띠 위에 두면 가장 가까운 가장자리 칸이 되는가. 커서와 칸이 맞는가.
  3. F11을 처음 화면·카운터·결투 중·멈춤 화면에서: 바뀌는가, 결투 중에는 먼저 멈추는가, 카운터에서 초점 버튼이 눌리지 않는가.
  4. 전체 화면 또는 1600×900으로 두고 끄고 다시 켜기: 그대로 열리는가, 켤 때 잠깐 창이 바뀌는 것이 거슬리지 않는가.
  5. 창 가장자리를 끌어 길쭉하게: 검은 띠가 생기고 조준이 맞는가. 다시 켜면 고른 크기로 돌아오는가.
  6. 모니터가 둘이면: 창을 둘째 모니터로 옮긴 뒤 전체 화면이 그 모니터를 덮는가, 크기 목록이 그 모니터에 맞는가.
  7. 전체 화면에서 Alt+Tab: S02의 멈춤이 그대로인가, 돌아오면 전체 화면 그대로인가.

## 위험

- **R1 테스트·찍기가 진짜 창을 바꾼다**: 잠금은 명령 줄·헤드리스로 정하고(결정 531, 실행 차례에 기대지 않는다), T102-1이 러너의 잠금과 `_window_calls` 0을, V1b가 전체 화면·1920×1080이 적힌 파일을 건 채 창으로 찍은 장의 크기를 본다. 새 찍기 도구는 `res://tests/` 아래에 두는 한 저절로 잠긴다. 테스트 밖의 경로로 결투 씬을 띄우는 도구가 생기면 이 규칙을 다시 본다.
- **R2 셈과 엔진의 변환이 다르다**(분수 배율의 반올림): T102-5가 칸 가운데와 경계 안쪽 3화소로 보고, 헤드리스 루트 창으로 엔진의 길을 두 크기(나누어떨어지는 1600×1000, 분수 배율 1366×768)에서 탄다. 헤드리스에서 루트 창의 크기가 늘이기에 반영되지 않으면 INFO로 건너뛰고 사용자 확인 1·2·5가 본다.
- **R3 T102-5가 루트 창을 되돌리지 않아 뒤의 묶음이 흔들린다**: 처음 `size`·변환을 담아 두고 끝에 되돌린 뒤 같은지 단언한다. 헤드리스가 아니면 이 단계 자체를 건너뛴다.
- **R4 S02의 알림 버그가 다시 난다**(모드를 바꾸는 동안의 포커스·크기 알림): 새 코드에 알림 처리기가 없고, 듣는 처리기는 글만 고친다(결정 527·529, 작업 1·3의 diff 확인). 결투의 F11 멈춤은 입력 처리 안에서 붙인다(알림 안이 아니다). 사용자 확인 3·7.
- **R5 모드를 바꾼 같은 프레임에 크기가 먹지 않는다**(전체 화면 → 창): `_apply_plan_to_window`의 다음 프레임 한 번 더. 자동 확인이 닿지 않는 곳이라 사용자 확인 1·3이 본다. 어긋나면 그 함수 하나를 고친다.
- **R6 켤 때 창이 잠깐 바뀐다**: 엔진이 창을 먼저 1280×720으로 띄우기 때문이다. 없애려면 `override.cfg`를 써야 해서 이 계획에서는 받아들인다(사용자 확인 4, 거슬리면 BACKLOG).
- **R7 작은 모니터**(1366×768 등): `sizes_for`의 대신 크기 하나(T102-4). 적힌 크기가 들어가지 않으면 줄여 열고 파일은 그대로(큰 모니터로 옮기면 돌아온다).
- **R8 Windows의 `MODE_FULLSCREEN`은 가장자리에 1화소 테두리를 남긴다**(엔진의 의도된 동작 — 기술 검토 1회차): `MODE_FULLSCREEN`을 고른 까닭과 대안(배타 전체 화면, 한 줄)은 결정 527. 사용자 확인 2가 그 줄을 보고, 거슬린다고 하면 바꿀지를 사용자에게 묻는다(배타 모드는 Alt+Tab마다 전환이 일어나고 S02의 포커스 멈춤이 함께 걸린다).
- **R9 편집기의 "게임 창 안에 넣기"(Godot 4.4 뒤)에서 모드를 바꾸면 편집기 안에서 이상하게 보일 수 있다**: 사용자는 `play.ps1`로 켠다. 편집기의 F5는 이 계획의 확인 대상이 아니다.
- **R10 고해상도 배율(Windows 150% 등)**: 크기는 물리 화소이고 쓸 수 있는 넓이도 물리 화소로 견준다(엔진 기본 `allow_hidpi`). 사용자 확인 1·6.

## 검토 전에 물을 것

- **답 받음(2026-11-27, 선택 창)**: 셋 모두 권한 답이다. v1의 본문이 권함으로 쓰였으므로 v2는 조건 갈래를 확정 문장으로 바꿨을 뿐이다.

| 물음 | 고른 답 | 계획에 미친 것 |
|---|---|---|
| Q1 창에서만 보이는 확인(여러 창 크기·전체 화면·여러 모니터의 커서와 조준칸) | 가 — 사용자가 직접 | "맡길 확인"의 "직접 해 보실 것" 일곱, playtester·V2 없음 |
| Q2 손으로 끌어 바꾼 창 크기 | 가 — 끌 수 있고 기억하지 않는다 | 결정 527(다음에 켜면 고른 크기), 결정 529의 "지금" 글 "끌어서 바꿨다", 사용자 확인 5 |
| Q3 전체 화면 단축키 | 나 — F11 하나 | 결정 528(Alt+Enter 갈래를 지웠다), `project.godot`의 액션 한 줄·`RESERVED`·`CONTROLS_HINT`, T0의 한 줄, T102-6, T103-3·4, 사용자 확인 3 |

- planner가 임시로 정한 것(되돌리기 쉽다): 모드는 창과 테두리 없는 전체 화면 둘(배타 전체 화면 없음), 표준 크기 다섯과 대신 크기 하나·64 배수의 16:9면 읽음(525), 곧바로 걸고 되돌림 타이머 없음(527), 크기 버튼은 창으로 돌려 놓음(526), 모니터를 적지 않음(527), 창의 가장 작은 크기 640×360(527), 흐르는 결투의 F11은 먼저 멈춤(528), 도움말에는 F11을 적지 않음(528), 잠긴 실행의 본보기 모니터 2560×1400(526), 창 도구가 확인용 설정 파일로(531).

## 검토 대응 기록

- v1 → v2(검토 전, 사용자 답 반영): 머리의 버전, 근거에 답 받음 줄, 목표 3의 "Q3 '나'일 때" → "Q3 '나'", 결정 527·528의 "권함" → 사용자 답, 결정 528의 "Q3 가/다" 갈래 문단을 지우고 Alt+Enter를 넣지 않는 까닭 한 마디, 작업 목록 머리 줄, "맡길 확인"의 Q1 표기, "검토 전에 물을 것"을 답 받음 표로. 검토는 아직 없다.
- v2 → v3(1회차: 디자인 REVISE · 기술 REVISE). D1과 T1은 한 설계로 풀었다 — "값이 같으면 아무것도 안 함"을 "모드·크기를 함께 견주고, 둘 다 같으면 창에 다시 건다(파일·`changed`·`_dirty`는 그대로)"로 바꿨다.
  - **D1 (디자인, 전체 화면에서 눌린 크기 버튼)**: 수용. 결정 526(`set_window_size`가 크기와 모드를 함께 견준다 — 모드가 바뀌면 같은 값이 아니다, `changed(&"display", &"mode")`), 결정 529(눌린 버튼을 누르면 그 크기의 창으로, 잇는 신호는 `pressed`), 목표 1, T102-3, T103-1(전체 화면에서 눌린 `Size_1600x900` → 창·1600×900·`changed` mode·파일), T103-2(실제 클릭), 사용자 확인 2.
  - **T1 (기술, 끌거나 최대화한 창에서 눌린 버튼)**: 수용. 결정 526(둘 다 같으면 `apply_display()`만, 거짓), 결정 527(`_apply_count` — 잠겨도 센다), 결정 529(`pressed`로 잇는다, `toggled`는 쓰지 않는다), 작업 1·3의 완료 확인, T102-3·T103-1(`_apply_count` +1·`changed` 0·파일 그대로), T103-2(묶음 안의 눌린 토글을 실제 클릭으로 다시), 사용자 확인 1.
  - **T2 (기술, 잠긴 실행의 모니터)**: 수용. (1) 결정 525 `LOCKED_USABLE`·`LOCKED_DECOR`, 결정 526 `available_sizes`, 527 `apply_display`의 `plan`, 531 `detach_for_run`의 `last_plan`이 같은 본보기 모니터, T102-1(`last_plan` 1280×720·`clamped` 거짓). (2) 결정 525 `sizes_for`·`fit_size`의 바닥 `[BASE]`, T102-4에 0×0·600×300. (3) 결정 531 `detach_for_run`은 `_window_calls`·`_apply_count`를 건드리지 않는다, 작업 1의 완료 확인, T102-3.
  - 기술 비차단(1px 테두리와 배타 모드): 받음. 결정 527에 `MODE_FULLSCREEN`을 고른 까닭(Alt+Tab·포커스 멈춤과의 관계)과 한 줄 대안, R8 고쳐 씀, 사용자 확인 2에 1화소 줄과 대안.
  - 기술 비차단(T102-5): 받음. 처음 `size`·변환을 담아 두고 되돌려 견줌, 분수 배율 1366×768 더함, 작업 7에 "엔진의 길이 돌면 INFO 갈래를 실패로", R2·R3.
  - 디자인 비차단(멈춤 → 설정 → 화면 → 계속 뒤 조준): 받음. 사용자 확인 1.

## 계획 뒤의 차례

S04 보고로 설정 갈래 S01~S04가 끝난다. 보고서 4번에 **"설정 갈래 끝 — 5단계(사운드) 진행 여부"**를 사용자 결정으로 둔다(S01 Q-B "가": S04 뒤 5단계). 사용자가 "다음 진행"이라 하면 5단계의 첫 계획을 쓴다. 이 계획은 5단계를 시작하지 않는다.
