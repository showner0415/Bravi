# 계획 016: 저장 — 가게는 폐점할 때 적히고, 이어서 하면 그날 아침부터다

- 버전: v1 (검토 전. "실행 전에 물을 것"의 두 물음에 답을 받으면 같은 파일을 고친다)
- 개발 단계: CLAUDE.md 9장 2단계 (하루 루프). 2단계의 마지막 작업이다(결정 88의 순서: … → 저장 → 2단계 완료 판정). 단계를 넘지 않는다
- 근거:
  - 사용자 지시(2026-11-20): "…계속 진행해줘." 직전 보고(`docs/reports/015-haggle-odds-and-refusal-cost.md` 5번)의 다음 작업이 "016 저장 → 2단계 완료 판정"이고 CLAUDE.md 9장의 현재 위치도 같다. 저장의 내용에 대한 사용자 지시는 아직 없다. 그래서 본문은 권하는 안으로 썼고, 플레이 규칙이 갈리는 곳 둘을 "실행 전에 물을 것"에 올렸다.
  - 결정 54(계획 005): "날을 넘는 것(날 번호, 소지금, 가진 업그레이드)은 `DayState`가 함께 가진다. 갈라내는 것은 저장에서 한다." 지금 `scripts/economy/day_state.gd`에 "날을 넘는 것"(`day_number`, `money`, `owned`, `reputation`)과 "하루의 것"이 주석으로 갈라져 있다.
  - 계획 015가 넘긴 것(`docs/DECISIONS.md` 계획 015 절 끝): (1) 흥정의 결과를 저장에 넣는가, (2) 저장하고 불러와 주사위를 다시 뽑는 길을 막는가. 이 계획의 답은 규칙 "다"에 있다.
  - 지금의 코드(planner가 읽음):
    - 저장이 없다. `GameSession.start_day_play()`는 늘 1일차 새 하루를 만든다. `user://`를 쓰는 곳은 `tests/flow_tests.gd`의 임시 폴더뿐이다.
    - 처음 화면(`scripts/title.gd`)의 버튼은 둘이다(`Proceed` "가게를 연다", `Practice`). T33이 "버튼이 2개"를 통과 조건으로 본다(`tests/day_tests.gd` 513줄).
    - 카운터의 "오늘은 그만"과 폐점의 "처음 화면으로"(둘 다 노드 이름 `Quit`)는 `end_day_play()` 뒤 처음 화면으로 간다. 스모크가 3일차 카운터에서 `Quit`을 누르고, 그 뒤 처음 화면의 Enter가 "새 1일차 카운터"인 것을 본다(`tests/day_smoke.gd`의 `quit`, `title_enter`, `counter_final`).
    - 테스트 러너(`--script`)에는 오토로드가 없다(`/root/GameSession`이 null). 스모크는 씬으로 돌아 오토로드가 있다.
    - 흥정의 주사위는 `DayState._rng`가 누를 때 뽑는다(`haggle(roll := -1)`). 테스트는 `roll`로 결과를 고정한다.
    - 테스트 래퍼는 출력의 `ERROR:` 줄이 하나라도 있으면 실패로 본다(`tests/run_tests.ps1`의 `$errorPattern`).
  - 직전 상태: 계획 011~014는 `playtester`가 실행해 확인했다(`ALL PASS 55/55`, 스모크 OK). **계획 015(흥정의 확률, 새 테스트 T55)는 아직 아무도 실행하지 않았다.** 이 계획은 그 위에 얹힌다("위험" 1번).
  - 사용자 규칙: 메인은 테스트와 게임을 실행하지 않는다. 실행 확인은 사용자가 요청하면 `playtester`가 한다. 완료 기준에 실행 확인을 넣지 않는다. 보류 중인 결정(계획 012~015 보고서 4번)은 건드리지 않는다.
- 번호: 016. 결정 번호는 146부터다. `docs/plans/013-playtester.md`는 사용자의 파일이고 이 계획과 상관없다.

## 목표와 범위

**확인할 결과** (전부 코드 읽기·Grep·값 대조·손 계산. 실행 확인은 작업 8의 playtester 목록으로 넘긴다)

1. 게임을 껐다 켜도 가게가 이어진다. 이어지는 것은 **날을 넘는 것**이다: 날 번호, 소지금, 가진 업그레이드, 평판(과 흥정 주사위의 씨앗).
2. 저장 파일은 "**다음에 열 날의 아침**" 하나다. 폐점 화면이 뜨면 그날은 적힌 것이다. 하루 중에 그만두면 그날 한 일은 남지 않고, 이어서 하면 그날 아침부터다. 이 규칙이 누르기 전에 화면에서 읽힌다(카운터의 한 줄, 폐점의 한 줄, 처음 화면의 버튼 글).
3. 처음 화면: 저장이 있으면 "이어서 한다 — N일차 아침부터"와 "새로 시작한다"(두 번 눌러야 지워진다)가 보인다. **저장이 없으면 화면과 동작이 지금과 글자 그대로 같다**(버튼 둘, "가게를 연다" = 새 1일차).
4. 하루를 다시 해도 흥정의 주사위는 다시 뽑히지 않는다(같은 가게의 같은 날 같은 손님은 같은 주사위다).
5. 읽을 수 없는 저장(없음, 깨짐, 버전이 다름)을 만나도 게임이 죽지 않고 오류 줄을 찍지 않는다. 저장된 값은 믿지 않는다(평판은 범위로 자르고, 목록에 없는 업그레이드는 버린다).
6. 테스트·스모크·playtester가 사용자의 실제 저장 파일을 건드리지 않는다(규칙 "바").
7. 기존 테스트 56개(T55 포함)의 통과 조건과 스모크가 지나는 씬의 순서가 바뀌지 않는다. 새 테스트 셋(T56~T58)이 저장의 내용·파일·화면을 본다(실행은 playtester).

**범위 밖**: 하루 중의 저장(손님 순번, 결과 목록, 돌려보낸 손님, 흥정의 결과), 여러 슬롯, 설정 화면, 자동 백업, 옛 버전 저장의 옮기기(버전이 다르면 읽지 않는다), 날을 넘는 것을 다른 클래스로 갈라내기, 연습(의뢰 선택) 경로, 스모크에 "이어서 한다" 구간을 더하는 것, 칼 수리비와 부상에 따른 의뢰 수 감소(CLAUDE.md 5장의 "아직 없는 것").

## 규칙

### 가. 무엇을 언제 적는가

- **적는 것**(파일 하나, 슬롯 하나): 버전, **다음에 열 날**의 번호, 소지금, 가진 업그레이드의 id 목록, 평판, 흥정 주사위의 씨앗.

  ```
  {"version":1,"day":3,"money":142,"owned":["parlor_chair"],"reputation":27,"dice_seed":2891336453}
  ```

- **적는 때 셋**:
  1. 새로 시작할 때 — 1일차의 아침(시작 소지금, 가진 것 없음, 시작 평판).
  2. 폐점에 들어설 때 — 내일의 아침. 그날의 수입과 지출(임대료, 치료비)이 끝난 소지금과 그날 끝의 평판이다.
  3. 폐점에서 업그레이드를 살 때마다 — 내일의 아침을 다시 적는다(소지금과 가진 것이 바뀌었다).
- "다음 날을 연다"와 폐점의 "처음 화면으로"는 따로 적지 않는다(이미 적혀 있다). 폐점 화면이 뜬 뒤에는 어떻게 나가든(다음 날, 처음 화면, 창 닫기) 같은 아침에서 이어진다.
- **하루의 것은 적지 않는다**: 손님 순번, 결과 목록, 돌려보낸 손님, 흥정의 결과, 단계. 이어서 하면 `DayState._begin_day()`가 그날을 처음부터 만든다(그날의 손님, 그날 시작의 평판으로 정한 손님 수와 기본 보수).
- 불러온 아침은 끄지 않고 "다음 날을 연다"로 넘어간 아침과 같다: 같은 날 번호, 소지금, 가진 것, 평판, 손님, 주사위.

### 나. 하루 중에 그만두면

- 카운터의 "오늘은 그만"은 지금처럼 하루 플레이를 버리고 처음 화면으로 간다. 달라지는 것은 **버려지는 것이 그날 하루뿐**이라는 것이다(지금은 가게 전부가 사라진다). 처음 화면의 "이어서 한다"가 그날 아침으로 데려간다.
- 창을 닫아도(Alt+F4) 같다. 결투 중이든 정산 중이든 그날 아침으로 돌아간다.
- 이 규칙은 누르기 전에 읽힌다: 카운터의 "오늘은 그만" 아래에 한 줄(`오늘 한 일은 남지 않는다 — 이어서 하면 오늘 아침부터다`), 처음 화면의 버튼 글("… N일차 **아침부터**").
- **알고 두는 것 — 하루를 다시 할 수 있다.** 그날이 마음에 들지 않으면 폐점 화면이 뜨기 전에 그만두고 이어서 하면 된다. 첫 결투를 망쳤을 때는 값이 거의 없는 "다시 하기"가 된다(CLAUDE.md 5장의 "하루 중의 결투는 한 번뿐"이 하루 단위로 느슨해진다). 「좋은 피자, 위대한 피자」의 하루 단위 저장과 같은 성질이다. 이것을 받아들일지가 "실행 전에 물을 것" 1번이다. 흥정의 주사위만은 다시 해도 같다(규칙 "다").

### 다. 흥정의 주사위 — 계획 015가 넘긴 두 가지

- **(1) 흥정의 결과는 저장하지 않는다.** 저장이 하루 안에 없으므로, 받아 줌·거절의 상태(`_haggle`, `_haggle_index`)가 파일에 들 자리가 없다.
- **(2) 다시 뽑는 길은 막는다.** 하루 단위 저장에도 길이 하나 있다: 아침에 첫 손님에게 흥정 → 거절 → "오늘은 그만" → "이어서 한다" → 다시 흥정. 값이 클릭 몇 번이다. 그래서 주사위를 누를 때 뽑지 않고 **정해진 값에서 읽는다**.
  - 가게마다 씨앗 하나(`dice_seed`)를 새로 시작할 때 뽑아 저장에 넣는다.
  - 손님의 주사위(0~99) = 씨앗 · 날 번호 · 손님의 순번으로 정해지는 값. 같은 가게의 같은 날 같은 순번의 손님은 늘 같은 주사위다.
  - 판정은 그대로다(`roll < haggle_chance()`). 확률은 누르는 순간의 별에서 나오므로, 다시 한 하루에서 별이 달라졌으면 같은 주사위가 다른 결과를 낼 수 있다. 그것은 다시 뽑기가 아니라 다르게 플레이한 것이다.
  - 화면은 바뀌지 않는다. 확률도 주사위도 보이지 않는다(결정 141 그대로).
- 남는 길(알고 둔다): 하루를 한 번 해 보면 그날 누가 받아 주는지 알게 되고, 다시 한 하루에서 그 앎을 쓸 수 있다. 하루를 다시 할 수 있는 한 막을 수 없다("위험" 3번).
- 테스트의 `haggle(roll)`은 그대로다(인자로 준 주사위가 먼저다).

### 라. 처음 화면

| 저장 | 보이는 것 | 포커스 |
|---|---|---|
| 없다 | 지금과 같다: `가게를 연다`(`Proceed`), `연습 — 의뢰를 골라 결투`(`Practice`), 힌트 한 줄. 자리도 그대로다 | `Proceed` |
| 있고 읽힌다 | `이어서 한다 — 3일차 아침부터`(`Continue`, 큰 버튼) / 정보 한 줄 `소지금 142 · 가진 업그레이드 1개 · 평판 별 4/5`(`SaveInfo`) / `새로 시작한다`(`NewGame`) / `연습 — …`(`Practice`) / 힌트 | `Continue` |
| 있는데 읽을 수 없다 | 저장이 없을 때와 같은 버튼 둘 + 한 줄 `저장 파일을 읽지 못했다 — 가게를 열면 새로 시작하고, 그 파일은 덮어쓴다`(`SaveUnreadable`) | `Proceed` |

- **이어서 한다**: 저장된 아침으로 하루 플레이를 만들고 그 단계의 씬(보통 카운터)으로 간다.
- **새로 시작한다**는 두 번 눌러야 한다. 지금 가게를 지우는, 되돌릴 수 없는 선택이기 때문이다.
  - 첫 번째: 버튼의 글이 `한 번 더 누르면 새로 시작한다`로 바뀌고 붉은 한 줄 `지금 가게(3일차)는 지워진다. 되돌릴 수 없다`(`NewGameWarning`)가 뜬다. 파일은 그대로다.
  - 두 번째: 1일차의 새 하루를 만들고 그 아침을 적는다(옛 저장을 덮어쓴다).
  - 그 사이에 "이어서 한다"나 "연습"을 누르면 그쪽으로 간다(파일은 그대로다). 처음 화면에 다시 오면 처음 상태다.
- 저장이 없을 때의 `가게를 연다`는 확인 없이 바로 시작한다(지울 것이 없다). 읽을 수 없는 저장도 같다(한 줄로 알린 뒤다).
- 정보 한 줄의 값은 불러와 고친 값이다(평판을 범위로 자른 뒤의 별, 목록에 있는 업그레이드의 수). 평판이 없는 규칙이면 평판 부분을 뺀다.

### 마. 파일과 읽을 수 없는 저장

- 자리: `user://bravi_save.json`(이 PC에서는 `%APPDATA%\Godot\app_userdata\Bravi\`). 형식은 JSON 한 줄이다. 사람이 열어 볼 수 있어 playtester가 내용을 눈으로 확인한다.
- **읽을 수 없는 저장**(처음 화면에서 "이어서 한다"가 나오지 않는다):
  - 파일이 없다 / 열리지 않는다 / JSON이 아니다 / 맨 위가 `{…}`가 아니다
  - `version`이 숫자가 아니거나 1이 아니다(다른 버전은 옮기지 않는다)
  - `day`나 `money`가 숫자가 아니다
- **읽히지만 고쳐 쓰는 값**(저장된 값을 믿지 않는다):

  | 값 | 고치기 |
  |---|---|
  | `day` | 1보다 작으면 1 |
  | `money` | 그대로(음수일 수 있다. 지금도 소지금은 0 아래로 내려간다) |
  | `owned` | 목록(`UpgradeCatalog`)에 있는 id만 남긴다. 목록의 순서로, 겹치지 않게. 배열이 아니거나 목록이 없으면 빈 것이다 |
  | `reputation` | `ReputationRules.clamp_value()`로 자른다. 숫자가 아니면 시작 평판. 평판이 없는 규칙이면 0 |
  | `dice_seed` | 0~4294967295로 자른다. 숫자가 아니면 새로 뽑은 값 |

- JSON은 숫자를 실수로 돌려줄 수 있다(`2.0`). 숫자인지는 정수와 실수 둘 다로 보고, 쓸 때 `int()`로 바꾼다.
- **오류 줄을 찍지 않는다.** 깨진 파일은 예상한 입력이다. `JSON.parse_string()`과 `ConfigFile.load()`는 파싱에 실패하면 엔진이 `ERROR:` 줄을 찍는다(테스트 래퍼가 실패로 본다). 그래서 `JSON.new()`의 `parse()`를 쓰고 돌려준 값만 본다. 쓰기에 실패했을 때만 `push_warning`을 한 번 남긴다(게임은 계속된다).
- 쓰기는 파일을 열어 한 번에 적는다(임시 파일과 바꿔치기는 하지 않는다. "위험" 6번).

### 바. 실제 저장을 건드리지 않는 장치

| 누가 | 장치 |
|---|---|
| 테스트 러너(`--script`) | 오토로드가 없다. 테스트가 `Session.new()`로 만든 `GameSession`은 트리에 오르지 않아 `save_path`가 빈 채다(= 저장 꺼짐: 읽지도 쓰지도 않는다). 저장을 보는 테스트는 `user://bravi_test_save.json`을 직접 넣고, 끝에 지운다 |
| 스모크 | 오토로드가 있다. 운전자가 맨 처음에 `GameSession.save_path`를 비운다. 그래서 스모크가 지나는 씬의 순서와 기대값이 지금과 같다(처음 화면은 늘 버튼 둘, "가게를 연다" = 새 1일차). 끝에서 실제 저장 파일이 처음과 같은지 견준다 |
| playtester(게임 창) | 환경 변수 `BRAVI_SAVE_PATH`가 있으면 그 경로를 쓴다. playtester는 `user://bravi_playtest_save.json`을 걸고 실행한다 |
| 게임 | `GameSession._ready()`(오토로드로 트리에 오를 때)가 경로를 정한다: 환경 변수, 없으면 `user://bravi_save.json` |

### 사. 화면의 글 (새 노드와 글 전부)

| 화면 | 노드 | 글 | 있는 때 |
|---|---|---|---|
| 처음 화면 | `Continue`(버튼) | `이어서 한다 — %d일차 아침부터` | 읽히는 저장이 있다 |
| 처음 화면 | `SaveInfo` | `소지금 %d · 가진 업그레이드 %d개` + (평판이 있으면) ` · 평판 별 %d/%d` | 〃 |
| 처음 화면 | `NewGame`(버튼) | `새로 시작한다` → 한 번 누르면 `한 번 더 누르면 새로 시작한다` | 〃 |
| 처음 화면 | `NewGameWarning` | `지금 가게(%d일차)는 지워진다. 되돌릴 수 없다` (붉은 글) | `NewGame`을 한 번 누른 뒤 |
| 처음 화면 | `SaveUnreadable` | `저장 파일을 읽지 못했다 — 가게를 열면 새로 시작하고, 그 파일은 덮어쓴다` | 파일이 있는데 읽을 수 없다 |
| 카운터 | `QuitNote` | `오늘 한 일은 남지 않는다 — 이어서 하면 오늘 아침부터다` | 늘("오늘은 그만" 아래) |
| 폐점 | `SavedNote` | `저장했다 — 끄고 다시 켜도 %d일차 아침부터 이어진다` (%d는 내일) | 이 실행에서 내일의 아침을 적는 데 성공했다 |

- 기존 노드의 이름과 글, 자리는 바꾸지 않는다(저장이 없을 때의 처음 화면, 카운터의 `Quit`, 폐점의 `Quit`·`Proceed`).
- 테스트(오토로드 없음)와 스모크(저장 꺼짐)에서는 `SavedNote`가 만들어지지 않는다.

## 작업 목록

**공통 규칙** (계획 012~015와 같다. 이름은 지금 코드에 맞췄다)

- 메인 에이전트는 Godot을 어떤 방식으로도 실행하지 않는다(`tests/run_tests.ps1`, 스모크, 헤드리스, `play.ps1` 전부). 확인은 파일 읽기, Grep, `git diff`, 손 계산뿐이다. 실행 확인은 사용자가 요청할 때 playtester가 한다(작업 8의 목록). 작업을 파일 하나씩 끊고, 작업마다 고친 함수를 다시 읽는다.
- 이미 있는 함수의 시그니처는 바꾸지 않는다(이번에는 인자를 더하는 곳도 없다). 새 멤버의 기본값은 "지금과 같은 동작"이다: `GameSession.save_path`가 빈 글이면 저장이 꺼져 있고, `title.gd`의 `saved`가 null이면 지금의 처음 화면이다.
- **새 `class_name`은 만들지 않는다.** 저장 파일의 스크립트는 `preload`로 쓴다(`day_ui.gd`를 `Ui`로 쓰는 것과 같다). 새 `class_name`을 만들면 클래스 캐시(`.godot/`)를 갱신해야 하고(`tests/run_tests.gd` 머리 주석), 갱신 전에는 그 이름을 쓰는 스크립트가 로드되지 않는다. 그 위험을 지지 않는다. `.uid` 파일은 만들지 않는다(Godot이 만든다).
- 대조나 손 계산이 어긋나면 값을 맞추지 말고 멈춰서 보고한다.
- **스크립트를 하나 고칠 때마다 확인할 것**(새 스크립트와 새 테스트 파일도 같다):
  1. 들여쓰기: 고친 `.gd`에서 `^ +\S`를 Grep해 0건이다(탭만 쓴다).
  2. 같은 함수 안의 이름 겹침과 멤버 가리기. 새 지역 변수와 멤버는 아래 이름을 피한다.
     - `day_state.gd`의 멤버 전체: `rules`, `data`, `catalog`, `schedule`, `_fallback_data`, `reputation_rules`, `day_number`, `money`, `owned`, `reputation`, `phase`, `index`, `results`, `declined`, `last_declined`, `_summary`, `_guest_count`, `day_start_reputation`, `_haggle`, `_haggle_index`, `_rng`. 새 멤버는 `dice_seed`, 새 상수는 `SAVE_VERSION`·`DICE_SEED_MAX`다. 새 함수의 지역 변수는 `day_to_open`, `ids`, `owned_id`, `version`, `saved_reputation`, `saved_seed`, `kept`, `wanted`, `dice`다
     - `game_session.gd`의 멤버: `commission`, `day`. 새 멤버는 `save_path`, `saved_day`, 새 상수는 `SaveStore`·`SAVE_PATH`·`SAVE_ENV`다. 새 함수의 지역 변수는 `custom`, `saved`, `restored`, `loaded`다
     - `title.gd`의 `_ready`: `title`, `subtitle`, `open`, `practice`, `hint`, `session`. 새 멤버는 `saved`, `save_unreadable`, `_new_game`, `_armed`다
     - `counter.gd`의 `_build`: `header`, `reputation`, `base`, `pay_percent`, `first_counter`, `guest_text`, `guests`, `client`, `tween`, `bubble`, `dialogue`, `accept`, `hint`, `proceed`, `decline`, `note`, `quit`. 새 지역 변수는 `quit_note` 하나다
     - `closing.gd`의 `_build`: `header`, `book`, `result`, `line`, `declined`, `names`, `missed`, `missed_line`, `gap`, `profit_text`, `profit`, `quit`. 새 지역 변수는 `session`, `saved_note`다. 새 함수 `_save_now`의 지역 변수는 `session`이다
  3. Variant 추론: 고친 파일에서 `:= .*\.get\(`, `:= .*\.call\(`, `:= .*\[`를 Grep한다.
     - `.get(`과 `.call(`에 걸린 줄은 전부 `int(...)`·`bool(...)`·`String(...)`으로 감싸거나 타입을 적는다(새것: `int(session.get("saved_day"))`, `bool(session.call("save_exists"))`, `session.call("load_saved_day") as DayState`).
     - 저장에서 읽은 값을 지역 변수로 받을 때는 `var version: Variant = saved.get("version")`처럼 `Variant`를 적는다(`:=`로 받지 않는다).
     - 테스트 파일에서 `_d.` 도우미의 결과와 `Session.new()`를 받는 줄은 타입을 적는다(`var rules: EconomyRules = _d._rules(…)`, `var first: Node = Session.new()`).
  4. 서식 문자열: `%` 연산자를 거치는 글의 자리 수와 인자 수를 줄마다 센다. 새 글(규칙 "사")에는 퍼센트 글자가 없다. 자리가 있는 글은 다섯이다: `이어서 한다 — %d일차 아침부터`(1), `소지금 %d · 가진 업그레이드 %d개`(2), ` · 평판 별 %d/%d`(2), `지금 가게(%d일차)는 지워진다. 되돌릴 수 없다`(1), `저장했다 — 끄고 다시 켜도 %d일차 아침부터 이어진다`(1). 자리가 둘인 글의 인자는 배열로 준다.
  5. `@warning_ignore("integer_division")`는 나눗셈이 든 문장 바로 윗줄에 둔다(이번 계획에는 새 나눗셈이 없다. 주사위의 씨앗은 곱셈과 덧셈뿐이다).
- 새 테스트 파일은 작업 7의 "선언 대조"를 따로 한다(로드되지 않으면 러너 전체가 멈춘다).

### 작업 1. 저장 파일의 읽기와 쓰기

- 대상: `scripts/save_store.gd`(새 파일. `extends RefCounted`, `class_name` 없음, 함수는 전부 `static`)
- 무엇: 파일만 안다. 무엇이 읽을 수 있는 저장인지는 모른다(그것은 `DayState`가 안다).
  - `static func read(path: String) -> Dictionary` — 파일이 없거나, 열리지 않거나, JSON이 아니거나, 맨 위가 Dictionary가 아니면 빈 Dictionary. 오류를 찍지 않는다.

    ```
    static func read(path: String) -> Dictionary:
    	if path == "" or not FileAccess.file_exists(path):
    		return {}
    	var file := FileAccess.open(path, FileAccess.READ)
    	if file == null:
    		return {}
    	var text := file.get_as_text()
    	file.close()
    	var json := JSON.new()
    	if json.parse(text) != OK:
    		return {}
    	if json.data is Dictionary:
    		var found: Dictionary = json.data
    		return found
    	return {}
    ```

  - `static func write(path: String, content: Dictionary) -> bool` — `path`가 비었거나 파일이 열리지 않으면 false. `FileAccess.open(path, FileAccess.WRITE)`, `store_string(JSON.stringify(content))`, `close()`, true.
  - `static func exists(path: String) -> bool` — `path != "" and FileAccess.file_exists(path)`.
  - `static func erase(path: String) -> void` — 있으면 `DirAccess.remove_absolute(path)`(테스트의 뒷정리가 쓴다. `tests/flow_tests.gd`가 `user://` 경로에 같은 함수를 쓴다).
- 완료 확인:
  - 파일에 `JSON.parse_string`, `ConfigFile`, `push_error`가 0건이다(Grep). `class_name`이 0건이다.
  - `read`의 돌아가는 길 다섯(빈 경로·없는 파일, 열기 실패, 파싱 실패, Dictionary 아님, 성공)을 읽어서 따라간다. 삼항식으로 `Variant`를 돌려주는 줄이 없다.
  - 공통 규칙 다섯 가지.

### 작업 2. 하루의 상태 — 아침을 내주고, 아침으로 되돌린다

- 대상: `scripts/economy/day_state.gd`. Node와 파일을 모르는 채로 둔다(`FileAccess`·`JSON`이 0건).
- 무엇:
  - 상수 둘(enum 아래): `const SAVE_VERSION := 1`, `const DICE_SEED_MAX := 4294967295`.
  - "날을 넘는 것" 묶음의 주석을 `# --- 날을 넘는 것 (저장에 드는 것. saved_state / restore) ---`로 고치고, 그 묶음 끝에 멤버 하나를 더한다.
    - `var dice_seed := 0` — 주석: "흥정 주사위의 씨앗. 새로 시작할 때 한 번 뽑고 저장에 든다. 같은 가게의 같은 날 같은 순번의 손님은 같은 주사위다(haggle_roll)."
  - `_init`: `_rng.randomize()` 바로 아래에 `dice_seed = _rng.randi()` 한 줄(`_begin_day()`보다 앞이다).
  - `_rng`의 주석을 "흥정 주사위의 씨앗을 뽑는다(새로 시작할 때 한 번)"로 고친다.
  - 읽기 함수 하나(`haggle_chance()` 아래).

    ```
    ## 지금 손님의 흥정 주사위(0~99). 씨앗·날 번호·손님의 순번이 같으면 늘 같은 값이다
    ## (하루를 다시 해도 다시 뽑히지 않는다). 상태를 바꾸지 않는다.
    func haggle_roll() -> int:
    	var dice := RandomNumberGenerator.new()
    	dice.seed = dice_seed * 1000003 + day_number * 1009 + index
    	return dice.randi_range(0, 99)
    ```

  - `haggle(roll := -1)`: `roll = _rng.randi_range(0, 99)` 한 줄을 `roll = haggle_roll()`로 바꾼다. 주석의 "음수면 뽑는다"를 "음수면 지금 손님의 정해진 주사위(haggle_roll)를 쓴다"로 고친다. 다른 줄은 그대로다.
  - 저장의 함수 넷("전환" 묶음 앞에 `# ---- 저장` 묶음으로).

    ```
    static func _is_number(value: Variant) -> bool:
    	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


    ## 읽을 수 있는 저장인가: 버전이 같고 날과 소지금이 숫자다.
    static func is_readable_save(saved: Dictionary) -> bool:
    	var version: Variant = saved.get("version")
    	if not _is_number(version) or int(version) != SAVE_VERSION:
    		return false
    	return _is_number(saved.get("day")) and _is_number(saved.get("money"))


    ## 저장할 것: 다음에 열 날의 아침. 폐점이면 내일이고, 아직 아무도 맡거나 돌려보내지 않은 아침이면 오늘이다.
    ## 하루 중(그 뒤부터 폐점 전까지)에는 빈 Dictionary다(적을 아침이 없다). 상태를 바꾸지 않는다.
    func saved_state() -> Dictionary:
    	var day_to_open := 0
    	if phase == Phase.CLOSING:
    		day_to_open = day_number + 1
    	elif phase == Phase.COUNTER and index == 0 and results.is_empty() and declined.is_empty():
    		day_to_open = day_number
    	if day_to_open <= 0:
    		return {}
    	var ids: Array[String] = []
    	for owned_id in owned:
    		ids.append(String(owned_id))
    	return {"version": SAVE_VERSION, "day": day_to_open, "money": money, "owned": ids,
    		"reputation": reputation, "dice_seed": dice_seed}


    ## 저장된 아침으로 되돌리고 그날을 시작한다. 읽을 수 없는 저장이면 아무것도 바꾸지 않고 false다.
    ## 값은 믿지 않는다: 날은 1 이상, 가진 것은 목록에 있는 것만, 평판은 범위로 자른다.
    func restore(saved: Dictionary) -> bool:
    	if not is_readable_save(saved):
    		return false
    	day_number = maxi(int(saved["day"]), 1)
    	money = int(saved["money"])
    	owned = _known_ids(saved.get("owned"))
    	var saved_reputation: Variant = saved.get("reputation")
    	if has_reputation() and _is_number(saved_reputation):
    		reputation = reputation_rules.clamp_value(int(saved_reputation))
    	var saved_seed: Variant = saved.get("dice_seed")
    	if _is_number(saved_seed):
    		dice_seed = clampi(int(saved_seed), 0, DICE_SEED_MAX)
    	_begin_day()
    	return true


    ## 저장된 id 가운데 목록에 있는 것. 목록의 순서이고 겹치지 않는다.
    func _known_ids(value: Variant) -> Array[StringName]:
    	var kept: Array[StringName] = []
    	if catalog == null or not (value is Array):
    		return kept
    	var wanted: Array = value
    	for upgrade in catalog.upgrades:
    		if upgrade != null and wanted.has(String(upgrade.id)) and not kept.has(upgrade.id):
    			kept.append(upgrade.id)
    	return kept
    ```

  - `restore()`는 갓 만든 `DayState`에 부른다(`_init`이 1일차를 한 번 시작한 뒤다. 그 하루의 것은 `_begin_day()`가 전부 다시 만든다). 평판이 없는 규칙이면 `reputation`은 `_init`이 넣은 0 그대로다.
  - `payout`·`settle`·`settle_rules`·`can_haggle`·`haggle_chance`·`accept`·`decline`·`finish_duel`·`proceed`·`buy`·`next_day`·`_begin_day`·`_enter_closing`은 고치지 않는다.
- 완료 확인: 다시 읽고 손으로 따라간다. 숫자는 T31·T35가 이미 보는 장부다(`_rules(70, 60, 20, 250)`, `_three_fixed()`, `_test_upgrades()`의 40·90·120).
  - (1) 새 하루(시작 소지금 250): `saved_state()`는 `day` 1, `money` 250, `owned` 빈 배열, `version` 1. `accept()` 뒤에는 빈 Dictionary다. 정산 단계와, 첫 손님을 돌려보낸 뒤의 카운터(`index` 1)도 빈 Dictionary다.
  - (2) 고정 하루를 폐점까지(소지금 322): `day` 2, `money` 322. 40짜리를 사면 `money` 282, `owned`는 `["t_medicine"]`. 셋을 다 사면 `money` 72, `owned` 셋.
  - (3) (2)의 마지막 것을 새 `DayState`(같은 규칙·하루·목록)에 `restore()`: true, `day_number` 2, `money` 72, `owned` 셋, 단계 카운터, `index` 0, `results` 빔. `next_day()`를 부른 원래 하루와 같은 값이다. 그 하루를 고정 하루로 끝내면 폐점 소지금 169다(T35의 2일차와 같다: 가진 것의 효과가 살아 있다).
  - (4) 고치는 값: `owned`가 `["nope", "t_chair", "t_chair"]`이면 `[&"t_chair"]` 하나. `owned`가 글이면 빈 배열. `day`가 0이나 −3이면 1. `day`가 `2.0`(실수)이면 2. 평판 규칙(0~20)에서 `reputation` 999는 20, −5는 0, 글이면 시작 평판 그대로.
  - (5) 읽을 수 없는 것: `version` 2, `version` 없음, `day`가 글, `money` 없음, 빈 Dictionary. 전부 false이고 `day_number`·`money`·`owned`·`reputation`·`dice_seed`·단계가 그대로다(`is_readable_save`가 맨 앞에서 돌려보낸다).
  - (6) `haggle_roll()`: 멤버를 고치는 줄이 없다. 씨앗에 드는 것이 `dice_seed`·`day_number`·`index` 셋이다. 가장 큰 씨앗은 4294967295 × 1000003 + … ≈ 4.3 × 10^15로 64비트 정수 안이다.
  - (7) `haggle()`에서 바뀐 줄이 하나다(`git diff`). T55가 부르는 `haggle(69)`·`haggle(70)`·`haggle(99)`·`haggle(0)`은 인자가 먼저라 그대로이고, 인자 없는 `haggle()`(T55의 "아", 확률 100)은 어떤 주사위에서도 받아 준다.
  - (8) `scripts/economy/day_state.gd`에 `FileAccess`, `JSON`, `get_node`, `user://`가 0건이다(Grep). `_rng.randi_range`가 0건이다.
  - 공통 규칙 다섯 가지.

### 작업 3. GameSession — 경로와 적는 때

- 대상: `scripts/game_session.gd`
- 무엇:
  - 상수 셋: `const SaveStore := preload("res://scripts/save_store.gd")`, `const SAVE_PATH := "user://bravi_save.json"`, `const SAVE_ENV := "BRAVI_SAVE_PATH"`.
  - 멤버 둘:
    - `var save_path := ""` — 주석: "저장 파일의 경로. 비어 있으면 저장이 꺼져 있다(읽지도 쓰지도 않는다). 오토로드로 트리에 오를 때 정해진다(_ready). 테스트가 new()로 만든 것은 빈 채다."
    - `var saved_day := 0` — 주석: "이 실행에서 마지막으로 적은 저장의 '다음에 열 날'. 적은 적이 없거나 마지막 쓰기가 실패했으면 0. 폐점 화면이 읽는다."
  - `_ready()`(새 함수): `var custom := OS.get_environment(SAVE_ENV)`, `save_path = custom if custom != "" else SAVE_PATH`.
  - `_new_day() -> DayState`(새 내부 함수): 지금 `start_day_play()` 안의 `DayState.new(load(…) …)` 문장을 글자 그대로 옮겨 돌려준다.
  - `start_day_play()`: `commission = null`, `day = _new_day()`, `save_game()`. 주석에 "그 아침을 적는다(옛 저장을 덮어쓴다)"를 더한다.
  - `load_saved_day() -> DayState`(새): 저장을 읽어 되돌린 하루. `save_path`가 비었거나 파일이 읽히지 않거나 읽을 수 없는 저장이면 null. `day`를 건드리지 않는다(처음 화면이 정보 한 줄에 쓴다).
    - `var saved: Dictionary = SaveStore.read(save_path)` → 비었으면 null → `var restored: DayState = _new_day()` → `return restored if restored.restore(saved) else null`
  - `continue_day_play() -> bool`(새): `var loaded: DayState = load_saved_day()`. null이면 false(아무것도 바꾸지 않는다). 아니면 `commission = null`, `day = loaded`, true.
  - `save_exists() -> bool`(새): `save_path != "" and SaveStore.exists(save_path)`.
  - `save_game() -> bool`(새): `save_path`가 비었거나 `day`가 null이면 false. `var saved: Dictionary = day.saved_state()`가 비었으면 false(하루 중이다). `SaveStore.write(save_path, saved)`가 실패하면 `saved_day = 0`, `push_warning("저장하지 못했다: %s" % save_path)`, false. 성공하면 `saved_day = int(saved["day"])`, true.
  - `go_to_phase_scene()`: 씬을 바꾸기 전에 한 줄 — `day`가 있고 단계가 폐점이면 `save_game()`. 폐점으로 가는 길(카운터의 돌려보내기, 정산의 다음, 손님이 없는 날)이 전부 이 함수를 지난다.
  - `end_day_play()`·`go_to_title()`·`go_to_practice()`·`scene_for_phase()`와 기존 상수는 고치지 않는다(저장 파일은 `end_day_play()`로 지워지지 않는다).
- 완료 확인: 다시 읽는다.
  - `save_path`가 빈 글일 때 `start_day_play()`·`save_game()`·`load_saved_day()`·`continue_day_play()`·`save_exists()`가 파일을 건드리는 줄에 닿지 않는다(다섯 함수를 따라간다).
  - `start_day_play()`가 만든 하루는 지금과 같은 인자의 `DayState.new`다(`git diff`에서 그 문장이 옮겨지기만 했다).
  - `save_game()`을 부르는 곳: `start_day_play`, `go_to_phase_scene`(폐점일 때), 폐점 화면의 구매(작업 5). 그 밖에는 없다(Grep `save_game`).
  - `scripts/`에서 `SAVE_PATH`를 직접 읽는 곳이 `_ready` 하나다(Grep). 다른 곳은 전부 `save_path`를 지난다.
  - 공통 규칙 다섯 가지. `push_error`가 0건이다.

### 작업 4. 처음 화면

- 대상: `scripts/title.gd`(씬 파일 `scenes/ui/title.tscn`은 고치지 않는다)
- 무엇: 규칙 "라"와 "사".
  - 글은 파일 머리의 상수로 둔다: `CONTINUE_TEXT`, `SAVE_INFO`, `SAVE_INFO_REPUTATION`, `NEW_GAME_TEXT`, `NEW_GAME_ARMED`, `NEW_GAME_WARNING`, `SAVE_UNREADABLE`, `PRACTICE_TEXT`(지금의 연습 버튼 글 그대로).
  - 멤버: `var saved: DayState`(주석: "이어서 할 저장을 되돌린 하루. 비어 있으면 /root/GameSession에서 읽는다. 없으면 저장이 없는 처음 화면이다"), `var save_unreadable := false`, `var _new_game: Button`, `var _armed := false`.
  - `_ready()`: 배경·제목·부제는 그대로. 그 뒤에
    - `saved`가 null이고 세션이 있으면 `saved = session.call("load_saved_day") as DayState`, `save_unreadable = saved == null and bool(session.call("save_exists"))`
    - `saved`가 있으면 `_build_continue()`, 없으면 `_build_fresh()`
  - `_build_fresh()`: 지금 `_ready`의 버튼 둘·힌트·`open.grab_focus()`를 **글자·이름·자리·크기 그대로** 옮긴다. `save_unreadable`이 참이면 흐린 한 줄(`SaveUnreadable`, 16pt, 가운데 정렬, 자리 `(0, 600)` 크기 `(1280, 28)`)을 더한다.
  - `_build_continue()`(자리는 임시다. 1280x720 기준):

    | 노드 | 자리 / 크기 | 글자 크기 |
    |---|---|---|
    | `Continue` | (400, 330) / (480, 84) | 28 |
    | `SaveInfo`(가운데 정렬, 흐림) | (0, 422) / (1280, 28) | 18 |
    | `NewGame` | (440, 462) / (400, 50) | 20 |
    | `Practice` | (440, 522) / (400, 50) | 20 |
    | 힌트(지금의 글) | (0, 590) / (1280, 30) | 16 |
    | `NewGameWarning`(가운데 정렬, 붉음. 한 번 누른 뒤에 만든다) | (0, 624) / (1280, 28) | 18 |

    - `SaveInfo`의 글: `SAVE_INFO % [saved.money, saved.owned.size()]`, `saved.has_reputation()`이면 뒤에 `SAVE_INFO_REPUTATION % [saved.reputation_stars(), saved.reputation_rules.max_stars()]`.
    - 포커스는 `Continue`에 둔다.
  - `_on_new_game()`: `_armed`가 거짓이면 참으로 바꾸고, `_new_game.text = NEW_GAME_ARMED`, `NewGameWarning`을 만들고 돌아온다(세션이 없어도 여기까지는 한다 — 테스트가 본다). 참이면 `_open_shop()`을 부른다.
  - `_continue()`: `_open_shop()`과 같은 가드(세션이 없거나 현재 씬이 아니면 돌아온다). `bool(session.call("continue_day_play"))`가 참이면 `go_to_phase_scene`, 거짓이면(그 사이에 파일이 사라졌다) `go_to_title`.
  - `_open_shop()`·`_practice()`는 고치지 않는다(`start_day_play()`가 새 1일차를 만들고 적는다).
- 완료 확인: 다시 읽고 손으로 넣는다.
  - `saved`가 null이고 세션이 없을 때(T33): 버튼이 `Proceed`·`Practice` 둘이고 다른 Button이 없다. `git diff`에서 그 두 버튼과 힌트의 글·자리·크기·이름이 그대로다.
  - 스모크(세션이 있고 `save_path`가 빔): `load_saved_day()`가 null, `save_exists()`가 거짓 → `_build_fresh()`, `SaveUnreadable` 없음.
  - 3일차 · 소지금 142 · 가진 것 하나 · 별 4인 저장: `이어서 한다 — 3일차 아침부터` / `소지금 142 · 가진 업그레이드 1개 · 평판 별 4/5`. 소지금이 음수면 `소지금 -78 · …`이다.
  - `NewGame`을 한 번 누른 뒤: 글 `한 번 더 누르면 새로 시작한다`, `지금 가게(3일차)는 지워진다. 되돌릴 수 없다`. 이때까지 `start_day_play`에 닿지 않는다.
  - 길이 어림(한글 한 글자 ≈ 글자 크기 px): `Continue`의 글은 28pt에서 두 자리 날까지 약 400px(버튼 480px). `SaveInfo`는 18pt에서 약 420px. 화면으로는 확인하지 못한다(playtester 11번).
  - 공통 규칙 다섯 가지.

### 작업 5. 카운터와 폐점 — 한 줄씩, 그리고 살 때의 저장

- 대상: `scripts/commission/counter.gd`, `scripts/economy/closing.gd`
- 카운터:
  - 상수 `QUIT_NOTE := "오늘 한 일은 남지 않는다 — 이어서 하면 오늘 아침부터다"`.
  - `_build`의 `quit` 버튼 아래에 흐린 한 줄: `var quit_note := Ui.add_label(self, QUIT_NOTE, 13, Ui.DIM)`, 이름 `QuitNote`, 자리 `(40, 694)`. `Quit` 버튼(자리 `(40, 650)`, 크기 `(170, 42)`)과 `_quit()`은 고치지 않는다.
- 폐점:
  - 상수 `SAVED_NOTE := "저장했다 — 끄고 다시 켜도 %d일차 아침부터 이어진다"`.
  - `_build`의 `quit` 버튼을 만든 뒤, `refresh_shop()` 앞에: 세션이 있고 `int(session.get("saved_day")) == day.day_number + 1`이면 흐린 한 줄(`SavedNote`, 16pt, 자리 `(268, 650)` 크기 `(590, 24)`. "처음 화면으로"와 "다음 날을 연다" 사이다).
  - 새 함수 `_save_now()`: 세션이 있고 `is_inside_tree()`이고 현재 씬이 자신이면 `session.call("save_game")`.
  - `_buy()`: `day.buy(upgrade)`가 참일 때 `refresh_shop()` 앞에서 `_save_now()`를 부른다.
  - `_next_day()`·`_quit()`·`refresh_shop()`·`reputation_ledger_text()`는 고치지 않는다.
- 완료 확인: 다시 읽는다.
  - 세션이 없는 화면(T33·T36·T39·T54·T55): `SavedNote`가 없고, `_buy`가 `_save_now`에서 아무것도 하지 않는다. 카운터에 `QuitNote`가 하나 생긴다.
  - `tests/`에서 `QuitNote`·`SavedNote`·`남지 않는다`·`저장했다`가 0건이고(새 테스트 파일을 쓰기 전), 카운터나 폐점의 Label 수를 세는 테스트가 없다(Grep `find_children\("\*", "Label"` — 지금은 `day_ui.gd`의 `all_text`뿐이다).
  - `QuitNote`의 아랫변: 694 + 약 20 = 714 < 720. 폭은 13pt에서 약 330px이라 흥정 버튼(x 410부터)에 닿지 않는다. 화면으로는 확인하지 못한다(playtester 11번).
  - 공통 규칙 다섯 가지.

### 작업 6. 스모크 — 저장을 끄고 돈다

- 대상: `tests/day_smoke.gd`(운전자 `Driver`)
- 무엇: 지나는 씬의 순서와 기존 기대값은 한 줄도 바꾸지 않는다. 더하는 것만 있다.
  - 멤버 둘: `var _real_save_path := ""`, `var _real_save_before := ""`.
  - 도우미 `_file_text(path: String) -> String`: `path`가 비었거나 파일이 없으면 `"<없음>"`, 있으면 `FileAccess.get_file_as_string(path)`.
  - `plan()`의 맨 앞: `var session := _session()`. null이면 `_fail("GameSession 오토로드가 없음")` 뒤 false. `_real_save_path = String(session.get("save_path"))`, `_real_save_before = _file_text(_real_save_path)`, `session.set("save_path", "")`.
  - `title_open`: `Continue`가 있으면 `_fail("저장을 껐는데 처음 화면에 Continue가 있음")`.
  - `counter_final`: `_succeed()` 앞에서 `_file_text(_real_save_path) != _real_save_before`이면 `_fail("스모크가 실제 저장 파일을 바꿈")`. 같으면 `print("DAY SMOKE 저장: 꺼짐, 실제 저장 파일 그대로")`.
  - 파일 머리 주석에 한 줄: "저장은 끄고 돈다(GameSession.save_path를 비운다). 저장과 이어서 하기는 tests/save_tests.gd와 playtester가 본다."
- 완료 확인: `git diff`에 지워진 줄이 없다(주석 한 줄을 고친 것 말고는 더한 줄뿐이다). `plan()`의 기존 지역 변수(`catalog`, `day1`, `day2`, `guests1`)와 겹치지 않는다. `_drive_once`의 `session`·`day`는 그대로 쓴다. 공통 규칙 다섯 가지.

### 작업 7. 테스트 — 새 테스트 셋(T56~T58)과 기존 테스트 읽기

**새 테스트를 쓴다.** 까닭: 저장의 핵심(내준 아침 = 되돌린 아침, 깨진 파일에서 죽지 않음)은 화면 없이 값으로 확인하는 것이 가장 싸고, 깨진 값의 경우는 게임 창에서 만들기 번거롭다. 메인은 돌리지 않고 playtester가 돌린다.

- 대상: `tests/save_tests.gd`(새 파일), `tests/run_tests.gd`(`TEST_FILES`의 끝에 `"res://tests/save_tests.gd",` 한 줄)
- 틀: `tests/haggle_tests.gd`와 같다(`extends RefCounted`, `var _d := Day.new()`, `list(tree)`에서 `_d.set("_tree", tree)`, `cleanup()`, `_expect`, `_result`). 기존 테스트 파일은 고치지 않는다.
- 상수: `Day`(`res://tests/day_tests.gd`), `DT`(`res://scripts/duel/duel_types.gd`), `Session`(`res://scripts/game_session.gd`), `Store`(`res://scripts/save_store.gd`), `TEST_PATH := "user://bravi_test_save.json"`.
- 통과 조건은 테스트가 직접 만든 규칙으로 본다(`.tres`의 값을 바꿔도 흔들리지 않게). 로드한 데이터를 쓰는 곳(T57의 `Session`)은 절대값이 아니라 "적은 값 = 하루의 값"으로 견준다.
- 파일은 `TEST_PATH`만 쓴다. 테스트의 처음에 지우고 끝에 지운다(`Store.erase`). 깨진 파일의 내용은 ASCII만 쓴다(잘못된 UTF-8은 엔진이 오류 줄을 찍을 수 있다). `Session.new()`로 만든 노드는 테스트 끝에 `free()`한다(누수 경고).

**T56 "저장의 내용: 아침을 내주고 아침으로 되돌린다 (250 → 322 → 72 → 169)"** — `_d._rules(70, 60, 20, 250)`, `_d._three_fixed()`, `_d._catalog(_d._test_upgrades())`

| # | 무엇 | 기대 |
|---|---|---|
| 가 | 새 하루의 `saved_state()` | `version` 1, `day` 1, `money` 250, `owned` 빈 배열, `dice_seed`가 멤버와 같고 0~`DICE_SEED_MAX` |
| 나 | 하루 중 | `accept()` 뒤, `finish_duel` 뒤(정산) 빈 Dictionary. 다른 새 하루에서 첫 손님을 `decline()`한 뒤에도 빈 Dictionary |
| 다 | 폐점 | `_d._run_fixed_day` 뒤 `day` 2, `money` 322. 첫째(40)를 사면 282와 `["t_medicine"]`. 나머지를 사면 72와 셋 |
| 라 | JSON을 지나 되돌리기 | "다"의 마지막 것을 `JSON.stringify` → `JSON.new().parse` → 새 `DayState`에 `restore()`: true, 2일차, 72, 가진 것 셋, 카운터, `index` 0, `results` 빔, 씨앗 같음. 원래 하루에 `next_day()`를 부른 값과 같다(`day_number`, `money`, `owned`, `commission_count()`). 되돌린 하루를 `_d._run_fixed_day`로 끝내면 소지금 169 |
| 마 | 고치는 값 | `owned`가 `["nope", "t_chair", "t_chair"]` → `[&"t_chair"]`. `owned`가 글 → 빈 배열. `day` 0 → 1, `day` 2.0 → 2. 평판 규칙(시작 9, 0~20, 문턱 4·8·12·16)의 하루에서 `reputation` 999 → 20, −5 → 0, 글 → 9, 13 → 13이고 `day_start_reputation`도 13, 별 4 |
| 바 | 읽을 수 없는 것 | `version` 2, `version` 없음, `day`가 글, `money` 없음, 빈 Dictionary: `restore()`가 false이고 `[day_number, money, owned, reputation, dice_seed, phase]`가 그대로 |
| 사 | 주사위 | `haggle_roll()`을 두 번 불러 같은 값, 0~99. 되돌린 하루와 원래 하루(`next_day()` 뒤)가 순번 0·1·2에서 같은 값(`decline()`으로 넘긴다). 흥정이 켜진 규칙(`haggle_bonus_percent` 30, 확률표가 한 칸 `[50]` 둘, 손님의 `haggle_min_stars`를 1로 적음, 위의 평판 규칙)에서 인자 없는 `haggle()`의 결과가 `haggle_roll() < haggle_chance()`와 같다 |

**T57 "저장 파일과 GameSession: 쓰고, 읽고, 깨진 파일, 꺼진 저장"**

| # | 무엇 | 기대 |
|---|---|---|
| 가 | `Store` 왕복 | 지운 뒤 `exists` 거짓, `read`가 빔. `write` true 뒤 `exists` 참, `read`의 `int(day)`·`int(money)`·`owned`(배열)가 쓴 값 |
| 나 | 깨진 파일 | 내용이 `{{{ not json`, `[1, 2]`, 빈 파일일 때 `read`가 빔. `read("")`가 빔, `write("", …)`가 false |
| 다 | 꺼진 저장 | `Session.new()`의 `save_path`가 빈 글. `start_day_play` 뒤 `day`가 있고 `TEST_PATH`가 생기지 않는다. `save_game`·`continue_day_play`·`save_exists`가 거짓 |
| 라 | 적는 때 | `save_path`에 `TEST_PATH`를 넣은 `Session.new()`: `start_day_play` 뒤 파일의 `day` 1, `money`가 `day.rules.starting_money`, `saved_day` 1. 손님을 전부 `decline()`해 폐점에 간 뒤 `save_game`이 true, `saved_day` 2, 파일의 `day` 2, `money`·`reputation`이 하루의 값 |
| 마 | 이어서 하기 | 다른 `Session.new()` + `TEST_PATH`: `load_saved_day`가 null이 아니고 그 뒤에도 `day`는 null. `continue_day_play`가 true이고 `day`의 날 2, 소지금·평판·씨앗이 "라"의 하루와 같고, "라"의 하루에 `next_day()`를 부른 것과 단계·`commission_count()`·`data`가 같다 |
| 바 | 읽을 수 없는 파일 | `TEST_PATH`를 `{{{`로 바꾼 뒤와 `version` 2인 저장으로 바꾼 뒤: `save_exists` 참, `load_saved_day` null, `continue_day_play` 거짓 |

**T58 "저장의 화면: 이어서 한다, 새로 시작한다, 카운터와 폐점의 한 줄"** — 처음 화면은 `saved`와 `save_unreadable`을 직접 넣어 붙인다(파일 안의 도우미 `_spawn_title`. `_d._spawn_screen`은 `day`만 넣는다)

| # | 무엇 | 기대 |
|---|---|---|
| 가 | 저장이 없는 처음 화면 | Button 2개, `Proceed` 있음, `Continue`·`NewGame`·`SaveUnreadable` 없음 |
| 나 | 읽을 수 없는 저장 | `save_unreadable`을 참으로 넣으면 Button 2개, `SaveUnreadable` 있음 |
| 다 | 저장이 있는 처음 화면 | T56 "라"의 되돌린 하루(2일차, 72, 셋, 평판 없음)를 넣으면 Button 3개(`Continue`·`NewGame`·`Practice`), `Proceed` 없음. `Continue`의 글에 `2일차`, `SaveInfo`에 `소지금 72`와 `3개`가 있고 `평판`이 없다. 포커스가 `Continue` |
| 라 | 새로 시작의 확인 | `NewGame`을 한 번 누르면 글에 `한 번 더`, `NewGameWarning`이 있고 `2일차`를 담는다. 한 번 더 눌러도(세션 없음) 화면이 그대로다 |
| 마 | 평판이 있는 저장 | T56 "마"의 평판 13인 하루를 넣으면 `SaveInfo`에 `평판 별 4/5` |
| 바 | 한 줄 둘 | 카운터에 `QuitNote`가 있고 `아침`을 담는다. 세션 없이 붙인 폐점에 `SavedNote`가 없다 |

- **선언 대조**(새 파일을 쓴 뒤. 로드되지 않으면 러너가 멈춰 나머지 56개도 돌지 않는다):
  - 파일이 쓰는 상수 다섯(`Day`, `DT`, `Session`, `Store`, `TEST_PATH`)이 파일 머리에 있다. `Ui`를 쓰면 그것도 선언한다.
  - 파일이 부르는 `_d.` 도우미를 Grep으로 모아 `tests/day_tests.gd`의 선언과 하나씩 맞춘다. 지금 있는 것(planner가 확인): `_rules`, `_fixed_commission`, `_record`, `_three_fixed`, `_spawn_screen`, `_catalog`, `_test_upgrades`, `_run_fixed_day`, `_duel_rules`, `_press`, `_label_text`, `_has_node`, `cleanup`. 이 밖의 것을 쓰게 되면 선언이 있는지 먼저 본다.
  - 글로 부르는 이름(파서가 잡지 못한다)을 선언과 맞춘다: `.call("…")`의 `start_day_play`·`save_game`·`load_saved_day`·`continue_day_play`·`save_exists`, `.get/.set("…")`의 `save_path`·`saved_day`·`day`·`saved`·`save_unreadable`, 노드 이름 `Continue`·`NewGame`·`Practice`·`Proceed`·`SaveInfo`·`NewGameWarning`·`SaveUnreadable`·`QuitNote`·`SavedNote`.
  - `DayState.SAVE_VERSION`·`DayState.DICE_SEED_MAX`·`saved_state`·`restore`·`haggle_roll`·`dice_seed`가 작업 2의 이름과 같다.
- 기존 테스트는 **읽어서 확인만** 한다. `tests/`에서 `_rng`, `haggle(`, `start_day_play`, `TITLE_PATH`, `"Quit"`, `go_to_phase_scene`을 찾아 통과 조건이 바뀌는 줄이 없는지 본다. 지금 아는 것:
  - T33의 처음 화면은 세션 없이 붙는다 → 버튼 둘 그대로다.
  - T55는 주사위를 인자로 주거나(인자가 먼저다) 확률 100에서 인자 없이 부른다 → 그대로다.
  - 화면 테스트는 `day`를 직접 넣고 세션이 없다 → 어떤 테스트도 파일을 쓰지 않는다(새 T57만 `TEST_PATH`를 쓴다).
  - 통과하면 마지막 줄이 `ALL PASS 59/59`가 된다(지금 56. T55는 아직 실행되지 않았다).
- 완료 확인: 새 파일에 공통 규칙 다섯 가지와 선언 대조. 표의 기대값을 작업 2의 손 확인 (1)~(5)와 맞춘다(250, 322, 282, 72, 169, 20, 0, 9, 13). `git diff`에서 `run_tests.gd`에 더한 줄이 하나다. 새 파일에 `bravi_save.json`이 0건이다(실제 저장의 이름을 쓰지 않는다).

### 작업 8. 기록과 보고

- `docs/DECISIONS.md`: 2026-11-20 계획 016 절. 사용자 지시, "실행 전에 물을 것"의 두 답(원문), 결정 146~154 한 줄씩, "결정 54의 '갈라내기'는 `saved_state()`/`restore()` 두 함수로 대신했다", "계획 015가 넘긴 두 가지의 답"(규칙 "다"), "테스트·게임을 실행하지 않았다".
- `CLAUDE.md`:
  - 5장 "지금 만든 범위": 괄호를 "계획 016까지"로. 끝에 "저장(슬롯 하나. 폐점에 들어설 때와 살 때 다음 날의 아침을 적는다: 날, 소지금, 가진 업그레이드, 평판. 하루 중에 그만두면 그날은 남지 않고 그날 아침부터 이어진다. 처음 화면에서 이어서 하거나 새로 시작한다)"를 더하고, "아직 없는 것"에서 "저장"을 뺀다.
  - 8장 폴더 구조: `scripts/` 줄에 `save_store.gd`(저장 파일의 읽기와 쓰기)를 더한다.
  - 9장 현재 위치: "계획 016(저장)까지 실행했다. 2단계의 작업은 여기까지이고, 완료 판정은 사용자가 한다."
- `docs/reports/016-save.md`와 사용자 보고(10장 형식). 2번의 "확인 못 한 것"에 실행 전부를 적고, 아래 **playtester에게 맡길 확인** 목록을 싣는다. "껐다 켜도 이어진다"는 실행으로만 확인된다.
  0. **준비**: 실행하는 PowerShell에서 `$env:BRAVI_SAVE_PATH = "user://bravi_playtest_save.json"`을 먼저 건다(사용자의 실제 저장 `bravi_save.json`을 건드리지 않는다). 파일은 `%APPDATA%\Godot\app_userdata\Bravi\`에 있다. 시작 전에 `bravi_playtest_save.json`을 지운다. 실제 저장 파일이 있으면 내용을 적어 두고 맨 끝에 견준다.
  1. 테스트가 `ALL PASS 59/59`(T55~T58 포함)이고 스모크가 `RESULT: OK`이며 `DAY SMOKE 저장: 꺼짐, 실제 저장 파일 그대로` 줄이 있는가. 실행 뒤 `bravi_test_save.json`이 남지 않았는가. 실패하거나 `save_tests.gd`·`haggle_tests.gd`가 로드되지 않으면 그 줄을 글자 그대로 보고한다(T55의 실패는 계획 015, T56~T58의 실패는 이 계획이다).
  2. 저장이 없는 처음 화면이 전과 같은가(버튼 둘, `가게를 연다`에 포커스).
  3. `가게를 연다` → 1일차 카운터에서 창을 닫는다(Alt+F4) → 다시 켠다: `이어서 한다 — 1일차 아침부터`와 정보 한 줄이 보이는가. 누르면 1일차 첫 손님이고 소지금이 시작값인가. 파일의 내용이 `day` 1인가.
  4. 1일차를 끝까지 해 폐점에 간다: `저장했다 — 끄고 다시 켜도 2일차 아침부터 이어진다`가 보이는가. 파일의 `day` 2, `money`·`reputation`이 화면의 소지금·평판과 같은가. 업그레이드를 하나 사면 파일의 `money`와 `owned`가 바로 바뀌는가. "다음 날을 연다"를 누르지 않고 창을 닫는다 → 다시 켜 이어서 한다: 2일차 첫 카운터이고, 소지금·평판·별·손님 수·보수 덧붙임이 폐점에서 본 값("내일의 손님 N명 · 내일의 보수")과 같은가. 산 것의 효과가 나는가(의자면 보수 줄의 팁 최대, 조끼면 결투의 내 자세).
  5. 2일차에 한 판을 끝내고 다음 카운터에서 `오늘은 그만`을 누른다(그 아래 한 줄이 `오늘 한 일은 남지 않는다 — 이어서 하면 오늘 아침부터다`인가) → 처음 화면의 `이어서 한다 — 2일차 아침부터` → 2일차 첫 손님이고 소지금·평판이 2일차 아침의 값인가(방금 한 판의 돈과 평판이 없다).
  6. 흥정의 주사위: 그날 첫 손님(흥정할 수 없는 손님이면 돌려보내고 다음 손님)에게 값을 올려 부르고 결과를 적는다 → `오늘은 그만` → 이어서 한다 → 같은 손님에게 다시 누른다. 세 번 되풀이해 세 번 다 같은 결과인가.
  7. `새로 시작한다`를 한 번 누르면 글이 `한 번 더 누르면 새로 시작한다`로 바뀌고 붉은 줄이 뜨며, 파일은 그대로인가. 여기서 `이어서 한다`를 누르면 옛 가게가 그대로 열리는가. 다시 처음 화면에서 두 번 누르면 1일차 카운터이고 파일이 `day` 1 · 시작 소지금 · `owned` 빈 배열 · 시작 평판인가.
  8. 게임을 끄고 playtest 파일을 고친 뒤 켠다(네 가지를 따로): 내용을 `{{{`로 → 죽지 않고 버튼 둘과 `저장 파일을 읽지 못했다 …` 한 줄, 오류 줄 0. `version`을 2로 → 같다. `reputation`을 999로 → 이어서 하면 평판이 최대(`data/reputation_rules.tres`의 `max_value`. 지금 44)다. `owned`에 `"nope"`을 더하면 → 무시되고 죽지 않는다.
  9. 폐점의 `처음 화면으로` → 처음 화면이 `이어서 한다 — (그다음 날)일차 아침부터`인가.
  10. 연습(의뢰를 골라 결투)을 하고 돌아와도 파일이 그대로인가.
  11. 글이 넘치거나 겹치지 않는가: 처음 화면의 `Continue`·정보 한 줄·붉은 줄, 카운터의 `QuitNote`(화면 아랫변에 잘리지 않는가, 흥정 버튼에 닿지 않는가), 폐점의 `SavedNote`("처음 화면으로"와 "다음 날을 연다" 사이).
  12. 계획 015 보고서의 "playtester에게 맡길 확인" 9가지(아직 실행하지 않았다). 이 계획은 그 가운데 3번(여러 번 눌러 받아 줌과 거절이 둘 다 나오는가)의 방법을 바꾼다: 같은 가게의 같은 날 같은 손님은 늘 같은 결과이므로, **새로 시작한 가게마다** 한 번씩 눌러 센다.
- 4번(사용자 결정)에는 아래 "사용자 결정 필요"를 싣는다. 맨 위에 "2단계 완료 기준 충족 — 다음 단계 진행 여부"를 둔다. 5번에는 playtester 확인 → 사용자의 2단계 완료 판정을 적는다.
- **플레이 체크리스트 T**(사용자용): (1) 껐다 켰을 때 "어디서 이어지는지"를 미리 알고 있었는가(폐점의 한 줄, 카운터의 한 줄). (2) 하루 중에 그만둔 뒤 그날을 다시 하는 것이 자연스러웠는가, 꼼수로 느껴졌는가. (3) 결투를 망친 뒤 일부러 그만두고 다시 한 적이 있는가. (4) "새로 시작한다"를 실수로 누를 뻔했는가, 두 번 누르기가 번거로웠는가. (5) 하루를 다시 했을 때 흥정의 결과가 같다는 것을 알아챘는가.
- 완료 확인: 보고서 파일이 있고 "확인 못 한 것"과 playtester 목록이 있다. 두 문서의 `git diff`에서 그 줄들만 바뀌었다.

## 설계 결정

번호는 계획 015의 표(138~145)에 잇는다. 전부 임시이고, 146·148은 "실행 전에 물을 것" 1번, 150은 2번의 답에 따라 바뀔 수 있다.

| # | 결정 | 이유 | 되돌리기 |
|---|---|---|---|
| 146 | 저장은 하루 단위다. 파일은 "다음에 열 날의 아침"(날, 소지금, 가진 업그레이드, 평판, 주사위의 씨앗)만 담고 하루의 것은 담지 않는다 | 2단계에서 가장 작은 저장이다. 날을 넘는 것은 이미 정수 넷과 id 목록이다. 하루의 것(결과 목록의 Dictionary들)을 파일에 넣으면 작업이 두세 배가 된다 | 보통 — 하루 중 저장으로 가려면 `saved_state`/`restore`를 넓힌다(계획 하나) |
| 147 | 적는 때는 셋이다: 새로 시작할 때, 폐점에 들어설 때, 폐점에서 살 때마다. 폐점 화면이 뜬 뒤에는 어떻게 나가도 같은 아침에서 이어진다 | 하루를 끝낸 뒤 가게를 구경하다 창을 닫는 것이 가장 흔한 끝내기다. "다음 날을 연다"를 눌러야만 적히면 그 하루가 사라진다 | 쉬움 — `save_game()`을 부르는 곳 셋 |
| 148 | 하루 중에 "오늘은 그만"을 누르거나 창을 닫으면 그날 한 일은 남지 않고, 이어서 하면 그날 아침부터다. 카운터에 그 한 줄을 보인다 | 146의 귀결이다. 버려지는 것을 누르기 전에 읽히게 한다(되돌릴 수 없는 선택의 조건은 누르기 전에. 014의 D1과 같은 기준) | 쉬움 — 글 |
| 149 | 흥정의 주사위는 가게의 씨앗 · 날 · 손님의 순번으로 정해진다. 하루를 다시 해도 같은 주사위다. 흥정의 결과는 저장하지 않는다 | 계획 015가 넘긴 두 가지의 답. 하루 단위 저장에도 "아침의 첫 손님에게 다시 누르기"가 클릭 몇 번이라 막는다. 씨앗 하나라 저장에 드는 것이 정수 하나다 | 쉬움 — `haggle()`의 한 줄 |
| 150 | 슬롯은 하나다. 저장이 있으면 처음 화면에 "이어서 한다 — N일차 아침부터"(포커스)와 "새로 시작한다"(두 번 눌러야 한다)가 보인다. 저장이 없으면 지금과 글자 그대로 같다 | 지우는 것은 되돌릴 수 없다. 저장이 없을 때의 동작을 그대로 두어 기존 테스트와 스모크가 흔들리지 않는다 | 쉬움 — `title.gd` |
| 151 | 파일은 `user://bravi_save.json`, JSON, `version` 1이다. 읽을 수 없는 저장(없음, 깨짐, 버전이 다름, 날이나 소지금이 숫자가 아님)은 없는 것으로 치고 처음 화면에 한 줄로 알린다. 읽힌 값도 믿지 않는다(평판은 범위로, 업그레이드는 목록에 있는 것만, 날은 1 이상). 오류 줄을 찍지 않는다 | 사람이 열어 확인할 수 있다. 값이 전부 임시라 데이터가 바뀌어도 옛 저장으로 죽지 않아야 한다. `JSON.new().parse()`는 실패해도 오류 줄을 찍지 않는다 | 쉬움 |
| 152 | `DayState`는 파일을 모른다(`saved_state()`가 내주고 `restore()`가 받는다). 파일은 `scripts/save_store.gd`, 경로와 적는 때는 `GameSession`이 맡는다. 날을 넘는 것을 다른 클래스로 갈라내지 않는다(결정 54의 "갈라내기"를 이 두 함수로 대신한다) | `DayState`가 Node 없이 테스트되는 구조를 지킨다. 클래스를 가르면 playtester가 확인한 코드 전체를 실행 없이 다시 쓰게 된다 | 보통 |
| 153 | 테스트·스모크·playtester는 실제 저장을 건드리지 않는다: 트리 밖의 `GameSession`은 저장이 꺼져 있고, 스모크는 저장을 끄고 돌며, 게임은 환경 변수 `BRAVI_SAVE_PATH`가 있으면 그 경로를 쓴다 | 사용자의 가게를 확인 작업이 덮어쓰면 안 된다 | 쉬움 |
| 154 | 새 테스트 셋(T56~T58, `tests/save_tests.gd`)을 쓴다. 새 `class_name`은 만들지 않는다. 스모크에 "이어서 한다" 구간은 더하지 않는다 | 저장의 값과 깨진 파일은 화면 없이 확인하는 것이 싸다. 스모크는 "가게를 연다 = 새 1일차"를 전제로 짜여 있어 그대로 둔다 | 쉬움 |

## 위험

1. **실행되지 않은 계획 015 위에 얹는다.** 015의 변경과 T55는 아직 아무도 실행하지 않았다. 이 계획은 그 `haggle()`의 한 줄을 고친다. 015에 오류가 있으면 016의 확인과 섞인다. 대비: playtester 1번이 T55와 T56~T58의 실패를 갈라 보고한다. 015의 실행 확인을 016 실행 앞에 둘지는 "사용자 결정 필요" 2번이다.
2. **하루를 다시 할 수 있다**(규칙 "나"). 하루 단위 저장의 성질이고, 첫 결투는 사실상 값없이 다시 할 수 있다. "의뢰를 정확히 수행한다"의 긴장이 느슨해질 수 있다. 대비: "실행 전에 물을 것" 1번에서 사용자가 고른다. 체크리스트 T의 2·3번.
3. **하루를 다시 해서 주사위를 알아낼 수 있다.** 한 번 해 본 하루에서 누가 받아 주는지 본 뒤, 다시 한 하루에서 받아 주는 손님에게만 누를 수 있다. 다시 뽑기보다 값이 크지만(하루를 다시 해야 한다) 길은 있다. 2번이 막히지 않는 한 막을 수 없다. 알고 둔다.
4. **스모크나 playtester가 실제 저장을 덮어쓴다.** 스모크의 한 줄(`save_path`를 비우기)이 빠지거나 playtester가 환경 변수를 걸지 않으면 사용자의 가게가 새 1일차로 바뀐다. 대비: 스모크가 끝에서 실제 저장 파일이 처음과 같은지 견주고, playtester 목록의 0번이 준비다. 지금은 사용자의 저장 파일이 아직 없다(기능이 처음 생긴다).
5. **실행 없이 쌓이는 변경.** 새 스크립트 하나(`save_store.gd`), 고치는 스크립트 다섯(`day_state`, `game_session`, `title`, `counter`, `closing`), 스모크, 새 테스트 파일 하나. 대비: 공통 규칙, 작업마다의 손 확인, 새 `class_name` 없음, 기존 함수의 시그니처와 몸을 거의 건드리지 않음(`haggle()`의 한 줄, `start_day_play()`의 옮기기, `go_to_phase_scene()`의 한 줄, `_buy()`의 한 줄).
6. **적는 도중에 꺼지면 파일이 깨진다.** 그러면 읽을 수 없는 저장이 되어 가게를 잃는다(죽지는 않는다). 파일이 한 줄(백 바이트 안팎)이고 한 번에 적으므로 그대로 둔다. 임시 파일과 바꿔치기는 Windows에서 실행 없이 확인하기 어렵다.
7. **엔진의 동작을 읽어서만 안다**: `JSON.new().parse()`가 실패에 오류 줄을 찍지 않는 것, JSON의 숫자가 실수로 돌아올 수 있는 것, `OS.get_environment`가 없는 변수에 빈 글을 주는 것, `FileAccess.get_as_text()`가 ASCII 쓰레기에 오류 줄을 찍지 않는 것. 프로젝트는 Godot 4.7이다. 대비: 숫자는 정수·실수 둘 다 받는다. T57의 "나"·"바"와 playtester 8번이 오류 줄을 본다. 어긋나면 그 줄을 글자 그대로 보고받아 고친다.
8. **데이터가 바뀌면 옛 저장의 뜻이 달라진다.** 값이 전부 임시인 단계다(평판의 눈금, 업그레이드의 값). 평판과 업그레이드는 읽을 때 고치지만, 소지금과 날은 그대로 온다. 버전은 올리지 않는다(형식이 바뀔 때만 올린다). 감수한다.
9. **새 줄의 자리.** `QuitNote`는 화면 아랫변에서 6px 위다. `Continue`의 글은 버튼 폭의 약 85%다. 대비: playtester 11번. 넘치면 글자 크기를 줄이거나 글을 줄인다.
10. **design-reviewer가 2번을 차단할 수 있다.** 사용자의 답("실행 전에 물을 것" 1번)을 "지켜야 할 사용자 요구"로 검토자에게 전달한다.

## 실행 전에 물을 것

메인이 검토 전에 묻는다. 본문은 두 물음 모두 **가**로 썼다.

**1. 저장은 언제 되고, 하루 중에 그만두면 어떻게 될까요?**

| 안 | 플레이에서 | 작업 |
|---|---|---|
| **가. 하루 단위 — 그날 아침으로 (권함)** | 폐점 화면이 뜨면 그날이 저장된다. 하루 중에 "오늘은 그만"을 누르거나 창을 닫으면 그날 한 일은 사라지고, 다음에는 그날 아침부터 한다. 「좋은 피자, 위대한 피자」와 같다. **그날을 다시 할 수 있다**(첫 결투를 망치면 그만두고 이어서 하면 된다). 흥정의 주사위만은 다시 해도 같다 | 본문 그대로 |
| 나. 하루 단위 — "오늘은 그만"은 일찍 문 닫기 | 저장은 가와 같다. "오늘은 그만"이 그날을 버리는 것이 아니라 **폐점**이 된다(임대료를 내고, 남은 손님은 만나지 못하고, 저장된다). 화면 안에는 하루를 다시 하는 길이 없다. 창을 강제로 닫으면 여전히 그날 아침이다(버튼보다 창 닫기가 유리해진다) | 가 + `DayState`에 "일찍 닫기" 전환 하나, 카운터의 버튼 글과 한 줄, 스모크의 `quit` 걸음(지금은 3일차 카운터에서 처음 화면으로 간다)을 고친다 |
| 다. 손님마다 저장 — 끈 자리에서 | 카운터·정산·폐점에 들어설 때마다 저장된다. 끝난 결투는 되돌릴 수 없다("하루 중의 결투는 한 번뿐"이 지켜진다). 결투 도중에 끄면 그 손님의 카운터로 돌아간다(그 결투만 다시 한다) | 계획을 다시 쓴다. 하루의 것 전부(순번, 결과 목록, 돌려보낸 손님, 흥정의 결과, 단계)를 파일에 넣고 되돌려야 한다. 작업이 두세 배이고 계획을 둘로 나눌 수 있다 |

- 권하는 까닭: 2단계의 완료 기준("하루 3의뢰를 끝까지 플레이 가능")에 가장 작은 저장으로 닿는다. 하루를 다시 하는 것이 문제로 느껴지는지는 플레이해 봐야 알고, 그때 나나 다로 가는 길이 막히지 않는다.

**2. 저장이 있을 때 "새로 시작한다"는 어떻게 지울까요?**

| 안 | 플레이에서 |
|---|---|
| **가. 두 번 눌러야 지워진다 (권함)** | 한 번 누르면 글이 `한 번 더 누르면 새로 시작한다`로 바뀌고 `지금 가게(N일차)는 지워진다`가 뜬다. 한 번 더 누르면 1일차다 |
| 나. 바로 지운다 | 한 번 누르면 1일차다. 잘못 누르면 가게를 잃는다 |
| 다. 새 가게의 첫날을 마칠 때 지운다 | 누르면 바로 1일차지만 옛 저장은 남아 있다. 1일차의 폐점 화면이 뜨기 전에 그만두면 처음 화면에 옛 가게가 그대로 있다. 확인은 없지만 "언제 지워지는지"를 설명해야 한다 |

- 답이 나면 `title.gd`의 `_armed`와 붉은 줄, T58의 "라"가 빠진다. 다면 `start_day_play()`가 적지 않게 되고(적는 때가 둘이 된다) T57의 "라"가 바뀐다.

## 사용자 결정 필요 (실행을 막지 않는다. 보고서 4번에 올린다)

| # | 무엇 | 이 계획이 정한 것 | 답이 다르면 |
|---|---|---|---|
| 1 | **2단계 완료 기준 충족 — 다음 단계 진행 여부** | 이 계획이 2단계의 마지막 작업이다(결정 88). 실행과 playtester 확인 뒤에 사용자가 판정한다. 3단계(스타일 바이블)의 계획은 만들지 않았다 | 판정을 미루면 보류 중인 결정들(계획 012~015 보고서 4번)이나 CLAUDE.md 5장의 "아직 없는 것"(칼 수리비, 부상에 따른 의뢰 수 감소)이 다음 후보다 |
| 2 | 계획 015의 실행 확인을 016 실행 앞에 둘지 | 정하지 않았다(실행 확인은 사용자가 요청한다). 권하는 것은 앞에 두는 것이다: 015의 오류와 016의 오류가 섞이지 않는다 | 뒤에 한꺼번에 하면 playtester 12번으로 함께 본다 |
| 3 | 하루를 다시 했을 때 흥정의 주사위 | 같다(가게의 씨앗 · 날 · 순번) | 다시 뽑히게 하려면 `haggle()`의 한 줄을 되돌린다. 씨앗은 저장에 남아도 해가 없다 |
| 4 | 읽을 수 없는 저장 | 한 줄로 알리고, 가게를 열면 덮어쓴다 | 덮어쓰기 전에 옛 파일을 다른 이름으로 남기려면 `save_store.gd`에 한 함수(범위 밖으로 둔 "백업"이다) |
| 5 | 화면의 글과 자리 | 규칙 "사"의 일곱 줄, 처음 화면의 자리(작업 4의 표) | 글과 숫자만 고친다 |
| 6 | 하루를 다시 하는 길을 화면에 그대로 두는 것 | "실행 전에 물을 것" 1번의 답대로 | 플레이한 뒤 생각이 바뀌면 나(일찍 닫기)는 작은 계획 하나, 다(손님마다 저장)는 큰 계획이다 |

보류 중인 것(그대로 둔다): 계획 012의 승리 +1·별에 따른 결투 수·궂은일을 맡는 값·속도·토마소의 0점 합, 계획 013의 기본 보수 덧붙임 크기·낮은 별의 깎임, 계획 014의 100점 조건이 팁에도 걸리는 것·+30%와 의뢰인의 값, 계획 015 보고서 4번의 넷과 design-reviewer의 의견 셋.
