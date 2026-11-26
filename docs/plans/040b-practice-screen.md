# 계획 040b: 연습 화면을 상대 고르기 꼴로 — 상대와 의뢰가 늘어도 화면을 다시 고치지 않게

- 버전: v3 (2026-11-27. 2회차 디자인 APPROVE · 기술 REVISE 신규 T5~T8 — 검토 상한에 닿아 **2회차 뒤 메인 판단(사용자 위임 2026-11-27)으로 통과 조건을 그대로 반영, 추가 검토 없음**. 꼴과 설계는 v2 그대로다. v2: 1회차 D1~D3·T1~T4와 M-1~M-4 반영. v1: 2026-11-27)
- 개발 단계: CLAUDE.md 9장 **6단계(콘텐츠)**, 나눔 039 v2.1 결정 578의 둘째 계획. 새 상대·새 의뢰는 만들지 않는다(041부터).
- 시작점: 040은 커밋되었다(브랜치 `stage6-content`, `4fc17f0`. `ALL PASS 116/116`).
- 근거:
  - 039 결정 578: "연습 화면은 상대가 늘기 전에 한 번만 꼴을 바꾼다 — 뒤의 계획들이 화면의 폭·높이 테스트를 거듭 고치지 않게." 완료 기준은 상대 7명 이상(+멧돼지), 의뢰 18개 이상이다. 결정 575 ④와 planner의 의뢰 표: 같은 의뢰인의 속편이 온다(클라라, 비토리오, 굴리엘모).
  - 이 세션의 방식(사용자 위임 2026-11-27): 꼴은 메인이 대신 고른다. 손이 있어야 아는 판정은 "나중에 사용자가 볼 판"으로.
  - 지금 화면(`scripts/commission/commission_select.gd`, 040 뒤):
    - 제목 줄(`_head`): 제목 + 빈틈 버튼 넷(`OpeningDay0~3`) + `PartCounterToggle` + `StyleTierPick`(상대들의 단 수의 최댓값). 단을 고르면 `_on_tier_picked`가 `TrialGrid`·`PatternHelp`만 지우고 다시 짓는다 — 픽은 `_head`에 있어 지워지지 않는다(172·177~185·196~209행).
    - 의뢰 카드: `CommissionLibrary.load_all("res://data/commissions")` — **폴더 바로 아래의 셋만** 가로로 깐다(`variants/`의 넷은 연습에 나오지 않는다). 사연은 **전부 보인다**. 카드마다 "이 의뢰를 맡는다" 버튼.
    - 시험 칸 `TrialGrid`: `load_trials()`가 `data/opponents/`의 `OpponentData`를 파일 이름순으로 읽고 상대마다 칸 하나(`TrialDuel<n>`, `signature` 공격마다 `PatternDrill<n>`, 첫 상대에만 `SlashDrill`). 끝에 `SpareCell`(`SpareCaption`, `data/attacks/`의 공격마다 `SpareDrill<n>`).
    - `PatternHelp`: 이어 베기·휩쓸기·높이와 빈틈·뛰어들기의 네 줄(모든 상대의 것을 한꺼번에).
    - 고른 상태는 `static` 셋(`_opening_day`, `_part_effects`, `_style_tier`). 지금 크기: 시험 칸 폭 1118/1216, 화면 1248×716/720.
  - 데이터의 사실: 사연의 귀띔은 **끝 문단**에 있다(`variants/legs_only.tres` 18행 "막은 칼을 떼지 말고 끝까지 따라가세요", `variants/first_blood_usurer.tres` 17행). 지금 일곱의 사연은 문단 둘, 가장 긴 것이 약 245자다(`feather_cut.tres`·`throw_match.tres`). 휩쓸기도 데이터로는 `chain`이 차 있다(`opponent_02.tres` — `chain` + `sweep = true`). 기본 검술도 단이 오르면 사슬이 된다(겹찌르기, 찌르고 베기 — 040).
  - 기술 검토가 확인한 사실(1회차):
    - 자동 줄바꿈에 말줄임(`text_overrun_behavior`)이나 자름(`clip_text`)을 켠 `Label`은 자체 최소 크기가 글과 무관해져 `custom_minimum_size`가 높이를 정한다(프레임 없이도). `max_lines_visible`만으로는 그렇지 않다. (엔진 지식 — 실행 확인은 아님)
    - 컨테이너·버튼·위 조건의 `Label`은 프레임 없이 `get_combined_minimum_size()`로 잴 수 있다(`pattern_tests.gd` 500행, `style_tests.gd` 721행의 선례). 예외 둘: 화면의 뿌리는 그냥 `Control`이라 늘 (0, 0)이고(`scenes/ui/commission_select.tscn` 5행), `FlowContainer`의 최소 높이는 마지막 정렬 때의 값이라 프레임 없는 러너에서 0이다.
    - 신호를 내는 중인 노드를 `free`하면 Godot이 ERROR를 찍는다(`verify.ps1` 44행의 패턴에 걸린다).
    - `grab_focus`는 트리 안이면 동기로 돌고 `get_viewport().gui_get_focus_owner()`도 바로 읽힌다. 포커스를 가진 노드를 `remove_child`하면 포커스가 풀린다. 러너에는 `current_scene`이 없어 Esc의 "간다"는 못 본다(스모크 `select_esc`가 본다).
    - 테마: `OptionButton`·토글 버튼은 프로젝트 테마의 `Button` 칸을 받는다. 테마의 `Button/styles/focus`가 빈 StyleBox라(`assets/ui/manuscript_theme.tres` 92·104행) **포커스가 눈에 보이지 않는다**(기존 상태). 버튼의 좌우 여백은 28 + 28이다(40~43행).
    - `run_ui_shots.ps1`: `fit,select`·`practice,select`의 패턴(70·83행)은 `select,`까지 맞춰 새 장과 섞이지 않는다. 29행 `$count = 25`가 장의 수다(6~8행 주석도). static은 찍기 프로세스 안에 남는다.
    - `load_all`은 확장자 `tres`만 봐서(`commission_library.gd` 13행) 내보낸 빌드의 `.tres.remap`을 건너뛴다(기존 흠).
    - `TrialDuel<n>`의 글, `PatternHelp`의 글을 읽는 기존 테스트는 없다.
  - 기술 검토가 확인한 사실(2회차):
    - T75(`tests/manuscript_tests.gd`)가 이 화면의 글을 본다(212~214행이 `_check_text`를 부른다): Label·Button의 글자 크기는 20행의 `STEPS = [54, 46, 34, 28, 24, 20, 18, 16, 14]` 안이어야 하고(15는 없다), 글자가 글꼴에 있어야 한다(72~75행 `has_char`). `_check_text`는 `RichTextLabel`을 보지 않는다.
    - `RichTextLabel`은 이 프로젝트의 첫 사용이고 테마에 그 칸이 없다: 글꼴은 `default_font`를 받지만 글자색 `default_color`는 기본 테마의 흰색이고, 글자 크기 덮어쓰기의 이름은 `normal_font_size`다(`font_size`가 아니다 — 틀리면 말없이 다른 크기가 된다). 기본 줄바꿈은 `AUTOWRAP_WORD_SMART`다.
    - 글꼴 셈은 프레임 없이 된다(선례 `manuscript_tests.gd` 253행).
    - 빈 포커스 StyleBox를 기대하는 테스트는 없다(`manuscript_tests.gd` 111행, `painted_ui_tests.gd` 26행은 normal·hover·pressed·disabled뿐). 버튼 판은 그림이 아니라 스크립트 StyleBox(제비꼬리 꼴)다.
    - 지금 코드는 다시 지은 노드를 기둥의 끝에 붙인다(`commission_select.gd` 226·249행 `column.add_child`).
    - `style_tests.gd` 727~731행을 `load_tree`로 바꾸는 것은 선다. `pattern_tests.gd`의 넷째 칸 화면 부분은 476행의 주석부터 508행 `select.free()`까지다.
  - 이 화면을 보는 테스트와 도구: 아래 "기존 테스트를 옮기는 법"의 표(기술 검토의 Grep으로 빠진 자리가 없다).
  - 지킬 것: 원칙 4(관찰로 이긴다 — 사연의 귀띔), 5(데이터 주도), CLAUDE.md 4장(`dialogue`는 버릇 힌트를 담는다), 결정 323(막는 법의 글은 이 화면과 도움말에만), 7장의 필사본 UI(새 그림 0장), Esc는 처음 화면, 예약 키와 S03의 조작을 건드리지 않는다.
- 결정 번호 594~606, 테스트 T117~T119.

### 넘지 않는 선

- 메인은 Godot·테스트·게임을 실행하지 않는다. 확인은 verifier(`tests/verify.ps1` — 테스트와 `ui` 찍기). playtester는 부르지 않는다.
- 코드는 메인이 Sonnet 하위 에이전트에게 작업 하나씩 맡기고 diff로 확인한다. 편집은 80줄 안쪽으로 나눈다. HANDOFF 4번의 기계적 확인 다섯을 지킨다.
- 고치지 않는 것: 결투·하루의 코드, 상대·의뢰·공격의 데이터, 그림, 처음 화면, `run_ui_shots.ps1`의 `fit,select`·`practice,select` 판정 줄, `CommissionLibrary.load_all`.
- 연습에서 판에 넘기는 것(빈틈의 날, 반격 실험, 단, 의뢰의 판은 1단·날 없음)은 한 치도 바꾸지 않는다. 바뀌는 것은 화면의 꼴과 테마의 포커스 테두리(결정 605)뿐이다.

## 목표와 범위

연습 화면이 **목록에서 하나를 고르는 꼴**이 되어, 뒤의 계획이 상대 파일 하나나 의뢰 파일 하나를 더하면 화면에 나오고 화면의 코드·테스트를 다시 고치지 않는다.

**확인할 결과**:

1. `data/opponents/`에 상대 파일을, `data/commissions/`(와 그 아래 폴더)에 의뢰 파일을 더하면 코드 없이 목록에 나온다. 같은 의뢰인의 의뢰가 둘이어도 줄이 갈린다(T117·T118).
2. 상대 12명과 의뢰 30개, 긴 이름·긴 사연·많은 패턴을 넣어도 모든 쪽·모든 고르기에서 1280×720 안이다(T118, 찍기 `select-many`).
3. **폴더의 실제 의뢰는 사연이 전부, 스크롤 없이 보인다**(T117, 찍기 `select-story`). 뒤 계획이 긴 사연을 더하면 이 확인이 떨어진다.
4. 고른 상대의 막는 법이 그 상대(그 단)의 공격에 맞는다(T117).
5. 고른 상대, 단, 빈틈의 날, 반격 실험, 고른 의뢰가 결투에서 돌아와도 남는다(T117).
6. 키보드만으로 모든 것에 닿고 **포커스가 눈에 보인다**. Esc는 처음 화면이다(T119, 장 `select`).
7. 판에 넘어가는 상대와 의뢰가 지금과 같다(T111·T115의 옮긴 기대, 기존 116개).

## 화면의 꼴(결정 594)

```
┌────────────────────────────────────────────────────────────────────────────────────────────┐
│ 연습  (Esc: 처음 화면)                    빈틈 [늘 열린다][1일차][2일차][3일차부터] [반격 실험] │ 머리 줄(_head)
├─────────────────────────┬──────────────────────────────────────────────────────────────────┤
│ 상대            ◀ 1/1 ▶ │ ● 바르톨로 · 이어 베기                          [검술 1단 ▼]     │ TrialHead
│ [● 바르톨로 · 이어 베기 ]│ [자유 결투] [베기만  ] [이어 베기] [세 번 베기]                  │ TrialGrid
│ [● 브루노 · 휩쓸기      ]│ [        ] [        ] [        ] [        ]   (한 줄에 넷, 두 줄)│
│ [● 로렌초 · 뛰어드는 …  ]│ 그 상대(그 단)의 막는 법 — 네 줄까지                            │ PatternHelp
│ [  주인 없는 검술       ]├──────────────────────────────────────────────────────────────────┤
│                         │ 모자 장인 클라라 · 상대: 바르톨로                                 │
│ 의뢰            ◀ 1/2 ▶ │ 사연 전부 (칸의 폭 전체, 일곱 줄. 실제 의뢰는 다 든다)            │ 의뢰 카드
│ [● 클라라 · 바르톨로    ]│ …끝 문단의 귀띔까지                                               │ (한 장)
│ [● 에밀리오 · 바르톨로  ]│                                                                  │
│ [● 이네스 · 바르톨로    ]│ 조건(강조색, 세 줄까지)                      [이 의뢰를 맡는다]  │
│ [● 토마소 · 바르톨로    ]│                                                                  │
│ [● 오르솔라 · 브루노    ]│                                                                  │
└─────────────────────────┴──────────────────────────────────────────────────────────────────┘
```

왼쪽(폭 360)은 **목록 둘**(상대, 의뢰 — 한 쪽 다섯 줄, 넘치면 쪽 넘김), 오른쪽(폭 836)은 **고른 것의 칸 둘**이다. 머리 줄의 도구는 상대의 시험 버튼에만 탄다(지금 그대로).

## 설계 결정

594. **꼴은 위 그림이다**(메인이 대신 고름 — 사용자 위임 2026-11-27). 가로로 늘어놓던 것을 세로 목록과 "고른 것 하나"로 바꾼다. 화면에 한꺼번에 보이는 것의 수가 데이터의 수와 상관없어진다. 맨 위의 `MarginContainer`에 이름 `ScreenMargin`을 준다(크기를 재는 자리 — 결정 601).
595. **데이터의 자리 — 폴더 그대로**:
     - 상대: `data/opponents/`의 `OpponentData`를 파일 이름순으로(`load_trials()` 그대로). 따로 목록 `.tres`를 만들지 않는다(고칠 곳이 둘이 되어 빠뜨릴 수 있다). 화면은 `_ready`에서 **한 번** 읽어 인스턴스에 두고 다시 지을 때 또 읽지 않는다.
     - 의뢰: `data/commissions/`와 그 아래 폴더의 `Commission` 전부. `CommissionLibrary.load_tree(dir)`를 새로 둔다 — 바로 아래의 파일(이름순) 다음에 하위 폴더(이름순)의 파일(이름순). `get_files_at`·`get_directories_at`를 각각 `sort()`하고 `load_trials`처럼 `.remap`을 떼고 읽는다. `load_all`은 고치지 않는다. 그래서 변형 넷(`variants/`)도 연습에 나와 의뢰가 일곱이 된다(판 F-3).
     - 주인 없는 공격: `data/attacks/`(`load_spare_attacks()` 그대로). 공격이 있으면 상대 목록의 **끝에 "주인 없는 검술" 한 줄**이 생기고, 폴더가 비면 사라진다. 몸은 첫 상대다 — **상대가 하나도 없으면 그 줄을 만들지 않는다**(몸이 없다. 상대 목록 자리에 "상대가 없습니다" 글).
596. **넘침은 "정한 크기"로 막는다**(데이터의 길이가 화면의 크기를 바꾸지 못하게):
     - **목록**: 한 쪽 `LIST_ROWS = 5`줄. 줄의 버튼은 폭이 정해져 있고(글자 16) 글이 넘치면 `clip_text` + 풍선말. 쪽 넘김은 목록 머리의 `◀ n/m ▶`(한 쪽뿐이면 두 버튼이 꺼진다 — 자리는 그대로). "◀"·"▶"가 본문 글꼴에 있는지는 확인하지 않았다 — **V1에서 T75가 "[연습 선택] 글꼴에 없는 글자"를 내면 글을 `<`·`>`(그것도 없으면 "이전"·"다음")로 바꾼다**(미리 허락된 길. 고침의 횟수로 세지 않는다).
     - **글자 크기**: 이 화면의 Label·Button의 글자 크기는 전부 T75의 `STEPS` 안의 값(28·24·20·18·16·14)만 쓴다.
     - **시험 칸의 버튼**: `TrialGrid`는 `GridContainer`(한 줄에 `DRILL_COLUMNS = 4`, 두 줄)다. 버튼의 폭은 같고 정해져 있으며(약 200 — 테마의 여백 56을 빼고 18pt 여덟 자가 든다. "뛰어드는 찌르기"가 다 보인다) 넘치면 `clip_text` + 풍선말. 칸은 버튼이 적어도 두 줄의 높이를 차지한다. 자리는 여덟: 자유 결투 + 베기만 + **패턴만 `DRILL_MAX = 6`개까지**. 고유 공격이 여섯을 넘는 단이면 앞의 여섯만 버튼이 되고, **실제 데이터에서는 모든 상대·모든 단의 고유 공격이 여섯 이하**임을 T117이 지킨다(지금 가장 많은 것이 둘). `HFlowContainer`는 쓰지 않는다(최소 크기를 프레임 없이 잴 수 없다).
     - **막는 법**: `PatternHelp`는 네 줄의 높이로 정하고(자동 줄바꿈 + 말줄임 + `custom_minimum_size`) 넘치면 풍선말.
     - **의뢰 카드**: 크기가 정해진 한 장. **사연 칸은 카드의 폭 전체, 일곱 줄**(`STORY_LINES = 7`, 글자 16)이고 `RichTextLabel`이다 — 말줄임을 하지 않는다. 일곱 줄을 넘는 글은 칸 안에서 세로로 스크롤된다(포커스를 받고 위·아래 키로 움직인다. 스크롤바가 보이는 동안은 위·아래가 칸에 먹히므로 포커스는 Tab·좌우로 나간다 — 비정상 길이에서만 생기는 일이다). 칸의 높이는 손 어림이 아니라 `font.get_height(16) × STORY_LINES`(+ 줄 간격)에서 얻는다. 조건은 세 줄까지(자동 줄바꿈 + 말줄임 + 풍선말).
     - **사연의 길이 기준**(039의 새 의뢰를 쓸 때의 잣대): **280자 이하, 문단 둘 이하**(임시. 칸 폭 약 800에서 한 줄에 약 48~55자, 지금 가장 긴 사연이 약 245자·여섯 줄 어림). 판정은 글자 수가 아니라 T117의 줄 셈과 찍기 `select-story`다: **폴더의 실제 의뢰는 모두 일곱 줄 안에 들어 스크롤이 생기지 않아야 한다.** 스크롤은 시험 데이터 같은 비정상 길이의 안전망이다.
     - 어림한 세로 예산(안쪽 1216×656. 실제 값은 V1의 장으로 맞춘다): 머리 줄 44 · 간격 20 · 몸 592. 왼쪽 = [머리 40 + 다섯 줄 200] × 2 + 16 = 496. 오른쪽 = `TrialHead` 40 + 10 + `TrialGrid` 92 + 10 + `PatternHelp` 88 + 16 + 카드 308(여백 36 · 머리 30 · 사연 154 · 조건과 버튼 72 · 간격 16) = 564.
     - **넘치면 줄이는 차례**(상수만): 왼쪽이 넘치면 `LIST_ROWS` 5 → 4. 오른쪽이 넘치면 ① 칸 사이의 간격 16·10 → 8 ② 조건 세 줄 → 두 줄(지금 의뢰의 조건은 한두 줄이다. T117(바)의 조건 줄 셈이 실제 데이터에서 그대로 통과할 때만) ③ `PatternHelp`의 글자 16 → **14**(15는 T75의 `STEPS`에 없다). **사연 칸은 줄이지 않는다** — 실제 데이터의 가장 긴 사연이 드는 줄 수 아래로는 내리지 않는다. 그래도 넘치면 멈추고 수와 장을 보고한다.
597. **고른 상태는 `static`으로 남는다**: 지금의 셋에 `_picked_opponent`(목록의 번호. "주인 없는 검술"은 마지막 번호), `_picked_commission`을 더한다. 쪽은 고른 번호에서 셈한다. 화면을 지을 때 번호를 목록의 길이로 자른다. `_style_tier`는 고른 값 그대로 남기고 칸을 지을 때 **그 상대의 단 수로 잘라** 쓴다(7단을 고른 채 6단짜리 로렌초로 가면 6단이 보이고, 바르톨로로 돌아오면 다시 7단). **지금 보이는 쪽은 인스턴스 변수**다(목록마다 하나): 쪽 넘김은 고른 번호를 바꾸지 않고 보이는 쪽만 바꾼다. "쪽은 고른 번호에서 셈한다"는 화면을 처음 열 때와 `pick_*`에만 선다.
598. **고른 상대의 칸**:
     - `TrialHead`(첫 줄): 고유 색의 점 · 이름 · 고유 검술의 이름(흐리게) · 오른쪽 끝에 `StyleTierPick`(항목 = 그 상대의 `tier_count()`. 단이 하나뿐인 상대와 "주인 없는 검술"에서는 만들지 않는다). **상대를 고를 때만** 새로 짓는다.
     - `TrialGrid`(버튼 칸. 이름을 지킨다): `TrialDuel0`("자유 결투"), 첫 상대일 때만 `SlashDrill`("베기만" — 지금 규칙 그대로. R02의 판 P 전에는 넓히지 않는다), 그 단의 `signature` 공격마다 `PatternDrill<n>`(0부터, 여섯까지). "주인 없는 검술"이면 `SpareDrill<n>`이 서고 `TrialHead`의 글이 `SpareCaption`("주인 없는 검술 — 다음 상대 몫")이다. 상대나 단을 고르면 새로 짓는다.
     - 버튼에 묶이는 상대는 지금과 같다: `opponent.at_tier(단)`과 그 `drill(공격)`, 누를 때 `_trial_copy`가 빈틈의 날과 반격 실험을 얹는다.
     - 목록의 줄(`OpponentPick<n>`): 고유 색의 점(버튼의 아이콘 — 그 상대의 첫 `signature` 공격의 `pose_color`. 없으면 점이 없다) · "이름 · 고유 검술". 고른 줄은 눌린 채다(토글, `ButtonGroup`).
     - **`PatternHelp`를 고르는 규칙**: **고른 단의 공격 목록 전체**(기본 + 고유, 변주까지)로 가른다.
       - 이어 베기의 줄(`HELP_CHAIN`) = `chain`이 있고 `sweep`이 **아닌** 공격이 하나라도 있을 때.
       - 휩쓸기의 줄(`HELP_SWEEP`) = `sweep`인 공격이 있을 때.
       - 뛰어들기의 줄(`HELP_DIVE`) = `dive`인 공격이 있을 때.
       - 높이와 빈틈의 줄(`HELP_HEIGHT` + `opening_help`) = 늘.
       - "주인 없는 검술"은 **그 공격들**로 가른다(층층·엇박이면 이어 베기의 줄과 높이의 줄).
       - 뒤의 계획이 새 검술의 줄을 더할 때도 같은 꼴로(그 칸을 가진 공격이 있을 때만) 더한다. 한 상대에게 다섯 줄이 되면 그 계획이 글을 줄인다.
599. **의뢰의 목록과 카드**:
     - 목록의 줄(`CommissionPick<n>`): 그 의뢰의 **상대의 고유 색 점** · "**의뢰인 · 상대 이름**". 같은 글의 줄이 둘이면 뒤의 것에 차례로 " (2)", " (3)"을 붙인다(같은 의뢰인이 같은 상대로 다시 오는 속편). 풍선말은 첫 조건의 설명이다.
     - **고른 상대의 의뢰에 표시**: 상대를 고르면 그 상대가 서는 의뢰의 줄이 강조색 글자가 된다(차례와 쪽은 바꾸지 않는다). "주인 없는 검술"이면 표시가 없다.
     - 카드(`CommissionCard`): 첫 줄 "의뢰인 · 상대: 이름", 사연 칸 `CommissionStory`, 아래 줄에 조건(왼쪽)과 `CommissionStart`("이 의뢰를 맡는다" — 글을 지킨다). 의뢰의 판은 지금과 같다(`session.commission`, 1단, 날 없음, 머리 줄의 도구는 타지 않는다). 의뢰가 하나도 없으면 지금의 글("의뢰가 없습니다 …")이 카드 자리에 선다.
600. **다시 짓기와 포커스**(같은 호출 안에서 `remove_child` + `free`. `queue_free`·`reload_current_scene`은 쓰지 않는다):
     - **누른 것은 지우지 않는다.** 상대의 줄을 누르면 `TrialHead`·`TrialGrid`·`PatternHelp`를 새로 짓고 목록은 눌림과 의뢰 줄의 표시만 바꾼다. 의뢰의 줄을 누르면 카드만. 쪽 넘김을 누르면 그 목록의 줄들만(쪽 넘김 버튼은 목록 머리에 남는다). **단을 고르면 `TrialGrid`·`PatternHelp`만** 새로 짓는다 — `StyleTierPick`과 그 조상(`TrialHead`)은 건드리지 않는다(지금의 `_on_tier_picked`와 같은 범위. 신호를 내는 노드를 `free`하지 않는다).
     - **다시 지은 노드는 제자리에 선다**: 오른쪽 기둥의 차례는 늘 [`TrialHead`, `TrialGrid`, `PatternHelp`, `CommissionCard`]다. 자리마다 지킴 컨테이너를 두고 그 안에서 갈아 끼우거나, 붙인 뒤 `move_child`로 번호를 맞춘다(지금 코드처럼 기둥의 끝에 붙이면 칸이 카드 아래로 내려간다). 목록의 줄들도 목록 머리 아래의 제 자리에 선다.
     - **줄의 `pressed` 길에서는 그 목록의 줄을 다시 짓지 않는다.** `pick_*`가 줄들을 다시 짓는 것은 "보이는 쪽 ≠ 그 번호의 쪽"일 때뿐이다(누른 줄은 늘 보이는 쪽에 있다). 의뢰 줄의 표시(강조색)는 색 덮어쓰기로 제자리에서 바꾼다.
     - 포커스: 누른 노드가 남으므로 포커스가 그대로다. `pick_opponent`·`pick_commission`을 메서드로 불렀거나 포커스를 가진 노드가 지워진 경우를 위해, 다시 지은 뒤 **포커스의 주인이 없으면**(`gui_get_focus_owner() == null`) 방금 고른 줄(쪽이 넘어갔으면 새 줄)이 잡는다. 화면을 처음 열면 `CommissionStart`가 잡는다.
     - 새 단축키는 두지 않는다. 모든 버튼·`OptionButton`·사연 칸은 `focus_mode`가 전부다.
601. **노드 이름**(테스트와 찍기가 기대는 것):
     - **지킨다**: `_head`(머리 줄 — T115가 폭을 잰다), `TrialGrid`, `PatternHelp`, `OpeningDay0~3`, `PartCounterToggle`, `StyleTierPick`, `TrialDuel0`, `SlashDrill`, `PatternDrill<n>`, `SpareCaption`, `SpareDrill<n>`, 버튼 글 "이 의뢰를 맡는다", 정적 함수 `load_trials`·`load_spare_attacks`, 메서드 `_trial_copy`·`_start_opponent`.
       - `TrialGrid`는 버튼 두 줄뿐이라 T115의 한도(높이 ≤ `TrialDuel0` × 2 + 20, 폭 ≤ 1216)가 **그대로 선다**(세로 간격 12).
       - `ui_shots.gd`의 `fit,`·`practice,` 줄과 `run_ui_shots.ps1`의 그 판정은 고치지 않는다: 처음 여는 화면은 첫 상대가 골라져 있어 `SlashDrill`이 있고, `TrialGrid`의 오른쪽 끝 ≤ 1248, `PatternHelp`의 아래 끝 ≤ 720.
     - **새로 생긴다**: `ScreenMargin`, `OpponentList`, `OpponentPick<n>`, `OpponentPrev`·`OpponentNext`·`OpponentPage`, `CommissionList`, `CommissionPick<n>`, `CommissionPrev`·`CommissionNext`·`CommissionPage`, `TrialHead`, `CommissionCard`, `CommissionStory`, `CommissionStart`.
     - **사라진다**: `TrialDuel1` 이상, `SpareCell`, 메서드 `_add_trial_column`·`_add_card`.
     - 테스트가 쓰는 길: `pick_opponent(index)`, `pick_commission(index)`(버튼을 누른 것과 같은 일. 다른 쪽의 번호면 쪽도 넘긴다), 정적 함수 `story_lines(commission) -> int`(결정 603).
602. **시험 데이터를 넣는 길**: 인스턴스 변수 `trial_source: Array[OpponentData]`·`spare_source: Array[AttackData]`·`commission_source: Array[Commission]`(형 있는 배열)와 `use_sources := false`. 트리에 붙이기 전에 채우고 켜면 폴더 대신 **셋 다** 그것으로 짓는다(빈 목록도 그대로 쓴다). 게임에서는 늘 꺼져 있다.
603. **사연이 다 보이는가를 재는 법**: `story_lines(commission)`은 사연 칸의 글꼴·글자 크기·정해진 폭으로 줄 수를 셈한다(프레임이 없어도 된다). 화면도 같은 상수를 쓴다.
     - 줄 수는 높이를 줄 높이로 나눠 어림하지 않고 **`TextParagraph`에 문단마다 글을 넣어 `get_line_count()`로 센다**(문단의 합). 줄바꿈의 깃발은 `RichTextLabel`의 기본(`AUTOWRAP_WORD_SMART`, 가장자리 공백 자름)과 같게 **명시한다**(`get_multiline_string_size`의 기본 깃발은 그와 다르다).
     - 셈의 폭 상수 `STORY_WIDTH`는 실제 칸의 폭 **이하**여야 한다(셈이 실제보다 너그럽지 않게).
     - 같은 셈 함수(글·글자 크기·폭을 받는 것)로 **조건 칸**과 **`PatternHelp`**의 줄 수도 잰다(T117(바)). T117이 폴더의 모든 의뢰에서 `story_lines ≤ STORY_LINES`를 보고, 찍기 `select-story`가 가장 긴 사연의 의뢰를 고른 화면에서 실제로 놓인 꼴을 낸다: `story,select-story,<놓인 줄 수>,<칸의 줄 수>,<get_content_height()>,<칸의 높이>,<칸의 실제 폭>,<STORY_WIDTH>`. 판정은 놓인 줄 수 ≤ 칸의 줄 수, 내용의 높이 ≤ 칸의 높이, `STORY_WIDTH` ≤ 실제 폭이다.
604. **글**: 제목은 "연습  (Esc: 처음 화면)". 목록의 머리는 "상대"·"의뢰", 시험 칸의 버튼은 "자유 결투"(지금은 상대의 이름이 버튼 글이다 — 이름은 `TrialHead`로 간다). 도움말 화면과 처음 화면의 글은 그대로다.
605. **포커스가 눈에 보이게 한다**(메인의 결정 M-3): 프로젝트 테마(`assets/ui/manuscript_theme.tres`)의 `Button/styles/focus`를 빈 StyleBox에서 **가운데를 칠하지 않는 굵은 테두리**(StyleBoxFlat, `draw_center = false`, 테두리 3, 색은 테마의 강조색, 버튼 판의 모서리에 맞춤)로 바꾼다. 새 그림은 없다. `OptionButton`·토글도 같은 칸을 받는다. **다른 화면의 버튼에도 포커스 테두리가 보이게 된다**(처음 화면, 설정, 카운터 등) — 받아들인다. 사연 칸(`RichTextLabel`)의 포커스에도 같은 테두리를 건다(이 화면에서 덮어쓰기). 빈 포커스 StyleBox를 기대하는 테스트는 없으므로(2회차 확인) **테마를 고치는 첫째 길로 간다**. 버튼 판이 제비꼬리 꼴의 스크립트 StyleBox라 네모 테두리가 판의 꼴과 어긋나 보일 수 있다 — V1의 장에서 메인이 보고, 어긋나면 테두리의 굵기·모서리 값을 고친다(값만). 강조색이 조건 글·고른 상대의 의뢰 표시·포커스 테두리 세 곳에 쓰이므로 `select.png`에서 "고른 줄"(눌린 판)과 "포커스"(테두리)가 갈리는지 본다. 그래도 다른 화면에서 받아들이기 어려운 꼴이면 **이 화면의 버튼에만** 덮어쓰기로 건다(`add_theme_stylebox_override("focus", …)`).
606. **확인**: 새 테스트 셋(T117~T119, `tests/practice_screen_tests.gd`), 옮기는 기존 기대(아래 표), 찍기 장 셋(`select-spare`·`select-many`·`select-story`)과 새 판정 줄 둘(`many,`, `story,`). 테스트의 수는 `load_trials()`·`load_tree()`·`load_spare_attacks()`의 크기에서 얻고 수를 적지 않는다(메인의 결정 M-2). 주인 없는 검술의 확인과 장은 `spare_source`로 넣은 시험 공격으로 한다 — 041·042가 `data/attacks/`를 비워도 고칠 것이 없다.

## 기존 테스트를 옮기는 법(결정 601)

기대 값을 고치는 곳은 이 표뿐이다. 판에 넘어가는 상대·의뢰를 보는 기대는 뜻을 지키고 "고르는 걸음"만 더한다. 수는 적지 않고 읽는 함수의 크기에서 얻는다.

| 자리 | 지금 보는 것 | 옮긴 뒤 |
|---|---|---|
| `flow_tests.gd` 141~150행 | "이 의뢰를 맡는다" 버튼 수 == `load_all`의 크기(3) | 시작 버튼 **1개**, `CommissionPick*`의 수 == min(`load_tree`의 크기, `LIST_ROWS`) |
| `pattern_tests.gd` 346~357행 (T81의 6) | `TrialDuel*` = 상대 수, `PatternDrill*` = 패턴 합, "이 의뢰를 맡는다" 3 | 처음 화면: `TrialDuel*` 1, `PatternDrill*` = 첫 상대의 고유 공격 수, 시작 버튼 1. `pick_opponent`로 상대를 돌며 `PatternDrill*`의 합 == `pattern_total`, `OpponentPick*` == min(상대 수 + 주인 없는 검술의 줄, `LIST_ROWS`) |
| `pattern_tests.gd` 476~508행 (넷째 칸) | `SpareCaption`·`SpareDrill*` 2, 글과 풍선말, 높이, 버튼 수 [5, 3] | **화면을 보는 줄을 지운다**(476~508행의 화면 부분 — 폴더의 공격 데이터를 보는 앞 줄들은 그대로). 주인 없는 검술의 화면은 T117이 `spare_source`로 본다 |
| `pattern_cell_tests.gd` 353~358행 | `TrialFlat*` 0개 | 그대로(고치지 않는다) |
| `pattern_cell_tests.gd` 487~525행 (T91의 6·7) | `load_trials()` 셋과 차례, 버튼 수 [3, 5, 0, 4], `_add_trial_column`으로 채운 폭, 이름이 이어진다 | `load_trials()`의 줄은 그대로. 버튼 수 [1, 첫 상대의 고유 수, 0, 4]. 채워서 폭을 재던 줄(503~516행)은 지운다 — T118이 잰다. 이름이 이어지는지는 고른 칸 안에서(`PatternDrill0~`) |
| `part_effect_tests.gd` 1238~1282행 (T111) | 이름 여섯(`TrialDuel0~2`, `PatternDrill0`, `SlashDrill`, `SpareDrill0`)에 묶인 상대와 `_trial_copy`의 결과, 토글이 남는다 | 같은 것을 고르며 읽는다: `pick_opponent(n)`마다 `TrialDuel0`, 0번에서 `PatternDrill0`·`SlashDrill`. `SpareDrill0`은 `spare_source`에 시험 공격 하나를 넣은 화면에서(폴더가 비어도 돈다). 넘어가는 사본의 기대는 그대로. 끝에 static을 되돌린다 |
| `style_tests.gd` 668~719행 (T115의 연습) | `StyleTierPick`의 항목 = 단 수의 최댓값, `TrialDuel0~2`가 그 단의 목록, 패턴만 5, 자유 결투 3 · 빈틈 4 · 토글 1 · 베기만 1, `item_selected` 뒤 `TrialGrid`·`PatternHelp`가 새 노드 하나 | 상대마다 `pick_opponent(n)` 뒤 **픽을 다시 찾는다**: 항목 = 그 상대의 `tier_count()`, 단마다 `item_selected` 뒤 `TrialGrid`·`PatternHelp`가 새 노드 하나이고 **픽은 같은 노드로 살아 있다**, `TrialDuel0`이 그 단의 목록, 패턴만 = 그 상대 그 단의 고유 수, 자유 결투 1 · 빈틈 4 · 토글 1 · 베기만(0번만 1). 7단을 고른 채 로렌초로 가면 6단이 보이고 `_style_tier`는 남는다 |
| `style_tests.gd` 720~726행 | `TrialGrid` 높이 ≤ `TrialDuel0` × 2 + 20 · 폭 ≤ 1216, `_head`의 폭 ≤ 1216 | **그대로**(고치지 않는다 — 결정 601: `TrialGrid`는 버튼 두 줄뿐이고 `_head`의 이름을 지킨다) |
| `style_tests.gd` 727~731행 | `load_all`의 의뢰의 상대가 1단 | `load_tree`로 바꾼다(연습에 나오는 의뢰 전부) |
| `opening_chance_tests.gd` 305~309행, `manuscript_tests.gd` 212~215행, `day_smoke.gd` 210행 | `OpeningDay<n>`, 띄우기, Esc | 그대로(고치지 않는다) |
| `ui_shots.gd`의 `select` 장과 `fit,`·`practice,` 줄 | 113~118행 | 줄은 그대로. 장 셋을 `select` **뒤에** 더하고 끝에 static을 되돌린다(작업 6) |
| `run_ui_shots.ps1` 29행 `$count = 25`, 6~8행 주석 | 장의 수 | 28 |

## 작업 목록

차례대로 한다. 완료 확인은 메인의 diff 읽기이고, 실행 확인은 끝의 V1에 모은다.

| # | 작업 | 대상 | 의존 | 완료 확인 |
|---|---|---|---|---|
| 0 | **사전 읽기**(고치지 않는다): ① 위 표의 줄 번호가 `4fc17f0`에서 맞는가 ② 테마의 강조색 값과 버튼 판의 모서리 값(`manuscript_theme.tres`, `day_ui.gd`의 `ACCENT`) ③ Label의 글자색(`font_color`)의 값과 그것을 얻는 길(사연 칸의 `default_color`에 넣을 값) | Grep·Read | — | 세 답을 실행 기록에 한 줄씩(v2의 ③ 글꼴·④ 포커스 테스트는 2회차 검토가 답했다 — "근거") |
| 1 | **읽기**: `CommissionLibrary.load_tree`. 화면의 `trial_source`·`spare_source`·`commission_source`·`use_sources`, static 둘, `_ready`에서 한 번 읽어 두는 세 목록(결정 595·597·602) | `scripts/commission/commission_library.gd`, `scripts/commission/commission_select.gd` | 0 | `load_all`은 한 줄도 바뀌지 않았다. `load_trials`·`load_spare_attacks`의 이름과 돌려주는 것이 그대로다 |
| 2 | **뼈대와 왼쪽**: `_ready`를 `ScreenMargin` · 머리 줄(`_head`) · 왼쪽(목록 둘) · 오른쪽으로 다시 짠다. 목록 짓기 하나(줄 다섯, 쪽 넘김, `clip_text`와 풍선말, 색의 점, 같은 글의 " (2)", 고른 줄의 눌림, 고른 상대의 의뢰 표시)를 상대와 의뢰가 함께 쓴다. `pick_opponent`·`pick_commission`과 쪽의 셈(결정 596·597·599·600) | `commission_select.gd` | 1 | `reload_current_scene`·`queue_free`가 없다. 목록의 폭과 줄 수가 상수다. 머리 줄의 `OpeningDay<n>`·`PartCounterToggle`은 지금 함수 그대로다. `_add_tier_pick`은 `_head`가 아니라 `TrialHead`에 붙인다 |
| 3 | **오른쪽 위**: `TrialHead`(상대를 고를 때만), `TrialGrid`(`GridContainer`, 넷씩 두 줄, 버튼 폭 고정, `DRILL_MAX`)와 `PatternHelp`의 줄 고르기(결정 598). 단 고르기는 `TrialGrid`·`PatternHelp`만 다시 짓는다. `_add_trial_column`·`SpareCell`을 지운다 | `commission_select.gd` | 2 | 버튼에 묶이는 상대를 만드는 식(`at_tier`·`drill`·`_trial_copy`)이 지금과 글자까지 같다. 단 고르기의 길에 `TrialHead`·`StyleTierPick`을 지우는 줄이 없다. 다시 지은 노드가 제자리에 선다(기둥의 끝에 붙이는 `add_child`만으로 끝나지 않는다 — 결정 600). 글자 크기가 `STEPS` 안이다 |
| 4 | **오른쪽 아래**: 카드 한 장(`CommissionCard`·`CommissionStory`·`CommissionStart`), 줄을 세는 정적 함수와 `story_lines`(결정 599·603). `_add_card`를 지운다. **사연 칸(`RichTextLabel`)의 값**: `bbcode_enabled` 끔, `fit_content` 끔, 스크롤 켬, `focus_mode` 전부, 글자색 덮어쓰기 `default_color` = Label의 `font_color`(작업 0-③), 글자 크기 덮어쓰기 **`normal_font_size`** = 상수 16(`font_size`가 아니다), 높이 = `font.get_height(16) × STORY_LINES`(+ 줄 간격) | `commission_select.gd` | 2 | `_start`·`_start_opponent`·`_unhandled_input`은 고치지 않았다. 사연 칸에 말줄임이 없다. `add_theme_font_size_override`의 이름이 `normal_font_size`다. 카드를 다시 지은 뒤 기둥의 넷째 자리다 |
| 5 | **포커스 테두리**(결정 605): 테마의 `Button/styles/focus`, 사연 칸의 포커스(이 화면의 덮어쓰기) | `assets/ui/manuscript_theme.tres`, `commission_select.gd` | 0 | 가운데를 칠하지 않는다(`draw_center = false`). 새 그림 파일이 없다 |
| 6 | **기존 테스트 옮기기**: 위 표의 자리 | `tests/flow_tests.gd`, `tests/pattern_tests.gd`, `tests/pattern_cell_tests.gd`, `tests/part_effect_tests.gd`, `tests/style_tests.gd` | 3, 4 | 표 밖의 기대 값을 고친 줄이 없다(고쳐야 하면 멈추고 까닭을 적는다) |
| 7 | **새 테스트와 찍기**: T117~T119. 찍기 장 `select-spare`·`select-many`·`select-story`를 `select` 뒤에(끝에 static 다섯을 처음 값으로), `many,`·`story,` 줄. `run_ui_shots.ps1`의 장 수 28과 두 줄의 판정 — 판정은 `verify.ps1`이 아니라 **`run_ui_shots.ps1`의 `$reasons`**에 넣는다(줄 수가 1이 아니면 실패, `-Resolution`일 때는 건너뛴다 — 기존 `fit`의 꼴) | `tests/practice_screen_tests.gd`(새), `tests/run_tests.gd`(파일 목록 한 줄), `tests/ui_shots.gd`, `tests/run_ui_shots.ps1` | 3, 4, 5 | 시험 데이터는 메모리에서 만든다(`data/`에 파일을 더하지 않는다). `.ps1`은 ASCII만. `fit,select`·`practice,select`의 판정 줄은 그대로다 |
| 8 | **V1**(verifier) → 넘치면 결정 596의 차례로 상수만 고쳐 다시(두 번까지). 메인이 장을 읽는다 | — | 6, 7 | 아래 "확인" |
| 9 | **문서**: `docs/DECISIONS.md` 594~606, CLAUDE.md 4장(사연의 길이 기준 한 줄)·5장(연습의 꼴)·7장(포커스 테두리)·9장, `docs/HANDOFF.md` 1번과 3번(판 F), `docs/BACKLOG.md`, `docs/reports/040b-practice-screen.md`, 커밋 | 문서 | 8 | 10장 형식의 보고 |

### 테스트

세 테스트 모두 **끝과 이른 return의 길에서** static 다섯(`_opening_day` 1, `_part_effects` 거짓, `_style_tier` 0, `_picked_opponent` 0, `_picked_commission` 0)을 처음 값으로 되돌린다.

| ID | 이름 | 보는 것 |
|---|---|---|
| T117 | 목록·고르기·사연·막는 법 | (가) 폴더의 데이터: `OpponentPick*`가 `load_trials()`의 차례, `CommissionPick*`가 `load_tree`의 차례다. `load_tree`가 `load_all`의 것을 앞에 그대로 담는다. (나) **데이터만 더하면 나온다**: 시험 목록에 상대 하나·의뢰 하나를 더해 띄우면 줄이 하나씩 늘고 그 밖의 것은 같다. `spare_source`가 차 있으면 상대 목록 끝에 "주인 없는 검술", 비면 없다, 상대가 0명이면 공격이 있어도 없다. (다) 고르기: `pick_opponent(n)` 뒤 `TrialGrid`가 새 노드 하나이고 `TrialDuel0`에 묶인 상대가 그 상대(그 단)다, 고른 줄만 눌려 있다, **그 상대가 서는 의뢰의 줄만 표시**된다. `pick_commission(n)` 뒤 카드의 의뢰인·조건이 그 의뢰의 것이고 `CommissionStart`가 그 의뢰를 넘긴다. **자리**: `pick_opponent`·단 고르기(`item_selected`)·`pick_commission`을 한 뒤마다 `TrialHead`·`TrialGrid`·`PatternHelp`·`CommissionCard`가 화면에서 위에서 아래로 이 차례다(같은 부모면 부모 안의 번호, 지킴 컨테이너를 썼으면 그 컨테이너들의 번호)이고 저마다 하나뿐이다. (라) 쪽: 여섯째 것을 고르면 둘째 쪽이 열린다, 쪽 넘김을 누르면 쪽 글이 바뀌고 한 쪽뿐이면 둘 다 꺼져 있다. (마) 남는다: 화면을 지우고 새로 띄워도 고른 상대·의뢰·단·빈틈의 날·반격 실험이 같다. 번호가 넘치면 마지막 것으로 잘린다. (바) **실제 데이터는 잘리지 않는다**: `load_tree`의 모든 의뢰에서 `story_lines ≤ STORY_LINES`이고 사연 칸의 글이 `dialogue`와 글자까지 같다. 사연 칸의 `get_theme_color("default_color")`가 Label의 `font_color`와 같고(흰색이 아니다) `get_theme_font_size("normal_font_size")`가 16이다, `bbcode_enabled`·`fit_content`가 꺼져 있다. 같은 줄 셈으로 — 모든 실제 의뢰의 **조건 글**이 조건 칸의 줄 수 이하, 모든 실제 상대·모든 단과 주인 없는 검술의 **막는 법**이 네 줄 이하다(뒤 계획의 조건 둘짜리 의뢰나 새 검술의 줄이 조용히 잘리지 않고 여기서 떨어진다). (사) **막는 법**: `PatternHelp`의 글에 `HELP_CHAIN`·`HELP_SWEEP`·`HELP_DIVE`의 글이 있는가 — 바르톨로 1단(있음·없음·없음), 브루노 1단(없음·있음·없음), 로렌초 1단(없음·없음·있음), **브루노 3단**(겹찌르기가 든 단: 있음·있음·없음), 사슬과 높이를 가진 시험 공격의 주인 없는 검술(있음·없음·없음, 높이의 줄 있음). 높이와 빈틈의 줄은 늘 있다. (아) **주인 없는 검술의 칸**(`spare_source`에 시험 공격 둘): `SpareCaption`이 있고 `SpareDrill0·1`이 `TrialGrid`의 자손이며 글·풍선말이 공격의 이름이다, `TrialDuel*`·`StyleTierPick`이 없다, 묶인 상대가 첫 상대의 `drill`이다. (자) 실제 데이터의 모든 상대·모든 단에서 `signature` 공격이 `DRILL_MAX` 이하다. `ERROR:` 줄이 없다 |
| T118 | 넘침(12명·30개) | 시험 데이터: 상대 12(이름 12자, 고유 검술 이름 12자, 고유 공격 6개 — 이름 10자, 단 9개), 주인 없는 공격 6, 의뢰 30(의뢰인 이름 20자, 사연 600자, 조건 4개. **의뢰인 이름이 같은 의뢰 둘은 상대가 다르고, 또 둘은 상대까지 같다**). 재는 것은 **`ScreenMargin`의 `get_combined_minimum_size()`**다(가장자리 32 포함): 0보다 크고 1280×720 이하. 모든 상대 번호(13)·모든 의뢰 번호(30)·가장 높은 단에서 그 값이 폴더의 데이터로 띄운 화면의 값과 **같다**(데이터가 크기를 바꾸지 못한다). 한 쪽의 줄 ≤ `LIST_ROWS`, 쪽 수 = 올림(13/5)·올림(30/5). 버튼 칸: `PatternDrill*` ≤ `DRILL_MAX`이고 줄 수는 **버튼 수 ÷ `DRILL_COLUMNS`의 올림 ≤ 2**로 셈한다(컨테이너의 최소 크기로 재지 않는다), 버튼의 최소 폭이 모두 같다. 넘친 글의 버튼에 풍선말이 있다. 의뢰인 이름이 같은 줄들의 글이 서로 다르다(상대가 다르면 상대 이름으로, 같으면 " (2)"로). 고유 공격 8개짜리 시험 상대는 버튼 여섯만 선다 |
| T119 | 키보드와 포커스 | 처음 띄우면 `CommissionStart`가 포커스를 가진다(`gui_get_focus_owner()`). 화면의 보이는 버튼·`OptionButton`·사연 칸이 `focus_mode` 전부이고 꺼진 쪽 넘김 버튼만 예외다. 목록의 줄에 포커스를 주고 `pressed`를 내면 그 줄이 같은 노드로 포커스를 가진다. 쪽 넘김 뒤 그 버튼이(끝 쪽이라 꺼지면 반대쪽 버튼이) 가진다. `StyleTierPick`에 포커스를 주고 `item_selected`를 내면 **같은 픽 노드**가 포커스를 가진다. 포커스 없이 `pick_opponent(다른 쪽의 번호)`를 부르면 그 번호의 새 줄이 잡는다 — 포커스의 주인이 `null`인 걸음이 없다. 버튼의 `focus` StyleBox가 빈 것이 아니고 가운데를 칠하지 않는다(결정 605). `back`(Esc): 다른 씬 아래에 붙은 화면은 **가지 않는다**만 본다("간다"는 스모크 `select_esc`의 몫) |

### 확인(verifier)

- **V1** `tests/verify.ps1`: `VERIFY: OK`, `ALL PASS 119/119`, 스모크 OK, `ui` 찍기 28장 — `fit select`가 1248×720 안, `practice,select`의 둘이 1이고 1280×720 안, `many,select-many,<x>,<y>`가 1280×720 안, `story,select-story,…`에서 놓인 줄 수 ≤ 칸의 줄 수 · 내용의 높이 ≤ 칸의 높이 · `STORY_WIDTH` ≤ 실제 폭(결정 603). T75가 "[연습 선택] 글꼴에 없는 글자"를 내면 쪽 넘김의 글을 바꾸고 다시 돌린다(결정 596).
- 메인이 읽을 장(`run_ui_shots.ps1 -Shots <폴더>`): `select.png`(목록 둘과 칸 둘이 읽히는가, 고른 줄과 **포커스 테두리**가 눈에 띄는가, 색의 점, 고른 상대의 의뢰 표시), `select-story.png`(가장 긴 사연이 끝 문단까지 보이는가), `select-spare.png`, `select-many.png`(잘린 글의 꼴, 쪽 넘김, 여섯 버튼의 두 줄, 스크롤이 생긴 사연 칸). 테마를 고쳤으면 `title.png`·`settings.png`에서 포커스 테두리가 어색하지 않은지.
- 넘치면 결정 596의 차례로 상수만 고친다. 두 번 고쳐도 넘치면 멈추고 수와 장을 보고한다.

## 위험

- **R1 어림한 높이가 틀린다**: 테마의 버튼·판의 실제 높이를 재지 않았다(예산은 손 어림. 오른쪽의 여유가 약 28). → 줄이는 차례(결정 596)와 V1의 `fit,`·`many,` 줄. 사연 칸은 줄이지 않는다.
- **R2 글의 높이**: 조건·`PatternHelp`에는 자동 줄바꿈과 함께 **말줄임을 켜** `custom_minimum_size`가 높이를 정하게 한다(`max_lines_visible`만으로는 최소 높이가 글을 따른다). 사연 칸은 `RichTextLabel`(스크롤, `fit_content` 끔)이라 최소 높이가 정한 값이다. 실제 놓인 꼴은 프레임을 넘기는 찍기가 본다.
- **R3 `story_lines`의 셈과 실제 줄바꿈이 어긋난다**: → 셈은 `TextParagraph.get_line_count()`와 `RichTextLabel`의 기본과 같은 깃발로 하고, 셈의 폭은 실제 폭 이하로 둔다(결정 603). 찍기 `select-story`가 놓인 줄 수·내용의 높이·칸의 높이·두 폭을 함께 낸다. 그래도 어긋나면 셈에 여유 한 줄을 둔다(실제 의뢰는 여섯 줄 어림이라 일곱 줄 칸에 한 줄이 남는다).
- **R9 `RichTextLabel`은 이 프로젝트의 첫 사용이다**: 테마에 칸이 없어 글자색이 흰색, 글자 크기 덮어쓰기의 이름이 다르다. → 작업 4의 값 목록과 T117(바)의 색·크기 확인. T75의 `_check_text`는 이 칸을 보지 않으므로 T117이 유일한 확인이다.
- **R4 옮기는 테스트가 많다**: 다섯 파일. 표에 적은 것만 고치고 판에 넘어가는 사본의 기대(T111·T115)는 글자를 지킨다. 표 밖이 걸리면 멈춘다.
- **R5 다시 지을 때의 신호**: 누른 것은 지우지 않는다(결정 600). 단 고르기는 지금과 같은 범위(`TrialGrid`·`PatternHelp`)만 지우고 픽은 그 밖(`TrialHead`)에 있다 — 지금 코드의 꼴 그대로다. 상대의 줄을 누르면 `TrialHead`(픽 포함)가 지워지지만 신호를 내는 것은 목록의 줄이다.
- **R6 포커스 테두리가 다른 화면에 번진다**: 처음 화면·설정·카운터의 버튼에도 보인다(받아들인 것). 테스트가 깨지면 이 화면에만 건다(결정 605). 결투 화면에는 포커스를 가진 버튼이 결과 판과 멈춤 판에만 있다 — 그 장(`result`, `pause-*`)도 찍기에 있으니 함께 본다.
- **R7 연습의 의뢰가 일곱이 된다**: 변형 넷이 연습에 나온다. 되돌리려면 `load_tree`를 `load_all`로(한 줄, 판 F-3).
- **R8 한눈에 견주지 못한다**: 한 번에 한 상대다. 목록의 줄에 고유 검술의 이름과 색을 싣고, 고른 상대의 의뢰에 표시를 준다(판 F-1).

## 나중에 사용자가 볼 판(판 F — HANDOFF 3번으로. 계획을 막지 않는다)

- F-1 꼴: 왼쪽의 목록 둘과 오른쪽의 칸 둘이 한눈에 읽히는가. 상대를 한 번에 하나만 보는 것이 불편한가.
- F-2 의뢰 카드가 한 장씩인 것, 의뢰의 줄 "의뢰인 · 상대"와 고른 상대의 의뢰 표시.
- F-3 변형 의뢰 넷이 연습에 나오는 것.
- F-4 한 쪽 다섯 줄의 쪽 넘김(스크롤이 나은가).
- F-5 "주인 없는 검술"이 상대 목록의 끝에 한 줄로 있는 것, "베기만"이 첫 상대에만 있는 것.
- F-6 포커스 테두리의 꼴과, 그것이 다른 화면에도 보이는 것.
- F-7 사연의 길이 기준(280자·문단 둘) — 새 의뢰의 사연이 이 안에서 써지는가.

## 사용자 결정 필요

없다(메인이 대신 고름 — 사용자 위임 2026-11-27).

## 검토 대응 기록(1회차 → v2)

- **D1**(사연 말줄임이 귀띔을 자른다): 결정 596 — 사연 칸을 카드의 폭 전체·일곱 줄로 넓히고 **말줄임을 없앴다**(넘치면 칸 안의 스크롤, 키보드로 닿는다). 줄이는 차례에서 사연을 뺐다("사연 칸은 줄이지 않는다"). 확인 (가): 결정 603의 `story_lines`, T117(바), 찍기 `select-story`와 `story,` 줄. 길이 기준 280자·문단 둘(결정 596, 판 F-7).
- **D2**(의뢰 줄이 갈리지 않는다): 결정 599 — 줄 = 상대의 색 점 · "의뢰인 · 상대 이름", 같은 글이면 " (2)". 고른 상대의 의뢰 표시(M-1). T118의 시험 데이터(이름이 같은 의뢰 둘씩)와 T117(다).
- **D3**(`PatternHelp`의 규칙): 결정 598 "`PatternHelp`를 고르는 규칙"(고른 단의 목록 전체, `sweep`이 아닌 사슬, 주인 없는 검술은 그 공격들), T117(사)의 다섯 기대.
- **T1**(픽이 자기 신호 안에서 지워진다): 결정 598(`TrialHead`를 따로 두고 픽은 거기에, 상대를 고를 때만 새로)·600(단 고르기는 `TrialGrid`·`PatternHelp`만)·601, 표의 T115 줄("픽은 같은 노드로 살아 있다"), T119, 위험 R5(v1의 "선례" 문장을 고침).
- **T2**(표에 없던 자리): 표에 `flow_tests.gd` 141~150행(새 기대), `style_tests.gd` 720~726행(그대로 선다 — `TrialGrid`가 버튼 두 줄, `_head`를 601의 "지킨다"에), 727~731행, `pattern_cell_tests.gd` 353~358행. 작업 6의 대상에 `flow_tests.gd`.
- **T3**(뿌리의 최소 크기는 늘 0): 결정 594·601의 `ScreenMargin`, T118이 그것을 재고 0보다 큰지도 본다.
- **T4**(`HFlowContainer`): 결정 596 — `GridContainer` 넷씩 두 줄, 버튼 폭 고정, `DRILL_MAX = 6`, 실제 데이터의 상한은 T117(자), T118은 줄 수를 버튼 수로 셈한다.
- 기술 검토가 확인한 사실: "근거"로 옮겼다. 작업 0의 미확인 여섯 → 넷(줄 번호, 테마의 값, `RichTextLabel`의 글꼴, 포커스 StyleBox를 기대하는 테스트). `load_tree`의 `.remap`·`sort`(결정 595), 형 있는 `*_source`와 한 번 읽기·"상대 0명"의 꼴(595·602), 장의 수 28과 static 되돌리기(표·작업 7), T119의 Esc.
- 메인의 결정: M-1(결정 599) · M-2(결정 606, 표의 넷째 칸·T111, T117(아)) · M-3(결정 605, 작업 5, T119, 위험 R6, 판 F-6) · M-4(결정 596·603).
- v1과 달라진 그 밖의 것: 왼쪽 폭 320 → 360·오른쪽 876 → 836, 카드의 조건이 사연의 옆에서 아래로, 결정이 594~604 → 594~606(605 포커스 테두리, 606 확인), 작업이 여덟 → 열(오른쪽을 둘로, 포커스 테두리), 찍기 장 `select-story` 추가, `pattern_tests.gd`의 넷째 칸 화면 확인을 T117로 옮김.

## 검토 대응 기록(2회차 → v3)

2회차: 디자인 APPROVE · 기술 REVISE(신규 T5~T8. T1~T4는 해결). 검토 상한(2회)에 닿았다. **2회차 뒤 메인 판단(사용자 위임 2026-11-27)으로 검토자의 통과 조건을 그대로 반영했고 추가 검토는 없다.** 화면의 꼴과 설계 결정의 내용은 v2 그대로다.

- **T5**(글자 15는 T75를 깬다): 결정 596 — 줄이는 차례 ③을 16 → 14로, "글자 크기는 `STEPS` 안의 값만". 작업 3의 완료 확인.
- **T6**(`RichTextLabel`의 색·크기): 작업 4의 값 목록(`default_color`, `normal_font_size`, `bbcode_enabled`·`fit_content` 끔, `focus_mode`), T117(바)의 색·크기 확인, 위험 R9, 작업 0-③.
- **T7**(다시 지은 노드의 자리): 결정 600 "다시 지은 노드는 제자리에 선다", T117(다)의 "자리", 작업 3·4의 완료 확인.
- **T8**(쪽 넘김의 글자): 결정 596 — T75가 그 줄을 내면 `<`·`>`(또는 "이전"·"다음")로 바꾸는 길을 미리 허락. "확인" V1.
- 비차단 반영: 결정 597(보이는 쪽은 인스턴스 변수) · 600(줄의 `pressed` 길에서는 줄을 다시 짓지 않는다, 표시는 색 덮어쓰기) · 603(`TextParagraph`의 줄 수, 깃발 명시, 셈의 폭 ≤ 실제 폭, `story,` 줄의 칸 여섯, 조건·막는 법도 같은 셈) · 596(사연 칸의 높이는 글꼴에서, 스크롤 중의 위·아래) · 605(테마를 고치는 길로 확정, 제비꼬리 판과 테두리, 고른 줄과 포커스의 갈림) · 작업 7(판정은 `run_ui_shots.ps1`의 `$reasons`) · T117(바)(조건과 막는 법의 "실제 데이터는 잘리지 않는다").
- planner가 덧붙인 것 하나: 줄이는 차례 ②(조건 세 줄 → 두 줄)에 "T117(바)의 조건 줄 셈이 실제 데이터에서 통과할 때만"을 걸었다(새 확인과 줄이는 차례가 서로 어긋나지 않게).
