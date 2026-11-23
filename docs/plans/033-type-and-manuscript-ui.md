# 계획 033: 글꼴과 UI의 꼴 "필사본" — 코드로 그린 양피지

- 버전: v3 (1회차 검토 대응: 기술 T1~T4와 비차단 여섯, 디자인 비차단 하나. 끝의 "v3에서 바뀐 곳". v2는 검토 전 사용자 답 — 완료 기준 "025 견본 화면처럼", 도움말 띠를 없애고 처음 화면에 도움말, 글꼴은 원본 그대로. v1은 첫 판)
- 개발 단계: CLAUDE.md 9장 **4단계(아트 교체)**, 계획 028 "4단계 나눔"의 033 줄("글꼴(서브셋·라이선스)과 UI의 꼴 '필사본'(Theme), 글자 크기의 아홉 단계, HUD 손보기, 밀착의 모자-경고 글자 겹침(BACKLOG 020-1)"). 5단계로 넘어가지 않는다. 판정 코드(`scripts/duel/duel_core.gd`, `scripts/ai/` 아래, `scripts/duel/opponent_motion.gd`)와 시간·자세·부위·경제의 값은 고치지 않는다.
- 근거:
  - 사용자 지시(2026-11-23): "일단 테스트 다음의 계획 진행해줘". 그린 질감(바이블 16절)의 답: **"일단 코드로 그리고 스크린샷 찍어서 보여줘. 괜찮으면 그대로, 바꿀 게 있으면 그림."** → 이 계획은 질감을 코드(StyleBox·결 텍스처)로 만들고 게임 화면을 찍어 판 N으로 묻는다. 그림으로 바꾸는 일은 033b(결정 322).
  - **검토 전 사용자 답(2026-11-23, DECISIONS "2부의 판정")**: (1) 031 L1에 "아니 sample 많이 줬었잖아 너 왜 그거처럼 안만들어" → 판 S(왼쪽 025 견본 `ui-duel`을 `?ui=b`로 구운 것, 오른쪽 게임 `stage-alley-mid`)를 보고 **"맞다 — 025 견본 화면처럼"**. 이 계획의 완료 기준이다(결정 324). (2) Q2: **"이제 도움말 띠는 지워. 그리고 게임을 처음 킨 화면에 이어하기처럼 '도움말' 버튼을 만들어서 눌렀을 때 저 설명이 뜨는 화면을 보여줘."**(결정 323) 판 처음에 조작을 알리는 다른 장치는 두지 않는다. (3) Q1: **"가 — 원본 그대로"**. (4) 031·032의 다른 답(033 밖): L3 "크게 그린다(031b)", L4 "맞다", M2-1 "맞다", M2-2 "레이피어 꼴로 그린다(032b)", M2-3(엉킴 테두리 10)은 묻지 않았고 이 계획의 판 N에서 묻는다. 사용자가 033을 먼저 하라고 했다(033 → 031b·032b).
  - 견본 굽기(메인이 해 봤다): `docs/style/tools/bake025.ps1 -Budget 5000 -OutDir <dir> -Shots @('ui-duel+ui=b','ui-counter+ui=b','ui-settle+ui=b','ui-closing+ui=b')`. PowerShell 배열로 넘긴다(bash의 쉼표는 한 장으로 뭉친다). `?ui=b`가 필사본이다. 구운 장: `%TEMP%\bravi-style\033-samples\ui-duel-ui-b.png`. 견본의 화면은 "지금 게임의 자리·글·크기 그대로"이고 꾸밈만 필사본이다(바이블 6·10절). 견본은 HUD를 상대 위에, 내 손을 HUD 위에 그렸다(`sceneUiDuel`: 무대 → 상대 → HUD → 손).
  - 031·032 2부 결과(playtester, 2026-11-23): 테스트 75/75·스모크·가져오기·찍기 회귀 통과, 스크립트 오류 0. 실패 둘은 이 계획이 다룬다: (1) 밀착 큰 베기(`big-hold-close`)의 칼끝이 세 무대 모두 y ≈ 0~5·x ≈ 425~435까지 올라 칼날 위쪽 약 55화소가 반투명 `BandTop`(x 334~1006 · y 6~61) 밑을 지나 어둡게 보인다(교전 `big-hold`는 miny 64로 통과). (2) 준비·막기·이동·회수에서 장갑과 소매가 `help_bar`(y 616~720, 짙은 0.85) 밑이라 거의 안 보이고, 다 보이는 것은 높은 예비 동작 끝 셋뿐이다. 작은 것: 오른쪽 상단 조준에서 날밑이 "조준:" 글자 첫머리에 겹친다, `run_hand_shots.ps1`이 `size,` 줄을 보지 않는다(1886×1061 장도 OK), 이 컴퓨터는 1920×1080 창을 열지 못한다(`run_stage_shots` 1920 FAIL), 연습 결과 창의 Esc는 확인 못 했다. 찍은 폴더: `%TEMP%\bravi-031-shots`(무대 9), `%TEMP%\bravi-032-hand`(손 15), `%TEMP%\bravi-031-opp-stages`(21 + `ext.txt`), `%TEMP%\bravi-031-play\`.
  - 바이블 6절 "UI의 꼴 — 나 · 필사본"의 표, 9절 글꼴(나눔스퀘어라운드 ExtraBold · 송명 · Noto Sans KR 900, 해시 앞 16자리, "배포할 때 지킬 것"), 10절 글자 크기 아홉 단계·선 굵기·여백과 버튼, 16절의 "글꼴 파일"·"글자 크기와 HUD의 자리"·"그린 질감"·"밀착에서 모자와 엉킴 경고 글자" 줄. 명세 4부(같은 값, "4단계로 넘기는 것": 방심 막대가 코드에서는 (850, 36)에 있고 위 가운데 패널이 양옆과 6·46화소 겹친다). 견본 `docs/style/samples/025-type-ui-size.html`: `paper` 필터(122~129행: 큰 결 `baseFrequency 0.012 0.02`·3옥타브·색 (0.36, 0.25, 0.15)·알파 0.45n − 0.14, 잔 결 0.85·2옥타브·(0.3, 0.2, 0.12)·0.3n − 0.08), `UI.b.panel`·`button`·`cell`·`bar`·`rule`(491~508행), `duelHud`(563~576행), 화면 넷(606~647행).
  - 지금 코드: 하루 화면은 `scripts/day_ui.gd`(색 `GOLD`·`RED`·`DIM`, `add_background`·`add_panel`·`add_button`·`add_counter_band`)를 `title.gd`·`counter.gd`·`settlement.gd`·`closing.gd`가 쓰고, 연습 선택 `commission_select.gd`과 결투 결과 `result_panel.gd`(검은 `ColorRect` 0.82)는 따로 만든다. 프로젝트 테마는 없다(`project.godot`에 `gui/theme` 없음). 글자 크기는 부르는 곳의 정수다(13·15·17·19·22·26·30·32가 단계 밖). 결투 HUD(`duel_hud.gd`, `CanvasLayer` layer 1)는 결정 298의 임시 띠 셋(`BandTopLeft`·`BandTop`·`BandBottomLeft`)과 `help_bar`(가로 전체 y 616~720)를 깔고 라벨에 짙은 테두리 4를 준다. 게이지 넷(`PostureCells`·`Meter`·`BindBar`·`ComplacencyBar`)은 `ThemeDB.fallback_font`로 글을 그린다. 결투 씬은 `Background`(CanvasLayer −1) → `OpponentView`·`PlayerSwordView`(기본 캔버스) → `HUD`(1) → `ResultPanel`(5)의 차례다. 상태 글자는 `opponent_view.tscn`의 `StateLabel`(28, 테두리 8). 엉킴 경고 글자는 HUD의 `BindWarning`(x 340~940 · y 104~138, 26).
  - 테스트가 보는 것: T73(`tests/stage_tests.gd`)이 띠 셋의 앵커·사각형·조용한 구역 밖과 HUD 라벨의 테두리 4를 본다(이 계획이 고친다). `bind_tests`·`lunge_tests`·`scene_tests`는 HUD의 `_bind_bar`·`_bind_warning`·`_aim_label`·`_log_label`·`_help_label`·`_debug_label`·`_complacency_bar`(이름 `ComplacencyBar`)와 `BindBar.COLOR_WARN`·`DuelHud.BIND_WARN_RATIO`·`BIND_WARN_TEXT`, 글의 `contains`만 본다. `day_tests`·`flow_tests`는 `ResultPanel.shown_score`·`is_showing()`과 화면의 노드 이름·글을 본다. 색·글자 크기·자리를 보는 테스트는 T73뿐이다.
  - 글꼴 파일은 로컬 `docs/style/generated/fonts/`에 있다: `nanumsquareround/NanumSquareRoundEB.ttf`(약 1.0MB)·`OFL-NAVER.txt`·`NAVER-FONT-LICENSE-NOTICE.txt`, `songmyung/SongMyung-Regular.ttf`(2.0MB)·`OFL.txt`, `notosanskr/NotoSansKR-wght.ttf`(가변, 10.4MB)·`OFL.txt`. 이 컴퓨터에는 Python이 없다(HANDOFF 4번).
  - 결정 번호는 312부터(DECISIONS의 마지막은 311).

## 검토 전에 받은 답 (v2)

| 물음 | 사용자의 답 | 반영한 곳 |
|---|---|---|
| L1(판 S를 보고) | **"맞다 — 025 견본 화면처럼"** | 목표와 범위, 결정 324, "견본과 다르게 두는 것", 작업 0·7·10 |
| Q1 글꼴 파일 | **가 — 원본 그대로** | 결정 313, 작업 1 |
| Q2 아래 띠와 손 | **도움말 띠를 없애고, 처음 화면에 "도움말" 버튼과 설명 화면** | 결정 316·323, 작업 4·5·6 |
| L3 · L4 · M2-1 · M2-2 | 크게 그린다(031b) · 맞다 · 맞다 · 레이피어 꼴로 그린다(032b) | 계획 뒤의 차례 |
| L2 · M2-3 | L2는 이 계획이 대신한다 · M2-3은 묻지 않았다 | M2-3은 판 N의 N3 |

**v2의 검토 전에 더 물을 것: 없다.** 남은 물음(N1~N3)은 게임 화면을 찍어야 답할 수 있고, 답마다 바뀌는 것이 작업 10·11에 적혀 있다.

**판 N0·판 A·판 S는 메인이 만들었다**(했음. 저장소를 고치지 않았다): `<W>\board-N0-layers.png`, `board-A-stages.png`, `board-S-sample-vs-game.png`와 감싸개 `boardN0.ps1` 등. 아래는 v1에서 판 N0과 물음을 적은 기록이다.

<details><summary>v1의 물음과 판 N0(기록)</summary>

이 계획의 물음은 둘(Q1 글꼴 파일, Q2 아래 띠와 손)이다. 031의 판 L(L1~L4)과 032의 판 M2(M2-1~M2-3)도 아직 묻지 않았으므로, **선택 창 두 개로 한 번에** 묻기를 권한다(창마다 넷까지, 그림을 먼저 보인다. 바이블 13.7).

| 창 | 먼저 보일 그림 | 물음 |
|---|---|---|
| **창 A — 무대와 칼** | 031의 판 L(무대 셋, 1920 대신 판 L0), 032 판 M2의 칼 장 | L1 무대 셋 "맞다 / 고친다", L3 1920의 늘어남 "괜찮다 — 지금 그림 / 크게 그린다(031b)", L4 의뢰마다의 무대 "맞다 / 고친다", M2-2 칼 "지금 꼴과 선으로 맞다 / 레이피어 꼴로 그린다(032b)" |
| **창 B — 손과 HUD** | 판 M2의 손 장(1280), 판 N0(아래) | M2-1 손 그림(크기·선·날밑과 자루·둥근 끝의 색) "맞다 / 고친다" — **띠에 가리는 것은 Q2로 따로 묻는다고 창에 적는다**, M2-3 엉킴 경고 테두리 10 "맞다 / 고친다", **Q2**, **Q1** |

- **L2(HUD의 임시 띠·테두리)는 묻지 않는다.** 이 계획이 임시 띠를 필사본 패널로 바꾸고 위 가운데 띠의 실패(칼끝)를 결정 316으로 푼다. 창 A의 머리에 "L2는 033이 대신한다" 한 줄을 적는다.
- M2-1과 Q2의 차례: 손 그림 자체(M2-1)를 먼저, 그 손이 띠에 가리는 것(Q2)을 다음에 묻는다. M2-1 "고친다"는 손 그림의 화소 손질(032b 또는 손·칼 움직임 계획)로 가고 이 계획을 바꾸지 않는다. Q2만 이 계획의 작업을 바꾼다.
- L3 "크게 그린다"(031b)·M2-2 "레이피어 꼴"(032b)은 이 계획과 파일이 겹치지 않는다(무대 그림, `player_sword_view`). 033은 그 답과 상관없이 같다. 031b·032b가 먼저 돌면 033의 작업 0에서 `git diff`로 겹침만 다시 본다.

**판 N0**(메인이 묻기 전에 만든다. 저장소를 고치지 않는다. `<W>\board-N0-layers.png`, 감싸개 `<W>\boardN0.ps1`, `System.Drawing`):
1. 위 줄 — 지금(실패 1): `%TEMP%\bravi-031-opp-stages`의 `big-hold-close`(뒷골목)에 지금의 `BandTop`(x 334~1006 · y 6~61, `#2E2620` 0.85)을 **칼 위에** 얹은 것 / 바꾼 뒤: 같은 장에 필사본 위 가운데 패널(x 433~847 · y 4~60, `#E9D8B4`, 테두리 3)을 **칼 밑에** 깐 것(칼이 패널 위로 지난다, 결정 316). 둘 다 x 380~900 · y 0~200을 1:1.
2. 아래 줄 — 손(실패 2): `%TEMP%\bravi-032-hand`의 가운데 준비·가운데 막기·오른쪽 높은 준비 셋을 1:1(x ± 200, y 480~720)로, 행 셋: (라) 지금(`help_bar` 짙은 0.85가 손 위) / (가) 필사본 띠(`#E9D8B4` 0.94)를 **손 밑에** 깐 꼴 — 띠 사각형을 먼저 칠하고 손 장에서 손·칼 화소만 얹는다(손 화소는 같은 장면의 HUD 없는 장이 없으므로 `assets/art/player/hand.png`와 칼 다각형을 결정 303·304의 자리·배율로 다시 그린다. 032 판 M1의 `<W032>\boardM1.ps1` 꼴) / (다) 필사본 띠를 **손 위에** 얹은 꼴. 장마다 아래에 "띠 위로 보이는 장갑 화소 / 장갑 높이".
- 감싸개의 값은 `duel_hud.gd`와 결정 298·316에서 읽어 적는다. 판의 글자는 숫자와 짧은 이름만.

| 물음 | 선택지 | 답에 따라 달라지는 것 |
|---|---|---|
| **Q1 글꼴 파일** | **가(권함) 원본 셋을 고치지 않고 싣는다** — 약 13.4MB(나눔스퀘어라운드 EB 1.0 · 송명 2.0 · Noto Sans KR 가변 10.4). 고치지 않았으니 Reserved Font Name을 바꿀 일이 없고 라이선스 글과 저작권 줄만 싣는다. 서브셋은 6단계 글이 다 정해진 뒤 내보내기 전에(바이블 16절의 줄을 그렇게 고친다) / 나 서브셋을 만든다 — HarfBuzz의 공식 Windows 배포(`hb-subset.exe`)를 저장소 밖에 받아 쓰고, Reserved Font Name이 있는 둘(나눔스퀘어라운드, Noto Sans KR)은 이름 표를 PowerShell로 고쳐 새 이름(`Bravi Round`, `Bravi State`)으로 낸다. 시험해 본 적 없는 길이고, 글이 늘 때마다 다시 만든다 / 다 Python과 fonttools를 이 컴퓨터에 깔아 서브셋과 이름 바꾸기를 한다(설치는 사용자 컴퓨터를 바꾼다) | 가: 작업 1이 복사·해시 대조뿐. 나·다: 작업 1에 도구 받기(나)·설치(다)와 서브셋 만들기, 이름 바꾸기, 글자 목록(게임의 글 628자 + KS X 1001 2,350자 + 기호)이 들고, T75의 글자 검사가 서브셋을 지킨다. 위험 R1이 커진다. 나에서 이름 표 고치기가 깨지면 그 글꼴만 원본으로 돌아가고 보고한다 |
| **Q2 아래 띠와 손** (실패 2) | **가(권함) HUD 패널을 인물 밑에 깐다** — 위 가운데처럼 아래 패널 둘과 도움말 띠(필사본 양피지 0.94)를 상대·손 밑 층(`HudBack`)에 두어, 손·칼이 늘 띠 위로 보인다. 도움말 글자는 가운데 조준에서 손에 조금 가린다 / 나 가 + 도움말 띠는 판 처음 10초 동안만 보이고 사라진다 / 다 띠는 지금처럼 손 위(필사본 0.94)에 두고, 손 자리를 올리는 일은 손·칼 움직임 계획으로(결정 308 밖) / 라 이대로 — 띠가 손 위(필사본 0.94라 지금보다 더 가린다) | 가·나: 결정 316의 아래 줄, 작업 5의 층 나눔, T73의 층 검사. 나는 `HELP_SHOW_SEC` 하나와 T73의 한 칸이 더해진다. 다·라: 아래 패널 둘과 도움말 띠는 HUD 층(1)에 남고 위 패널 셋만 `HudBack`이다. 다는 "계획 뒤의 차례"에 손·칼 움직임 계획을 올린다 |

- Q1을 묻는 까닭: 바이블 16절은 "서브셋을 만든다"인데 이 컴퓨터에는 서브셋 도구가 없고, 도구를 들이는 길은 바깥 실행 파일을 받거나 설치를 해야 한다. 가는 바이블과 다르게 가므로 사용자가 정한다.
- Q2를 묻는 까닭: 032의 M1-2 답은 "이대로"였지만 게임 화면에서 손이 거의 안 보이는 것이 확인되었다(실패 2). 층을 바꾸면 HUD가 인물에 가릴 수 있는 쪽으로 규칙이 바뀐다(위험 R4).

</details>

**031b·032b와 파일이 겹치는가(v2에서 다시 봄)**: v1의 판단을 유지한다. 031b는 무대 그림(`assets/art/stages/`, `data/stages/`의 그림 칸, `docs/style/tools/cutstage.ps1`의 값)을, 032b는 칼(`scripts/duel/player_sword_view.gd`·`scenes/duel/player_sword_view.tscn`, `assets/art/player/`, `data/player/`)을 바꾸고, 033은 그 어느 것도 고치지 않는다(넘지 않는 선). 겹칠 수 있는 곳은 넷뿐이고 모두 작다: (1) `tests/run_tests.gd`의 목록 줄(줄 하나씩 더하므로 합치기 쉽다. 테스트 수의 기대 값은 뒤에 도는 계획이 033의 76에서 센다), (1′) `tests/stage_tests.gd` — 033은 T73을 고치고, 031b는 무대 크기를 바꾸면 T72의 `STAGE_SIZES`를 고친다(서로 다른 함수와 상수라 033 뒤에 031b가 그 줄만 고치면 된다), (2) `scenes/duel/duel.tscn` — 033은 `Background`의 `layer` 한 줄만 고친다. 031b가 무대를 크게 그려도 `Background/Stage`의 텍스처 경로만 같으면 이 파일을 고칠 일이 없다, (3) 033이 엉킴 경고 글자를 내 칼 바로 위로 옮기므로(결정 318), 032b가 칼날 길이를 바꾸면 겹침을 그 계획의 찍기에서 다시 본다. 033이 먼저 돈다(사용자 지시).

### 넘지 않는 선

- 메인은 Godot·테스트·게임을 실행하지 않는다(`tests/run_tests.ps1`, `run_smoke.ps1`, 헤드리스 Godot, `play.ps1`, 찍기 러너 전부). `System.Drawing`·화소 재기·`git`·파일 복사·해시는 이 규칙 밖이다. 실행 확인과 찍기는 2부에서 playtester만 한다.
- 그림 생성은 하지 않는다(Codex 호출 0). 질감은 코드로만 만든다(사용자 답). 판 N에서 "그림으로"가 오면 033b가 몫을 먼저 묻는다.
- 고치지 않는 것: 판정 코드(위), `data/` 아래 의뢰·상대·무기·무대의 값, `scripts/duel/player_sword_view.gd`와 손 그림(032. 판 N의 N3 "고친다"일 때 `BIND_OUTLINE_WIDTH` 값 하나만 예외, 작업 11), `scenes/duel/opponent_view.tscn`의 `StateLabel` 밖의 노드, `docs/style/basis/`·견본 020~027, 사용자의 파일(`tools/`, `.codex/`, `AGENTS.md`, `.claude/agents/playtester.md`, `docs/plans/013-playtester.md`). `git commit` 하지 않는다.
- 편집은 작게: Write·Edit 한 번은 80줄 안쪽, 파일 하나·함수 하나씩. 스크립트마다 HANDOFF 4번의 기계적 확인 다섯(탭 들여쓰기, 같은 함수 안의 이름 겹침, `:= .*\.get\(`·`:= .*\[` 추론, 서식 문자열의 자리 수와 `%%`, `warning_ignore` 위치). 손으로 쓰는 `.tres`·`.tscn`은 `load_steps` = 자원 수 + 1, id 겹침 0, 경로가 모두 있는지. 한글이 든 `.ps1`은 UTF-8 BOM. 주석은 "왜"만 한 줄과 결정 번호.
- 작업 폴더 `<W>` = `%TEMP%\bravi-style\033`, 032의 것은 `<W032>` = `%TEMP%\bravi-style\032`.

## 목표와 범위

**완료 기준(사용자 답, 결정 324)**: 결투·카운터·정산·폐점의 게임 화면을 025 견본 화면(`?ui=b`, 필사본)과 같은 장면끼리 나란히 놓았을 때 **같아 보인다**. 견본이 없는 처음 화면·도움말·연습 선택·결투 결과는 같은 필사본 부품으로 만든다. 견본과 다른 곳은 아래 "견본과 다르게 두는 것"의 표에 까닭과 함께 있어야 하고, 표에 없는 차이는 고칠 거리다. 이 판정은 **정적 확인이 아니라 playtester가 찍은 게임 화면과 구운 견본을 나란히 댄 판**으로만 한다(작업 9·10). 사용자가 화가 난 지점("견본을 많이 만들었는데 게임이 그렇게 생기지 않았다")이 이 계획이 푸는 것이다.

**실행 차례**: 031·032 2부의 결과와 검토 전 답은 받았다(근거). 두 관점의 승인 뒤 작업 0부터 한다. **두 부분**으로 끝나고, **중심은 2부다**:

- **1부**: 작업 0~8. 견본 굽기, 글꼴·테마·화면·HUD·도움말·테스트·찍기 씬·문서. 정적 확인은 2부에서 헛걸음을 줄이는 몫이고 완료의 근거가 아니다.
- **2부**: 작업 9(playtester: 테스트와 찍기) → 작업 10(메인이 견본과 나란히 대어 차이를 고치고 다시 찍기를 두 번까지) → 판 N과 사용자의 답. 사용자가 스크린샷을 보여 달라고 했으므로 **1부가 끝나면 묻지 않고 바로 2부로 간다**.

**확인할 결과**:

1. 글꼴: 본문·버튼·HUD는 나눔스퀘어라운드 ExtraBold, 화면 머리 줄·간판·큰 수·주 버튼은 송명, 상태 글자와 엉킴 경고 글자는 Noto Sans KR 900이다. 화면의 어느 글자도 대체 글꼴로 떨어지지 않는다(T75). 글꼴 파일과 라이선스 글이 `assets/fonts/`에 있다(Q1의 답대로).
2. 필사본의 꼴: 처음 화면·카운터·정산·폐점·연습 선택·결투 결과의 벽과 패널이 양피지(`#E9D8B4`)에 종이 결, 패널은 바깥 테두리 3 + 5 안쪽 가는 선 1 + 네 모서리 마름모, 버튼은 제비꼬리 띠(상태 다섯: 보통·올림·누름·못 누름·값이 걸린 채 못 누름, 주 버튼은 송명의 붉은 글자), 글자는 잉크 색이다. 모두 코드(StyleBox·결 텍스처)이고 그림 파일은 없다.
3. 글자 크기가 아홉 단계(54·46·34·28·24·20·18·16·14) 밖에 없다(Grep과 T75).
4. 결투 HUD: 임시 띠 셋과 도움말 띠가 없어지고, 견본 `duelHud`의 자리에 필사본 패널 다섯(위 왼쪽·위 가운데·위 오른쪽·아래 왼쪽·아래 오른쪽)이 있다. 패널끼리 겹치지 않는다. 방심 막대는 위 오른쪽 패널 안(견본 자리)이다. 경고 막대 둘은 짙은 띠 위이고 경고 색은 코드 값 그대로다.
5. 실패 둘이 풀린다: 다섯 패널은 모두 상대·내 손 밑 층이라, 밀착 큰 베기의 칼이 위 가운데 패널 **위로** 지나고(결정 316), 손·칼이 화면 아래 끝까지 늘 보인다(도움말 띠가 없다, 결정 323).
6. 밀착에서 엉킴 경고 글자가 모자·두 줄 상태 글자와 겹치지 않는다(결정 318, BACKLOG 020-1의 밀착 줄).
7. 처음 화면에 "도움말" 버튼이 있고(저장이 있을 때와 없을 때 모두), 누르면 조작·규칙 글이 필사본 패널 화면으로 뜨고, 닫으면(버튼 또는 Esc) 처음 화면으로 돌아간다. 결투 화면에는 조작 안내가 없다(결정 323).
8. 정산·폐점의 장부가 견본처럼 이름은 왼쪽·수는 오른쪽 맞춤, 줄 사이 가는 줄선, 합계 위 두 줄 선이다(결정 325).
9. 판정은 그대로다: 판정 코드의 `git diff`가 0줄, 테스트는 `ALL PASS 76/76`(T73을 고치고 T75를 더하고, 도움말·장부를 보는 테스트를 새 꼴로 고친다).
10. **견본과 나란히 댄 판(판 N)에서 네 장면이 같아 보이고**(결정 324), 사용자가 질감을 "코드 그대로 / 그림으로" 정한다.

1부에서는 1·3·9를 Grep·코드 읽기·`git diff`로, 2·4·6·8을 사각형과 견본 좌표의 대조로 본다. 같아 보이는지(10), 게임에서의 모습, 글자 모습, 테스트 통과는 2부에서만 확인된다.

**범위 밖**: 그림으로 만든 질감(033b), 카운터 배경 그림과 의뢰인 그림(034. 견본의 그린 의뢰인 대신 지금의 색 사각형), 손·칼의 움직임과 자리(결정 308), 무대 그림(031b), 칼 그림(032b), 소리, 판 처음에 조작을 알리는 장치(사용자 답: 두지 않는다. 제안은 "계획 뒤의 차례" 5). BACKLOG의 018-F7(폐점 소지금 줄의 뜻)·018-F19(정산 머리 줄의 분모)는 글의 뜻이라 넣지 않는다. 018-F8(평판 줄의 자리)은 견본이 지금 자리(정산은 장부 패널 아래, 폐점은 나무 띠 위)에 그렸으므로 견본대로 두고 닫는다(결정 324). 손 찍기의 `size,` 검사는 BACKLOG 032-1로 남긴다(작업 8). 교전의 깃털 끝과 두 줄 상태 글자의 겹침(020-1의 교전 줄)은 판 N에 보이고 남으면 020-1에 남긴다.

## 설계 결정

312. **질감은 코드다**(사용자 답 "일단 코드로"). 그림 파일 없이 셋으로 만든다: (가) 결 텍스처 `scripts/ui/paper_grain.gd` — 고정 씨앗의 `FastNoiseLite` 둘(견본 `paper`의 큰 결과 잔 결)을 256×256 이음매 없는 RGBA 한 장으로 합쳐 정적 변수에 한 번 만든다(색 (0.36, 0.25, 0.15)·알파 0.45n − 0.14, (0.3, 0.2, 0.12)·0.3n − 0.08, 두 겹을 알파로 겹침). 큰 결의 주파수는 견본의 **세로 값 0.02**로 만들고, 그릴 때 **가로만 0.02 ÷ 0.012 ≈ 1.67배 늘린 타일(427×256)**로 깐다 — 견본의 결이 가로로 늘어난 섬유 꼴(가로 0.012 · 세로 0.02)이 되게(디자인 비차단). 잔 결도 같은 타일에 들어 가로로 1.67배 늘지만 0.85의 잔 점이라 눈에 띄지 않는다(판 N1에서 본다). (나) 패널 `scripts/ui/manuscript_panel_style.gd`(`extends StyleBox`, `@tool`) — 칠 → 결(427×256 타일을 **손으로 나눠** `canvas_item_add_texture_rect_region`으로 그린다. 텍스처 반복 설정에 기대지 않는다) → 바깥 테두리 3 `#3B2A1E` → 5 안쪽 가는 선 1 `#6B5440` → 네 모서리 마름모(반지름 4, `#D2B98C`, 선 1 `#3B2A1E`). 내보내는 값(칠·칠의 알파·결 세기·테두리·안쪽 선·마름모)을 0으로 하면 그 몫을 그리지 않는다(벽은 칠과 결만). (다) 버튼 `scripts/ui/swallowtail_style.gd`(`extends StyleBox`, `@tool`) — 견본 `UI.b.button`의 제비꼬리 다각형(홈 n = min(12, 높이 × 0.28)), 테두리 2.5, 위아래 5 안쪽의 가는 선 1(알파 0.7), 누름은 2화소 내려앉음(`sink`)과 글자 여백 위 +2·아래 −2. 값은 견본에서 옮긴 임시이고 판 N에서 본다. 되돌리기 쉽다(StyleBox 둘과 텍스처 하나).
313. **글꼴 파일**(Q1의 답 "가 — 원본 그대로"): `assets/fonts/`에 원본 셋을 해시가 같게 둔다(`NanumSquareRoundEB.ttf`, `SongMyung-Regular.ttf`, `NotoSansKR-wght.ttf`)와 라이선스 글(`OFL-NanumSquareRound.txt` = `OFL-NAVER.txt`, `NAVER-FONT-LICENSE-NOTICE.txt`, `OFL-SongMyung.txt`, `OFL-NotoSansKR.txt`)과 `assets/fonts/README.md`(글꼴마다 저작권 줄·Reserved Font Name·"고치지 않은 원본"·배포처 한 줄씩). 가져오기 설정은 Godot의 기본값(`.import`는 미리 쓰지 않는다). 서브셋은 6단계 글이 다 정해진 뒤 내보내기 전에 한다(바이블 16절의 "글꼴 파일" 줄을 그렇게 고친다).
314. **테마는 데이터다**: `assets/ui/manuscript_theme.tres`(Theme)를 프로젝트 테마(`project.godot`의 `gui/theme/custom`)로 건다. 기본 글꼴 나눔스퀘어라운드 EB·기본 크기 20, `Label` 글자색 `#3B2A1E`, `PanelContainer`·`Panel`의 `panel` = 결정 312 (나)(`content_margin` 0. 여백은 지금처럼 `MarginContainer`가 22·16), `Button` 다섯 상태(보통 `#E9D8B4` · 올림 `#D2B98C` · 누름 `#B8996C`+sink 2 · 못 누름 `#D2B98C`에 테두리·글자 `#6B5440` · 초점은 `StyleBoxEmpty`), 글자 여백 좌우 16 + 홈 12, 위아래 6. 형 변형 셋: `TitleLabel`(Label, 송명), `PrimaryButton`(Button, 송명, 글자 `#84422F`), `HaggledButton`(Button, 못 누름의 글자 `#7A5232`). 송명 자리는 `assets/ui/font_title.tres`(FontVariation, `base_font` = 송명, `fallbacks = [나눔스퀘어라운드 EB]`)를 쓴다 — 송명은 KS X 1001의 2,350자라 `—`(U+2014)·`·`·`→`·`…` 같은 기호가 빠질 수 있고, 빠진 글자는 본문 글꼴로 받친다(작업 1의 글자 대조가 미리 센다). 상태 글자의 글꼴은 `assets/ui/font_state.tres`(FontVariation, Noto Sans KR 가변, `variation_opentype`의 `wght` 태그 = 900).
   - **양피지 밖에 놓인 라벨은 색을 직접 준다**(기술 T1): 테마의 `Label` 글자색(잉크 `#3B2A1E`)은 양피지 위의 글을 위한 것이다. 무대·나무 띠 위에 바로 놓인 라벨은 덮어쓰기로 색을 준다 — 상대의 `StateLabel`은 흰색(바이블 9절 "28, 흰 글자, 검은 테두리 8"), 엉킴 경고는 `#FF7333`, 기록·디버그는 `ON_WOOD`(결정 319), 나무 띠 위의 글은 `ON_WOOD`(결정 315). 덮어쓰기가 없는 라벨이 무대·띠 위에 있으면 고칠 거리다(T75의 6).
   - **HUD의 Control은 모두 마우스를 무시한다**(기술 T3): 결투 입력은 `DuelScene._unhandled_input`이 받으므로, `HUD` 아래의 `Back`·`Root`·패널·라벨·게이지와 결과 패널의 새 `Panel`은 모두 `MOUSE_FILTER_IGNORE`(지금 `duel_hud.gd`·`result_panel.gd` 머리 주석의 규칙 그대로). `Panel`의 기본값은 STOP이라 만들 때 반드시 놓는다. 하루 화면의 벽·들보·머리 띠·장부 줄도 IGNORE이고, 처음 화면의 `HelpScreen`만 STOP(아래 버튼을 막는다, 결정 323). 벽은 `assets/ui/wall_style.tres`(결정 312 (나)에 테두리·선·마름모 0). 코드로 테마를 만들지 않는 까닭: 편집기에서 열어 볼 수 있고 033b가 StyleBox만 갈아 끼운다.
315. **글자색**(`day_ui.gd`): `GOLD`·`RED`를 없애고 `ACCENT := #84422F`(조건, 평판, 나쁜 소문, 다침, 손해, 새로 시작의 경고), `DIM := #6B5440`, `ON_WOOD := #E9D8B4`(카운터 나무 띠 위의 글), 본문은 테마의 `#3B2A1E`. 좋은 소문(`HINT_GOOD`)과 이익은 본문 색이다(좋고 나쁨을 붉은 글자가 있고 없음으로 가른다. 바이블 6절에 붉은 글자 하나뿐이라). `BACKGROUND`·`COUNTER_COLOR`·`COUNTER_TOP_COLOR`는 견본 `counterBg`·`counterBand`(594~597행)대로 바꾼다: 벽(양피지+결), **들보의 빗금 띠**(x 0부터 160마다 폭 22 · y 0~540, 평행 빗금 6 간격 · −35° · 1.1 · `#3B2A1E` 알파 0.5. 바이블 6절 "빗금은 띠로만"의 값. `scripts/ui/hatch_rect.gd`, `Control`의 `_draw`), 위쪽 머리 띠(y 0~64 양피지 결 없음, y 64의 잉크 선 2.5), 나무 띠(`#7A5232`, 윗줄 14 `#D2B98C`, y 540·554의 잉크 선 2.5). 처음 화면은 벽과 결만(견본 없음).
316. **결투 HUD의 패널과 층.** 임시 띠 셋(결정 298)과 도움말 띠를 없애고, 견본 `duelHud`(565~573행)의 패널 다섯을 필사본 패널(테마의 `Panel`)로 같은 자리에 둔다. 견본과 다른 곳은 위 가운데의 양옆 6화소(견본은 양옆 패널과 6·46화소 겹쳤다)와 조준 패널이 덧말 한 줄만큼 자라는 것뿐이다(1280×720 화면 좌표. 앵커는 지금 라벨의 것):

| 패널 | 화면 사각형 (견본) | 안에 든 것 (견본의 자리) |
|---|---|---|
| `PanelTopLeft` | x 10~340 · y 6~156 (같음) | 간격(24, y 14~44), 엉킴 막대(x 152~334 · y 17~41), 조건(16, `ACCENT`, x 20~330 · y 50~124), 충족도 자(x 20~330 · y 128~146) |
| `PanelTop` | x 346~894 · y 4~60 (334~946 · 4~62) | 상대 이름과 자세(18, 가운데 맞춤, y 10~34), 상대 자세 칸(y 40~54) |
| `PanelTopRight` | x 900~1272 · y 6~64 (같음) | 시간(20, 오른쪽 맞춤, x ~1260 · y 10~34), 방심 막대(x 906~1116 · y 35~59. 명세 4부의 "코드는 (850, 36)"을 견본 자리로) |
| `PanelBottomLeft` | x 10~350 · y 556~614 (같음) | 내 자세(18, y 562~588), 내 자세 칸(y 590~604) |
| `PanelBottomRight` | x 780~1272 · y 550~614, 덧말이 있으면 y 526~614 (550~614) | 조준 글(18, 오른쪽 맞춤 x ~1260, 줄 사이 24: 조준 / 런지·멀리의 덧말 / 내 상태). 덧말은 지금의 띄어쓰기 대신 줄을 바꾸고, 덧말이 있는 동안만 패널의 윗변이 24 올라간다(`refresh`. 가장 긴 줄이 폭 472에 든다, T75) |

   - 패널끼리 겹치지 않는다(위 가운데와 양옆 사이 6화소씩, 아래 둘 사이 430화소). 조용한 구역(x 433~847 · y 62~683)과는 `PanelBottomRight`의 x 780~847만 겹친다. 견본이 그 자리에 그렸고(사용자가 고른 화면), 패널이 상대·손 밑이라 신호를 가리지 않으므로 예외로 둔다(T73, 바이블 6절 "결투 HUD" 줄에 한 마디). 나머지 넷은 밖이다(`PanelTop`의 아래 변 60 < 62).
   - **층**: HUD 안에 `Back`(CanvasLayer, layer −1)을 두고, 결투 씬의 `Background`를 layer −2로 내린다. 차례는 무대(−2) → HUD 뒤판(−1) → 상대·내 손(기본 캔버스 0) → HUD(1) → 결과(5). **패널 다섯과 그 안의 것은 모두 `Back`**이다. 밀착 큰 베기의 칼이 위 가운데 패널 위로 지나고(실패 1, 판 N0 위 줄. 상대의 예비 동작은 HUD에 가리지 않는다, 원칙 4), 손·칼이 아래 패널 위로 그려진다(오른쪽 조준의 날밑과 조준 글의 겹침도 칼이 위가 된다). 견본도 손을 HUD 위에 그렸다. 견본과 다른 것은 상대가 위 가운데 패널 위로 온다는 것 하나다("견본과 다르게 두는 것").
   - `Back`·`Root`·패널 다섯과 그 안의 Control은 모두 `MOUSE_FILTER_IGNORE`다(결정 314의 둘째 규칙, 기술 T3). 패널이 화면의 왼쪽·오른쪽 위와 오른쪽 아래 조준 칸에 걸치므로, 놓치면 그 칸의 좌클릭·우클릭이 공격·막기로 가지 않는다.
   - 도움말 띠·도움말 글은 결투 화면에 없다(결정 323). 손은 화면 아래 끝까지 가리는 것이 없다.
   - `HUD`에 남는 것: 엉킴 경고 글자(결정 318), 기록(결정 319), 디버그. 결과 패널은 그대로 layer 5.
317. **HUD 게이지의 꼴**(바이블 6절): `PostureCells` — 24×14, 사이 4, 테두리 1.5 `#3B2A1E`, 찬 칸 상대 `#7A5232`·나 `#59663F`, 빈 칸 `#E9D8B4`에 빗금(잉크 1, 알파 0.6). `Meter` — 잉크 눈금 아홉의 자(찬 곳 `#59663F`, 기다리는 몫은 같은 색 알파 0.38, 빈 곳 `#E9D8B4`, 테두리 1.5), 막대 폭 110, 글은 그 오른쪽 10에 본문 색 14(가장 긴 `"의심 100 (지금 끝나면 +100)"`이 폭 316에 든다. T75). `BindBar`·`ComplacencyBar` — 제 사각형 전체에 짙은 띠 `#2E2620`을 깔고 빈 곳은 띠의 색, 평소 칠 엉킴 `#8FA3B3`·방심 `#CFC8BA`, 라벨은 평소 `#E9D8B4`(경계일 때 알파 0.45)·경고 때 경고 색, 글 16. **`COLOR_WARN`·`COLOR_FULL`과 `warn`·`ratio`·`caption()`은 그대로다**(테스트와 바이블 6절 규칙 1). `COLOR_FILL` 두 값만 바뀐다. 넷 모두 `ThemeDB.fallback_font` 대신 `get_theme_default_font()`로 그린다.
318. **엉킴 경고 글자의 자리**(BACKLOG 020-1 "다"): x 510~770 · y 550~590(앵커 아래 가운데, `Rect2(-130, -170, 260, 40)`. 가운데가 화면 가운데 640이고, 아래 오른쪽 패널의 왼변 780과 10 떨어진다. 글 폭 약 160이 260 안에 든다), 28, Noto Sans KR 900(`font_state.tres`), `#FF7333`, 검은 테두리 8(상태 글자와 같은 꼴). 위쪽(y 104~138)에서는 밀착의 모자와 두 줄 상태 글자(y 62~142)에 겹쳤다. 아래 가운데는 내 칼 바로 위라 칼의 주황 테두리와 한눈에 읽히고, 위 패널·아래 패널 어디와도 겹치지 않는다. 가로는 여전히 화면 가운데라 CLAUDE.md 3장의 "화면 가운데와 내 칼에 경고"는 "화면 가운데 아래, 내 칼 위"로 고쳐 적는다. 견본(`?warn=1`)은 위쪽에 두었고 캡션에서 모자와의 겹침을 적었다 — 견본과 다른 곳이다("견본과 다르게 두는 것"). 임시이고 사각형 하나라 되돌리기 쉽다. 판 N의 N2로 본다.
319. **무대 위에 바로 놓는 글**(패널 없이): 기록(`_log_label`)은 x 20~430 · y 280~440(조용한 구역 밖으로 좁히고 줄바꿈), 디버그는 그대로, 둘 다 `ON_WOOD` 글자에 짙은 테두리 4 `#2E2620`(결정 298의 테두리는 여기만 남는다). 패널 안의 라벨은 테두리 0이다.
320. **글자 크기**: 바이블 10절 "지금 크기 → 단계"대로 13→14, 15→16, 17→18, 19→20, 22→24, 26→28, 30→28, 32→34. 송명(`TitleLabel`)은 처음 화면의 가게 이름(54), 정산·폐점의 머리 줄(28), 결투 결과의 제목(28)과 충족도(46), 정산의 충족도(34), 폐점의 손익(34)에, `PrimaryButton`은 `Proceed`·`Continue` 이름의 버튼(처음 화면의 "가게를 연다"·이어서 하기, 카운터 "맡는다", 정산, 폐점 "다음 날을 연다")에 쓴다. 카운터의 머리 줄은 견본처럼 본문 글꼴이다.
321. **찍기의 크기**: 이 컴퓨터는 1920×1080 창을 열지 못한다(031 2부). 033의 찍기는 1280×720과 **1600×900**(창의 배율 1.25. 글꼴의 확대와 결 텍스처의 늘어남을 본다)이고, 러너가 장마다 `size,` 줄을 기대 크기와 견준다. 1920의 모습은 확인 못 한 것으로 남긴다.
322. **그린 질감은 033b**(판 N의 N1이 "그림으로"일 때만). 이 계획의 뒷부분에 넣지 않는 까닭: (1) 그림의 장 수를 돌리기 전에 사용자에게 알려야 하고 그 판정(판·자르기·9칸 여백)이 한 계획만 하다. (2) 코드 꼴은 그 자체로 끝난 것이라 그림이 늦거나 어긋나도 되돌아갈 곳이 된다. (3) 바꿀 곳이 테마의 StyleBox 셋(패널·버튼·벽)과 결 텍스처로 좁아 033의 코드·테스트를 다시 열지 않는다. (4) 033의 검토 2회 상한 안에 그림의 판정까지 넣지 않는다.
323. **도움말은 처음 화면에서**(사용자 답 "도움말 띠는 지워 … 처음 킨 화면에 이어하기처럼 '도움말' 버튼"). 결투 HUD의 `help_bar`·`_help_label`과 `refresh`의 도움말 갱신을 지운다. `DuelHud.help_text()`·`heavy_parts()`·상수(`HELP_TEXT`, `HELP_RETRY`, `HELP_LUNGE`, `HELP_BIND`)는 `static`이라 그대로 두고 도움말 화면이 부른다(`lunge_tests`가 `help_text`를 부른다). `day_mode` 필드는 결투 씬이 놓으므로 남기되 쓰는 곳이 없어진다(한 줄 주석). 처음 화면(`title.gd`)에 `Help` 버튼("도움말", 보통 버튼 20)을 "연습" 아래에 더한다(저장 없음: x 440 · y 534 · 400×54, 안내 줄은 y 600·읽지 못한 저장 줄은 y 636으로 / 저장 있음: x 440 · y 582 · 400×50, 안내 줄 y 642·새로 시작의 경고 y 676). 누르면 처음 화면 위에 `HelpScreen`(전체 화면 `Control`, `mouse_filter` STOP: 벽 + 필사본 패널 x 140~1140 · y 60~620, 머리 글 "도움말"(송명 28) + 밑줄, 본문 18)을 보이고 `HelpClose`에 초점을 준다(Space·Enter가 아래 버튼을 누르지 않게). `HelpClose` 버튼("돌아간다", 보통 20, 패널 아래 가운데)이나 Esc로 감추고 `Help` 버튼에 초점을 돌린다. **`HelpScreen`은 처음 열 때 만든다**(`_ready`에서 만들지 않는다. 기술 T2): 그래서 열기 전의 처음 화면에는 버튼이 하나만 늘어난다 — 저장 없음 3(`Proceed`, `Practice`, `Help`), 읽을 수 없는 저장 3, 저장 있음 4(`Continue`, `NewGame`, `Practice`, `Help`). 한 번 연 뒤에는 감춰도 `HelpClose`가 남아 하나 더 세어진다(테스트는 열기 전의 화면을 센다). 장면을 바꾸지 않는다(세션의 길을 늘리지 않는다). 본문은 `help_text(<기본 상대>, false, false, <기본 무기>)`의 글을 줄(`\n`)마다 한 묶음으로, 묶음 안의 항목(`" · "`)마다 한 줄(`"· "` 머리)로 펼친 것이다. 기본 상대·무기는 연습 결투가 의뢰 없이 쓰는 그 데이터다(지금 바르톨로와 레이피어. 경로는 `duel.gd`에서 읽는다). 상대가 늘면 상대마다 다른 줄을 어떻게 보일지는 BACKLOG 033-1. 판 처음에 조작을 알리는 다른 장치는 두지 않는다(사용자 답).
324. **완료 기준은 견본과 나란히**(사용자 답 "맞다 — 025 견본 화면처럼"). 견본 `025-type-ui-size.html`의 `ui-duel`·`ui-counter`·`ui-settle`·`ui-closing`을 `?ui=b`로 구운 장(작업 0)과 playtester가 찍은 같은 장면의 게임 장을 나란히 놓아 판정한다(작업 10). 자리·크기·색은 견본 코드의 값(565~647행)에서 옮기고, 다른 곳은 "견본과 다르게 두는 것"의 표에 까닭과 함께 둔다. 018-F8(평판 줄의 자리)은 견본이 지금 자리에 그렸으므로 견본대로 두고 닫는다. 카운터 말풍선에는 견본처럼 의뢰인 이름의 머리 글(`ACCENT` 20 + 가는 밑줄 1 `#6B5440`, 노드 이름 `PanelHead`)을 맨 위에 둔다(견본 `panelHead`).
325. **장부는 견본의 꼴**(견본 `ledgerRow`·`UI.b.rule`): 정산·폐점의 장부 줄을 `Ui.add_ledger_row(parent, key, name_text, value_text, size, total := false)`로 만든다 — `HBoxContainer`(이름 `Ledger<Key>`) 안에 `Name`(왼쪽)과 `Value`(오른쪽 맞춤, 늘어남) 라벨, 줄 위에 가는 줄선 1(`#6B5440` 알파 0.6), 합계(`total`)는 그 대신 2화소 떨어진 두 줄 선 1(`#3B2A1E`). 줄: 정산 `Base`·`Tip`·`Total`(받은 돈, 합계)·`Money`, 폐점 `Income`·`Rent`·`Medical`·`Profit`(오늘의 손익, 합계, 송명 34)·`Money`. 이름 칸에 지금 글의 괄호 덧말(`(평판 +10% · 흥정 +30%)`, `(1회)`)을 그대로 두고, 수 칸에 수(`45 / 45`, `-20`, `-18 → -78`)를 둔다. 수의 글은 지금 서식 그대로다(018-F7의 뜻은 바꾸지 않는다). 테스트가 보는 장부 글(`safety_tests`의 `"치료비   -20  (1회)"` 등)은 줄 노드의 `Name`·`Value`를 보게 고친다(작업 6). v1에서 BACKLOG로 미뤘던 것을 완료 기준 때문에 넣는다.

### 견본과 다르게 두는 것

실행 중에 더 찾은 차이는 이 표에 줄을 더하고(까닭과 함께) 보고서에 옮긴다. 표에 없는 차이는 고칠 거리다(작업 10).

| 무엇 | 견본 | 게임 | 까닭 |
|---|---|---|---|
| 위 가운데 패널 | x 334~946 · y 4~62, 상대 밑 | x 346~894 · y 4~60, **상대 위로 칼이 지난다** | 양옆과 6·46화소 겹침을 푼다. 밀착 큰 베기의 칼이 가리지 않게(031 실패 1, 판 N0 위 줄을 사용자가 봄) |
| 아래 도움말 띠 | 가로 전체 y 616~720 | 없음, 처음 화면의 "도움말" | 사용자 답(결정 323) |
| 아래 오른쪽 조준 | 두 줄 | 덧말(런지·멀리)이 있으면 세 줄, 패널이 24 자람 | 게임 글의 길이: 런지의 덧말이 한 줄에 들지 않는다 |
| 엉킴 경고 글자 | 위 가운데(모자와 겹침) | 아래 가운데, 내 칼 위 | BACKLOG 020-1, 결정 318 |
| 기록(최근 사건)·디버그 | 없음 | 무대 위 글(양피지 글자 + 짙은 테두리) | 견본에 없는 HUD 요소. 기록은 조용한 구역 밖으로 좁힌다(결정 319) |
| 충족도 자의 글 | 막대 위에 "충족도" 13 | 막대 오른쪽에 "의심 N (지금 끝나면 +N)" 14, 막대 폭 110 | 명세 4부: 찬 막대 위의 라벨은 읽기 어렵다. 게임의 글은 조건이 주는 라벨이다 |
| 글자 크기 | 지금 게임의 크기(13·15·17·19·21·22·26·30·32) | 아홉 단계 | 바이블 10절(견본은 크기를 옮기기 전의 화면이다) |
| 의뢰인 | 그린 의뢰인(클라라·비토리오) | 색 사각형과 이름 | 의뢰인 그림은 034 |
| 상대·무대·손·칼 | 견본의 그림 | 게임의 그림(029~032) | 이 계획 밖. 무대는 031b, 칼은 032b |
| 처음 화면·도움말·연습 선택·결투 결과 | 없음 | 같은 필사본 부품 | 견본이 그리지 않은 화면 |

## 작업 목록

차례대로 한다. 두 관점의 승인이 있어야 작업 0을 시작한다.

**작업 0. 시작 상태**
- 할 일:
  1. 031·032 2부 보고(근거의 실패 둘과 작은 것)를 이 계획의 결정 316·318·321·323과 작업 8의 BACKLOG 줄에 대응시켜 표로 보고서 머리에 적는다(오류 고침은 따로 없다).
  2. 고칠 파일의 사본을 `<W>\before\`에 둔다: `scripts/day_ui.gd`, `title.gd`, `commission/counter.gd`, `commission/commission_select.gd`, `economy/settlement.gd`, `economy/closing.gd`, `duel/result_panel.gd`, `duel/duel_hud.gd`, `scenes/duel/duel.tscn`, `scenes/duel/opponent_view.tscn`, `tests/stage_tests.gd`, `tests/scene_tests.gd`, `tests/day_tests.gd`, `tests/bind_tests.gd`, `tests/safety_tests.gd`, `tests/save_tests.gd`, `tests/run_tests.gd`, `project.godot`. 해시와 `git status`를 `<W>\start.txt`에.
  3. **견본 굽기**(완료 판정의 한쪽): `docs/style/tools/bake025.ps1 -Budget 5000 -OutDir <W>\samples -Shots @('ui-duel+ui=b','ui-counter+ui=b','ui-settle+ui=b','ui-closing+ui=b')`를 PowerShell에서(작은 감싸개 `.ps1`로) 돌린다. 밀착 경고 장면이 굽히면(`'ui-duel+ui=b+warn=1'`) 그것도. 넷(또는 다섯)이 1280×720이고 빈 장면이 없는지 본다.
  4. 견본 코드(565~647행)에서 장면마다 패널·버튼·글의 사각형과 크기·색을 읽어 `<W>\sample-rects.txt`에 표로 적는다(작업 4·5가 옮기고, 작업 10이 찍은 장과 대조한다). 그 장면의 글(견본의 비토리오 카운터, 클라라 정산, 1일차 폐점, 교전 큰 베기에 막기)도 적어 작업 7이 같은 장면을 찍게 한다.
- 완료 확인: 사본 열여덟, `start.txt`, 기준 커밋(`git rev-parse HEAD`), 구운 견본 넷 이상, `sample-rects.txt`.

**작업 1. 글꼴 파일 (Q1 "가"의 꼴)**
- 대상: `assets/fonts/`(새): 글꼴 셋, 라이선스 글 넷, `README.md`. `assets/MANIFEST.md`에 글꼴 셋의 줄.
- 할 일: 로컬 `docs/style/generated/fonts/`에서 복사한다(결정 313의 이름). README에는 글꼴마다 배포처, 저작권 줄(바이블 9절 표), Reserved Font Name, "고치지 않은 원본이다(서브셋은 6단계 뒤)"를 적는다. MANIFEST의 꼴은 바이블 14절(파일명·용도·크기·상태 `final`·출처).
- **글자 대조(1부, 메인. 실행 규칙 밖의 PowerShell)**: `scripts/`·`data/`·`scenes/`의 글에서 ASCII 밖의 글자(한글과 `—`·`·`·`→`·`…`·`“`·`”` 같은 기호)를 모아(025가 628자를 센 꼴), 감싸개 `<W>\glyphs.ps1`이 `System.Windows.Media.GlyphTypeface`의 `CharacterToGlyphMap`으로 세 글꼴마다 빠진 글자를 센다. 결과 `<W>\glyphs.txt`: 글꼴마다 빠진 글자 목록. 송명에 빠진 글자는 `font_title.tres`의 받침(결정 314)이 맡고, 나눔스퀘어라운드 EB나 Noto Sans KR에 빠진 글자가 있으면 그 글이 어느 노드에 쓰이는지 적어 보고서 3번에 둔다(받침 글꼴을 더할지는 판 N2의 고칠 거리).
- 완료 확인: 세 파일의 SHA256 앞 16자리가 바이블 9절과 같다(`9E845FC35C5BC4A5`, `7F90AB2025091156`, `194018E6B2B293A7`). 라이선스 글 넷이 원본과 해시가 같다. `assets/fonts/` 아래 `.import`를 쓰지 않았다. `glyphs.txt`가 있고 본문 글꼴의 빠진 글자가 0이거나 그 쓰임이 적혀 있다.

**작업 2. 결 텍스처와 StyleBox 둘 (결정 312)**
- 대상(새): `scripts/ui/paper_grain.gd`, `scripts/ui/manuscript_panel_style.gd`, `scripts/ui/swallowtail_style.gd`. `class_name`은 두지 않는다(테마가 경로로 부르고, 테스트는 스크립트 경로로 본다).
- 할 일:
  - `paper_grain.gd`: `static var _texture: ImageTexture`와 `static func texture() -> Texture2D`. 처음 부를 때 `FastNoiseLite`(큰 결: 씨앗 2, 주파수 0.02(견본의 세로 값), 옥타브 3 / 잔 결: 씨앗 5, 주파수 0.85, 옥타브 2)의 `get_seamless_image(256, 256)` 둘을 화소마다 합친다(결정 312 (가)의 식, 노이즈 값은 0~1로 옮겨 쓴다). 상수 `SIZE := 256`, `DRAW_SIZE := Vector2(427, 256)`(가로 1.67배로 그리는 타일 크기. 결정 312).
  - `manuscript_panel_style.gd`: `@tool`, `extends StyleBox`. `@export` 값: `fill_color`(`#E9D8B4`), `grain`(1.0), `border_color`·`border_width`(3), `inner_color`·`inner_inset`(5)·`inner_width`(1), `corner_color`(`#D2B98C`)·`corner_radius`(4). `_draw(to_canvas_item: RID, rect: Rect2)`은 `RenderingServer`의 `canvas_item_add_rect`·`canvas_item_add_texture_rect_region`(그리는 타일 427×256 = 텍스처 256×256을 가로로 늘린 것을 x·y로 나눠 깔고, 끝 타일은 그리는 사각형과 원본 영역을 같은 비로 잘라서)·`canvas_item_add_polyline`(닫힌 사각형, 테두리는 사각형 안쪽으로 반 폭 들여)·`canvas_item_add_polygon`(마름모)만 쓴다. 값이 0인 몫은 건너뛴다.
  - `swallowtail_style.gd`: `@tool`, `extends StyleBox`. 값: `fill_color`, `border_color`, `border_width`(2.5), `notch_max`(12)·`notch_ratio`(0.28), `inner_inset`(5)·`inner_alpha`(0.7), `sink`(0). 다각형은 견본 499행의 여섯 점(sink만큼 아래로 옮긴 사각형에서).
- 완료 확인: 기계적 확인 다섯. 세 파일이 `Node`·`Control`에 기대지 않는다(Grep `get_node`, `get_tree` 0). `_draw`의 인자 꼴이 Godot 4의 `StyleBox._draw(to_canvas_item: RID, rect: Rect2)`와 같다. 정적 변수는 `static var`로만.

**작업 3. 테마·글꼴 변형·벽 (결정 314)**
- 대상(새): `assets/ui/manuscript_theme.tres`, `assets/ui/font_state.tres`, `assets/ui/font_title.tres`, `assets/ui/wall_style.tres`. 고침: `project.godot`에 지금 없는 `[gui]` 절을 새로 두고 그 아래 `theme/custom="res://assets/ui/manuscript_theme.tres"`(절 머리와 키, 그리고 앞 절과 가르는 빈 줄. Godot이 쓰는 절의 차례대로 `[global_group]`·`[input]` 등과의 자리는 알파벳 차례에 맞춘다).
- 할 일: `.tres`를 손으로 쓴다. 테마의 키는 `default_font`, `default_font_size`, `Label/colors/font_color`, `Button/colors/font_color`·`font_hover_color`·`font_pressed_color`·`font_hover_pressed_color`·`font_focus_color`·`font_disabled_color`, `Button/styles/normal`·`hover`·`pressed`·`disabled`·`focus`, `PanelContainer/styles/panel`, `Panel/styles/panel`, `TitleLabel/base_type = &"Label"`·`TitleLabel/fonts/font`(= `font_title.tres`), `PrimaryButton/base_type = &"Button"`·`PrimaryButton/fonts/font`(= `font_title.tres`)·`PrimaryButton/colors/font_color`(올림·누름·초점도 같은 색), `HaggledButton/base_type = &"Button"`·`HaggledButton/colors/font_disabled_color`. StyleBox 다섯(패널 하나, 버튼 넷)은 `sub_resource`이고 `script = ExtResource(…)`로 결정 312의 스크립트를 건다. 버튼의 `content_margin_*`은 결정 314(누름은 위 +2·아래 −2). `font_state.tres`는 `FontVariation`(`base_font` = `NotoSansKR-wght.ttf`, `variation_opentype = {2003265652: 900}` — 2003265652는 `wght` 태그의 정수다. 줄 끝에 그렇게 주석을 달 수 없으므로 README에 적는다).
- 완료 확인: `.tres`마다 `load_steps` = 자원 수 + 1, id 겹침 0, 모든 `ext_resource`의 경로가 있다. 스크립트를 건 `sub_resource`마다 `script = ExtResource(…)` 줄이 그 스크립트의 `@export` 값 줄들보다 **먼저** 온다(기술 비차단. 뒤에 오면 값이 스크립트 없는 StyleBox에 붙어 버려진다). 테마 키의 철자를 Godot 4 `Theme`의 항목 이름과 대조한 목록을 보고서에 둔다. `2003265652` = 0x77676874(`w`·`g`·`h`·`t`)를 손으로 셈해 적는다. `project.godot`의 `git diff`가 `[gui]` 절 머리·키 한 줄·빈 줄의 더함뿐이다.

**작업 4. 하루 화면·도움말·연습 선택·결투 결과 (결정 315·320·323~325)**
- 대상: `scripts/day_ui.gd`, `scripts/title.gd`, `scripts/commission/counter.gd`, `scripts/commission/commission_select.gd`, `scripts/economy/settlement.gd`, `scripts/economy/closing.gd`, `scripts/duel/result_panel.gd`, 새 `scripts/ui/hatch_rect.gd`.
- 할 일(자리·크기·색은 `sample-rects.txt`의 견본 값):
  - `day_ui.gd`: 색 상수(결정 315). `add_background`는 `Panel` 하나(이름 `Wall`, 전체 앵커, 마우스 무시, `wall_style.tres`)로 바꾸고 인자 `color`를 없앤다(부르는 곳이 인자를 주지 않는지 Grep). `add_beams(parent)`는 결정 315의 들보 빗금 띠(`hatch_rect.gd`. 견본의 `hatchBg` 무늬 값을 읽어 다르면 그것을 따른다). `add_counter_band`는 결정 315의 나무 띠. 화면 위쪽 머리 띠(y 0~64 양피지와 y 64의 잉크 선 2.5)는 카운터·정산·폐점에서 `add_header_rule(parent)` 하나로 긋는다. `add_panel_head(column, text)`(결정 324)와 `add_ledger_row(…)`(결정 325)를 더한다. `add_button`에 `primary := false` 인자를 더해 참이면 `theme_type_variation = &"PrimaryButton"`. `add_title(parent, text, size)`는 `TitleLabel` 변형의 라벨. `make_client`의 이름 라벨은 테마 색.
  - 부르는 곳: `GOLD` → `ACCENT`, `RED` → `ACCENT`, 카운터의 좋은 소문(`HINT_GOOD`)과 폐점의 이익(`shown_profit >= 0`)은 색 인자 없이. 크기는 결정 320의 표대로 고치고, 송명 자리는 `add_title`, 주 버튼은 `primary = true`. 나무 띠(y ≥ 540) 위에 바로 놓이는 라벨(카운터 `DeclineNote`·`QuitNote`, 폐점의 평판 줄·안내·"저장했다", 그 밖에 Grep으로 찾은 것)은 `ON_WOOD`. 흥정한 뒤 못 누름이 된 흥정 버튼은 `_refresh_haggle()`에서 `theme_type_variation = &"HaggledButton"`.
  - `commission_select.gd`: 자기 `ColorRect` 바탕을 `Ui.add_background`로, 크기 30→28(송명)·17→18.
  - `result_panel.gd`: `_panel`을 `ColorRect`에서 `Panel`(테마의 필사본)로 바꾸고 형도 `Panel`로. 제목은 송명 28, 충족도는 송명 46(본문 색), 내역 19→20, 바닥 글은 `DIM` 20(`modulate` 대신 색). `is_showing()`·`shown_score`·`hide_result()`는 그대로.
  - `counter.gd`: 말풍선 맨 위에 `Ui.add_panel_head(bubble, commission.client_name)`(결정 324). 머리 줄·평판·버튼의 자리는 지금 값이 견본과 같다(`sample-rects.txt`로 대조만).
  - `settlement.gd`·`closing.gd`: 장부 줄을 `add_ledger_row`로(결정 325의 키와 글). 정산의 "충족도 N"은 송명 34 본문 색, 폐점의 "오늘의 손익"은 합계 줄(송명 34, 손해면 `ACCENT`). 정산의 머리 줄은 견본처럼 송명 28.
  - `title.gd`: 결정 323의 `Help` 버튼과 `HelpScreen`(함수 `_build_help()`·`_show_help()`·`_hide_help()`. `_build_help()`는 `_show_help()`가 `HelpScreen`이 없을 때만 부른다. `_unhandled_input`에서 `HelpScreen`이 보일 때만 Esc를 받는다). 처음 화면 바탕은 벽(`add_background`)만.
  - 마우스(결정 314의 둘째 규칙): `result_panel.gd`의 새 `Panel`은 지금 `ColorRect`처럼 `MOUSE_FILTER_IGNORE`. `day_ui.gd`의 벽·들보·머리 띠·장부 줄(`HBoxContainer`)·패널 머리 글은 IGNORE. `HelpScreen`만 STOP.
  - 색(결정 314의 첫째 규칙): 나무 띠 위와 무대 위의 라벨은 모두 색 덮어쓰기가 있다.
- 완료 확인: 기계적 확인 다섯(파일 여덟). `Grep "font_size\", (13|15|17|19|22|26|30|32)\b"`와 `add_(label|wrapped|button)\(.*, (13|15|17|19|22|26|30|32)[,)]`이 `scripts/`에서 0건. `Ui.GOLD`·`Ui.RED`·`GOLD`·`Color(0.95` 0건(`scripts/day_ui.gd`·네 화면·결과 패널). 테스트가 보는 노드 이름(`Header`, `ReputationLabel`, `GuestNote`, `Dialogue`, `ReputationHint`, `HaggleLine`, `PayLine`, `Haggle`, `Proceed`, `Decline`, `DeclineNote`, `Quit`, `QuitNote`, `DeclinedLine`, `ReputationLine`, `ReputationLedger`, `Continue`, `NewGame`, `Practice`, `Buy_*`, `FullPayNote`, `HaggleNote`, `Reaction`, `MissedNote`, `SaveInfo`, `SaveUnreadable`, `NewGameWarning`)가 그대로이고, 새 이름 `Help`·`HelpScreen`·`HelpClose`·`PanelHead`·`Ledger*`·`Wall`이 다른 노드와 겹치지 않는다(사본과 `git diff`로 대조, `find_child`로 찾는 이름이 한 화면에 하나뿐). `title.gd`의 `_ready`·`_build_fresh`·`_build_continue`에서 `_build_help`를 부르지 않는다(Grep). 장부 줄의 수 칸 글이 옛 글의 수 부분과 같은 서식이다(`"%d / %d"`, `ledger_amount(…)` 등. 사본과 대조). `tests/`에서 `Ui.GOLD`·`Ui.RED`·`BACKGROUND`를 쓰는 곳이 0건. 처음 화면 두 꼴의 버튼·글 사각형을 손으로 셈해 겹침 0, 아래 끝 ≤ 720.

**작업 5. 결투 HUD와 상태 글자 (결정 316~319)**
- 대상: `scripts/duel/duel_hud.gd`, `scenes/duel/duel.tscn`(`Background`의 `layer` −1 → −2 한 줄), `scenes/duel/opponent_view.tscn`(`StateLabel`에 `theme_override_fonts/font` = `font_state.tres`와 **`theme_override_colors/font_color = Color(1, 1, 1, 1)`**(기술 T1: 프로젝트 테마의 잉크색이 흰 글자를 덮지 않게), ext_resource 하나, `load_steps`).
- 할 일(`duel_hud.gd`, 함수 하나씩 나눠 고친다):
  - `_ready`: `Back`(CanvasLayer, layer −1, 이름 `Back`)과 그 아래 `Root`(지금 `_root`와 같은 꼴, 이름 `Root`)를 만들고, 결정 316의 표대로 패널 다섯을 `_add_panel(name, anchor, rect)`로 `Back/Root`에 깐 뒤 그 안의 라벨·게이지도 `Back/Root`에 놓는다(앵커·사각형은 표의 화면 사각형에서 셈한 값). `Back/Root`와 `_add_panel`이 만드는 `Panel`은 `mouse_filter = MOUSE_FILTER_IGNORE`(기술 T3. 라벨·게이지는 지금처럼 IGNORE). `_add_band`와 `BAND_COLOR`의 띠 쓰임은 지운다(`BAND_COLOR`는 게이지의 짙은 띠와 무대 위 글의 테두리 색으로 남긴다).
  - `_add_label`에 `outline: bool` 인자: 무대 위 글(결정 319)만 참. 패널 안의 라벨은 색을 주지 않으면 테마의 본문 색이다(조건은 `ACCENT`). 크기는 결정 320(조건 15→16, 엉킴 경고 26→28).
  - 도움말(결정 323): `help_bar`·`_help_label`·`HELP_TEXT`를 쓰던 `_ready`의 몇 줄과 `refresh`의 도움말 갱신을 지운다. `help_text()`·`heavy_parts()`와 상수는 남긴다.
  - 엉킴 경고: 결정 318(`font_state.tres`, 테두리 8 검정).
  - `refresh`: 조준 글의 덧말 앞 `" "`을 `"\n"`으로(런지·멀리 둘), 덧말이 있으면 `PanelBottomRight`의 `offset_top`을 24 올리고 없으면 되돌린다. 글의 낱말은 그대로라 `lunge_tests`·`scene_tests`의 `contains`가 지킨다(Grep으로 `_aim_text`·`_aim_label`을 쓰는 검사를 다시 읽는다).
  - 게이지 넷: 결정 317. `Meter.BAR_WIDTH` 180 → 110.
- 완료 확인: 기계적 확인 다섯. `duel_hud.gd`에 `help_bar`·`_help_label`이 0건. `duel_hud.gd`에서 `.new()`로 만드는 Control마다 바로 아래에 `mouse_filter = Control.MOUSE_FILTER_IGNORE`가 있다(Grep `\.new\(\)` 줄에서 `CanvasLayer`를 뺀 수와 IGNORE 줄 수 대조). `opponent_view.tscn`의 `StateLabel`에 글자색 덮어쓰기가 있다. 테스트가 부르는 HUD 필드·상수 이름(`_bind_bar`, `_bind_warning`, `_aim_label`, `_log_label`, `_debug_label`, `_complacency_bar`, 노드 이름 `ComplacencyBar`·`BindBar`·`BindWarning`, `BIND_WARN_RATIO`, `BIND_WARN_TEXT`, `BindBar.COLOR_WARN`, `ComplacencyBar.COLOR_FULL`, `help_text`, `heavy_parts`, `bind_warning_now`, `lunge_aim_note`, `toggle_debug`)가 모두 있다(Grep `tests/`의 쓰임과 대조). `bind_tests`가 `duel.get_node("HUD")`에서 `get("_bind_warning")`처럼 필드로 찾는 것은 층과 상관없다. 결정 316 표의 사각형 다섯(조준 패널은 자란 꼴도)과 엉킴 경고 사각형을 손으로 셈해 서로 겹침 0, 조용한 구역과 겹치는 것은 `PanelBottomRight`의 x 780~847뿐임을 보고서에 적는다. 패널마다 견본 좌표(`sample-rects.txt`)와의 차를 표로 적는다(위 가운데 ±12·52, 조준 패널의 +24 말고는 0이어야 한다). `duel.tscn`·`opponent_view.tscn`의 `load_steps`·id·경로. 판정 코드의 `git diff`가 0줄.

**작업 6. 테스트: T73 고침, T75 새, 도움말·장부를 보는 테스트 고침 (`tests/stage_tests.gd`, `tests/manuscript_tests.gd` 새, `tests/run_tests.gd` 한 줄, `tests/scene_tests.gd`, `tests/day_tests.gd`, `tests/bind_tests.gd`, `tests/safety_tests.gd`, `tests/save_tests.gd`)**
- T73 "HUD 패널(필사본)": `BANDS`를 결정 316 표의 `PANELS`(이름 → 앵커, 앵커 기준 사각형, 1280×720 화면 사각형)로 바꾼다. 볼 것: 다섯이 모두 `HUD/Back/Root` 아래에 있고 형이 `Panel`이며 `panel` StyleBox의 스크립트가 `manuscript_panel_style.gd`, 앵커·오프셋에서 셈한 화면 사각형이 표와 같다(031 T73의 셈법), 다섯과 엉킴 경고 사각형이 서로 겹치지 않는다, 조용한 구역과 겹치는 것은 `PanelBottomRight`뿐이다, 층: `HUD/Back.layer` = −1, `Background.layer` = −2, `HUD` 아래에 이름이 `HelpBar`인 노드와 `_help_label` 필드가 없다, 패널 안의 라벨은 `outline_size` 0이고 무대 위 글(기록·디버그·엉킴 경고)은 0보다 크다. 조준 패널: 멀리에서 `refresh`하면 윗변이 526, 교전에서 550. **`HUD` 아래의 모든 `Control`(`find_children("*", "Control", true, false)`)의 `mouse_filter`가 `MOUSE_FILTER_IGNORE`**(기술 T3), 결과 패널의 `Panel`도 IGNORE.
- 처음 화면의 버튼 수(기술 T2. 결정 323: `HelpScreen`은 처음 열 때 만든다):
  - `day_tests.gd` 513행(T33): `== 2` → `== 3`, 그리고 `Help`가 있다.
  - `save_tests.gd` 399·400행(T58 가): 2 → 3, 이름 검사에 `Help`, 실패 글 "(기대 3: Proceed, Practice, Help)". 407·408행(나): 2 → 3과 `Help`. 418·419행(다): 3 → 4, 이름 검사에 `Help`, 실패 글 "(기대 4: Continue, NewGame, Practice, Help)". 세 화면 모두 `HelpScreen`·`HelpClose`가 없음도 본다(열기 전).
  - 그 밖에 `tests/`에서 `find_children("*", "Button"`·`_button_count`를 쓰는 곳을 Grep해 처음 화면을 세는 곳이 이 넷뿐인지 본다.
- 도움말을 HUD 라벨에서 읽던 검사를 `DuelHud.help_text(…)`로 바꾼다(검사하는 뜻은 같다):
  - `scene_tests.gd` 335·341행: `help_text(core.opponent_data, false, core.opponent_has_hat, core.weapon)`.
  - `bind_tests.gd` 604·608행: `help_text(core.opponent_data, false, false, weapon)`.
  - `day_tests.gd` 429~431행: 하루 모드의 글이 "다시 하기"를 빼는지는 `help_text(…, true, …)`로 보고, 더해서 결투 HUD에 `_help_label`이 없음을 본다.
  - 다른 파일에서 `_help_label`을 쓰는 곳이 0건인지 Grep.
- 장부(결정 325): `safety_tests.gd` 187·196행의 `text.contains("치료비   0  (0회)")` 꼴을 줄 노드(`LedgerMedical`의 `Name`에 `"(0회)"`, `Value`가 `"0"`, `LedgerRent`의 `Value`가 `"-60"`, `"-0"`이 없음)로 바꾼다. 그 밖에 `tests/`에서 장부 줄의 옛 글(세 칸 띄어쓰기 `"   "`가 든 글자 상수)을 Grep해 모두 같은 꼴로 바꾼다.
- T75 "필사본: 테마·글꼴·크기·글이 든다"(`manuscript_tests.gd`, 화면을 붙이는 도우미는 `safety_tests.gd`가 `DayTests`를 `_d`로 쓰는 꼴):
  1. 테마: `ThemeDB.get_project_theme()`가 있고, 기본 글꼴의 경로가 `NanumSquareRoundEB.ttf`, `PanelContainer`·`Panel`의 `panel`과 `Button`의 넷이 결정 312의 스크립트, 형 변형 셋의 바탕 형이 맞다. `font_state.tres`의 `variation_opentype`에 `TextServerManager.get_primary_interface().name_to_tag("wght")` 키의 값 900.
  2. 글자: 처음 화면(저장 없음, `HelpScreen`을 연 꼴 포함), 1일차의 카운터(의뢰마다), 정산(성공 하나·다친 하나), 폐점, 연습 선택, 결투 HUD(`refresh` 뒤), 결과 패널(`show_result`), 상대 뷰의 상태 글자를 붙여, 보이는 `Label`·`Button`의 글자마다 그 노드의 `get_theme_font("font").has_char()`가 참이다(빠진 글자를 모아 적는다). 송명이 걸린 노드는 송명으로 본다(2,350자).
  3. 크기: 같은 노드들의 `get_theme_font_size("font_size")`가 아홉 단계 안이다.
  4. 글이 든다: (가) 카운터의 `Header` 끝(위치 + `get_string_size`)이 `ReputationLabel`의 왼쪽(848)보다 작다(1일차 의뢰마다). (나) 자리·크기를 직접 정한 버튼마다(처음 화면·카운터·정산·폐점·도움말) `button.get_combined_minimum_size()`가 정한 크기 이하다(가로·세로 모두. 기술 T4: 최소 크기가 크면 버튼이 오른쪽·아래로 자라므로, 결정 314의 여백 좌우 28씩이 든 최소 크기로 본다). 컨테이너 안의 버튼(폐점의 살 것)은 `size`가 그 컨테이너 폭을 넘지 않는다. (다) HUD 조건 글: 모든 의뢰(`data/commissions`와 `variants`)의 `describe()`가 `get_multiline_string_size(…, 316, 16)`로 높이 74 안. (라) 조준 글: 방향·높이·부위 이름의 가장 긴 조합 + `" (2칸)"`, `LUNGE_AIM_WAIT`, `"내 상태: "` + 가장 긴 상태 이름의 각 줄이 폭 472 안, 세 줄 높이가 자란 패널 안(88 − 위아래 여백). (사) 도움말 화면: 펼친 줄이 모두 패널 안쪽 폭에 들고, 줄 수 × 줄 높이가 패널 안쪽 높이에 든다(저장 있음·없음의 `Help` 버튼으로 연 꼴 모두). `Help`를 누르면 `HelpScreen`이 보이고 `HelpClose`를 누르면 감춰진다. (아) 장부: 정산·폐점의 `Ledger*` 줄마다 `Value`가 오른쪽 맞춤이고 이름과 수가 한 줄에 든다.
  5. 송명 받침: `font_title.tres`의 `fallbacks`에 본문 글꼴이 있고, `TitleLabel`·`PrimaryButton`이 그 글꼴을 쓴다. 2의 글자 검사는 받침을 넣어 본다(`has_char`가 받침에서 참이면 통과).
  6. 색(기술 T1): 상대 뷰의 `StateLabel`의 `get_theme_color("font_color")`가 흰색이고 `outline_size`가 8이다. 엉킴 경고 `#FF7333`, 기록·디버그 `ON_WOOD`, 카운터의 `DeclineNote`·`QuitNote`와 폐점의 `ReputationLedger`가 `ON_WOOD`다. (마) 상태 글자: `"막기를 뗐다 다시 올려라"`의 폭 ≤ 414, 두 줄(`"큰 베기!!\n받아낼 준비"`)의 높이 ≤ 80(바이블 9절의 상자, Noto Sans KR 900 28). (바) `Meter`: 110 + 10 + `"의심 100 (지금 끝나면 +100)"`(14)의 폭 ≤ 316.
- 완료 확인(1부): 기계적 확인 다섯. 새 테스트의 수가 하나라 기대 값은 `ALL PASS 76/76`(032의 75에 T75). (라)의 "가장 긴 조합"을 고른 셈(글자 수 기준)과 표 넷(9단계, 패널 사각형, 조준 줄, 상태 글자)을 보고서에 적는다. 통과는 2부.

**작업 7. 찍기 씬 (`tests/ui_shots.gd`·`.tscn`, `tests/run_ui_shots.ps1` 새 파일. 테스트 목록에는 넣지 않는다)**
- 할 일: **견본과 짝이 되는 장**을 먼저, 견본이 없는 장을 뒤에 찍는다. 짝이 되는 장은 견본의 장면(작업 0의 `sample-rects.txt`)을 될 수 있는 만큼 같게 놓는다:
  - `pair-duel`: 교전, 뒷골목, 의뢰 `feather_cut`, 상대는 큰 베기의 예비 동작(hold. `tests/opponent_states.gd`의 `States.put`), 나는 갓 올린 막기·가운데, 방심 게이지 약 0.45(코어의 방심 값을 놓을 수 없으면 그 판의 값 그대로 두고 표에 적는다).
  - `pair-duel-warn`: 밀착, 엉킴 경고와 방심 가득(판을 멈춘 뒤 HUD의 `_bind_bar.set_values(0.9, true)`·`_bind_warning.visible = true`·`_complacency_bar.set_values(1.0, false)`, 032 `hand_shots.gd`의 꼴).
  - `pair-counter`: 견본의 의뢰인(비토리오)이 손님인 카운터(그 의뢰가 든 날을 `DayState`로 열고 그 손님까지 돌려보내거나 그 의뢰를 첫 손님으로 둔 하루를 테스트 도우미로 만든다. 안 되면 1일차 첫 손님과 표에 적는다), 평판 줄 있음.
  - `pair-settle`: 100점 정산(견본 장면의 의뢰인과 같은 의뢰, 평판 줄 있음). `pair-closing`: 1일차를 끝낸 폐점(다친 판 하나, 살 것 하나가 못 누름).
  - 견본이 없는 장: `title`(저장 없음), `title-save`(저장 있음: `saved`를 밖에서 넣는다), `help`(`HelpScreen`을 연 꼴), `select`(연습 선택), `settle-hurt`(다침), `duel-far`·`duel-close`(간격, 031 `stage_shots.gd`의 걸음 꼴), `duel-close-bighold`(밀착 + 큰 베기 hold — 칼이 위 가운데 패널 위로 지나는지), `duel-right-high`(교전, 오른쪽·상단 조준 준비 — 날밑과 조준 패널), `result`(결과 패널: 의뢰 `feather_cut`, 코어의 `ended`·`end_reason`을 놓고 `show_result`). 결투 장은 결투 노드가 트리에 들어간 **뒤에** `set_process(false)`·`set_physics_process(false)`(031·032의 꼴). 장마다 `state,<장>,<놓으려던 것>,<놓인 것>`도 내어 견본 장면과 다르게 놓인 것을 작업 10이 표에 옮기게 한다. 장마다 `size,<장>,<w>x<h>`와 `shot,<장>`, 끝에 `UI SHOTS OK <n>`. `run_ui_shots.ps1`은 `run_stage_shots.ps1`의 꼴(`-Shots`, `-Resolution`, 가져오기 단계, 오류 줄)이고 판정은 "OK 줄 하나, 오류 0, `size,` 줄이 n개이고 모두 기대 크기(`-Resolution` 또는 1280x720)".
- 완료 확인(1부): 기계적 확인 다섯, `.ps1`이 ASCII이고 구문 오류 0(PowerShell 파서로). 찍기는 2부.

**작업 8. 정적 확인과 문서 (1부 끝)**
- 정적 확인: 작업 1~7의 완료 확인을 다시 한 번에 돌리고, `git diff --stat`에 판정 코드·`data/`·`player_sword_view.*`·사용자의 파일이 없다.
- 문서:
  - `docs/STYLE_BIBLE.md`: 6절 161행의 "033까지 결투 HUD는 … 짙은 띠(결정 298)"를 결정 316·319의 한 줄로, "UI의 꼴" 표 아래에 "게임의 자리(계획 033)" 한 문단(테마·StyleBox·결 텍스처의 경로, HUD 패널 다섯과 층, 도움말은 처음 화면, 장부 줄, 결정 312~325). 같은 표의 "결투 HUD" 줄에 "아래 오른쪽 패널(x 780~)은 견본 자리이고 인물 밑 층이라 조용한 구역의 예외". 9절 아래에 글꼴 파일의 자리와 Q1의 답. 10절 "단계 밖의 크기를 옮기는 것은 4단계의 일"을 "옮겼다(계획 033)". 16절의 "글꼴 파일"·"글자 크기와 HUD의 자리"·"그린 질감"(판 N1의 답은 "미확인(2부)")·"밀착에서 모자와 엉킴 경고"(결정 318) 줄.
  - `docs/style/STYLE_SPEC.md` 4부 "4단계로 넘기는 것"의 넷(글꼴 파일, 단계 밖의 크기, HUD의 자리, 밀착의 겹침)에 "(계획 033)"과 한 마디.
  - `docs/DECISIONS.md`: "2026-11-23 — 계획 033" 절에 312~325 한 줄씩과 "실행 중에 정한 것"(검토 전의 답: 완료 기준·도움말·글꼴, L2를 묻지 않은 것, 031·032 2부의 실패 둘을 받은 것).
  - `docs/BACKLOG.md`: 020-1의 밀착 줄을 "결정 318로 옮겼다"(교전 줄은 판 N 뒤에 닫거나 남긴다). 018-F8을 "닫은 것"으로(견본대로, 결정 324). 새 항목 **032-1**(`tests/hand_shots.gd`가 `size,`를 내지 않고 `run_hand_shots.ps1`이 크기를 보지 않는다 — 1886×1061 장도 OK. 고칠 곳 두 파일, `run_stage_shots`의 꼴, 다시 볼 때: 손 그림을 다시 찍는 계획)과 **033-1**(도움말 화면의 상대마다 다른 줄 — 지금은 기본 상대·무기에서 조립한다. 상대가 늘면(035~036) 상대마다 다른 줄을 빼거나 상대별로 보인다. 다시 볼 때: 둘째 상대를 넣는 계획).
  - `assets/MANIFEST.md`(작업 1), `CLAUDE.md`: 3장 엉킴의 "화면 가운데와 내 칼에" → "화면 가운데 아래(내 칼 위)와 내 칼에"(결정 318), 5장 "지금 만든 범위"의 처음 화면에 "도움말", 8장에 `assets/fonts/`·`assets/ui/`·`scripts/ui/`, 9장에 "033(글꼴·필사본 UI, 판 N 남음)". `docs/HANDOFF.md` 1번. 보고서 `docs/reports/033-type-and-manuscript-ui.md`(1부. 머리에 "견본과 다르게 두는 것"의 표를 옮긴다).
- 완료 확인: `DECISIONS.md`에 `^312\.`~`^325\.`이 하나씩. 바이블·명세에 새 hex가 없다(이 계획의 색은 모두 바이블 6절 표와 경고 규칙에 있다. `check027.ps1`의 못 찾은 수 0). 실행에 기대는 칸은 "미확인(2부)". 1부 보고를 하고 **묻지 않고 작업 9로 간다**.

**작업 9. playtester의 확인과 찍기 (2부)**
- 메인이 아래 "playtester에게 맡길 확인"을 한 호출로 넘긴다. 오류가 나면 018·019 보고서의 "가리는 순서"로 가리고, 범위·규칙을 바꾸지 않는 오류는 고쳐서 다시 맡긴다(같은 확인 안에서 한 번까지. 더 걸리면 멈추고 보고).
- 완료 확인: 결과를 보고서 2번에.

**작업 10. 견본과 나란히: 메인의 대조와 고치기, 그다음 판 N (2부, 이 계획의 중심)**
1. **나란히 대기**(`<W>\board-N-pairs.png`, `System.Drawing`. 장은 구운 그대로·찍은 그대로 쓰고 그 위에 그리지 않는다): 장면마다 한 줄에 왼쪽 견본(작업 0) · 오른쪽 게임(`pair-*`)을 같은 크기로. 줄 다섯: 결투(교전), 결투(밀착 경고), 카운터, 정산, 폐점. 아래에 같은 자리를 1:1로 잘라 견본·게임을 붙인 조각: 결투의 위 왼쪽·위 오른쪽·아래 오른쪽 패널, 카운터 말풍선의 왼쪽 위 200×120(패널 머리 글·모서리 마름모), 버튼(주·보통), 장부 세 줄, 벽의 결과 들보.
2. **메인의 차이 목록**(`<W>\diff-N.txt`): 판을 Read로 보고, 패널마다 `sample-rects.txt`와 찍은 장의 화소 사각형(패널 테두리 `#3B2A1E`의 바깥 상자를 `measure.ps1 -Regions`나 행·열 재기로)을 견주어 4화소를 넘는 차, 글꼴·크기·색이 다른 글, 견본에 있고 게임에 없는 것(또는 반대)을 적는다. 각 차이를 "표에 있음(까닭 그대로) / 표에 없음 → 고칠 거리"로 가른다.
3. **고치고 다시 찍기 — 두 번까지**: "고칠 거리"가 결정 312~325 안의 값·자리라면 메인이 고치고(기계적 확인 다섯), playtester에게 찍기(`run_ui_shots` 1280과 T73·T75가 든 테스트)만 다시 맡긴다. 두 번 고쳐도 남거나, 고치려면 결정 밖(층·도움말·장부의 규칙)을 바꿔야 하면 멈추고 "견본과 다르게 두는 것" 표에 "남은 차이(까닭 미정)"로 적어 판 N에 함께 보인다.
4. **판 N**: `board-N-pairs.png`(마지막 찍기), `board-N-other.png`(견본이 없는 장 `title`·`title-save`·`help`·`select`·`settle-hurt`·`duel-far`·`duel-close-bighold`·`duel-right-high`·`result`를 640×360으로), `board-N-1600.png`(1600×900 장 가운데 `pair-counter`·`pair-settle`·`pair-duel`의 같은 자리 400×300을 1:1)와 "견본과 다르게 두는 것"의 표(남은 차이 포함)를 먼저 보이고 한 선택 창(셋)으로 묻는다:
   - **N1 질감**(결정 312·322): "맞다 — 코드 그대로 / 그림으로 바꾼다(033b. 그림의 장 수는 그때 묻는다)".
   - **N2 견본처럼 보이는가**(결투·카운터·정산·폐점, 그리고 견본 없는 화면의 꼴·도움말·엉킴 경고의 새 자리): "맞다 / 고친다".
   - **N3 엉킴 경고 테두리 10**(032 M2-3, 장 `pair-duel-warn`의 내 칼 둘레 1:1): "맞다 / 고친다".
- "고친다"는 다음 글로 받는다. 값·자리의 손질(결정 312~325 안)은 고쳐 다시 찍고 판을 다시 보인다(playtester 찍기 한 번 더). 규칙이 바뀌면(층을 되돌림, 그림을 넣음 등) CLAUDE.md 11장의 수정 절차.
- 완료 확인: `board-N-pairs.png`·`diff-N.txt`와 고친 횟수, 남은 차이의 수, 답을 DECISIONS "실행 중에 정한 것"과 보고서 "2부" 절에. **N2가 "맞다"이기 전에는 이 계획을 끝났다고 보고하지 않는다.**

**작업 11. 답 뒤의 마무리 (메인)**
- N3 "고친다"면 `player_sword_view.gd`의 `BIND_OUTLINE_WIDTH` 하나를 고칠 거리로 받는다. 이 계획의 "고치지 않는 것"에 든 파일이라, 값 하나만 고치고 보고서 3번에 적는다(032의 결정 306의 값. 사용자 답이 근거).
- BACKLOG 020-1의 교전 줄: 판 N의 교전 장에서 깃털과 두 줄 상태 글자가 겹치지 않으면 020-1을 닫고, 겹치면 남긴다.
- 바이블 16절 "그린 질감" 줄과 HANDOFF에 N1의 답. "그림으로"면 "계획 뒤의 차례"의 1.
- 완료 확인: 보고서 4·5번, HANDOFF 1번.

## playtester에게 맡길 확인 (2부)

게임·테스트를 띄우는 명령마다 같은 줄에서 `$env:BRAVI_SAVE_PATH = "user://bravi_playtest_save.json"`을 건다.

1. 테스트: `ALL PASS 76/76`(T73·T75 포함, 오류 줄 0). 스모크 OK.
2. 가져오기: `assets/fonts/`의 `.ttf` 셋에 `.import`가 생기고 가져오기 오류·경고 줄이 0이다. `docs/style` 아래 `.import` 0. **첫 `--import`**에서는 프로젝트 테마가 아직 가져오지 않은 `.ttf`를 읽으려 해 ERROR 줄이 날 수 있다(기술 비차단): 그때는 가져오기를 한 번 더 돌려, 둘째에도 남는 줄만 오류로 적는다(첫째의 줄은 그대로 옮겨 둔다).
3. 찍기: `tests/run_ui_shots.ps1 -Shots "$env:TEMP\bravi-033-ui"`와 `-Shots "$env:TEMP\bravi-033-ui-1600" -Resolution 1600x900`이 모두 `RESULT: OK`이고, `state,` 줄을 그대로 보고에 옮긴다(견본 장면과 다르게 놓인 것). 회귀로 `run_stage_shots.ps1`(1280만, `$env:TEMP\bravi-033-stage`), `run_hand_shots.ps1`(1280, `$env:TEMP\bravi-033-hand`), `run_opponent_shots.ps1 -Stages`(`$env:TEMP\bravi-033-opp-stages`)가 OK이고 `ext` 줄이 `%TEMP%\bravi-031-opp-stages\ext.txt`와 같다(상대 뷰는 상태 글자의 글꼴만 바뀌었다).
4. 게임 창(1280, 그다음 1600×900 창 한 번):
   - (가) 처음 화면에서 "도움말"을 눌러 설명 화면이 뜨고, "돌아간다"와 Esc로 각각 처음 화면으로 돌아오는지(저장 없음·있음 둘 다). 그다음 가게를 연다 → 카운터 → 맡는다 → 결투 → 정산 → 다음 의뢰인까지. 벽·패널·버튼이 양피지·잉크이고, 버튼에 마우스를 올리고 누르면 칠이 바뀌고 누를 때 내려앉는다. 글자가 네모(빠진 글자)로 나오는 곳이 없다.
   - (나) 결투에서 멀리·교전·밀착을 오가며: 왼쪽 위·오른쪽 위·오른쪽 아래 조준 칸(패널 위)에서 좌클릭이 공격, 우클릭이 막기로 나간다(기술 T3). 상대의 상태 글자가 흰 글자에 검은 테두리다(기술 T1). 화면 아래에 도움말 띠가 없고 손·소매가 화면 아래 끝까지 보인다. 위 패널 셋과 아래 패널 둘이 겹치지 않고, 방심 막대가 위 오른쪽 패널 안이다. 멀리에서는 조준 패널이 한 줄 높아진다. 밀착에서 상대가 큰 베기를 들 때 칼이 위 가운데 패널 **위로** 보인다. 오른쪽·상단 조준에서 날밑이 조준 글 **위로** 그려진다. 밀착에서 엉킴 경고가 켜지면 글자가 내 칼 위(아래 가운데)에 뜨고 모자·상태 글자와 겹치지 않는다.
   - (다) 연습: 처음 화면 → 연습 → 의뢰 고르기 → 결투 → 결과 창에서 R(다시 하기)과 **Esc(의뢰 선택으로)**(031·032 2부에서 확인 못 한 것).
   - (라) 폐점에서 살 것 하나를 사고 다음 날을 연다. 로그의 오류 줄 0.

## 위험

- **R0 견본처럼 보이지 않는다**(사용자가 이미 한 번 실망한 곳): 자리·색을 견본 값으로 옮겨도 Godot의 글자 모습, 결 텍스처(SVG 필터와 다른 노이즈), 버튼 글의 세로 자리, 게임 글의 길이(견본은 짧은 예문)로 달라 보일 수 있다. 막는 것: 작업 0의 견본 좌표 표, 작업 10의 나란히 대기·차이 목록·두 번의 고치기, "견본과 다르게 두는 것"의 표. 두 번 뒤에도 남으면 숨기지 않고 판 N에 "남은 차이"로 보인다.
- **R1 손으로 쓴 테마와 StyleBox 스크립트**: 실행 없이 쓴 `.tres`의 키 철자나 StyleBox의 `_draw` 꼴이 틀리면 테마가 걸리지 않아 모든 화면이 기본 꼴이 되거나 오류 줄이 난다. T75의 1이 잡고, 되돌릴 곳은 `project.godot` 한 줄(테마를 떼면 지금과 같은 꼴에 글꼴만 기본)이다.
- **R2 Godot의 글자 모습**: 힌팅·줄 높이·작은 글자가 Edge의 견본과 다를 수 있다. 상태 글자 두 줄의 높이(80), 조준 세 줄(자란 패널), 조건 글(74), 도움말 화면의 줄 수가 넘치면 T75가 잡는다. 넘치면 상자를 늘리고(패널 표의 값) 다시 셈한다. 가져오기 설정(힌팅, MSDF)은 기본값으로 두고 판 N에서 본다.
- **R3 층의 차례**: HUD 안에 둔 `CanvasLayer`(layer −1)가 결투 씬의 기본 캔버스(상대·손) 밑에 그려지는지는 실행해야 안다. T73은 층의 값만 본다. 찍기 `duel-close-bighold`와 게임 창 (나)가 실제 차례를 본다. 안 되면 `Back`을 결투 씬의 노드(`Background` 다음)로 옮긴다(작은 손질).
- **R4 HUD가 인물에 가린다**: 위 가운데 패널은 밀착 큰 베기 동안 칼에 일부 가리고(상대 이름·자세 칸), 오른쪽 조준의 칼과 높은 공격의 손이 아래 오른쪽 패널(조준 글)을 잠깐 가린다. 정보보다 인물의 신호(원칙 4)와 내 손을 앞에 두는 맞바꿈이다(견본도 손을 HUD 위에 그렸다). 판 N2에서 본다.
- **R8 도움말을 결투 중에 못 본다**: 사용자 답대로 결투 화면에는 조작 안내가 없다. 처음 하는 사람이 처음 화면의 도움말을 지나치면 런지·엉킴 같은 규칙을 모를 수 있다. 이 계획은 다른 장치를 넣지 않고 제안만 남긴다("계획 뒤의 차례" 5).
- **R5 결 텍스처**: 처음 화면을 열 때 256×256 화소를 GDScript로 한 번 합친다(짧은 멈춤). 이음매가 보이거나 결이 너무 세거나 약하면 값(주파수·알파)만 고친다.
- **R6 글이 커진다**: 22→24·17→18 등으로 글이 커지고, 버튼의 글 여백(좌우 28씩)이 넓어져 버튼의 최소 크기가 정한 크기보다 커지면 버튼이 오른쪽·아래로 자란다. T75 4(나)가 `get_combined_minimum_size()`로 잡고, 판 N의 장이 본다. 걸리면 버튼 크기나 글 크기를 고친다(견본 자리를 지키는 쪽이 먼저).
- **R7 1920은 못 본다**: 이 컴퓨터의 한계(결정 321). 1600×900에서 글꼴과 결이 늘어나는 모습만 본다.

## 사용자 결정 필요

**검토 전**: 답을 받았다(맨 위 "검토 전에 받은 답"). **v2의 검토 전에 더 물을 것은 없다.**

| 물음 | 때 | 선택지 | 답에 따라 달라지는 것 |
|---|---|---|---|
| N1 | 2부(작업 10의 4) | 맞다 — 코드 그대로 / 그림으로(033b) | 그림으로: 다음 계획이 033b(그림의 몫을 먼저 묻는다). 맞다: 다음은 031b·032b(사용자가 정한 차례) |
| N2 | 2부 | 맞다 / 고친다 | 고친다: 결정 312~325 안이면 값·자리의 손질과 다시 찍기, 층·도움말·장부의 규칙이 바뀌면 수정 절차. "맞다" 전에는 끝났다고 보고하지 않는다 |
| N3 | 2부 | 맞다 / 고친다 (엉킴 경고 테두리 10, 032 M2-3) | 고친다: 작업 11의 `BIND_OUTLINE_WIDTH` 값 하나 |

- 판 N에서 묻지 않는 것: 018-F8(평판 줄의 자리)은 견본대로 두고 닫는다(결정 324. 사용자가 판 N2에서 "고친다"로 다시 열 수 있다).
- 이 계획 뒤에 단계를 넘는 결정은 없다(4단계 안).

## 계획 뒤의 차례

1. N1이 "그림으로"면 033b(그린 질감: 패널·버튼·벽·결 그림의 몫을 먼저 묻고, 테마의 StyleBox 셋과 결 텍스처를 그림으로 바꾼다).
2. **031b**(L3 "크게 그린다": 무대 셋을 1920 이상으로 다시 그린다)와 **032b**(M2-2 "레이피어 꼴로 그린다"). 사용자가 033을 먼저 하라고 했으므로 033 뒤다. 033과 파일이 겹치지 않는다("검토 전에 받은 답"의 끝 문단). 032b는 033이 옮긴 엉킴 경고 글자(내 칼 위)와의 겹침을 찍기에서 다시 본다.
3. 그다음 034(카운터 배경 그림과 의뢰인 그림 — 견본의 그린 의뢰인 자리).
4. 사용자의 플레이 확인 9판(030 작업 13)과 031~033의 커밋(사용자가 요청할 때). L4 "맞다"·M2-1 "맞다"는 031·032의 기록으로만 남긴다.
5. 제안(사용자 답으로 이 계획에는 넣지 않는다): 연습의 첫 판이나 1일차 첫 결투 전에 "처음 화면의 도움말을 보았는가"를 한 번 묻는 길, 결투 중 키 하나(예: F2)로 도움말 화면을 여는 길. 사용자가 원하면 그때 계획한다.

## v2에서 바뀐 곳

| 절 | v1 | v2 |
|---|---|---|
| 머리·근거 | v1, 그린 질감의 답 | v2, 검토 전 답 넷(완료 기준 "025 견본처럼", 도움말 띠를 없애고 처음 화면에 도움말, 글꼴 원본, 031·032의 다른 답)과 견본 굽기 명령. 견본의 그리는 차례(상대 → HUD → 손) |
| 검토 전에 물을 것 | 창 A·B, Q1·Q2, 판 N0 만들기 | "검토 전에 받은 답" 표, 더 물을 것 없음, 판 N0·A·S는 했음, v1 기록은 접어 둠, 031b·032b와 겹침을 다시 봄(유지, 겹칠 수 있는 셋) |
| 목표와 범위 | 결과 8개, 정적 확인과 판 N | 완료 기준 "견본과 나란히 같아 보인다"를 맨 위에, 2부가 중심. 결과 10개(도움말 화면 7, 장부 8, 견본 판정 10 더함. 도움말 띠 없음). 범위 밖: 018-F8은 견본대로 닫음, 장부는 범위 안으로, 판 처음의 안내 장치는 두지 않음 |
| 결정 313 | Q1 가의 꼴(나·다면 v2) | Q1 답 "가" 확정 |
| 결정 315 | 들보 빗금은 034로 | 들보 빗금 띠를 넣음(`hatch_rect.gd`), 머리 띠, 견본 행 번호 |
| 결정 316 | 자리를 새로 정함(위 가운데 433~847, 위 오른쪽 853~, 조준 853~1272), 도움말 띠, Q2 갈래 | 견본 `duelHud`의 자리 그대로(위 가운데만 346~894, 조준 패널은 덧말일 때 24 자람), 다섯 모두 인물 밑 층, 도움말 띠 없음, 조준 패널의 조용한 구역 예외 |
| 결정 318 | x 440~840, N4로 봄 | x 470~770(조준 패널과 10 떨어짐), 견본과 다른 곳임을 적고 N2로 봄 |
| 결정 323~325 | 없음 | 323 도움말은 처음 화면(버튼 자리, `HelpScreen`, 본문 조립, `help_text`는 남김), 324 완료 기준은 견본과 나란히(018-F8 닫음, 카운터 말풍선의 머리 글), 325 장부는 견본의 꼴(`add_ledger_row`, 테스트를 줄 노드로) |
| "견본과 다르게 두는 것" | 없음 | 새 절: 차이 열 줄과 까닭 |
| 작업 0 | 사본 열셋 | 사본 열일곱, 견본 굽기(`bake025.ps1`), 견본 좌표 표 `sample-rects.txt` |
| 작업 4 | 화면 일곱 파일 | 여덟 파일: 처음 화면의 도움말, 카운터의 머리 글, 장부 줄, 들보. 지킬 노드 이름 더함 |
| 작업 5 | Q2 갈래, `HelpBar` | 도움말 띠·라벨 지움, 조준 패널이 덧말일 때 자람, 견본 좌표와의 차를 표로 |
| 작업 6 | T73·T75 | T73에 도움말 띠 없음·조준 패널, T75에 도움말 화면·장부, `scene_tests`·`bind_tests`·`day_tests`의 도움말 검사를 `help_text`로, `safety_tests`의 장부 검사를 줄 노드로 |
| 작업 7 | 장 열둘 | 견본과 짝이 되는 장 다섯(`pair-*`)을 먼저 + 견본 없는 장 아홉(도움말·저장 있는 처음 화면·오른쪽 상단 조준 더함), `state,` 줄 |
| 작업 8 | 결정 312~322, BACKLOG 033-1 장부 | 결정 312~325, 018-F8 닫음, BACKLOG 033-1은 도움말의 상대별 줄, CLAUDE.md 5장 한 마디 |
| 작업 10 | 판 N(장 모음)과 N1~N4 | 견본과 나란히 대기 → 메인의 차이 목록 → 고치고 다시 찍기 두 번까지 → 판 N. 물음 N1 질감, N2 견본처럼 보이는가, N3 엉킴 테두리 10(032 M2-3). N2 "맞다" 전에는 끝이 아님 |
| 작업 11 | N3 평판 줄 | N3 "고친다"면 `BIND_OUTLINE_WIDTH` 값 하나(넘지 않는 선의 예외로 적음) |
| playtester 확인 | Q2 갈래 | 도움말 화면 열고 닫기(버튼·Esc, 저장 있음·없음), 도움말 띠 없음, 조준 패널 높이, 오른쪽 상단의 날밑이 글 위, `state,` 줄 |
| 위험 | R1~R7 | R0 견본처럼 보이지 않는다, R8 결투 중 도움말 없음을 더함. R1의 Q1 갈래와 R4의 도움말 띠를 뺌 |
| 사용자 결정 필요 | Q1·Q2, N1~N4 | 검토 전 답 받음, N1~N3 |
| 계획 뒤의 차례 | 갈래 | 033 → 031b·032b → 034, 제안(판 처음의 안내 장치) |

## v3에서 바뀐 곳 (1회차 검토 대응)

1회차: 디자인 APPROVE, 기술 REVISE(T1~T4). 차단은 모두 수용했다.

| ID | 대응 | 고친 곳 (전 → 후) |
|---|---|---|
| T1 상태 글자의 색 | 수용 | 결정 314: 규칙 "양피지 밖에 놓인 라벨은 색을 직접 준다"를 더함(상태 글자 흰색, 엉킴 경고 `#FF7333`, 기록·디버그·나무 띠 위 `ON_WOOD`). 작업 5: `StateLabel`에 글꼴 줄만 → 글꼴 + `theme_override_colors/font_color = Color(1, 1, 1, 1)`, 완료 확인에 그 줄. T75: 새 6(상태 글자 흰색·테두리 8, 무대·띠 위 라벨의 색). playtester (나)에 "흰 글자에 검은 테두리" |
| T2 처음 화면의 버튼 수 | 수용 | 결정 323: "`HelpScreen`은 처음 열 때 만든다"와 버튼 수(저장 없음 3, 읽을 수 없음 3, 저장 있음 4), 열면 `HelpClose`에 초점. 작업 6: `day_tests` 513행(T33) 2 → 3, `save_tests` 399·407·418행(T58) 2·2·3 → 3·3·4와 이름·실패 글에 `Help`, 열기 전 `HelpScreen`·`HelpClose` 없음, 다른 버튼 세기 Grep. 작업 4: 지킬 이름에 `Help`·`HelpScreen`·`HelpClose`(새 이름과 겹침 없음), `_build_help`를 `_ready`에서 부르지 않음을 Grep. 작업 0의 사본에 `save_tests.gd`(열일곱 → 열여덟) |
| T3 HUD 패널이 클릭을 삼킴 | 수용 | 결정 314: 규칙 "HUD의 Control은 모두 마우스를 무시한다"(결과 패널의 새 `Panel` 포함, 하루 화면의 꾸밈도 IGNORE, `HelpScreen`만 STOP). 결정 316: 층 항목 아래에 IGNORE 한 줄과 까닭. 작업 4·5: `Back/Root`·`_add_panel`의 `Panel`과 결과 패널을 IGNORE로, 완료 확인에 `.new()`마다 IGNORE 대조. T73: `HUD` 아래 모든 Control과 결과 패널이 IGNORE. playtester (나): 패널 위 조준 칸에서 좌·우클릭이 공격·막기로 나감 |
| T4 버튼 여백과 T75 4(나) | 수용(대안 첫째) | T75 4(나): "글 폭 + 32 ≤ 버튼 폭" → 직접 정한 버튼마다 `get_combined_minimum_size()` ≤ 정한 크기(가로·세로), 컨테이너 안 버튼은 컨테이너 폭 안. R6: 최소 크기가 크면 버튼이 자란다는 것과 이 검사가 잡는다는 것 |
| 기술 비차단: 송명의 기호 | 수용 | 결정 314: 송명 자리를 `font_title.tres`(송명 + `fallbacks = [나눔스퀘어라운드 EB]`)로. 작업 1: 메인이 `GlyphTypeface.CharacterToGlyphMap`으로 게임 글의 글자를 세 글꼴과 대조(`glyphs.ps1`·`glyphs.txt`). 작업 3: `font_title.tres`와 테마의 두 키. T75: 새 5(받침) |
| 기술 비차단: sub_resource의 줄 차례 | 수용 | 작업 3 완료 확인: `script = ExtResource(…)`가 `@export` 값 줄보다 먼저 |
| 기술 비차단: `[gui]` 절이 없음 | 수용 | 작업 3: "`[gui]`에 한 줄" → 절 머리·키·빈 줄을 새로 두고, 완료 확인은 그 더함뿐 |
| 기술 비차단: 첫 `--import`의 ERROR | 수용 | playtester 확인 2: 첫 가져오기의 ERROR 줄은 한 번 더 돌려 남는 것만 오류로 |
| 기술 비차단: `stage_tests.gd`도 031b와 겹침 | 수용 | "검토 전에 받은 답" 끝 문단: 겹칠 수 있는 곳 셋 → 넷((1′) T73과 T72의 `STAGE_SIZES`는 다른 줄) |
| 기술 비차단: 결정 318의 가운데 | 수용 | 결정 318: `Rect2(-170, -170, 300, 40)`(x 470~770, 가운데 620) → `Rect2(-130, -170, 260, 40)`(x 510~770, 가운데 640, 조준 패널과 10) |
| 디자인 비차단: 결의 가로 늘임 | 수용 | 결정 312 (가)·(나): 큰 결 0.016 하나 → 주파수 0.02로 만들고 가로 1.67배(타일 427×256)로 그린다. 작업 2: 주파수와 `DRAW_SIZE`, 끝 타일을 같은 비로 자름 |

- 디자인 쪽 판단(플레이 규칙·경험·플레이 확인 기준)에 닿는 변경: 결의 가로 늘임(디자인 검토자가 권한 것 그대로)과 엉킴 경고 글자의 자리가 가운데로 20화소 옮겨진 것뿐이다. 플레이 규칙과 판 N의 물음·완료 기준은 바뀌지 않았다.
