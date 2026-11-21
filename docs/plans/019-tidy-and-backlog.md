# 계획 019: 2단계 정리 다섯과 나중에 고칠 목록

- 버전: v2 (1회차 검토 대응. 끝의 "검토 대응 기록")
- 개발 단계: CLAUDE.md 9장 2단계 (하루 루프). 018에 이은 **판정 전의 손질**이다. 새 기능·값·규칙은 없다. 단계를 넘지 않는다
- 근거:
  - 사용자 지시(2026-11-21, 원문): "f11, f16, f15, f20, f17만 고치고 나머지는 정리해서 나중에 고칠 수 있게 해줘." 번호는 계획 018 "점검 결과" 표의 것이다.
  - 넘지 않는 선(018과 같다): 보류 중인 값·결정(`docs/HANDOFF.md` 3번, 계획 012~018 보고서 4번)과 플레이 규칙은 건드리지 않는다. 사용자의 파일(`docs/plans/013-playtester.md`, `.claude/agents/playtester.md`)은 고치지 않는다.
  - 새 규칙(사용자 지시 2026-11-21, `CLAUDE.md` 10장 끝): 코드 주석은 코드만 봐서는 모르는 것(까닭, 일부러 한 것, 지키는 결정 번호, 건드리면 깨지는 것)만 한 줄로 쓴다. 기존 주석은 그 줄을 고칠 때만 줄인다. 이 계획의 코드 조각과 F16의 새 주석 셋은 이 규칙을 따른다.
  - 저장소 상태: 계획 018은 커밋했다(`2ffc964`, 원격에는 올리지 않았다). 작업 트리에는 이 계획 파일과 `M CLAUDE.md`(사용자 지시로 메인이 10장 끝에 더한 주석 규칙 한 줄, 커밋 전)가 있다. 코드 파일은 깨끗하다. 그래서 019 실행 뒤의 `git diff`는 코드에서 019만 보여 준다(v2, 기술 지적). **018은 아직 실행 확인 전이다**(기대 `ALL PASS 63/63`). 019는 018이 고친 파일(`title.gd`, `counter.gd`, `settlement.gd`, `closing.gd`, `day_ui.gd`)을 다시 고친다. 둘을 가르는 길은 작업 0과 작업 8의 "가리는 순서"다.
  - 018 표의 고침 하나: F11의 두 꼴은 "6곳과 6곳"이 아니라 **`is_inside_tree()`가 있는 4곳**(`counter.gd`·`settlement.gd`의 `_return_to_title`, `closing.gd`의 `_save_now`·`_return_to_title`)과 **없는 8곳**(`title.gd`의 `_continue`·`_open_shop`·`_practice`, `counter.gd`의 `_quit`·`_go`, `settlement.gd`의 `_proceed`, `closing.gd`의 `_next_day`·`_quit`)이다(planner가 지금 파일에서 셌다). 없는 쪽도 트리 밖에서 `get_tree()`까지 가지 않는다(`get_node_or_null`이 null을 돌려주고 단락 평가로 끝난다). 다만 그때 엔진이 "절대 경로를 트리 밖에서 찾았다"는 오류 줄을 찍는다. 지금은 트리 밖에서 불리는 길이 없다.
  - 러너의 사정(018에서 확인): `--script` 러너에도 오토로드 `GameSession`이 뜨고, 러너는 그 `save_path`를 비운다(`run_tests.gd` 55~60줄). 러너의 `current_scene`은 null이고, 테스트는 화면을 `root` 아래에 붙여 쓴다. 그래서 테스트의 화면은 늘 "현재 씬이 아니다". 스모크(`day_smoke.gd`)는 실제 씬 전환을 지나므로 화면이 현재 씬이다.
- 번호: 019. 결정 번호는 171부터다(`docs/DECISIONS.md`의 끝이 170).

## 목표와 범위

**확인할 결과** (메인은 코드 읽기·Grep·값 대조·손 계산으로 확인한다. 실행 확인은 작업 8의 playtester 목록으로 넘긴다)

1. 카운터·정산·폐점·처음 화면의 "현재 씬일 때만 세션을 쓴다" 가드 12곳이 `day_ui.gd`의 도우미 하나(`Ui.current_session`)를 부른다. 트리 안에서는 전과 같은 갈래로 간다(F11).
2. 폐점에서 업그레이드를 산 뒤의 저장이 실패하면 "저장했다" 줄이 사라지고, 다시 적히면 돌아온다(F20).
3. `CLIENT_POS`가 `day_ui.gd` 한 곳에 있다(F17). `DayState._rng` 멤버가 없다(F15). 낡은 주석 셋이 지금 코드와 맞는다(F16).
4. 018 표의 나머지(F7, F8, F12, F13, F14, F18, F19, F21)와 닫힌 F9가 `docs/BACKLOG.md`에 "나중에 이 목록만 읽고 계획을 시작할 수 있는" 꼴로 있다.
5. 그 밖의 동작·값·규칙은 바뀌지 않는다. 기존 테스트 63개(018 뒤)의 통과 조건은 그대로이고, 새 테스트 둘(T63·T64)을 더해 통과하면 `ALL PASS 65/65`이다. 스모크는 고치지 않는다.

**범위 밖**: 보류 중인 값과 결정 전부. F7·F8(사용자가 "나중에"라고 했다. 목록으로만 옮긴다). 결투 씬(`duel_scene.gd` 143·202줄)과 의뢰 선택 화면(`commission_select.gd` 105줄)의 비슷한 현재 씬 확인(018 표에 없고 세션을 얻는 꼴도 다르다. 보고서 5번에 한 줄로만 적는다). 018의 실행 확인(사용자가 요청할 때 playtester가 018과 함께 본다).

## 작업 목록

**공통 규칙** (계획 012~018과 같다)

- 메인 에이전트는 Godot을 어떤 방식으로도 실행하지 않는다(`tests/run_tests.ps1`, `tests/run_smoke.ps1`, 헤드리스, `play.ps1` 전부). 확인은 파일 읽기, Grep, `git diff`, 손 계산뿐이다. 실행 확인은 사용자가 요청할 때 playtester가 한다(작업 8의 목록). 작업을 파일 하나씩 끊고, 작업마다 고친 함수를 다시 읽는다.
- 이미 있는 공개 함수의 시그니처는 바꾸지 않는다. 지우는 것은 `DayState._rng`(멤버), `counter.gd`·`settlement.gd`의 `CLIENT_POS`(상수)뿐이다.
- **새 `class_name`은 만들지 않는다.** 새 테스트 파일은 `extends RefCounted`이고 `preload`로만 불린다. `.uid` 파일은 만들지 않는다.
- 값은 건드리지 않는다: `data/` 아래 파일은 열지 않는다.
- 대조가 어긋나면 값을 맞추지 말고 멈춰서 보고한다.
- 새로 쓰는 주석은 "근거"의 주석 규칙을 따른다(한 줄, 까닭만). 아래 코드 조각의 주석이 그 꼴이다. 고치지 않는 줄의 주석은 그대로 둔다.
- 꼬리표(018과 같다): **[위험 수정]** 동작이 바뀐다. **[표기 수정]** 화면의 글만 바뀐다. **[동작 불변]** 주석·정리·테스트만.
- **스크립트를 하나 고칠 때마다 확인할 것**(새 테스트 파일도 같다):
  1. 들여쓰기: 고친 `.gd`에서 `^ +\S`를 Grep해 0건이다(탭만 쓴다).
  2. 같은 함수 안의 이름 겹침과 멤버 가리기. 작업마다 적은 이름을 본다. 전역 함수 이름(`seed`, `sign`, `str`, `min` 등)을 인자·지역 변수 이름으로 쓰지 않는다.
  3. Variant 추론: 고친 파일에서 `:= .*\.get\(`, `:= .*\.call\(`, `:= .*\[`를 Grep한다. 걸린 줄은 `int(...)`·`String(...)`으로 감싸거나 타입을 적는다.
  4. 서식 문자열: `%` 연산자의 자리 수와 인자 수가 같고, 글 안의 `%`는 `%%`다.
  5. `@warning_ignore("integer_division")`: 이번 계획에는 새 나눗셈이 없다.

### 작업 0. 시작 전의 기록 [동작 불변]

- `git log -1 --oneline`이 `2ffc964`(018)이고 `git status --short`에 이 계획 파일(`?? docs/plans/019-tidy-and-backlog.md`)과 `M CLAUDE.md`만 있는지 적는다. `CLAUDE.md`의 변경은 10장 끝의 주석 규칙 한 줄뿐인지 `git diff -- CLAUDE.md`로 보고 적는다. 그 한 줄은 예외로 두고 진행한다(문서이고, 작업 0이 막으려는 것은 코드 파일에서 018과 019가 섞이는 것이다). 그 밖의 변경이 있으면 멈추고 사용자에게 묻는다(018 위에 커밋 안 된 코드가 섞이면 가리는 순서가 무너진다). (v2, 기술 지적)
- 끝에서 `git diff --stat`과 `git status --short`를 다시 적어 견준다: 바뀐 파일이 작업 1~8에 적은 것뿐이다(스크립트 아홉, 테스트 둘, 문서 다섯: `BACKLOG.md`·`DECISIONS.md`·`CLAUDE.md`·`HANDOFF.md`·보고서. `data/`, `docs/plans/013-playtester.md`, `.claude/` 변경 없음). 018의 변경은 `git show 2ffc964 -- <파일>`, 019의 변경은 `git diff -- <파일>`로 가른다.

### 작업 1. 화면의 세션 가드를 도우미 하나로 [동작 불변] (F11)

- 대상: `scripts/day_ui.gd`, `scripts/title.gd`, `scripts/commission/counter.gd`, `scripts/economy/settlement.gd`, `scripts/economy/closing.gd`
- **어느 꼴로 맞추는가**: `is_inside_tree()`를 먼저 보는 꼴로 맞춘다. 트리 안에서는 두 꼴의 갈래가 같고, 트리 밖에서는 이 꼴만 오류 줄 없이 null로 끝난다. 그리고 세션을 찾기 **전에** 현재 씬인지 본다(트리 밖에서 `/root/…`를 찾지 않게).
- `day_ui.gd` — static 함수 둘을 `swallow_arrival_press` 바로 위에 더한다:

  ```
  ## 테스트는 화면을 root 아래에 붙여 쓰므로 현재 씬이 아니다: 그때는 씬을 바꾸거나 저장하지 않는다.
  static func is_current_scene(screen: Node) -> bool:
  	return screen.is_inside_tree() and screen.get_tree().current_scene == screen


  ## 트리 밖에서 절대 경로를 찾으면 엔진이 오류 줄을 찍으므로 현재 씬인지 먼저 본다.
  static func current_session(screen: Node) -> Node:
  	if not is_current_scene(screen):
  		return null
  	return screen.get_node_or_null(^"/root/GameSession")
  ```

  `swallow_arrival_press`의 첫 줄 `if not screen.is_inside_tree() or screen.get_tree().current_scene != screen:`을 `if not is_current_scene(screen):`로 바꾼다(드모르간으로 같은 식이다. 다음 줄 `return`과 그 아래는 그대로).
- 화면 넷의 12곳을 아래 두 꼴 가운데 하나로 바꾼다. 함수의 나머지 줄과 함수 위의 기존 주석은 그대로다.

  ```
  	# 가: 일찍 돌아오는 꼴 (전: if session == null or get_tree().current_scene != self: return)
  	var session := Ui.current_session(self)
  	if session == null:
  		return
  ```
  ```
  	# 나: 감싸는 꼴 (전: if session != null [and is_inside_tree()] and get_tree().current_scene == self:)
  	var session := Ui.current_session(self)
  	if session != null:
  		session.call(…)   (몸은 그대로)
  ```

  | 파일 | 함수 | 꼴 |
  |---|---|---|
  | `title.gd` | `_continue`, `_open_shop`, `_practice` | 가 |
  | `counter.gd` | `_quit` | 가 |
  | `counter.gd` | `_go`, `_return_to_title` | 나 |
  | `settlement.gd` | `_proceed`(`day.proceed()` 확인 뒤의 두 줄), `_return_to_title` | 나 |
  | `closing.gd` | `_quit` | 가 |
  | `closing.gd` | `_next_day`(`day.next_day()` 확인 뒤의 두 줄), `_return_to_title` | 나 |
  | `closing.gd` | `_save_now` | 작업 4가 최종 꼴을 쓴다(가 꼴에 한 줄을 더한다) |

  `title.gd`의 `_open_shop` 안의 주석 "# 다른 씬 아래에 붙어 있을 때(테스트)는 아무 데도 가지 않는다."는 이제 도우미의 주석과 같은 말이다. 그 줄은 고치는 줄의 바로 위라, 규칙대로 지운다.
- 그대로 두는 것: 네 화면의 `_ready`에서 세션을 읽는 `get_node_or_null`(카운터·정산·폐점은 `day`, 처음 화면은 저장. 가드가 아니라 읽기다), `closing.gd` `_build`에서 "저장했다"를 정하려고 세션을 읽는 줄(작업 4).
- 이름: 새 이름 `is_current_scene`, `current_session`이 `day_ui.gd`의 함수(`is_arrival_press`, `swallow_arrival_press`, `add_*`, `client_color`, `make_client`, `reputation_text`, `all_text`)와 겹치지 않는다. 화면 쪽의 지역 변수 `session`은 전과 같은 이름이다. 타입: `Ui.current_session`의 반환 타입이 `Node`라 `var session :=`가 `Node`로 추론된다(`session.call(…)`은 전과 같다).
- 테스트에서 어떻게 움직이는가:
  - 러너: 화면이 `root` 아래이고 `current_scene`이 null이다 → `is_current_scene` 거짓 → `current_session` null → 12곳 모두 전처럼 아무 데도 가지 않는다(T58 "라"의 두 번째 누름, T36·T33·T39의 `pressed.emit()`, reputation_tests의 `Buy_t_more_duels`). 오토로드가 떠 있어도 null이다.
  - 스모크: 화면이 현재 씬이다 → 오토로드를 돌려받는다 → 전처럼 씬을 바꾼다. 스모크가 12곳 가운데 `_open_shop`(Enter)·`_practice`·카운터 `_quit`·`_go`·정산 `_proceed`·폐점 `_next_day`·`_save_now`(살 때)를 실제로 지난다. 도우미가 늘 null을 돌려주는 실수는 스모크가 "씬이 바뀌지 않음"으로 잡는다.
  - 새 T63(작업 6)이 트리 밖·현재 씬 아님의 두 갈래를 본다.
- 완료 확인:
  - Grep `get_tree\(\)\.current_scene` → `scripts/title.gd`, `counter.gd`, `settlement.gd`, `closing.gd`에서 0건. `day_ui.gd`에서 1건(`is_current_scene`). (`duel_scene.gd`·`commission_select.gd`의 것은 범위 밖이라 남는다.)
  - Grep `Ui\.current_session\(self\)` → `title.gd` 3, `counter.gd` 3, `settlement.gd` 2, `closing.gd` 4, 합 12.
  - Grep `get_node_or_null\(\^"/root/GameSession"\)` → 화면 넷에서는 `_ready`의 넷과 `closing.gd` `_build`의 하나만 남는다. `day_ui.gd`에 1건.
  - 12곳을 하나씩 손으로 따라간다: 트리 안에서 현재 씬이면 세션을 받아 전과 같은 호출, 아니면 전과 같은 되돌아옴. 감싸는 꼴의 함수는 몸이 그대로다.
  - 공통 규칙 다섯 가지. 서식: 바뀐 것이 없다.

### 작업 2. 의뢰인의 자리를 한 곳에 [동작 불변] (F17)

- 대상: `scripts/day_ui.gd`, `scripts/commission/counter.gd`, `scripts/economy/settlement.gd`
- `day_ui.gd` — `CLIENT_SIZE` 바로 아래에:

  ```
  ## 카운터와 정산이 같은 자리를 써야 화면이 바뀔 때 의뢰인이 튀지 않는다.
  const CLIENT_POS := Vector2(120, 164)
  ```

- `counter.gd` — 8~9줄(`## 의뢰인이 서는 자리와 미끄러져 들어오는 시간.`과 `const CLIENT_POS := …`)을 지운다. `const SLIDE_TIME := 0.45`는 그대로 두고 그 위 주석은 두지 않는다(이름이 말한다. 주석 규칙). `_build`의 `CLIENT_POS` 두 곳(`Vector2(-Ui.CLIENT_SIZE.x, CLIENT_POS.y)`, `tween_property(client, "position", CLIENT_POS, SLIDE_TIME)`)을 `Ui.CLIENT_POS`로.
- `settlement.gd` — 6줄 `const CLIENT_POS := …`와 그 아래 빈 줄 하나를 지운다. `_build`의 `client.position = CLIENT_POS`를 `Ui.CLIENT_POS`로.
- 값이 같다: 지우는 두 상수와 새 상수가 모두 `Vector2(120, 164)`다(018 뒤 파일에서 planner가 읽음).
- 이름: `Ui.CLIENT_POS`가 `day_ui.gd`의 상수(`BACKGROUND`, `COUNTER_COLOR`, `COUNTER_TOP_COLOR`, `GOLD`, `RED`, `DIM`, `COUNTER_Y`, `CLIENT_SIZE`, `ARRIVAL_GUARD_MSEC`)와 겹치지 않는다.
- 완료 확인: Grep `CLIENT_POS` → `day_ui.gd` 정의 1, `counter.gd` 2(모두 `Ui.CLIENT_POS`), `settlement.gd` 1(`Ui.CLIENT_POS`). Grep `const CLIENT_POS` → `day_ui.gd`만. 테스트에서 `CLIENT_POS`를 부르는 곳이 없다(planner Grep 0건). 공통 규칙 다섯 가지.

### 작업 3. 흥정 주사위의 씨앗을 뽑는 난수를 지역 변수로 [동작 불변] (F15)

- 대상: `scripts/economy/day_state.gd`
- 64~65줄(`## 흥정 주사위의 씨앗을 뽑는다(새로 시작할 때 한 번).`과 `var _rng := RandomNumberGenerator.new()`)을 지운다.
- `_init`의 첫 두 줄 `_rng.randomize()`·`dice_seed = _rng.randi()`를 이렇게:

  ```
  	var seed_rng := RandomNumberGenerator.new()
  	seed_rng.randomize()
  	dice_seed = seed_rng.randi()
  ```

- 같은 동작: 전에도 멤버는 `_init`에서 만들어지고(멤버 초기화는 `_init`보다 먼저 돈다) 이 두 줄에서만 쓰였다. 뽑는 범위(`randi`, 0~`DICE_SEED_MAX`)와 때(새로 만들 때 한 번, `restore`가 저장의 씨앗으로 덮는다)가 같다.
- 이름: `seed_rng`는 `_init`의 인자(`p_rules`, `p_data`, `p_catalog`, `p_schedule`, `p_reputation`)와 멤버와 겹치지 않는다. 전역 함수 `seed`를 쓰지 않는다. `haggle_roll`의 지역 `dice`와는 다른 함수다.
- 완료 확인: Grep `_rng` → `scripts/`·`tests/`에서 0건(`opponent_brain.gd`의 `p_rng`·`rng`는 `\b_rng\b`에 걸리지 않는다. Grep 식은 `\b_rng\b`). Grep `seed_rng` → `day_state.gd`의 `_init`에 3건. 공통 규칙 다섯 가지.

### 작업 4. 폐점의 "저장했다"가 마지막 쓰기를 따른다 [표기 수정] (F20)

- 대상: `scripts/economy/closing.gd`
- 지금: `_build`가 폐점이 열릴 때 한 번 `GameSession.saved_day`를 보고 `SavedNote`를 만든다. 그 뒤 살 때의 저장(`_save_now`)이 실패하면(`saved_day = 0`, `game_session.gd` 102~105줄) 줄이 그대로 남아 "저장했다"고 거짓을 말한다.
- 바꾼 뒤: 살 때마다 저장의 결과로 줄을 다시 정한다. 실패하면 숨기고, 들어설 때 실패했더라도 산 뒤에 적히면 보인다. 실패를 알리는 새 글은 더하지 않는다(들어설 때 실패한 지금의 폐점에도 줄이 없을 뿐이다. 경고는 `GameSession`이 출력에 찍는다).
- 무엇:
  - 멤버: `var _buy_upgrades: Array[UpgradeData] = []`(26줄) 바로 아래, `_opened_msec`의 `##` 주석(27줄 "화면이 열린 때 …") **위**에 두 줄을 넣는다. 그래야 27줄의 주석이 그대로 `_opened_msec`에 붙는다(v2, 기술 제안 2):

    ```
    ## 숨기기만 하고 지우지 않는다(같은 프레임에 지운 노드가 이름을 차지해 새 노드가 다른 이름을 받는다).
    var _saved_note: Label
    ```

  - `_build`의 116~123줄(주석 한 줄, `var session := …`, `if session != null and int(…) == day.day_number + 1:`과 그 아래 Label 다섯 줄)을 이렇게. 첫 주석 줄은 그대로 둔다:

    ```
    	# 이 실행에서 내일의 아침을 적는 데 성공했을 때만 알린다(세션이 없거나 저장이 꺼져 있으면 없다).
    	var session := get_node_or_null(^"/root/GameSession")
    	if session != null:
    		refresh_saved_note(int(session.get("saved_day")))
    ```

    여기는 `Ui.current_session`을 쓰지 않는다: 전처럼 테스트가 붙인 폐점도 오토로드의 `saved_day`를 읽는다(러너에서는 0이라 줄이 없다. T58 "바").
  - 함수 하나(`_build_shop` 위):

    ```
    ## saved_day는 GameSession.saved_day다(마지막 쓰기가 실패했으면 0). 테스트가 직접 넣는다.
    func refresh_saved_note(saved_day: int) -> void:
    	var saved_now := day != null and saved_day == day.day_number + 1
    	if _saved_note == null:
    		if not saved_now:
    			return
    		_saved_note = Ui.add_label(self, SAVED_NOTE % (day.day_number + 1), 16, Ui.DIM)
    		_saved_note.name = "SavedNote"
    		_saved_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    		_saved_note.position = Vector2(268, 650)
    		_saved_note.size = Vector2(590, 24)
    	_saved_note.visible = saved_now
    ```

    글·크기·색·자리는 지금의 다섯 줄 그대로다.
  - `_save_now`의 최종 꼴(작업 1의 가 꼴에 한 줄). 함수 위의 기존 주석은 그대로:

    ```
    func _save_now() -> void:
    	var session := Ui.current_session(self)
    	if session == null:
    		return
    	session.call("save_game")
    	refresh_saved_note(int(session.get("saved_day")))
    ```

- 바뀌지 않는 것: 들어설 때의 판단(같은 식 `saved_day == day.day_number + 1`), 저장이 꺼진 때(`save_path` 비어 있음 → `save_game`이 `saved_day`를 건드리지 않고 false → 0 그대로 → 줄 없음), 줄의 글과 자리, 살 수 있는가(`refresh_shop`).
- 손으로 따라간다(폐점 1일차, 내일은 2):
  - 들어설 때 성공(`saved_day` 2) → 줄이 생기고 보인다. 사서 성공(2) → 보인다. 사서 실패(0) → 숨는다. 다시 사서 성공(2) → 같은 노드가 다시 보인다.
  - 들어설 때 실패(0) → 줄이 없다. 사서 성공(2) → 줄이 생긴다(전에는 끝까지 없었다).
  - 러너·스모크: `save_path`가 비어 `saved_day`가 0 → 줄이 없다(T58 "바" 그대로). 스모크의 구매는 `_save_now`에서 `refresh_saved_note(0)` → 아무것도 만들지 않는다.
- 이름: 새 멤버 `_saved_note`, 새 함수 `refresh_saved_note`, 인자 `saved_day`, 지역 `saved_now`가 폐점의 이름(`day`, `shown_profit`, `shown`, `shown_money`, `_proceed`, `_money_label`, `_hint`, `_reputation_ledger`, `_buy_buttons`, `_buy_upgrades`, `_opened_msec`, `refresh_shop`, `ledger_amount`, `reputation_ledger_text`, `_build_shop`, `_buy`, `_save_now`, `_next_day`, `_quit`, `_return_to_title`)와 겹치지 않는다. `_build` 안의 다른 지역(`header`, `book`, `line`, `declined`, `names`, `missed`, `missed_line`, `gap`, `profit_text`, `profit`, `quit`, `session`)과도 겹치지 않는다(`saved_note` 지역은 없어진다).
- 완료 확인: Grep `SavedNote` → `closing.gd` 1건(`refresh_saved_note` 안). Grep `refresh_saved_note` → 정의 1, `_build` 1, `_save_now` 1. Grep `saved_day` → `closing.gd` 5줄: `_build`의 호출 1, `refresh_saved_note` 위 주석 1, 시그니처 1, 본문의 `var saved_now := …` 1, `_save_now`의 호출 1(v2, 기술 제안 1. 계획의 코드 조각을 다시 센 수다. 수가 다르면 멈춘다). 멤버 `_saved_note`의 주석과 `SAVED_NOTE` 상수에는 `saved_day`가 없다. 공통 규칙 다섯 가지. 서식: `SAVED_NOTE % (day.day_number + 1)`(자리 하나, 그대로).

### 작업 5. 낡은 주석 셋 [동작 불변] (F16)

- 대상: `scripts/economy/economy_rules.gd`, `scripts/game_session.gd`, `scripts/economy/reputation_rules.gd`. 주석 한 줄씩만 바꾼다(코드 줄 변경 없음).

| 파일:줄 | 지금 | 바꾼 뒤 | 맞는지 본 곳 |
|---|---|---|---|
| `economy_rules.gd:15` | `## 지금은 평판(별)이 그날의 사본에만 더한다(DayState.settle_rules).` | `## 그날의 평판(별)과 받아 준 흥정은 사본에만 더한다(DayState._rules_with_haggle).` | `day_state.gd` `_rules_with_haggle`의 `base_bonus_percent +=` 두 줄(315·317). `data/`에 이 필드를 적은 `.tres`는 없다 |
| `game_session.gd:11` | `# 씬 경로는 문자열로 둔다(preload하면 아직 없는 씬 때문에 이 스크립트가 로드되지 않는다).` | `# 씬 경로는 문자열로 둔다: change_scene_to_file과 테스트의 _spawn_screen이 경로로 부르고, preload하면 오토로드가 씬 넷을 미리 불러온다.` | `go_to_phase_scene`, `tests/day_tests.gd` `_spawn_screen`(`load(path)`), 테스트의 `Session.*_PATH` 23곳. `DECISIONS.md` 171줄(계획 004의 기록)은 그때의 것이라 고치지 않는다 |
| `reputation_rules.gd:6` | `## 값은 data/reputation_rules.tres에 있다. 아래 기본값은 그 파일의 눈금과 맞춰 둔 것이다.` | `## 값은 data/reputation_rules.tres에 있다. 기본값은 그 파일과 같되 pay_percent·day_scale만 일부러 비워 둔다(그 필드의 주석).` | `.tres`의 여덟 값을 기본값과 대조: `enabled`·`start` 20·`min_value` 0·`max_value` 44·`star_thresholds` 8·16·24·38·`guest_delta` −2~2·`perfect_bonus` 2는 같고, `pay_percent`·`day_scale`만 다르다(기본값은 빈 배열) |

- 완료 확인: 세 파일의 `git diff`가 각각 한 줄 바뀜이다. Grep "아직 없는 씬", "지금은 평판(별)이", "눈금과 맞춰" → `scripts/`에서 0건.

### 작업 6. 테스트 — 새 테스트 둘(T63·T64) [동작 불변]

**기존 테스트 파일의 통과 조건은 고치지 않는다**(바뀌는 것은 `run_tests.gd`의 한 줄). 018의 `tests/safety_tests.gd`에 더하지 않고 새 파일로 둔다: 로드 오류가 나면 파일 이름만으로 018과 019를 가를 수 있다.

- 대상: `tests/tidy_tests.gd`(새 파일), `tests/run_tests.gd`(`TEST_FILES`의 끝, `"res://tests/safety_tests.gd",` 아래에 `"res://tests/tidy_tests.gd",` 한 줄)
- 틀: `tests/safety_tests.gd`와 같다(`extends RefCounted`, `var _tree: SceneTree`, `var _d := Day.new()`, `list(tree)`에서 `_d.set("_tree", tree)`, `cleanup()`에서 `_d.cleanup()`·`_d = null`·`_tree = null`, `_expect`, `_result`). 파일을 쓰지 않으므로 `Store`와 `TEST_PATH`는 없다.
- 상수: `Day`(`res://tests/day_tests.gd`), `Session`(`res://scripts/game_session.gd`), `Ui`(`res://scripts/day_ui.gd`).
- 머리 주석 한 줄: `## T63·T64: 계획 019의 정리 가운데 테스트로 볼 수 있는 둘. 현재 씬인 갈래는 러너에서 만들 수 없어 스모크가 본다.`

**T63 "화면의 세션 가드: 트리 밖과 현재 씬이 아닌 화면은 세션을 받지 않는다"**

| # | 무엇 | 기대 |
|---|---|---|
| 가 | `Control.new()`를 트리에 붙이지 않고 | `Ui.is_current_scene` 거짓, `Ui.current_session` null. (도우미가 트리를 먼저 보지 않으면 여기서 엔진이 `ERROR:` 줄을 찍어 러너의 통과 판정이 깨진다 — 그것도 이 칸의 확인이다) |
| 나 | 같은 노드를 `_tree.root.add_child` 한 뒤 | `Ui.is_current_scene` 거짓, `Ui.current_session` null. 이때 `_tree.root.get_node_or_null(^"GameSession")`이 null이 아니면(러너에 오토로드가 떠 있다) 메시지 없이 지나가고, null이면 그것을 실패로 치지 않는다(도우미의 답은 어느 쪽이든 null이어야 한다) |

- 확인 뒤 `free()`. `_tree.current_scene`은 건드리지 않는다(러너의 상태를 바꾸지 않는다). 현재 씬일 때 세션을 돌려주는 갈래는 스모크가 지난다(작업 1의 "테스트에서 어떻게 움직이는가").

**T64 "폐점의 '저장했다': 마지막 쓰기의 결과를 따른다"**

| # | 무엇 | 기대 |
|---|---|---|
| 가 | `DayState.new(_d._rules(70, 60, 20, 250), _d._three_fixed())`에 `_d._run_fixed_day` → `_d._spawn_screen(Session.CLOSING_PATH, day)` | 붙인 폐점에 `SavedNote`가 없다(러너의 `saved_day`는 0) |
| 나 | 이어서 `closing.call("refresh_saved_note", day.day_number + 1)` | `SavedNote`(Label)가 있고 보이며, 글에 `%d일차` % (`day.day_number + 1`)가 있다 |
| 다 | 이어서 `refresh_saved_note(0)` | 같은 노드가 있고(`find_children("SavedNote", "Label", true, false)`가 1개) 보이지 않는다 |
| 라 | 이어서 `refresh_saved_note(day.day_number + 1)` | 같은 노드 하나가 다시 보인다 |
| 마 | 같은 규칙의 새 하루를 같은 꼴로 끝내 새 폐점을 붙이고 `refresh_saved_note(0)` | `SavedNote`가 없다(실패한 쓰기는 줄을 만들지 않는다) |

- 붙인 화면은 쓰고 나서 `free()`한다.
- `_d._run_fixed_day`가 하루를 폐점(`Phase.CLOSING`)에서 멈추는지는 T58 "바"(`save_tests.gd` 453~454줄)와 018의 T62 "라"가 같은 꼴로 쓴다. 실행할 때 메인은 `day_tests.gd`의 `_run_fixed_day`(654줄 근처)를 다시 읽어 확인한다.
- **선언 대조**(새 파일을 쓴 뒤. 로드되지 않으면 러너가 거기서 멈춘다):
  - 상수 셋이 파일 머리에 있다.
  - 부르는 `_d.` 도우미가 `tests/day_tests.gd`에 있다: `_rules`, `_three_fixed`, `_run_fixed_day`, `_spawn_screen`, `_has_node`, `cleanup`(실행 때 Grep `^func _rules\(` 등으로 줄을 적는다).
  - 글로 부르는 이름이 스크립트와 같다: 노드 `SavedNote`, 메서드 `refresh_saved_note`, `Ui.is_current_scene`·`current_session`, `Session.CLOSING_PATH`.
  - 지역 변수 이름으로 `list`를 쓰지 않는다. Variant: `find_child(…) as Label`, `find_children(…)`의 결과는 `Array[Node]`로 받는다. `_d._spawn_screen`의 결과는 `var closing: Node =`로 타입을 적는다.
- 기존 테스트를 **읽어서** 확인한다:
  - T58 "라"(`save_tests.gd` 425~435): `_open_shop`이 018의 잠금으로 먼저 돌아온다. 잠금이 풀린 뒤라도 도우미가 null을 돌려준다.
  - T58 "바"(447~456): `SavedNote` 없음 — 작업 4의 `_build`가 `refresh_saved_note(0)`이라 그대로 참.
  - T33·T36·T39와 reputation_tests의 폐점 구매: 붙인 화면에서 `pressed.emit()` → 12곳이 null로 돌아온다(전과 같다). `_buy`의 `_save_now`가 null로 돌아오므로 `refresh_saved_note`도 불리지 않는다.
  - 스모크: 세 화면과 처음 화면의 씬 전환, 폐점의 구매 → 작업 1·4의 손 따라가기대로 그대로 통과한다.
  - 통과하면 마지막 줄이 `ALL PASS 65/65`다(018 뒤 63 + 2).
- 완료 확인(작업 6): 새 파일에 공통 규칙 다섯 가지와 선언 대조. 이 계획이 `run_tests.gd`에 더한 줄이 하나다. 다른 기존 테스트 파일에 이 계획의 변경이 없다(`git diff --stat`).

### 작업 7. 나중에 고칠 목록 — `docs/BACKLOG.md` (새 파일) [동작 불변]

- **어디에**: 새 파일 `docs/BACKLOG.md`. 까닭: `docs/HANDOFF.md`는 세션을 넘길 때마다 지금 상태로 다시 쓰이는 파일이라 오래 둘 목록이 묻힌다. `DECISIONS.md`는 정한 것의 기록이고, 보고서는 계획마다 흩어진다. 앞으로 다른 계획이 "나중에"로 남기는 고칠 거리도 이 파일에 모은다.
- **무엇과 무엇을 가르는가**: BACKLOG는 **코드·화면을 고칠 거리**다(고치기 전에 사용자가 정할 것이 있으면 항목 안에 적는다). 사용자가 보류한 **값과 결정**(승리 +1, 확률표 등)은 지금처럼 `HANDOFF.md` 3번과 보고서 4번에 둔다. BACKLOG 머리에 그곳을 가리키는 한 줄을 둔다(옮기지 않는다).
- **항목의 꼴**: ID는 `<계획 번호>-<그 계획의 번호>`(예: `018-F7`). 항목마다 일곱 칸: 위치 / 무엇이 문제인가 / 지금 그대로 둔 까닭 / 고칠 방향과 후보 안 / 고치기 전에 사용자가 정할 것 / 손댈 파일과 테스트 / 다시 볼 때. 위치는 줄 번호가 흔들리므로 **파일 · 함수 · 찾을 글**로 적고, 줄 번호는 019 뒤의 것을 괄호에 둔다(메인이 작업 1~5를 끝낸 뒤 Grep으로 채운다. 아래의 `(줄 ?)`).
- **고치면**: 그 항목을 "닫힌 것"으로 옮겨 한 줄(ID, 닫은 계획, 한 일)만 남긴다.
- 메인은 아래 블록을 그대로 `docs/BACKLOG.md`에 옮긴다(`(줄 ?)`만 채운다).

````markdown
# 나중에 고칠 것

고치지 않고 미룬 코드·화면의 고칠 거리다. 새 계획은 여기서 항목 하나를 골라 바로 시작할 수 있다.
사용자가 보류한 값과 결정(승리 +1, 흥정의 확률표 등)은 여기 없다: `docs/HANDOFF.md` 3번과 계획 012~018 보고서의 4번에 있다.

- ID는 `<계획 번호>-<그 계획의 번호>`다. 위치는 파일 · 함수 · 찾을 글이고, 괄호의 줄 번호는 적은 때의 것이다.
- 고치면 그 항목을 아래 "닫힌 것"으로 옮겨 한 줄만 남긴다.

## 사용자가 먼저 정할 것이 있는 항목

### 018-F7 폐점의 소지금 줄

- 위치: `scripts/economy/closing.gd` `_build`의 `"소지금   %d → %d"` (줄 ?). 값은 `scripts/economy/day_state.gd` `_enter_closing`의 `"money_before"`(수입을 더한 뒤, 지출을 빼기 전)와 `"money_after"`.
- 문제: 왼쪽이 그날의 수입을 이미 더한 소지금이라, `소지금 -18 → -78`과 `오늘의 손익 +42`를 함께 읽으면 셈이 맞지 않아 보인다(playtester, 계획 014 보고서 끝).
- 그대로 둔 까닭: 버그가 아니라 무엇을 보여 줄지의 문제다. 계획 018 보고서 4번의 2번으로 물었고, 사용자가 "나중에"라고 했다(2026-11-21).
- 방향과 후보: 가(권함) 왼쪽을 그날 아침의 소지금으로 — 화면에서 `money_before − income`을 적는다(그날 아침부터 폐점까지 소지금은 정산의 받은 돈으로만 바뀐다. 구매는 폐점 뒤다). 그러면 오른쪽 − 왼쪽 = 오늘의 손익이다. 나 줄을 `소지금 Y`로 줄인다. 다 지금 값 그대로 두고 낱말로 가른다(`닫기 전 X → 닫은 뒤 Y`).
- 사용자가 정할 것: 가 / 나 / 다.
- 손댈 파일과 테스트: `closing.gd` 한 줄. 요약의 `money_before`는 뜻을 바꾸지 않는다 — T31(`tests/day_tests.gd` `t31_day_state`의 `money_before == 152`)과 스모크(`tests/day_smoke.gd`의 `summary.get("money_before") != _money_mark`)가 그 뜻을 본다. 폐점의 이 줄을 글로 보는 테스트는 없다 → 새 테스트 한 칸(018 T62 "다"의 꼴: 붙인 폐점의 `Ui.all_text`에서 그 줄을 찾는다).
- 다시 볼 때: 2단계 완료 판정 전에 사용자가 장부를 다시 볼 때. 늦어도 4단계(아트 교체)의 UI 작업.

### 018-F8 정산·폐점의 평판 줄의 자리

- 위치: `scripts/economy/settlement.gd` `_build`의 `"ReputationLine"`(`Vector2(432, 512)`, 줄 ?), `scripts/economy/closing.gd` `_build`의 `"ReputationLedger"`(`Vector2(40, 585)`, 줄 ?).
- 문제: 평판 줄이 어두운 패널 밖에 떠 있다. 잘리거나 겹치지는 않는다(playtester, 계획 014 보고서 끝).
- 그대로 둔 까닭: 정산의 장부 패널(`Rect2(410, 186, 830, 324)`)에 넣으면 한 줄만큼 자라 카운터 띠(y 540)에 닿을 수 있다(어림: 안쪽 높이 약 327px > 324 − 여백 32). 화면으로 보며 맞춰야 한다. 계획 018 보고서 4번의 3번으로 물었고 사용자가 "나중에"라고 했다.
- 방향과 후보: 가 패널 안으로 넣고 패널 안의 간격(`separation` 10)이나 `받은 돈` 글자(28)를 줄여 높이를 맞춘다. 나 평판만의 작은 패널을 하나 더 둔다(정산은 패널과 버튼 사이 y 512~580, 폐점은 장부 아래 y 585~630). 다 그대로 둔다.
- 사용자가 정할 것: 옮길지, 옮기면 가 / 나.
- 손댈 파일과 테스트: `settlement.gd`, `closing.gd`. 테스트는 노드 이름(`ReputationLine`, `ReputationLedger`)과 글로 찾는다 → 이름을 지키면 그대로다. 자리는 테스트가 보지 않으므로 playtester가 화면으로 본다(의뢰 줄이 많은 폐점, 다친 정산을 함께).
- 다시 볼 때: 4단계(아트 교체)에서 패널이 바뀔 때 함께. 그 전에 사용자가 거슬린다고 하면 먼저.

## 그대로 둔 것 (고칠 까닭이 생기면 볼 것)

### 018-F12 `DayState`의 크기

- 위치: `scripts/economy/day_state.gd` 전체(약 575줄). 파일 안은 절 주석(`# ---- 순수 함수`, 읽기, 저장, 전환)으로 나뉘어 있다.
- 문제: 경제의 순수 함수·읽기·흥정·저장·하루의 전환이 한 파일에 있다.
- 그대로 둔 까닭: 결정 152·169. 갈라내면 `DayState.payout`·`settle`·`boosted_*` 등을 부르는 약 37곳(`counter.gd` 4, 테스트 33)을 실행 없이 바꿔야 한다. 위험이 이득보다 크다.
- 방향과 후보: 가 순수 함수(`round_div`, `pay_score`, `payout`, `boosted_base_max`, `boosted_tip_max`)를 `scripts/economy/economy_math.gd`(`class_name` 없이 `preload`)로 옮기고, `DayState`에 같은 이름의 static 위임을 남긴다 → 부르는 곳을 고치지 않는다. 나 저장(`saved_state`, `restore`, `is_readable_save`, `_known_ids`)을 같은 꼴로 옮긴다. 가부터 한다.
- 사용자가 정할 것: 없다.
- 손댈 파일과 테스트: `day_state.gd`와 새 파일 하나. 기존 테스트(T29~T31, T45, T55~T57 등)가 지킨다. 실행 확인이 꼭 필요하다(playtester).
- 다시 볼 때: CLAUDE.md 5장의 "아직 없는 것"(칼 수리비, 부상에 따른 의뢰 수 감소)을 `DayState`에 더하는 계획에서, 또는 파일이 700줄을 넘을 때.

### 018-F13 테스트 도우미의 복사

- 위치: `tests/`의 13개 파일(019 뒤)의 `_expect`·`_result`, 4개 파일(`client_line_tests.gd`, `haggle_tests.gd`, `reputation_tests.gd`, `save_tests.gd`)의 `_rep_rules`.
- 문제: 같은 도우미가 파일마다 있다.
- 그대로 둔 까닭: `_expect`·`_result`는 모든 묶음이 따르는 꼴이라 각 파일이 혼자 읽힌다. 합치면 13개 파일을 실행 없이 고친다. `_rep_rules` 넷은 값이 다르다(`reputation_tests.gd`는 손님 증감 −2~+2와 시작값 인자, 나머지 셋은 증감 0) — 같은 것이 아니다.
- 방향과 후보: 가 `tests/test_util.gd`(`class_name` 없이)에 `expect`·`result`를 두고, 새 테스트 파일부터 쓴다(옛 파일은 그대로). 나 한꺼번에 바꾼다(실행 확인 필수). `_rep_rules`는 합치지 않는다.
- 사용자가 정할 것: 없다.
- 손댈 파일과 테스트: 가는 새 파일 하나. 나는 테스트 13개 파일 전부.
- 다시 볼 때: 테스트 파일을 새로 만드는 계획이 이어지거나, 도우미의 꼴을 바꿀 일이 생길 때(예: 실패 메시지에 칸 번호를 붙이기).

### 018-F14 규칙의 사본

- 위치: `scripts/economy/day_state.gd`의 `effective_rules()`, `settle_rules()`(그리고 `haggle_preview_rules()`, `haggle_refused_rules()`. 모두 `_rules_with_haggle`을 지난다).
- 문제: 부를 때마다 규칙의 사본을 만든다. 카운터를 한 번 열 때 약 8번, 흥정 한 번에 약 5번.
- 그대로 둔 까닭: 필드 열다섯의 작은 Resource이고, 프레임마다가 아니라 화면을 만들 때와 누를 때만이다. 캐시를 두면 "산 뒤에 다시 센다"(`closing.gd` `refresh_shop`) 같은 곳에서 낡은 값을 읽을 위험이 생긴다.
- 방향과 후보: 가 그대로. 나 고쳐야 하면 캐시가 아니라 부르는 쪽에서 한 번 받아 넘긴다(`counter.gd` `_build`와 `_refresh_haggle`).
- 사용자가 정할 것: 없다.
- 손댈 파일과 테스트: `counter.gd`(나). 기존 테스트가 지킨다.
- 다시 볼 때: 이 함수를 프레임마다 부르는 코드가 생길 때(예: 결투 화면에 보수를 띄울 때).

### 018-F18 규칙 기본값과 `.tres`의 차이

- 위치: `scripts/economy/economy_rules.gd`의 기본값과 `data/economy_rules.tres`(`full_pay_score` 100 / 80, `haggle_*` 0·빈 표 / 30·표 등). `scripts/economy/reputation_rules.gd`의 `pay_percent`·`day_scale`(빈 배열)과 `data/reputation_rules.tres`.
- 문제: 코드의 기본값이 실제 게임의 값과 다르다. 처음 읽는 사람이 헷갈린다.
- 그대로 둔 까닭: 일부러다. 테스트가 `EconomyRules.new()`·`ReputationRules.new()`로 만든 규칙은 "그 기능이 꺼진 것"으로 움직여야 한다(각 필드의 주석. 019가 `reputation_rules.gd` 머리 주석을 이 뜻으로 고쳤다).
- 방향과 후보: 가 그대로. 새 필드를 더할 때 "기본값은 꺼진 것" 규칙을 지킨다. 나 테스트가 쓸 "꺼진 규칙"을 도우미로 만들고 기본값을 `.tres`와 맞춘다(테스트 대부분을 고친다. 권하지 않는다).
- 사용자가 정할 것: 없다.
- 손댈 파일과 테스트: (나) 두 규칙 스크립트와 그 규칙을 `new()`로 만드는 테스트 전부.
- 다시 볼 때: 경제·평판에 새 필드를 더하는 계획마다(그 필드의 기본값을 정할 때).

### 018-F19 정산 머리 줄의 분모(`오늘의 결투 2/3`으로 끝나는 날)

- 위치: `scripts/economy/settlement.gd` `_build`의 `"%d일차 · 오늘의 결투 %d/%d 정산"` (줄 ?). 분모는 `rules.duels_per_day`다.
- 문제: 손님을 돌려보내 남은 손님(지금 + 문밖)이 남은 결투보다 적어진 날(018-F5와 같은 경우)에는, 그날 마지막 정산의 머리 줄이 `오늘의 결투 2/3`처럼 끝난다. 버튼은 "가게를 닫는다"인데 머리 줄은 결투가 하나 남은 것처럼 읽힌다. 평판의 별로 손님 수가 줄어서는 생기지 않는다(손님 수는 그날의 결투 수 아래로 줄지 않는다. CLAUDE.md 6장). 돌려보내기는 평소 플레이에서 흔하므로 이미 일어나고 있는 일이다.
- 그대로 둔 까닭: 하루의 결투 자리 수를 적는 줄이라 거짓은 아니다. 018은 같은 원인의 카운터 머리 줄("오늘 남은 결투", 018-F5)만 고쳤다. 그 줄은 남은 것을 세어 칠 수 없는 결투까지 셌고, 이 줄은 자리 수를 적는다. 사용자가 이번에 고칠 것으로 고르지 않았다(2026-11-21).
- 방향과 후보: 가 그대로. 나 분모를 `min(결투 자리, 오늘 치른 결투 + 문밖 손님)`(`mini(rules.duels_per_day, day.results.size() + day.waiting_count())`)으로 한다. 카운터의 018-F5와 같은 뜻이다(칠 수 있는 결투). 돌려보낸 날의 마지막 정산이 `2/2`로 끝난다. 다 분모를 지우고 `오늘의 결투 2번째`로 적는다.
- 사용자가 정할 것: 가 / 나 / 다. 분모가 결투 자리 수인가, 칠 수 있는 결투 수인가.
- 손댈 파일과 테스트: `settlement.gd` 한 줄. 이 줄을 글로 보는 테스트가 있는지 먼저 Grep한다(`오늘의 결투`). 새 칸 하나: 손님 셋·결투 셋의 하루에서 하나를 돌려보내고 둘을 치른 뒤의 정산 `Header`(018 T62 "가"의 꼴).
- 다시 볼 때: 사용자나 playtester가 정산의 분모를 헷갈려 할 때. 2단계 완료 판정 때 장부·머리 줄을 함께 볼 때(018-F7과 함께). 늦어도 4단계 UI.

### 018-F21 손으로 고친 저장의 아주 큰 수

- 위치: `scripts/economy/day_state.gd` `restore`의 `day_number = maxi(int(saved["day"]), 1)`과 `money = int(saved["money"])` (줄 ?).
- 문제: 손으로 고친 저장의 아주 큰 실수(예: `1e30`)는 `int()`에서 값이 뒤틀린다(날은 1 이상으로 자르지만 위로는 자르지 않는다. 소지금은 자르지 않는다).
- 그대로 둔 까닭: 파일을 손으로 고친 경우뿐이다. 결정 151이 막으려던 것은 깨진 파일과 모르는 id다. 평판과 주사위 씨앗은 이미 범위로 자른다.
- 방향과 후보: `int()` 전에 `clampf`로 자른다(날 1~9999, 소지금 −1,000,000~1,000,000 같은 넉넉한 범위). 범위는 planner가 정해도 된다.
- 사용자가 정할 것: 없다.
- 손댈 파일과 테스트: `day_state.gd` 두 줄. `tests/save_tests.gd`에 칸 하나(`{"day": 1e30, …}`를 되돌려 날·소지금이 범위 안).
- 다시 볼 때: 저장의 형식을 바꾸는 계획(버전 2)에서, 또는 사용자가 저장을 손으로 고쳐 쓰기 시작할 때.

## 닫힌 것

- 018-F9 — 닫음(계획 018, 문제 아님). T53의 이름 `9 → 10 → 12 → 16 → 13, 손님 3 → 5 → 3 → 7`은 테스트 안의 날마다 끝의 평판과 손님 수와 같다.
- 018-F11, F15, F16, F17, F20 — 고침(계획 019). 화면의 세션 가드를 `Ui.current_session` 하나로, `DayState._rng`를 지역 변수로, 낡은 주석 셋, `CLIENT_POS`를 `day_ui.gd`로, 폐점의 "저장했다"가 마지막 쓰기를 따른다.
- 018-F1~F6, F10 — 고침(계획 018).
````

- 완료 확인: `docs/BACKLOG.md`가 있고 항목 여덟(F7, F8, F12, F13, F14, F18, F19, F21)이 일곱 칸을 다 갖는다. `(줄 ?)`가 남지 않았다(Grep `줄 \?` 0건). 적힌 위치의 찾을 글이 지금 파일에 있다(항목마다 Grep 한 번).

### 작업 8. 기록과 보고

- `docs/DECISIONS.md`: 2026-11-21 계획 019 절. 사용자 지시 원문, 결정 171~175 한 줄씩(아래 "설계 결정"), 기록 넷: "018 표의 F11 '6곳과 6곳'은 4곳과 8곳이었다", "018 표 F19의 '손님이 결투 수보다 적은 날'은 손님을 돌려보내 남은 손님이 남은 결투보다 적어진 날이다(별로는 손님이 결투 수 아래로 줄지 않는다. v2, D1)", "`--script` 러너의 화면은 늘 현재 씬이 아니라, 세션 가드의 현재 씬 갈래는 스모크만 지난다", "값은 하나도 바꾸지 않았다. 테스트·게임을 실행하지 않았다(통과하면 `ALL PASS 65/65`)".
- `CLAUDE.md`:
  - 8장 폴더 구조의 `docs/` 줄: `STYLE_BIBLE.md, DECISIONS.md, plans/` → `STYLE_BIBLE.md, DECISIONS.md, BACKLOG.md, plans/`.
  - 9장 현재 위치: 지금 적힌 계획 번호를 "계획 019(2단계 정리 다섯과 나중에 고칠 목록)까지 실행했다"로. 나머지 문장(완료 판정은 사용자가 한다 등)은 018이 적은 그대로 둔다.
  - 10장 끝(사용자가 2026-11-21 더한 주석 규칙 줄 아래)에 한 줄: "나중으로 미룬 코드·화면의 고칠 거리는 `docs/BACKLOG.md`에 그 파일 머리의 꼴로 남긴다. 사용자가 보류한 값과 결정은 보고서 4번과 `docs/HANDOFF.md` 3번에 둔다."
  - 다른 장은 고치지 않는다(규칙이 바뀌지 않았다).
  - 완료 확인: `git diff -- CLAUDE.md`에 위 세 곳과 함께, 작업 0에서 적은 10장 끝의 주석 규칙 한 줄(사용자 지시, 019 전부터 있던 커밋 전 변경)도 보인다. 그 밖의 줄은 없다(v2, 기술 지적).
- `docs/reports/019-tidy-and-backlog.md`와 사용자 보고(CLAUDE.md 10장 형식). 1번에 다섯의 한 일과 BACKLOG의 자리. 남긴 항목을 설명할 때 018 표의 문장을 옮기지 않고 BACKLOG의 문장을 따른다(F19는 "돌려보낸 날의 마지막 정산이 `2/3`으로 끝난다"이다. v2, D1). 2번의 "확인 못 한 것"에 실행 전부(018 것까지)와 아래 목록. 5번에 범위 밖으로 둔 결투 씬·의뢰 선택 화면의 현재 씬 확인 한 줄.
- `docs/HANDOFF.md`를 지금 상태로:
  - 머리의 저장소 줄: "계획 018은 커밋되지 않았다"를 "계획 018은 커밋했다(`2ffc964`, 원격에는 올리지 않았다). 계획 019의 변경은 커밋되지 않았다"로(019를 실행한 뒤 커밋했으면 그 해시).
  - 1번: 다음에 할 일 = playtester로 018·019를 함께 확인(사용자가 요청할 때), 2단계 완료 판정, `docs/BACKLOG.md`의 항목.
  - 2번: 018·019 모두 실행되지 않았다. 기대 `ALL PASS 65/65`. 019가 바꾼 파일 목록.
  - 3번의 018 줄: "폐점의 소지금 줄의 뜻, 정산·폐점의 평판 줄의 자리는 사용자가 '나중에'라고 해 `docs/BACKLOG.md`(018-F7·F8)로 옮겼다. 계획 019는 했다. 018의 커밋은 했다. 남은 것: 겹친 누름의 두 값(0.4초·0.6초)." playtester가 올린 것의 줄에서 F7·F8의 자리를 "018 보고서 4번"에서 "`docs/BACKLOG.md`"로.
  - 3번 머리에 한 줄: "고칠 거리(코드·화면)는 `docs/BACKLOG.md`에 있다. 여기는 값과 결정만이다."
- **playtester에게 맡길 확인** (명령마다 `$env:BRAVI_SAVE_PATH = "user://bravi_playtest_save.json"`을 같은 줄에서 건다). **018의 목록 1~12(`docs/reports/018-stage2-checkup.md`)를 먼저 하고, 1번의 기대값만 `ALL PASS 65/65`로 바꾼다.** 이어서:
  13. 폐점에 들어서면 `저장했다 — 끄고 다시 켜도 N일차 아침부터 이어진다`가 보인다. 업그레이드를 하나 사도 그대로 보인다.
  14. 저장 실패: 폐점에서(줄이 보이는 때) 사용자 데이터 폴더의 `bravi_playtest_save.json`을 읽기 전용으로 바꾸고(`Set-ItemProperty <경로> -Name IsReadOnly -Value $true`) 업그레이드를 산다 → `저장했다` 줄이 사라지고, 출력에 `저장하지 못했다:` 경고가 있다. 읽기 전용을 풀고 하나 더 산다 → 줄이 다시 보이고 파일의 `money`·`owned`가 바뀌었다. 끝나면 읽기 전용을 풀어 둔다. (바꿔 끼우기가 읽기 전용 파일도 덮어써 실패가 안 생기면 줄이 그대로 남는다 — 그 경우는 "실패를 만들지 못했다"로 적는다. 019의 잘못이 아니다.)
  15. 의뢰인의 자리: 카운터에서 미끄러져 들어온 의뢰인과 그 판의 정산 화면의 의뢰인이 같은 자리다(화면이 바뀔 때 튀지 않는다).
  16. 흥정 주사위의 씨앗: 새로 시작하기를 두 번 해 저장 파일의 `dice_seed`가 서로 다르다(같으면 한 번 더. 두 번 연달아 같으면 실패).
  17. 처음 화면의 `연습`, 카운터의 `오늘은 그만`, 폐점의 `처음 화면으로`, `다음 날을 연다`가 평소처럼 화면을 바꾼다(세션 가드).
- **가리는 순서** (018과 019를 한 번에 볼 때):
  - **테스트 로드 오류**: 파일이 `tidy_tests.gd`면 019 작업 6, `safety_tests.gd`면 018 작업 7. 스크립트(`day_ui.gd` 등)의 파스 오류면 `git diff -- <파일>`(019)을 먼저 보고, 019의 줄이 아니면 `git show 2ffc964 -- <파일>`(018).
  - **T63** → `day_ui.gd`의 `is_current_scene`·`current_session`(019 작업 1). 출력에 "absolute paths from outside the active scene tree" 같은 `ERROR:` 줄이 있으면 도우미가 트리를 먼저 보지 않는 것이다.
  - **T64** → `closing.gd`의 `refresh_saved_note`(019 작업 4).
  - **T60~T62** → 018의 가리는 순서 그대로. 다만 T60 "가"·"다"가 실패하고 `swallow_arrival_press`가 원인이면 019가 바꾼 그 함수의 첫 줄부터 본다.
  - **기존 테스트가 새로 실패**: T58 "라"·"바", T33·T36·T39, reputation_tests의 폐점 구매 → 019 작업 1의 12곳(특히 감싸는 꼴의 몸이 그대로인지)과 작업 4를 먼저. T57·T58의 저장 칸 → 018 작업 3. 의뢰인·흥정·평판의 값 → 019 작업 2·3(자리와 씨앗)을 보되, 값이 바뀌었으면 019의 잘못이 아니라 다른 변경이다.
  - **스모크**: "씬이 바뀌지 않음"·멈춤 → 019 작업 1(도우미가 현재 씬에서 null을 돌려준다)을 먼저, 그다음 018의 입력 막기.
  - **게임 창**: 018의 1~12는 018의 가리는 순서. 다만 어떤 버튼이 시간이 지나도 늘 아무 일도 하지 않으면 019 작업 1. 13·14는 019 작업 4, 15는 작업 2, 16은 작업 3, 17은 작업 1.
- 4번(사용자 결정)에는 아래 "사용자 결정 필요"를 싣는다. 5번에는 playtester 확인(018·019) → 2단계 완료 판정 → BACKLOG 항목을 적는다.
- 완료 확인(작업 8): 보고서 파일이 있고 "확인 못 한 것", playtester 목록과 가리는 순서가 있다. `CLAUDE.md`·`docs/DECISIONS.md`·`docs/HANDOFF.md`에서 이 계획이 바꾼 줄이 위에 적은 것뿐이다.

## 설계 결정

번호는 계획 018의 표(164~170)에 잇는다. 전부 planner가 위임으로 정했다.

| # | 결정 | 이유 | 되돌리기 |
|---|---|---|---|
| 171 | 카운터·정산·폐점·처음 화면의 세션 가드 12곳은 `Ui.current_session(self)`를 부른다. 트리 안인지 → 현재 씬인지 → 세션 순으로 본다. 입력 막기(`swallow_arrival_press`)도 같은 `Ui.is_current_scene`을 쓴다 | 두 꼴(4곳·8곳)이 트리 안에서는 같고, 트리 밖에서는 이 꼴만 오류 줄 없이 끝난다. 같은 뜻을 한 곳에 둔다 | 쉬움 — 12곳이 같은 두 줄이다 |
| 172 | 폐점의 "저장했다"는 살 때마다 마지막 쓰기의 결과(`saved_day`)를 따른다. 실패하면 숨기고 다시 적히면 보인다. 실패를 알리는 새 글은 더하지 않는다 | 실패한 뒤에도 "저장했다"가 남아 거짓을 말했다(018-F20). 들어설 때 실패한 폐점에 줄이 없는 지금의 꼴과 같다 | 쉬움 — 함수 하나 |
| 173 | `CLIENT_POS`는 `day_ui.gd`에 하나. `DayState._rng`는 `_init`의 지역 변수. 낡은 주석 셋을 지금 코드에 맞춘다 | 같은 값·같은 동작이다(018-F15·F16·F17) | 쉬움 |
| 174 | 나중으로 미룬 코드·화면의 고칠 거리는 `docs/BACKLOG.md`에 ID(`<계획>-<번호>`)와 일곱 칸으로 둔다. 고치면 "닫힌 것"으로 한 줄. 보류한 값과 결정은 지금처럼 보고서 4번과 `HANDOFF.md` 3번에 둔다(BACKLOG 머리가 가리킨다) | 사용자 지시 "나중에 고칠 수 있게". `HANDOFF.md`는 세션마다 다시 쓰여 오래 둘 목록이 묻힌다 | 쉬움 — 문서 하나 |
| 175 | 새 테스트 둘(T63·T64, `tests/tidy_tests.gd`)을 018의 파일과 따로 둔다. 기존 테스트 파일의 통과 조건은 고치지 않는다. 새 `class_name`은 없다 | 로드 오류를 파일 이름으로 018과 가른다. 세션 가드의 현재 씬 갈래는 러너에서 만들 수 없어(현재 씬이 null) 스모크에 맡긴다 | 쉬움 — 파일 하나와 한 줄 |

## 위험

1. **실행되지 않은 018 위에 또 얹는다.** 같은 다섯 파일을 다시 고친다. 대비: 018은 커밋되어 `git diff`가 019만 보인다(작업 0). 작업 8의 가리는 순서. 019의 변경은 018의 함수 가운데 `swallow_arrival_press`의 한 줄만 건드린다.
2. **감싸는 꼴로 바꿀 때 몸을 잘못 옮긴다.** `settlement.gd` `_proceed`와 `closing.gd` `_next_day`는 가드 앞에 `day.proceed()`·`day.next_day()` 확인이 있다. 대비: 작업 1의 표에 함수마다 꼴을 적었고, 완료 확인에서 12곳을 하나씩 따라간다. 러너는 현재 씬이 아닌 갈래만 지나므로, 현재 씬 갈래의 실수는 스모크와 playtester 17번이 잡는다.
3. **T63 "가"가 엔진의 오류 줄에 기댄다.** 트리 밖의 `get_node_or_null(^"/root/…")`가 오류를 찍는다는 것은 엔진의 동작이라 실행해 봐야 안다. 찍지 않더라도 도우미는 null을 돌려주고 T63은 통과한다(잃는 것 없음).
4. **F20의 실패를 실제로 만들기 어렵다.** playtester 14번은 읽기 전용 파일로 실패를 만든다. 이 Windows의 바꿔 끼우기가 읽기 전용 파일을 덮어쓰면 실패가 생기지 않는다. 대비: 실패의 갈래는 T64 "다"·"마"가 함수로 본다.
5. **BACKLOG의 위치가 낡는다.** 파일·함수·찾을 글로 적고 줄 번호는 괄호로만 둔다. 항목을 고르는 계획이 먼저 Grep으로 위치를 다시 잡는다.

## 실행 전에 물을 것

없다. 고칠 다섯은 사용자가 골랐고, 고치는 방법과 목록의 자리·꼴은 위임으로 정했다. 보류 중인 값과 결정, F7·F8의 뜻은 건드리지 않고 목록으로만 옮겼다.

## 사용자 결정 필요 (실행을 막지 않는다. 보고서 4번에 올린다)

| # | 무엇 | 이 계획이 정한 것 | 답이 다르면 |
|---|---|---|---|
| 1 | 나중 목록의 자리 | `docs/BACKLOG.md`(새 파일)와 CLAUDE.md 8장·10장의 한 줄씩 | 다른 곳을 원하시면 파일 하나를 옮기고 두 줄을 고친다 |
| 2 | "저장했다" 줄이 실패 때 사라지기만 하는 것 | 실패를 알리는 글은 더하지 않았다(결정 172) | 붉은 한 줄(`저장하지 못했다 — …`)을 원하시면 `refresh_saved_note`에 갈래 하나다 |
| 3 | 018에서 이어진 것 | 겹친 누름의 두 값(0.4초·0.6초)은 그대로 묻는다(018 보고서 4번의 1번) | — |
| 4 | **2단계 완료 기준 충족 — 다음 단계 진행 여부** | 이 계획은 2단계의 범위를 넓히지 않았고 3단계의 계획을 만들지 않았다. 018·019의 playtester 확인 뒤에 판정하시기를 권한다 | 판정을 미루면 다음 후보는 `docs/BACKLOG.md`의 항목, 보류 중인 값들, CLAUDE.md 5장의 "아직 없는 것"이다 |
| 5 | 019의 커밋 | 정하지 않는다(커밋은 사용자가 지시한다) | — |

보류 중인 것(그대로 둔다): 계획 012~018 보고서 4번의 값과 의견들(`docs/HANDOFF.md` 3번), `docs/plans/013-playtester.md`의 번호 겹침.

## 검토 대응 기록

v1 → v2 (1회차: design-reviewer REVISE, tech-reviewer APPROVE). 고칠 다섯과 코드 조각은 바꾸지 않았다.

- **D1 (수용)**: 작업 7 BACKLOG의 018-F19를 고쳤다. 제목, 문제(돌려보낸 날의 마지막 정산이 `2/3`으로 끝난다. 018-F5와 같은 원인이고, 별로는 생기지 않는다), 둔 까닭, 방향과 후보(나의 식을 적고 다 안을 더함), 사용자가 정할 것, 테스트 칸, 다시 볼 때("별 1의 날"을 빼고 헷갈려 할 때 / 2단계 판정 때 / 늦어도 4단계 UI)를 바꿨다. 같은 오해가 다른 문서로 번지지 않게 작업 8의 `DECISIONS.md` 기록에 한 줄, 보고서 문안 규칙에 한 줄을 더했다.
- **기술 제안 1 (수용)**: 작업 4 완료 확인의 `saved_day` Grep 기대를 "2건과 인자"에서 계획 코드대로 다시 센 "5줄"로 바꿨다.
- **기술 제안 2 (수용)**: 작업 4의 멤버 자리를 "`_buy_upgrades`(26줄) 아래, `_opened_msec`의 `##` 주석(27줄) 위"로 적었다.
- **기술 지적 (작업 트리)**: 근거의 저장소 상태를 "`M CLAUDE.md` 한 줄이 있다"로 고쳤다. 작업 0은 그 한 줄을 확인한 뒤 예외로 두고 진행한다. 작업 8의 `CLAUDE.md` 완료 확인에 그 줄도 함께 보인다는 것을 적었다.
