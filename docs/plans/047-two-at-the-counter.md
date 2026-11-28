# 계획 047: 둘이 함께 — 다투는 이웃 둘이 한 카운터에, 고른 쪽이 남기는 플래그와 다음 날의 손님

- 버전: v2 (2026-11-28. 1회차 디자인 APPROVE · 기술 REVISE T1 · T2와 받아들인 비차단 — 끝의 "검토 대응 기록". 046이 결정 746을 써서 이 계획의 결정을 747부터로 밀었다. v1: 2026-11-28)
- 개발 단계: CLAUDE.md 9장 **6단계(콘텐츠)**, 나눔 039 v2.1의 차례 표 047 줄("카운터의 둘 가운데 고르기, `flags`와 저장, 플래그로 갈리는 손님(`DayData`의 조건 자리)", 그림 0장). 버티기 · 클라라의 맞수 · 비토리오의 독촉(048), 7일 일정의 확정(049)으로 넘어가지 않는다.
- 시작점: **046의 끝 커밋 `83cf9e7`**(합 N = **147** — T145~T147). 작업 0이 HEAD와 `ALL PASS 147/147`을 다시 읽는다. 아래의 수는 N으로 적었다(끝나면 N + 5 = 152).
- 결정 번호 747~765, 테스트 T148~T152.

## 근거

- 사용자(2026-11-27): "두 명의 의뢰인이 동시에 의뢰(… 한쪽 편을 들어주거나 …)". **개성이 중요하다 — 비슷한 느낌은 최대한 없게, 개성이 돋보일수록 좋다.** 독창적이되 지금까지와 딴판인 개연성 없는 의뢰는 안 된다. 물을 것은 메인이 대신 고르고(사용자 위임 2026-11-27) 손 · 눈이 있어야 아는 것은 판 M(HANDOFF 3번)에 모은다.
- 039 v2.1 의뢰 틀 표 1번: 베아트리체를 고르면 상대는 굴리엘모, 굴리엘모를 고르면 상대는 베아트리체. **두 쪽의 조건이 다르다** — 베아트리체 쪽 `TARGET_PART`(제빵사 모자, 유효타만), 굴리엘모 쪽 `SPAR`(다치게 말고 세 번 무너뜨려라). 둘 다 돌려보낼 수 있다. 고른 쪽이 **플래그**로 남아 뒤의 날의 손님이 갈린다. 저장에 `flags`(문자열 목록) — 없는 저장은 빈 목록으로 읽어 `SAVE_VERSION`은 그대로(위험 R5 "flags는 047 하나만"). 일정 초안: 6일차 둘이 함께, 7일차 "6일차 선택의 뒷이야기". planner의 표: "뒷이야기 둘 — 고르지 않은 쪽 / 고른 쪽, 플래그에 따라 하나만 온다". 완료 기준 4: 의뢰인 13명 이상, **둘 이상의 인물이 의뢰인과 상대의 두 역할**.
- 인물(044 · 045의 근거 절): 베아트리체 — 마흔 안팎, 클라라 가게 건너편의 모자 가게 주인, "손님에게 한 모자를 보여 주고 다른 모자를 팔고, 칼도 그렇게 쓴다", 말끝을 올려 되묻는다("이쪽이 어울리시죠? …아니, 이쪽?", "다음엔 제 가게로 오세요."), 속임 베기(1단 5일차 · 2단 7일차). 굴리엘모 — 쉰 안팎, 강변 문 곁의 제빵사, 새벽마다 남은 빵을 나눈다, 빵에 빗댄다("식기 전에!", "빵 하나 가져가요."), 치고 빠지기(1단 6일차 · 2단 8일차). 모자는 의뢰가 씌울 때만 — "조금 높은 주름 잡힌 제빵사 모자"(045 · 045b의 `hat.png`).
- 의뢰인 그림: `assets/art/clients/beatrice.png` · `guglielmo.png`(044b · 045b가 그렸고 아직 어느 의뢰에도 안 걸렸다). 이 계획이 건다 — **그림 0장**.
- 코드로 읽은 사실(planner, 2026-11-28 — 줄 번호는 작업 0이 다시 읽는다):
  - `DayState`(`scripts/economy/day_state.gd`): 손님은 `data.commissions[index]` 하나씩이고 `current_commission()`이 맡기 · 흥정 · 정산 · 카운터의 모든 읽기의 입구다. 흥정은 `_haggle_index == index`로 그 손님에게 묶인다. `decline()`은 `declined`에 이름 하나를 넣고 폐점의 `missed = 손님 수 − 결투 − declined.size()`가 그 수를 쓴다. 저장(`saved_state` · `restore`)은 아침만 적는다 — 폐점이면 내일, 아무도 만나지 않은 아침이면 오늘. 하루 중에 그만두면 그날은 버려진다. `_begin_day`가 `schedule.day_for(n)`으로 하루를 고르고 `_guests_for`로 손님 수를 정한다. `tomorrow_data()`가 폐점의 "내일 손님" 셈에 쓰인다.
  - 카운터(`scripts/commission/counter.gd`): `_build(commission)`이 의뢰인 하나(`Ui.make_client` — 그림이면 화면 (80, 120) 300×450), 말풍선(410, 70, 830×440), 버튼 넷(흥정 410,600 · 돌려보낸다 640,600 · 맡는다 900,590 · 오늘은 그만 40,650)을 만든다. 씬을 다시 열면(`GameSession.go_to_phase_scene` → `change_scene_to_file`) 처음부터 다시 그린다.
  - `Commission`: 자세 두 칸(043), 조건 목록, 한마디 여섯, `haggle_min_stars`. 짝 · 플래그의 칸은 없다. `CommissionLibrary.load_tree`가 하위 폴더까지 모아 연습 화면의 목록이 된다.
  - 조건: `TargetPartCondition`(`target_part` — `DuelTypes.Part { HEAD, HAT, TORSO, SWORD_ARM, SWORD_HAND, LEGS }`, `graze_penalty`, `hit_penalty`), `SparCondition`(`topples_needed` · `partial_scores` · `wound_score` · `hold_hint`), `ThrowUndetectedCondition`(맞을 때의 상황 — 막기를 쥔 채 맞으면 `WRONG_GUARD` 5, 아무것도 안 쥐면 `UNGUARDED` 20 · `duel_core.gd` 482행 곁).
  - 하루: `day_01`~`day_05`(046이 `day_05`를 더해 닷새를 돈다), `day_02`~`05`는 `base_guests = 5`.
  - 봇 통계(`tests/duel_stats.gd`): `--commission` · `--finisher=off|low` · `--chase` · `--bite`(속는 봇) · `--dive=retreat` · `--tier`. 끝내기의 칸은 늘 가운데 중단(`low`면 가운데 하단)이다 — **모자 · 칼 든 손**(윗줄의 칼 쪽 베기)을 끝내는 봇이 없다.
- 039 · 043 · 045의 어긋남(결정 762): 045의 넘기는 것("베아트리체를 고르면 상대는 굴리엘모 … 조건 `SPAR`")과 043의 넘기는 것("굴리엘모 쪽의 `SPAR` … 굴리엘모의 치고 빠지기를 따라붙으며 세 번")은 039 표 1번 · 045 근거 절의 모자 줄과 맞지 않는다. **039를 따른다**: `SPAR`는 굴리엘모가 맡기는 쪽이고 그 판의 상대는 베아트리체다.
- 지킬 것: 원칙 1~5, 결정 425 · 609(상대 파일의 판정 값은 고치지 않는다), 039 결정 577(규칙 갈래를 당겨 쓰지 않는다), 043의 배운 것(`States.put` 뒤 `tick` · `advance` 금지, 표의 "자동"이 정말 자동인지), 043의 넘기는 것 — **"참기"만으로 그 의뢰의 개성을 세우지 않는다**.

### 넘지 않는 선

- 메인은 Godot · 테스트 · 게임을 실행하지 않는다. 확인은 verifier. playtester는 부르지 않는다.
- 코드 · 데이터 · 테스트는 메인이 Sonnet 하위 에이전트에게 작업 하나씩 맡기고 diff로 확인한다.
- **고치지 않는 것**: `duel_core.gd` · `opponent_brain.gd` · `settlement.gd` · `closing.gd` · `game_session.gd` · `save_store.gd` · `reputation_rules.gd`(한 줄도), 상대 파일 일곱과 그림 데이터, `duel_rules.tres`(90초), `reputation_rules.tres` · `economy_rules.tres`, `data/days/day_01~05.tres`, 046의 두 의뢰, `duel_bots.gd`, `tests/plain_opponent.gd`, `docs/plans/R02b-*` · `H01-*` · `.gitignore`.
- 만들지 않는 것: 새 조건 타입, 새 무대, 그림, 새 규칙(결투의), 결과에 따라 갈리는 플래그(결정 752), 평판에 따라 갈리는 손님.

## 목표와 범위

6일차의 첫 손님 자리에 **모자 가게 베아트리체와 제빵사 굴리엘모가 함께 들어온다**. 그의 화덕 그을음이 그녀의 흰 깃털을 잿빛으로 만들고, 그녀는 아침마다 그의 가게 앞에 소금을 뿌린다. 둘은 "편을 못 얻은 쪽이 직접 칼을 든다"고 정하고 왔다. 카운터에는 한 사람이 말하고 한 사람이 뒤에 서 있다. **"다른 쪽 말을 듣는다"**로 번갈아 듣고 한쪽 편을 들거나 둘 다 돌려보낸다. 베아트리체 편이면 치고 빠지는 굴리엘모를 쫓아 **제빵사 모자**를 베고, 굴리엘모 편이면 헛손질을 섞는 베아트리체를 **다치게 하지 않고 세 번 무너뜨린다**. 고른 쪽이 플래그로 남아 **7일차의 첫 손님이 달라진다** — 그녀 편을 들었으면 굴리엘모가 원망 없이 와서 **그녀의 모자를 구긴 멋쟁이 로렌초의 손**을 베어 달라 하고, 그의 편을 들었으면 베아트리체가 와서 **같은 광장에서 자기에게 티 안 나게 져 달라** 한다.

**확인할 결과**:

1. 한 손님 자리에 두 의뢰가 서고, 번갈아 듣기 · 한쪽 맡기 · 둘 다 돌려보내기가 `DayState`의 규칙대로 돈다(흥정하면 그 편으로 굳는다). 짝이 없는 손님은 한 줄도 다르게 돌지 않는다(T149).
2. 맡은 쪽의 플래그가 정산 때 남고, 저장 · 이어 하기를 지나 **다음 날 아침의 손님 목록**을 거른다. 플래그 칸이 없는 하루는 그 객체 그대로다(T148 · T150).
3. 네 의뢰가 기존 조건만으로 서고 값 · 글 · 플래그가 `.tres`에 있다. 두 쪽의 상대가 서로 엇갈리고 의뢰인 그림 둘이 걸린다(T151).
4. 네 판 가운데 셋을 봇이 끝낸다: 모자(굴리엘모 — 따라붙기), 대련(베아트리체 — 헛손질), 칼 든 손(로렌초). 티 안 나게 지기는 기록으로 — "속은 채 맞기"가 "멍하니 맞기"보다 의심이 적다(T152, V2).
5. 6 · 7일차(새 하루 `day_06` · `day_07`), 일정이 이레를 돈다(T151).
6. 기존 테스트의 표(아래)를 고치고 `ALL PASS (N+5)/(N+5)`. 봇 통계의 기존 줄은 글자까지 그대로다.

손맛(누구 편을 들지가 고민인가, 번갈아 듣기가 읽히는가, 뒷이야기의 엇갈림이 보이는가)은 봇이 알려 주지 않는다. 임시 값으로 닫고 판 M에 올린다.

**수의 변화**: 의뢰 10 → **14**(+4). 의뢰인 10 → **12**(+ 베아트리체 · 굴리엘모 — 둘 다 두 의뢰에 선다). 완료 기준 4의 "13명"에 **하나가 모자란다** — 048의 셋(굴리엘모 · 클라라 · 비토리오)은 새 사람이 아니므로 049의 "토마소가 데려온 손님"(039 planner 표)이 열셋째다(위험 R8). "의뢰인과 상대의 두 역할"은 아고스티노에 베아트리체 · 굴리엘모가 더해 **셋**이다(완료 기준 4의 둘째 줄 충족).

## 꼴의 선택 — 견준 길(결정 748)

| 길 | 어떻게 | 새 코드 | 버린 · 고른 까닭 |
|---|---|---|---|
| ㄱ. 한 화면에 둘 다 | 의뢰인 둘을 나란히, 말풍선 둘, "이쪽 편" 버튼 둘 | 카운터를 새로 짠다(말풍선 830×440에 사연 280자 둘이 들지 않는다 — 글을 줄이거나 화면을 바꿔야), 테스트의 카운터 고리 거의 전부 | **버림**: 크고, 사연이 반으로 줄면 두 사람의 개성(말투 · 귀띔)이 깎인다 |
| ㄴ. 잇따른 두 손님 | 두 의뢰를 목록에 나란히, 하나를 맡으면 다른 하나는 돌아간다 | `DayState` 몇 줄(건너뛰기 — 손님 수 · 남은 결투 셈이 어긋난다) | **버림**: 첫 사람의 말만 듣고 정해야 한다 — "편을 든다"가 아니라 "먼저 온 사람을 받는다"가 된다. 둘째를 들으려면 첫째를 돌려보내야 하니 고르기가 없다 |
| **ㄷ. 한 자리, 두 쪽** | 한 손님 자리에 짝(`partner`)이 있는 의뢰. 한 사람이 말하고 다른 사람은 뒤에 흐리게 선다. "다른 쪽 말을 듣는다"가 말하는 쪽을 바꾼다(씬을 다시 연다). 맡으면 그 쪽, 돌려보내면 둘 다 | 의뢰 칸 넷 · `DayData` 함수 하나 · `DayState` 30줄 안팎 · 카운터 35줄 안팎 | **고름**: 두 사람의 말을 다 듣고 정한다. 지금의 말풍선 · 흥정 · 정산 · 평판이 **그대로 한 의뢰씩** 돈다(`current_commission()`이 말하는 쪽을 돌려줄 뿐). 화면은 지금 꼴에 사람 하나와 버튼 하나를 더한다 |

(v2) **뒷이야기 둘과 `day_07`을 047b로 가르는 길도 버렸다**(두 검토자): 뒷이야기와 `day_07`이 플래그를 실제로 읽는 유일한 곳이라 가르면 결정 763이 피한 "읽는 데 없는 플래그"가 되고, 고르기 → 저장 → 다음 날의 손님을 끝까지 보는 T150 ⑤도 사라진다.

ㄷ의 새 흐름은 "말하는 쪽" 하나다. 정산 · 폐점 · 결투 씬은 한 줄도 고치지 않는다. 대가: 바꿀 때 씬을 다시 열어 의뢰인이 한 번 더 미끄러져 들어온다(판 M-1, 위험 R1).

## 두 쪽과 뒷이야기가 다른 의뢰와 갈리는 곳(결정 755 · 756)

| | 베아트리체 편(`pair_hatter`) | 굴리엘모 편(`pair_baker`) | 뒷이야기 — 굴리엘모가 온다(`after_hatter`) | 뒷이야기 — 베아트리체가 온다(`after_baker`) |
|---|---|---|---|---|
| 상대 · 날 | 굴리엘모 1단(6일차), 모자를 쓴다 | 베아트리체 1단, 자세 3 · 3 | 로렌초 2단(7일차) | 베아트리체 2단(7일차) — **의뢰인 본인** |
| 조건 | 모자, 유효타만 | 대련 세 번 | 칼 든 손, 유효타만 | 티 안 나게 지기 |
| 손이 하는 일 | 찍고 뛰어 물러나는 그를 **막기를 떼고 W로 쫓아** 무너뜨린 뒤 윗줄 베기 | **헛손질을 읽어야** 빈틈이 난다(속으면 그 패턴의 빈틈이 0) — 무너뜨린 뒤 참는다 | 뛰어드는 그를 **같이 물러서 헛치게** 하고, 무너뜨린 뒤 **칼 쪽 윗줄 베기** | **헛손질에 일부러 속아** 쥔 막기로 맞는다(의심 5 — 멍하니 맞으면 20) |
| 가까운 의뢰와의 차 | 클라라(바르톨로의 깃털)는 서서 싸운다. 이쪽은 쫓는다 | 아고스티노(박자를 읽는다)와 갈리는 것은 "참기"가 아니라 **헛손질 읽기**다(043의 넘기는 것) | **칼 든 손을 노리는 첫 의뢰**. 비토리오(로렌초 · 첫 피)는 아무 데나 | **의뢰인에게 져 주는 첫 판**. 이네스 · 가스파로는 바르톨로에게 진다. 채점은 같고(틀린 칸을 쥐고 맞으면 5) 헛손질은 그럴 핑계다 — 다른 맛인지는 판 M-6 |
| 돈 · 평판(6 · 7일차 ×2) | 50 · 25, 해냄 +2 · 이김 +1 · 못 해냄 −1, 흥정 눈높이 3(값을 아는 장사꾼) | 30 · 15, 해냄 +3 · 못 해냄 −1, 눈높이 1("얼마든 좋습죠") | 30 · 20, **맡음 +1**(소문이 좋다) · 해냄 +3 · 이김 +1, 눈높이 1 | **55 · 30**, **맡음 −1**(가게가 진다는 소문) · 해냄 0 · 못 해냄 −1, 눈높이 2 |
| 말투 | 해요체에 말끝을 올려 되묻는다("…잖아요?", "…이시죠?") | 시장 상인의 "-습죠/-입죠"에 빵 빗댐, "식기 전에!" | 같다 | 같다 |
| 무대 | 광장 | 광장 | 뒷골목 | 광장("같은 광장, 같은 사람들 앞에서") |

**엇갈림**(결정 756): 쩨쩨한 쪽(그녀) 편을 들면 다음 날 착한 쪽(그)이 원망 없이 와서 **그녀를 위해** 좋은 일을 맡긴다. 착한 쪽 편을 들면 다음 날 쩨쩨한 쪽이 와서 돈은 크고 평판은 깎이는 짜고 치는 판을 내민다. 고른 편의 평판은 비슷하게 두고(6일차 ×2 — 흠 없이 해내면 그녀 편 해냄 +4 · 이김 +2, 그 편 해냄 +6, 둘 다 흠 없이의 덤), 돈과 싸움과 다음 날이 다르다.

## 설계 결정

모두 메인이 대신 고름(사용자 위임 2026-11-27)이고 수치는 임시다.

747. **범위**: 짝이 있는 손님 자리 · 플래그와 저장 · 플래그로 거르는 하루 · 의뢰 넷(두 쪽과 뒷이야기 둘) · 하루 둘(`day_06` · `day_07`). 새 조건 · 새 무대 · 그림은 없다. 게임의 코드는 `commission.gd` · `day_data.gd` · `day_state.gd` · `counter.gd` 넷(결정 749~753). 테스트 도구는 `duel_stats.gd`의 `--finisher=top`(결정 760).
748. **꼴 — 한 자리, 두 쪽**: 위 "꼴의 선택"의 ㄷ.
749. **짝의 데이터**(`commission.gd`): `@export var partner: Commission` — "함께 와서 맞서는 다른 쪽. 이 의뢰가 하루의 목록에 서고 짝은 목록에 넣지 않는다." **한쪽에만 적는다**(서로 가리키면 `.tres`의 불러오기가 돈다). 목록에 서는 쪽은 `pair_hatter`(그녀가 먼저 밀고 들어온다 — 성격), 짝은 `pair_baker`. 짝의 `partner` · 플래그 거름 칸은 읽지 않고 비워 둔다(T151이 본다). 연습 화면에는 둘 다 따로 나온다(`load_tree` — 연습은 짝을 모른다).
750. **`DayState`의 규칙**:
     - 하루의 것 `_side := 0`(0이면 목록의 의뢰, 1이면 그 짝). `_begin_day`와 `index`가 바뀌는 두 곳(`decline` · `proceed`)에서 0으로.
     - `current_commission()`: 지금처럼 목록의 의뢰를 잡고, `_side == 1`이고 짝이 있으면 짝을 돌려준다. 그 밖의 모든 읽기(흥정 · 맡기 · 정산 · 카운터)는 이 함수만 거친다 — 고치지 않는다.
     - 새 읽기 둘: `partner_commission()`(말하지 않는 쪽, 짝이 없으면 null), `can_switch_side()`(카운터이고, 짝이 있고, `haggle_state() == NONE`). 새 전환 `switch_side() -> bool`(되면 `_side`를 뒤집는다, 상태의 다른 칸은 그대로).
     - **흥정하면 그 편으로 굳는다**: 값을 부른 뒤에는 바꿀 수 없다(`can_switch_side`). 까닭: 흥정의 결과는 순번(`_haggle_index`)에 묶여 있어 쪽을 바꾸면 다른 사람이 그 대답을 물려받는다. 흥정의 주사위(`haggle_roll` — 순번)는 두 쪽이 같다(같은 자리의 같은 아침).
     - **둘 다 돌려보낸다**: `decline()`이 짝이 있으면 `declined`에 **한 칸** `"%s · %s" % [목록의 이름, 짝의 이름]`(폐점의 `missed` 셈이 한 자리 = 한 칸으로 맞는다), `last_declined`는 **말하던 쪽**의 이름과 `decline_line`.
     - 저장은 그대로 아침만 적는다 — 쪽은 저장에 들지 않는다(아침에는 늘 0).
751. **카운터의 그림**(`counter.gd`, 짝이 있을 때만 — 없으면 노드 · 글이 지금 그대로):
     - 말하지 않는 쪽: `Ui.make_client(짝)`을 말하는 쪽보다 **먼저** 붙여 뒤에 세운다. 이름 `Partner`, 자리 `CLIENT_POS + PARTNER_OFFSET`(처음 값 (−90, 24)), `scale` `PARTNER_SCALE`(0.92), `modulate` `PARTNER_TINT`(0.62, 0.62, 0.66). 그 이름 글은 숨긴다(말하는 쪽의 이름과 겹친다 — 누구인지는 버튼이 말한다). 미끄러지지 않고 처음부터 서 있다.
     - 버튼 `SwitchSide`: `SWITCH_BUTTON := "%s의 말을 듣는다"`(짝의 `client_name`), 자리 (40, 588) 330×50, 18pt. 누르면 `day.switch_side()`가 **참일 때만** `_go()`(씬을 다시 연다 — 다른 쪽이 앞으로 미끄러져 나온다. 거짓이면 아무것도 하지 않는다). 흥정한 뒤에는 꺼지고 `SWITCH_LOCKED := "값을 불렀다 — 이쪽 편이다"` — (v2 — T2) 이 꺼짐과 글은 `_refresh_haggle()`이 **그 자리에서** 고친다(`_on_haggle()`은 씬을 다시 열지 않고 `_refresh_haggle()`만 부르므로, 흥정 직후 지금 열린 카운터의 버튼이 바로 꺼진다). 새로 붙인 카운터도 `_build` 끝의 같은 `_refresh_haggle()`로 꺼진 채 선다. 버튼은 `_haggle_button`처럼 멤버(`_switch_button`)로 잡는다.
     - `Proceed`의 글 `PAIR_ACCEPT := "이쪽 편을 든다"`, `Decline`의 글 `PAIR_DECLINE := "둘 다 돌려보낸다"`. 버튼의 이름 · 자리 · 크기는 그대로.
     - "상대:" 줄의 꼬리 `PAIR_OPPONENT_TAIL := " — 고르지 않은 쪽이 직접 칼을 든다"`(줄 머리는 그대로라 contains로 보는 테스트가 산다).
     - 자리 · 크기 · 색의 상수는 처음 값이고 V3의 장과 판 M-1이 본다.
752. **플래그**(`commission.gd` 세 칸 · `day_state.gd`):
     - `@export var sets_flags := PackedStringArray()` — 이 의뢰를 **맡아 정산했을 때** 남긴다(`finish_duel`의 끝, 평판 다음). 돌려보내면 남지 않는다. **결과로 갈리지 않는다**(0점이어도 남는다) — 뒷이야기의 글은 결과와 상관없이 참이게 쓴다(결정 761). 결과로 갈리는 플래그는 칸 하나(`flags_on_success`)로 더할 수 있지만 지금 쓸 데가 없어 만들지 않는다.
     - `@export var requires_flags := PackedStringArray()`(모두 있어야 온다) · `@export var excluded_flags := PackedStringArray()`(하나라도 있으면 오지 않는다). `func allowed_by(flags: PackedStringArray) -> bool`.
     - `DayData.for_flags(flags) -> DayData`: 거른 목록이 원래와 같으면 **그 객체(self)**, 다르면 `DayData.new()`에 거른 목록과 같은 `base_guests`(원본은 고치지 않는다). 짝의 칸은 보지 않는다.
     - `DayState.flags: PackedStringArray`(날을 넘는 것). `_begin_day`가 `data = (그날의 하루).for_flags(flags)`, `tomorrow_data()`도 거른 것을 돌려준다(폐점의 내일 손님 수가 맞게). **오늘 남긴 플래그는 내일 아침부터** 거른다(하루 중에 손님 목록이 바뀌지 않는다).
     - 겹치지 않게 넣고(있으면 건너뛴다), 빈 글은 넣지 않는다.
753. **저장**: `saved_state()`에 `"flags": Array(flags)`를 더한다. `restore()`는 `"flags"`가 배열이면 글이고 비지 않고 64자 이하인 것만 겹치지 않게 64개까지, 아니면(없는 옛 저장 포함) 빈 목록. `SAVE_VERSION`은 1 그대로(039 R5). 하루 중에 그만두면 그날의 플래그는 버려진다(아침의 저장에서 다시 읽는다 — 지금의 소지금과 같은 길). (v2 — 기술 비차단) `restore()`는 `flags`를 **`_begin_day()`보다 먼저** 채운다(`day_state.gd` 415행 곁의 `_begin_day()` 앞) — 순서가 바뀌면 이어 한 날의 목록이 거르기 전 그대로다(T150 ② · ⑤가 본다).
754. **두 쪽의 꼴**(아래 "의뢰의 데이터"):
     - `variants/pair_hatter.tres`: 의뢰인 "모자 가게 베아트리체"(그림 `beatrice.png`), 상대 `opponent_07`(굴리엘모), **모자를 쓴다**, 무대 광장, `TargetPartCondition` — `target_part = HAT`(1) · `graze_penalty = 0` · `hit_penalty = 30`, 50 · 25, `{"accept": 0, "success": 2, "fail": -1, "win": 1}`, 눈높이 3, `partner = pair_baker`, `sets_flags = ["sided_hatter"]`, `excluded_flags = ["sided_hatter", "sided_baker"]`(한쪽 편을 든 뒤 일정이 돌아와도 다시 오지 않는다. 둘 다 돌려보냈으면 다시 온다).
     - `variants/pair_baker.tres`: 의뢰인 "제빵사 굴리엘모"(그림 `guglielmo.png`), 상대 `opponent_06`(베아트리체), 모자 없음, 무대 광장, `SparCondition` — `topples_needed = 3` · `partial_scores = (0, 25, 50)` · `wound_score = 0` · `hold_hint = "건드리지 마십쇼"`, 의뢰의 자세 3 · 3(043 결정 659의 칸), 30 · 15, `{"accept": 0, "success": 3, "fail": -1}`(`win` 없음 — 대련에서 이기면 0점이다), 눈높이 1, `sets_flags = ["sided_baker"]`, 거름 칸 비움.
755. **두 쪽의 개성**: 위 표. 같은 다툼의 두 쪽이 **보수 · 평판 · 손 · 다음 날**이 모두 다르다. 대련 쪽은 043의 넘기는 것대로 "참기"가 아니라 **헛손질 읽기**가 앞에 선다(베아트리체의 1단은 속임 베기 — 속으면 그 패턴의 빈틈이 0이라 무너뜨릴 기회가 준다). 사연의 귀띔이 그것을 말한다("한 번 휘두르는 척하고 다른 데를 칩죠").
756. **뒷이야기 둘 — 고르지 않은 쪽이 다음 날 온다**(039의 "고르지 않은 쪽 / 고른 쪽" 가운데 앞의 것):
     - `variants/after_hatter.tres`(그녀 편을 들었으면): 의뢰인 "제빵사 굴리엘모", 상대 `opponent_03`(로렌초), 모자 없음, 무대 뒷골목, `TargetPartCondition` — `target_part = SWORD_HAND`(4) · `graze_penalty = 0` · `hit_penalty = 30`, 30 · 20, `{"accept": 1, "success": 3, "fail": -1, "win": 1}`, 눈높이 1, `requires_flags = ["sided_hatter"]`, `excluded_flags = ["baker_helped"]`, `sets_flags = ["baker_helped"]`.
     - `variants/after_baker.tres`(그의 편을 들었으면): 의뢰인 "모자 가게 베아트리체", 상대 `opponent_06`(그녀 자신), 무대 광장, `ThrowUndetectedCondition`(기본 값 그대로 — 이네스의 것과 같은 셈), 55 · 30, `{"accept": -1, "success": 0, "fail": -1}`, 눈높이 2, `requires_flags = ["sided_baker"]`, `excluded_flags = ["hatter_rematch"]`, `sets_flags = ["hatter_rematch"]`.
     - 까닭: ① 고르지 않은 쪽이 오면 **어제의 상대가 오늘의 손님**이다 — 그 사람을 이미 칼로 안다. ② 두 사람의 성격이 결과를 비튼다(착한 제빵사는 원망 없이 이웃을 위해 온다, 쩨쩨한 모자 장수는 체면을 사러 온다). ③ 두 판 모두 그날의 조건 가운데 **아직 안 쓴 짝**이다(칼 든 손, 의뢰인에게 져 주기). ④ 그녀의 귀띔은 헛손질을 "속은 것처럼 보일" 핑계로 쓴다 — 쥔 막기로 맞으면 `WRONG_GUARD`(의심 5), 아무것도 안 쥐면 `UNGUARDED`(20)(T152 ④가 기록으로 본다). (v2 — 디자인 비차단) **채점으로는 이네스의 지기와 같다**(틀린 칸을 쥐고 맞으면 어느 판이든 5) — 헛손질은 틀린 칸을 자연스럽게 쥘 핑계일 뿐이다. 이 판의 개성은 이야기 쪽(상대가 의뢰인 본인, 맡는 값 −1과 보수 55의 거래)이고, 속임 베기가 정말 다른 지는 맛을 주는지는 판 M-6의 물음이다. 새 규칙은 당겨 오지 않는다.
     - "고른 쪽이 온다"는 만들지 않는다 — 고른 쪽은 이미 정산에서 한마디를 했고, 048의 버티기(굴리엘모)와 클라라의 맞수(베아트리체)가 그 사람들을 다시 세운다.
757. **플래그의 이름**: `sided_hatter` · `sided_baker` · `baker_helped` · `hatter_rematch`. 뜻은 이 표와 DECISIONS에만 있고 화면에 나오지 않는다. 뒷이야기는 맡아 정산하면 그 플래그로 다시 오지 않고, 돌려보내면 일정이 돌아와 다시 온다(그 날에 그 편의 플래그가 남아 있으므로).
758. **하루의 자리 — `day_06` · `day_07`, 일정이 이레를 돈다**:
     - `day_06`: [`pair_hatter`, 그다음 `day_03.tres`의 일곱을 그 차례로], `base_guests = 5`. 별 1에서도 `guest_count ≥ 3`이라 첫 자리는 늘 온다.
     - `day_07`: [`after_hatter`, `after_baker`, `feather_cut`, `first_blood`, `variants/first_blood_poor`, `variants/legs_only`, `variants/throw_bet`, `variants/first_blood_usurer`, `throw_match`], `base_guests = 5`. `day_04.tres`의 여덟에서 `spar.tres`를 빼고, (v2 — 디자인 비차단) **뒷이야기와 겹치는 셋을 목록 끝으로 민다** — 로렌초가 서는 비토리오(`first_blood_usurer`)와 티 안 나게 지기 둘(`throw_bet` · `throw_match`), 셋끼리는 `day_04`의 차례. 손님 수 셈은 그대로이고, 기준 다섯 안에는 뒷이야기 하나와 겹치지 않는 넷이 선다(셋은 별이 높을 때의 덤 자리) — "칼 든 손을 노리는 첫 의뢰"와 "의뢰인에게 져 주는 첫 판"이 같은 날 비슷한 판에 묻히지 않게. 거르면 아홉 가운데 하나 또는 둘이 빠진다(둘 다 돌려보냈으면 뒷이야기가 없다). 작업 0 ⑤가 세 파일의 경로를 다시 읽는다.
     - `day_schedule.tres`: 여섯째 · 일곱째. 8일차가 `day_01`(손님 셋), 대련은 11일차에 다시 온다(046 뒤에는 9일차). 저장에는 날 번호만 있어 저장은 그대로다. 049가 일정을 다시 짠다.
759. **그날의 단**: 6일차 — 굴리엘모 1단(처음 서는 날), 베아트리체 1단(7일차부터 2단). 7일차 — 로렌초 2단, 베아트리체 2단. `from_day`를 고치지 않는다(049).
760. **재는 길과 띠**(봇 통계, `-Opening 3`(0.64) · `-Nine` · `-Runs 60`):
     - 도구: `duel_stats.gd`의 `--finisher=top` — 끝내기의 칸이 **윗줄의 칼 쪽 베기**(모자를 쓴 상대면 모자, 아니면 칼 든 손 — 작업 0 ③이 조준 → 부위의 함수에서 그 방향을 읽어 적는다). 줄의 꼬리 `finisher=top`. **`--finisher`를 안 주거나 `on` · `off` · `low`인 줄은 고치기 전과 글자까지 같다**(V0).
     - 단계(`verify.ps1 -Stats`에 다섯 — 각각 하나의 명령으로도 돈다):
       - `pairhat`: `-Commission res://data/commissions/variants/pair_hatter.tres -Opening 3 -Nine -Runs 60 -Finisher top`(따라붙기는 안 주면 늘 — 045)
       - `pairhatwrong`: 같은 것 + `-Miss 0.1`
       - `pairspar`: `-Commission res://data/commissions/variants/pair_baker.tres -Opening 3 -Nine -Runs 60 -Finisher off -Bite 0.3`(속는 봇 — 헛손질의 셋에 하나를 막는다. 044 결정 677의 인자)
       - `pairsparclean`: 같은 것에서 `-Bite`를 뺀 것(속지 않는 봇 — **띠 없는 줄**, `pairspar`와의 차가 헛손질 읽기의 값이다)
       - `afterhand`: `-Commission res://data/commissions/variants/after_hatter.tres -Opening 3 -Nine -Runs 60 -Finisher top -Dive retreat -Tier 2`
       - 티 안 나게 지기(`after_baker`)는 지는 봇이 없어 재지 않는다(T152 ④와 판 M-6).
     - 띠(60판 — `stat,` 줄의 평균 초 · `끝 {…}`과 `score,` 줄):
       - (가) `pairhat` · `afterhand`: 평균 **≤ 70초**, 시간 초과 **≤ 6판**, 100점 **≥ 54판**.
       - (나) `pairhatwrong`: 시간 초과 **≤ 12판**, 조건 종료 **≥ 30판**.
       - (다) `pairspar`: 평균 **30~60초**(043의 35~60에서 아래만 원칙 1의 30으로), 시간 초과 **≤ 6판**, 조건 종료 **≥ 48판**(속는 봇이라 043의 54에서 낮춘다). `pairsparclean`의 평균 초 · 조건 종료를 함께 적는다.
     - 사다리(의뢰마다 두 번까지, 그 의뢰의 `.tres` 두 칸 `opponent_posture_max` · `opponent_recover_posture`만):

       | 걸린 것 | 고침 |
       |---|---|
       | (가) 평균 > 70 · 시간 초과 > 6, 또는 (나) | 자세 9 → 7 · 되찾는 자세 4 → 3 |
       | 그래도 걸림 | 자세 7 → 6 · 되찾는 자세 3 |
       | (다) 평균 > 60 · 시간 초과 > 6 · 조건 종료 < 48 | 되찾는 자세 3 → 2 |
       | (다) 평균 < 30 | 자세 3 → 4 |
       | (가) 100점 < 54인데 길이 · 시간 초과는 띠 안 | 고치지 않는다 — 끝의 갈래와 맞은 까닭을 보고서에 |
       | 두 번 고쳐도 띠 밖 | 멈추고 수를 보고한다(가장 가까운 값으로 두고 판 M-4) |

     - `-Tier`가 `-Commission`과 함께 서지 않으면(작업 0 ⑥) `afterhand`는 1단으로 재고 보고서에 적는다(멈추지 않는다). 60판이 3분을 넘겨 끊기면 `-Runs 30`으로 돌리고 띠의 판 수를 절반으로 읽는다.
761. **글의 틀**: 사연 280자 · 문단 둘(둘째가 상대의 버릇 귀띔), 정산의 글 56자 · 흥정 44자, 숫자 · 큰따옴표 · "치료비" 없음, 화면의 말(고리 · 칸)을 쓰지 않는다. **구간마다 참인 말** — 모자 · 칼 든 손(유효타만, 감점 30): 해냄 = 그 부위만 친 100점, 부분 = 그 부위 + 다른 부위 유효타(70 · 40 · 10), 못 해냄 = 그 부위를 못 친 판. 대련: 해냄 = 세 번, 부분 = 한두 번, 못 해냄 = 다치게 했거나 한 번도 못 무너뜨린 판(두 경우 모두 참인 말). 티 안 나게 지기: 해냄 · 부분은 그녀가 이긴 판, 못 해냄은 내가 이겼거나 시간이 다 됐거나 들킨 판. **두 쪽의 사연은 상대방이 곁에 서 있는 것을 말하고, 뒷이야기는 지난 판의 결과를 말하지 않는다**(플래그는 결과로 갈리지 않는다 — 결정 752). "어제"라 하지 않고 "지난번"이라 한다(돌려보낸 뒷이야기는 이레 뒤에 다시 온다).
762. **039를 따른다**(근거의 어긋남): `SPAR`는 굴리엘모 편, 그 판의 상대는 베아트리체. 045 · 043의 넘기는 것의 그 줄은 보고서 3번에 적고 DECISIONS의 이 결정이 바로잡는다.
763. **046과의 이음 — 5일차 귀족 → 6일차 제빵사**: 5일차에 레안드로의 일(굴리엘모의 다리)을 해냈어도 6일차에 굴리엘모가 걸어 들어와 칼을 든다. 이 계획은 귀족의 의뢰에 플래그를 걸지 않는다(읽는 데가 없는 플래그를 만들지 않는다). 두 쪽 · 뒷이야기의 글은 다리 · 백작을 말하지 않는다(레안드로를 몰라도 참 — 046의 넘기는 것). 049가 귀족을 7일차 뒤로 옮기거나 `requires_flags` · `excluded_flags`로 엮는다(BACKLOG 047-2, 판 M-8).
764. **그림 0장**: 의뢰인 그림 둘을 `client_portrait`에 건다(네 의뢰 모두). 굴리엘모의 모자는 045b의 `hat.png`. 모자를 쓴 굴리엘모가 밀착에서 HUD와 겹치는지는 V3의 결투 장 하나와 판 M-3.
765. **도움말 · 연습 화면의 줄은 넘긴다**: 네 의뢰는 연습 화면의 목록에 스스로 나온다(열넷 — 세 쪽). 같은 의뢰인 이름이 둘씩 선다(판 M-10). 도움말의 줄은 049.

## 의뢰의 데이터

줄바꿈은 사연 안의 한 번뿐(⏎). 글자 수는 작업 5가 세어 적고 넘치면 뜻을 지키며 줄인다(T59 · T117). `.tres`의 본보기는 046의 `variants/noble_baker.tres`(그림 줄을 더한 꼴 — `feather_cut.tres`), 대련은 `spar.tres`, 지기는 `throw_match.tres`. `partner`는 ext_resource 한 줄, `PackedStringArray("…")`로 적는다. `load_steps` = ext 수 + sub 수 + 1.

### `variants/pair_hatter.tres` — 목록에 서는 쪽

| 칸 | 값 |
|---|---|
| `client_name` | 모자 가게 베아트리체 |
| `dialogue` | 저 사람 화덕 그을음이 제 가게 창의 흰 깃털을 죄다 잿빛으로 만들었어요. 사과는커녕 빵 냄새 덕에 제 가게에 손님이 든다나요? 둘이 먼저 들어오겠다고 문 앞에서 다투다 같이 들어왔네요. 편을 못 얻은 쪽이 직접 칼을 들기로 했어요. 제 편이시죠? 저 높다란 제빵사 모자만 베어 주세요.⏎저 사람은 한 번 찍고는 화들짝 뒤로 뛰어요. 그때 막기를 풀고 따라붙어야 닿잖아요? 모자는 아주 무너뜨린 뒤에나 닿을 거예요. |
| `opponent` · `opponent_wears_hat` · `stage` | `opponent_07.tres` · 참 · `piazza.tres` |
| `client_portrait` | `res://assets/art/clients/beatrice.png` |
| `conditions` | `TargetPartCondition` — `target_part = 1`(HAT), `graze_penalty = 0`, `hit_penalty = 30` |
| `base_reward` · `tip_max` | 50 · 25 |
| `reputation_effect` | `{"accept": 0, "success": 2, "fail": -1, "win": 1}` |
| `haggle_min_stars` | 3 |
| `partner` · `sets_flags` · `excluded_flags` | `pair_baker.tres` · `["sided_hatter"]` · `["sided_hatter", "sided_baker"]` |
| `success_line` | 그 모자, 제 가게 창에 걸어 뒀어요. 그을음이 어디서 오는지 이제 다들 알겠죠? |
| `partial_line` | 모자는 떨어졌는데 다른 데도 다쳤다면서요? 저까지 못된 이웃 소리를 듣잖아요? |
| `fail_line` | 모자가 아직 그 머리 위에 있잖아요? 오늘도 깃털에 그을음이 앉겠네요. 값은 없어요. |
| `decline_line` | 둘 다 돌려보내요? 그럼 저 사람이랑 제가 직접 칼을 뽑으라는 거예요? |
| `haggle_agree_line` | 좋아요, 그 값에 해요. 대신 모자만이에요, 아셨죠? |
| `haggle_refuse_line` | 모자 하나에 그 값을요? 처음 값으로 해요. 덤도 줄일게요. |

### `variants/pair_baker.tres` — 짝

| 칸 | 값 |
|---|---|
| `client_name` | 제빵사 굴리엘모 |
| `dialogue` | 허허, 그을음 얘긴 맞습죠. 그래도 아침마다 제 가게 문 앞에 소금을 뿌려 대니 손님이 발을 돌립죠. 칼로 가리자기에 같이 왔습니다. 저 양반을 다치게 하진 마시고 세 번만 넘어뜨려 주십쇼. 사람들 앞에서 세 번 넘어지면 더는 우기지 못합죠. 내일도 마주 보고 장사할 이웃입죠.⏎저 양반은 한 번 휘두르는 척하고 다른 데를 칩죠. 처음 휘두르는 쪽에 손을 묶어 두지 마십쇼. 넘어진 뒤엔 건드리지 마시고요. 식기 전에! |
| `opponent` · `stage` | `opponent_06.tres` · `piazza.tres` |
| `opponent_posture_max` · `opponent_recover_posture` | 3 · 3 |
| `client_portrait` | `res://assets/art/clients/guglielmo.png` |
| `conditions` | `SparCondition` — `topples_needed = 3`, `partial_scores = PackedInt32Array(0, 25, 50)`, `wound_score = 0`, `hold_hint = "건드리지 마십쇼"` |
| `base_reward` · `tip_max` | 30 · 15 |
| `reputation_effect` | `{"accept": 0, "success": 3, "fail": -1}` |
| `haggle_min_stars` | 1 |
| `sets_flags` | `["sided_baker"]` (`partner` · 거름 칸은 비운다) |
| `success_line` | 세 번 넘어지고는 그 양반이 먼저 소금 바가지를 치웠습죠. 빵 하나 가져가요. |
| `partial_line` | 넘어지긴 했는데 세 번은 못 됐습죠. 우길 구석이 남았으니 값도 그만큼만 드립죠. |
| `fail_line` | 오늘 일은 없던 걸로 합죠. 내일도 소금과 그을음으로 다투겠습죠. 값은 없습니다. |
| `decline_line` | 허허, 그럼 우리끼리 반죽을 치대 봐야겠습죠. 빵이 식기 전에! |
| `haggle_agree_line` | 얼마든 좋습죠. 대신 그 양반 털끝 하나 다치면 안 됩니다. |
| `haggle_refuse_line` | 빵값으로 치르는 처지라 그건 어렵습죠. 처음 값으로 합죠. |

### `variants/after_hatter.tres` — 그녀 편을 든 다음 날

| 칸 | 값 |
|---|---|
| `client_name` | 제빵사 굴리엘모 |
| `dialogue` | 지난번엔 그 양반 편이셨지요. 원망은 없습죠. 그런데 오늘 아침 로렌초라는 멋쟁이가 그 양반 가게에서 모자를 써 보고는 촌스럽다며 손으로 구겨 던졌답니다. 그 양반은 이 가게에 또 오기 민망하다기에 제가 왔습죠. 값은 제가 치릅죠, 이웃이니까. 모자를 구긴 그 손에 한 줄만 그어 주십쇼.⏎그 멋쟁이는 몸을 뒤로 빼면 뛰어듭죠. 그때 같이 물러서면 헛칩니다. 구긴 손은 아주 무너뜨린 뒤 칼 쪽 위를 베야 닿습죠. |
| `opponent` · `stage` | `opponent_03.tres` · `alley.tres` |
| `client_portrait` | `res://assets/art/clients/guglielmo.png` |
| `conditions` | `TargetPartCondition` — `target_part = 4`(SWORD_HAND), `graze_penalty = 0`, `hit_penalty = 30` |
| `base_reward` · `tip_max` | 30 · 20 |
| `reputation_effect` | `{"accept": 1, "success": 3, "fail": -1, "win": 1}` |
| `haggle_min_stars` | 1 |
| `requires_flags` · `excluded_flags` · `sets_flags` | `["sided_hatter"]` · `["baker_helped"]` · `["baker_helped"]` |
| `success_line` | 그 멋쟁이가 손등을 감싸 쥐고 갔답니다. 그 양반이 처음으로 제 빵을 사 갔습죠. |
| `partial_line` | 손에 한 줄은 그었는데 다른 데까지 다쳤다지요. 이웃 일로 시끄러워지면 곤란합죠. |
| `fail_line` | 그 손은 멀쩡하답니다. 구겨진 모자는 제가 다려 볼 수밖에요. 값은 못 드립죠. |
| `decline_line` | 허허, 이웃 일까지 떠맡기긴 무리였습죠. 반죽이나 치대러 가겠습니다. |
| `haggle_agree_line` | 얼마든 좋습죠. 그 손만입니다, 그 손만. |
| `haggle_refuse_line` | 빵 판 돈으로 치르는 거라 그건 어렵습죠. 처음 값으로 합죠. 덤도 줄입죠. |

### `variants/after_baker.tres` — 그의 편을 든 다음 날

| 칸 | 값 |
|---|---|
| `client_name` | 모자 가게 베아트리체 |
| `dialogue` | 지난번 광장에서 당신이 빵장수 편으로 제 앞에 섰잖아요? 이제 온 골목이 저더러 대리인까지 붙을 만큼 못된 이웃이래요. 그러니 이번엔 같은 광장에서 제 상대로 서서 져 주세요. 제가 이겨야 말이 바뀌잖아요? 봐준 티가 나면 더 웃음거리고요.⏎제 칼은 휘두르는 척을 섞어요. 척하는 쪽을 막고 있다가 진짜에 맞으면 속은 걸로 보이잖아요? 가만히 서서 맞거나 금방 쓰러지면 다들 눈치채요. |
| `opponent` · `stage` | `opponent_06.tres` · `piazza.tres` |
| `client_portrait` | `res://assets/art/clients/beatrice.png` |
| `conditions` | `ThrowUndetectedCondition`(기본 값) |
| `base_reward` · `tip_max` | 55 · 30 |
| `reputation_effect` | `{"accept": -1, "success": 0, "fail": -1}` |
| `haggle_min_stars` | 2 |
| `requires_flags` · `excluded_flags` · `sets_flags` | `["sided_baker"]` · `["hatter_rematch"]` · `["hatter_rematch"]` |
| `success_line` | 광장 사람들이 제가 이겼다고 손뼉을 쳤어요. 다음엔 제 가게로 오세요? |
| `partial_line` | 이기긴 했는데 봐준 거 아니냐고 수군대요. 반만 체면을 세운 셈이잖아요? |
| `fail_line` | 광장 사람들이 또 웃었어요. 이래선 제 모자가 안 팔리잖아요? 값은 없어요. |
| `decline_line` | 져 주는 건 못 하겠다고요? 그럼 제 체면은 누가 세워 주죠? |
| `haggle_agree_line` | 좋아요, 그 값에 해요. 대신 티 나면 안 돼요, 아셨죠? |
| `haggle_refuse_line` | 져 주는 값치고 너무하잖아요? 처음 값으로 해요. 덤도 줄일게요. |

- planner의 셈: 사연은 넷 다 약 220~250자(첫 문단 150~170 · 둘째 70~85). 작업 5가 다시 센다.
- 모자 · 칼 든 손의 못 해냄 글("모자가 아직 그 머리 위에", "그 손은 멀쩡")은 다른 부위 유효타 넷(무너짐 넷)으로 0점이 된 판에서 거짓이다 — 90초 안에서는 거의 없다(위험 R7).

### 하루 · 일정

- `data/days/day_06.tres`: 위 결정 758. `day_07.tres`: 같다. `load_steps` = ext 수 + 1.
- `data/day_schedule.tres`: ext 두 줄(`8_day06` · `9_day07`), `load_steps` 8 → 10, `days` 끝에 두 칸.

## 코드

| 파일 | 더하는 것 | 크기(어림) |
|---|---|---|
| `scripts/commission/commission.gd` | `partner` · `sets_flags` · `requires_flags` · `excluded_flags`, `allowed_by(flags)` | 15줄 |
| `scripts/economy/day_data.gd` | `for_flags(flags) -> DayData` | 12줄 |
| `scripts/economy/day_state.gd` | `flags`, `_side`, `current_commission`의 한 갈래, `partner_commission` · `can_switch_side` · `switch_side`, `decline`의 짝 갈래, `finish_duel`의 플래그, `_begin_day` · `tomorrow_data`의 거름, 저장 · 되돌리기의 `flags`와 `_clean_flags` | 50줄 |
| `scripts/commission/counter.gd` | 상수 일곱, 짝이 있을 때의 `Partner` · `SwitchSide` · 두 버튼의 글 · 상대 줄의 꼬리, `_switch_side()` | 35줄 |
| `tests/duel_stats.gd` · `run_duel_stats.ps1` · `verify.ps1` | `--finisher=top`, 다섯 단계 | 20줄 |

주석은 까닭만 한 줄(결정 번호): 짝은 한쪽에만(749), 흥정하면 굳는다(750), 오늘의 플래그는 내일부터(752), 거르지 않으면 같은 객체(752).

## 기존 테스트를 고치는 곳

"손"은 표 · 기대 값을 고치는 것, "자동"은 폴더 · 일정을 읽어 스스로 걸리는 것이다. 표 밖의 기대 값은 고치지 않는다(걸리면 멈추고 까닭을 적는다). 줄 번호와 정확한 자리는 작업 0이 Grep으로 다시 읽는다.

| 자리 | 지금(046 뒤) | 047 뒤 | 길 |
|---|---|---|---|
| T136(`sixth_opponent_tests.gd`) "어느 의뢰도 베아트리체를 걸지 않는다" | 빈 목록 | 그녀를 거는 의뢰 `["after_baker.tres", "pair_baker.tres"]`(T126 ⑦의 꼴). **그 파일은 그 확인의 몇 줄만** | 손 |
| T141 ⑥(`seventh_opponent_tests.gd`) | `["noble_baker.tres"]` | `+ "pair_hatter.tres"`. 그 파일은 ⑥만 | 손 |
| 로렌초를 거는 의뢰의 목록(`third_opponent_tests` · `second_opponent_tests` — 작업 0이 찾는다) | 비토리오 | `+ "after_hatter.tres"` | 손 |
| `second_opponent_tests.gd`의 의뢰마다의 상대 | 열 | 네 갈래(경로 상수 넷) | 손 |
| T72(`stage_tests.gd`) `ASSIGNED` | 열 | `pair_hatter` · `pair_baker` · `after_baker` = `piazza.tres`, `after_hatter` = `alley.tres`. "열" → "열넷" | 손 |
| T77(`counter_art_tests.gd`) `PORTRAITS` · `NO_PORTRAIT` | 여덟 · 둘(046) | `PORTRAITS`에 넷(`beatrice.png` 둘 · `guglielmo.png` 둘) | 손 |
| T59(`client_line_tests.gd`) `PATHS` | 열 | 넷을 더한다. "열" → "열넷" | 손 |
| T37(`day_tests.gd`)의 두 목록 · `reputation_tests.gd` `COMMISSION_PATHS` | 열 | 넷을 더한다 | 손 |
| `opening_chance_tests.gd` `DAY_OPPONENTS` | 여섯(046) | `opponent_06`을 더한다(작업 0이 `opening_miss_limit`이 0인지 읽는다 — 아니면 더하지 않고 적는다) | 손 |
| 일정의 날 수를 넷 · 다섯으로 적은 곳 | (046 R4는 없다고 읽었다) | 작업 0이 `day_for(` · `days.size()` · `day_05`를 다시 Grep. 걸리면 멈춰 적는다 | — |
| 카운터의 고리(T 카운터 · 흥정 · 머리 줄) | 짝 없는 손님 | **그대로** — 짝이 없으면 노드 · 글이 같다(T149 ⑦이 굳힌다) | — |
| T115(`style_tests.gd` `t115_day_practice_save`, 750~754행 곁) | `saved_state()`의 열쇠를 정렬해 `["day", "dice_seed", "money", "owned", "reputation", "version"]`와 글자로 견준다 | (v2 — T1) 그 목록에 `"flags"`를 더한다(정렬된 자리 — `"dice_seed"`와 `"money"` 사이). **그 파일의 diff는 그 한 줄뿐** | 손 |
| `save_tests.gd` · `settings_tests` · `controls_tests`의 저장 | 키 여섯 | **그대로** — 열쇠를 센 곳이 없다(작업 0 ④가 `saved.size()` · `keys()` · 열쇠 목록의 글을 다시 Grep. T115 밖에서 걸리면 멈춰 적는다) | — |
| T21 · T22(`flow_tests.gd`) · T133 ②(`spar_tests.gd`) · T115의 하루 표 · 골든 · 패턴 표 | — | **그대로** — 넷 다 `variants/`, 대련 쪽은 짝이라 어느 하루 목록에도 없다 | — |
| T117 (바) · 연습 화면의 목록 · `manuscript_tests`의 HUD 글 · 일정의 갈래 셈(INFO) | 폴더 · 일정 | 자동(의뢰 열넷 — 세 쪽, 사연의 줄 수, 조건 글) | 자동 |
| UI 찍기 `select` | 첫 쪽 다섯 | 이름순으로 첫 쪽이 바뀔 수 있다(`after_*`가 앞) — 화소가 달라지는 것이 맞다 | 자동 |
| 봇 통계의 기존 줄 | — | 글자까지 그대로(V0) | 자동 |

### 새 테스트(`tests/pair_tests.gd` — `run_tests.gd`의 `TEST_FILES` 끝에 한 줄)

판은 씬 없이 코어와 봇만 건다(`spar_tests.gd` ①의 꼴). **`States.put`을 쓰지 않고, 화면은 붙인 뒤 `advance` · `tick` 없이 글만 읽는다**. 하루는 평판 규칙을 실은 `DayState.new(…, reputation_rules)`와 시험용 `DayData` · `DaySchedule`(코드로 만든 것)로.

| ID | 이름 | 보는 것 |
|---|---|---|
| T148 | 플래그와 거르기 | ① `allowed_by`: 빈 칸이면 늘 참, `requires` 모두 · `excluded` 하나의 갈래 여섯. ② `for_flags`: 거를 것이 없으면 **같은 객체**, 있으면 새 객체 · 원본의 목록 길이 그대로 · `base_guests` 같음. 실제 `day_01`~`day_05`는 어떤 플래그에도 같은 객체. ③ 시험 일정(이틀): 1일차 손님 A(`sets_flags = ["x"]`)를 맡아 정산 → `flags == ["x"]`, 1일차의 `data`는 그대로(하루 중에 바뀌지 않는다), `tomorrow_guests()`가 거른 수, 2일차의 목록에서 `requires ["x"]`는 오고 `excluded ["x"]`는 빠진다. ④ 돌려보내면 플래그가 남지 않는다. 0점(시간 초과)으로 정산해도 남는다. 같은 플래그는 한 번, 빈 글은 넣지 않는다 |
| T149 | 한 자리, 두 쪽 | ① `DayState`: 짝 있는 자리에서 `current_commission()`이 목록의 의뢰, `switch_side()` 뒤 짝, 다시 뒤 목록의 것. `partner_commission()`은 늘 말하지 않는 쪽. ② 짝 없는 자리에서 `switch_side()`가 거짓이고 아무것도 바뀌지 않는다. ③ 흥정 뒤 `can_switch_side()` 거짓 · `switch_side()` 거짓(받아 줌 · 거절 둘 다). ④ 짝 쪽을 맡아 정산: 결과의 `client_name`이 짝의 것, 평판 항목이 짝의 `reputation_effect`, 플래그가 짝의 `sets_flags`. ⑤ 둘 다 돌려보냄: `declined`가 한 칸 `"A · B"`, `last_declined`가 말하던 쪽, 다음 손님에서 `_side`가 0(`current_commission()`이 다음 목록의 것), 폐점의 `missed`가 짝 없는 같은 하루와 같다. ⑥ 카운터(짝 있는 손님, 평판 규칙을 실은 6일차): `Partner` · `SwitchSide`가 있고 버튼 글이 `SWITCH_BUTTON % 짝의 이름`, `Proceed`가 `PAIR_ACCEPT`, `Decline`이 `PAIR_DECLINE`, "상대:" 줄이 "굴리엘모 · 치고 빠지기"와 `PAIR_OPPONENT_TAIL`을 담는다. 쪽을 바꾼 하루로 새 카운터를 붙이면 이름 · 사연 · "상대: 베아트리체 · 속임 베기"가 짝의 것. 흥정한 뒤의 새 카운터는 `SwitchSide`가 꺼져 있고 `SWITCH_LOCKED`. (v2 — T2) **같은 카운터**에서 `_on_haggle()`을 부른 뒤(주사위는 `haggle(roll)`로 받아 줌 · 거절 둘 다) `SwitchSide.disabled`가 참이고 글이 `SWITCH_LOCKED`이며, 그 뒤 버튼의 누름 함수를 불러도 `_side`가 그대로다(`switch_side()`가 거짓 — 테스트에서는 `_go()`가 아무 데도 가지 않으므로 상태로 본다). ⑦ 짝 없는 손님의 카운터: `Partner` · `SwitchSide`가 없고 `Proceed` · `Decline`의 글이 "맡는다" · "돌려보낸다" |
| T150 | 플래그의 저장 | ① 새 하루의 아침 저장에 `"flags"`가 빈 배열. ② 폐점의 저장에 그날 남긴 플래그. `restore` → 같은 `flags`, 그날(내일)의 목록이 거른 것. ③ `"flags"`가 없는 옛 저장(버전 1) → 읽히고 빈 목록. ④ 쓰레기(`"flags": 3`, `[1, "", "a", "a", 65자 글]`) → `["a"]`. ⑤ `GameSession`의 길(`save_tests.gd` [라]~[마]의 꼴): 6일차 아침에서 시작해 첫 손님의 쪽을 바꾸고 아침 저장이 그대로인지(쪽은 저장에 들지 않는다), 짝 쪽을 맡아 정산 · 폐점 · 저장 → 이어 하기 → 7일차의 첫 손님이 `after_baker`. 그만두고(하루 중) 이어 하면 플래그가 아침의 것 |
| T151 | 네 의뢰와 이레 | ① 데이터: 위 표의 칸 — 두 쪽의 상대가 엇갈린다(`pair_hatter.opponent` = `opponent_07`(굴리엘모), `pair_baker.opponent` = `opponent_06`(베아트리체) — 저마다 짝의 의뢰인 본인), 조건 타입 넷이 위 표대로, 모자 · 무대 · 그림 경로 · 자세 칸, `pair_hatter.partner == pair_baker`, **짝의 `partner` · 거름 칸이 비었다**, `load_tree`의 어느 의뢰도 짝의 짝을 갖지 않고 어느 하루 목록에도 짝이 없다, 사연에 상대의 `display_name`이 있다(로렌초 · 베아트리체는 "그 양반" · "저 양반"으로 부르니 **뒷이야기 `after_hatter`에만 "로렌초"**를 본다), 플래그의 칸이 결정 754 · 756 그대로. ② 일정: `day_schedule`의 여섯째 · 일곱째가 `day_06` · `day_07`, `day_06`의 첫째가 `pair_hatter`, `day_07`의 첫째 · 둘째가 `after_hatter` · `after_baker`이고 마지막 셋이 `throw_bet` · `first_blood_usurer` · `throw_match`(v2 — 겹치는 판은 끝에, 결정 758), 별 1~5 모두 `guest_count ≥ 3`(플래그 없음 · 한쪽 · 둘 다로 거른 목록에서), `day_01~05`에 넷이 없다, `day_06` · `07`에 `spar.tres`가 없다. ③ 거름: 플래그 없음 → `day_07`에서 둘 다 빠지고 `day_06`에는 `pair_hatter`, `["sided_hatter"]` → `day_07`의 첫째가 `after_hatter` · `day_06`에 `pair_hatter` 없음, `["sided_baker"]` → `after_baker`, `["sided_hatter", "baker_helped"]` → 둘 다 빠진다. ④ 단: 6일차 굴리엘모 · 베아트리체 1단, 7일차 로렌초 · 베아트리체 2단(`style_label`). 의뢰의 자세 칸이 0이면 `fit_opponent(상대) == 상대`(객체), 0이 아니면 1 ≤ 되찾는 자세 ≤ 자세 ≤ 9 |
| T152 | 네 판 | ① 모자(굴리엘모 `with_opening(1.0)`, 의뢰의 조건 · 모자, 쥐고 막고 늘 따라붙는 봇, 끝내기 윗줄 칼 쪽): 씨앗 1~5 가운데 한 판 이상 `End.CONDITION` · 100점. 가운데 중단 끝내기 봇은 씨앗 1~3 모두 조건으로 끝나지 않는다. ② 대련(베아트리체 `with_opening(1.0)`, 의뢰의 자세 3 · 3 — `fit_opponent`, 끝내기 없는 봇, 속지 않음): 한 판 이상 `End.CONDITION` · 100점, 무너진 그녀를 친 판이 없다. ③ 칼 든 손(로렌초 2단 `with_opening(1.0)`, 물러서는 봇, 끝내기 윗줄 칼 쪽): 한 판 이상 100점, 그 판의 유효타가 `SWORD_HAND` 하나. ④ 티 안 나게 지기(기록을 손으로 — `spar_tests`의 기록 꼴): 막기 넷 · 닿음 둘 · 40초 뒤 패배인 두 기록에서 맞은 상황만 다르다 — `GUARD`(쥔 채)로 맞은 기록의 점수가 `UNGUARDED`로 맞은 기록보다 높다(사연 둘째 문단의 셈이 참이다). ⑤ 정산(평판 규칙을 실은 하루, 6 · 7일차 배율 200)의 `Reaction`이 네 의뢰 × 세 구간(위 결정 761의 기록)에서 그 글, 평판 항목이 `reputation_effect × 2`(뒷이야기 `after_baker`의 해냄 항목은 없다 — `success 0`) |

## 확인

나눔(메모리 — 3분 넘는 명령이 끊긴다): 테스트는 `tests/run_tests.ps1 -SkipImport -Only <묶음>`을 046 보고서의 묶음대로 돌리고 `pair`를 한 묶음으로 더한다. 모든 줄이 `ALL PASS`이고 합이 N + 5. 한 묶음이 끊기면 둘로 나눠 다시. `verify.ps1`은 `-Only smoke` · `-Only counter` · `-Only ui`를 따로. 봇 통계는 단계마다 한 명령.

- **V0**(작업 0, 고치기 전): `run_duel_stats.ps1 -Commission res://data/commissions/variants/noble_baker.tres -Opening 3 -Nine -Runs 30 -Finisher low`와 `run_duel_stats.ps1 -Commission res://data/commissions/spar.tres -Opening 3 -Nine -Finisher off -Runs 30`의 `stat,` · `score,` · `parts,` 줄을 받아 둔다(작업 4 뒤의 같은 명령과 **다른 줄 0**).
- **V1**(verifier): 묶음 모두 `ALL PASS`, 합 (N+5)/(N+5), 가져오기 오류 0, `verify.ps1 -Only smoke`(1~3일차 — 그대로) · `-Only counter` OK, `run_ui_shots.ps1` → `UI SHOTS OK (M+5)`(M은 046 뒤의 장 수 — 33으로 예상. 작업 7이 결투 장을 이 도구에 더하면 M+6).
- **V2**(verifier): 결정 760의 다섯 단계를 하나씩 — `stat,` · `score,` · `parts,` 줄을 띠로 읽는다. V0의 두 명령을 다시 돌려 다른 줄 0. `verify.ps1 -Stats`의 목록에 다섯이 있다(Grep — 목록 전체를 한 번에 돌리지 않는다).
- **V3**(verifier + 메인이 장을 읽는다): UI 찍기의 새 장 다섯 — `counter-pair`(6일차, 베아트리체가 말하고 굴리엘모가 뒤에), `counter-pair-other`(쪽을 바꾼 하루), `counter-pair-haggled`(흥정한 뒤 — 꺼진 버튼), `counter-after-hatter` · `counter-after-baker`(7일차, 플래그를 넣은 하루). 이름 · 사연(문단 둘) · 조건 글 · "상대:" 줄과 꼬리 · 소문(뒷이야기 둘) · 흥정 줄 · 보수가 말풍선 안에 서고, `Partner`가 말하는 쪽의 그림 · 말풍선 · 버튼을 가리지 않으며 화면 왼쪽 끝에서 잘린 만큼을 적는다. `SwitchSide`가 `Quit` · `QuitNote`와 겹치지 않는다. 결투 장 하나 — 모자를 쓴 굴리엘모의 밀착(045b의 모자 한계를 넘지 않는지). 카운터 장은 결투 씬을 쓰지 않으므로 `tick`이 없다.
- 창에서만 볼 것(번갈아 듣기의 다시 미끄러짐, 손맛)은 판 M이다. playtester는 부르지 않는다.

## 작업 목록

차례대로. 작업마다 Sonnet 하위 에이전트 하나, 메인이 diff를 본다. 새 `.gd`의 `.uid`는 가져오기가 만든다(함께 커밋).

| # | 작업 | 대상 | 완료 확인 |
|---|---|---|---|
| 0 | **시작점 읽기**(고치지 않는다): ① HEAD가 `83cf9e7`(046의 끝 커밋)이거나 그 뒤이고 `git status`에 남은 것이 다른 곳의 파일(`.gitignore`, `R02b` · `H01` 계획)과 이 계획 파일뿐 ② N · 장 수 M(046 보고서)과 테스트 묶음 ③ 조준 → 부위의 함수에서 **윗줄의 칼 쪽 베기**의 방향(모자를 쓰면 모자, 안 쓰면 칼 든 손인지) ④ "기존 테스트를 고치는 곳"의 자리를 Grep으로(`opponent_06` · `opponent_07` · `opponent_03`을 거는 의뢰의 목록, `ASSIGNED` · `PORTRAITS` · `PATHS` · `COMMISSION_PATHS` · `DAY_OPPONENTS` · `day_for(` · `days.size()` · `saved.size()` · `keys()` · `"dice_seed", "money"` — T115의 열쇠 목록은 "손" 줄로 이미 안다) ⑤ `opponent_06`의 `opening_miss_limit`, `day_03` · `day_04`의 목록 차례와 `day_07`에서 끝으로 미는 세 파일의 경로, `ThrowUndetectedCondition`의 상황 셈이 `PlS.GUARD` → `WRONG_GUARD`인지 ⑥ `duel_stats.gd`에서 `--tier`가 `--commission`의 상대에도 걸리는지 ⑦ V0 | Grep · Read · verifier | 일곱 답을 보고서 초안에. V0의 줄을 작업 폴더(`%TEMP%\bravi-047\`)에. ③ · ⑤가 근거와 다르면 멈추고 보고한다 |
| 1 | 의뢰와 하루의 칸(결정 749 · 752): `partner` · 플래그 세 칸 · `allowed_by`, `DayData.for_flags` | `scripts/commission/commission.gd`, `scripts/economy/day_data.gd` | 작업 6의 T148 ① · ② |
| 2 | `DayState`(결정 750 · 752 · 753): 쪽 · 플래그 · 거름 · 저장. `restore()`는 `flags`를 `_begin_day()` **앞에서** 채운다(결정 753) | `scripts/economy/day_state.gd` | T148 ③ · ④, T149 ①~⑤, T150(② · ⑤가 이어 한 날의 거른 목록을 본다). 메인이 diff에서 `restore()`의 차례를 본다. `settlement.gd` · `closing.gd` · `game_session.gd`의 diff 0줄 |
| 3 | 카운터(결정 751): `_switch_button` 멤버, 그 꺼짐 · 글은 `_refresh_haggle()`이 그 자리에서 고친다(흥정 직후 지금의 화면), 누름은 `switch_side()`가 참일 때만 `_go()` | `scripts/commission/counter.gd` | T149 ⑥(같은 카운터의 `_on_haggle` 뒤 줄 포함) · ⑦, V3 |
| 4 | 도구(결정 760): `--finisher=top`과 머리 주석, `run_duel_stats.ps1` 머리 주석, `verify.ps1`의 다섯 단계(목록 · `$scripts` · `$extra` · 거름 · 머리 주석). `.ps1`은 ASCII만 | `tests/duel_stats.gd`, `tests/run_duel_stats.ps1`, `tests/verify.ps1` | V0의 두 명령이 다른 줄 0 |
| 5 | 데이터: 네 의뢰(위 표 — `target_part`는 작업 0 ③의 값으로 다시 본다), `day_06` · `day_07`, `day_schedule.tres`. 글자 수를 세어 적는다 | `data/commissions/variants/pair_hatter.tres` · `pair_baker.tres` · `after_hatter.tres` · `after_baker.tres`(새), `data/days/day_06.tres` · `day_07.tres`(새), `data/day_schedule.tres` | 가져오기 오류 0(짝의 ext_resource가 돌지 않는다), 글자 수(사연 ≤ 280 · 정산 ≤ 56 · 흥정 ≤ 44) |
| 6 | 테스트: `pair_tests.gd`(T148~T152)와 `TEST_FILES`, "기존 테스트를 고치는 곳"의 "손" 줄. 지시문에 "`States.put` 뒤 `advance` · `tick` 금지" 한 줄 | `tests/pair_tests.gd`(새), `tests/run_tests.gd`, `tests/style_tests.gd`(T115의 열쇠 목록 한 줄 — T1), 표의 파일들 | V1의 묶음. 메인이 `pair_tests.gd`에 `States.put`이 없는지, `sixth` · `seventh_opponent_tests.gd`의 diff가 그 확인의 줄뿐인지, `style_tests.gd`의 diff가 열쇠 목록 한 줄뿐인지 본다 |
| 7 | UI 찍기의 장 다섯(V3)과 장 수 M → M + 5(`ui_shots.gd`, `run_ui_shots.ps1`의 머리 주석 · `$count`), 결투 장 하나는 기존 결투 찍기의 꼴(작업 0이 고른다 — 없으면 판 M-3으로 넘기고 적는다) | `tests/ui_shots.gd`, `tests/run_ui_shots.ps1` | V3 |
| 8 | verifier로 V1 → V2 → V3. 띠 밖이면 결정 760의 사다리와 그 단계 · T151 ④ · T152 묶음만 다시. V3에서 `Partner` · `SwitchSide`가 겹치면 결정 751의 상수만 고쳐 그 장을 다시 | 두 의뢰의 `.tres`, `counter.gd`의 상수 | 띠 안 · 겹침 0, 또는 멈춤과 수의 보고 |
| 9 | 문서와 커밋: DECISIONS 747~765(값 고침 · 상수 고침이 있으면 그 줄), CLAUDE.md 4장(의뢰의 칸 `partner` · 플래그 셋, 칼 든 손 · 의뢰인에게 져 주기), 5장(짝 손님과 번갈아 듣기, 플래그와 저장, "닷새치" → "이레치", 만든 범위), 9장, HANDOFF(1번 · 판 M), BACKLOG(047-1~4 아래 "넘기는 것"), 보고서 `docs/reports/047-two-at-the-counter.md`(10장의 꼴 — 띠의 수, 글자 수, 장의 겹침, 045 · 043 넘기는 것의 어긋남) | 문서, **이 계획 파일** | 커밋 하나. `git status`에 남은 것이 작업 0 ①의 다른 곳의 파일뿐 |

## 위험

- **R1 번갈아 듣기가 씬을 다시 연다**: 의뢰인이 다시 미끄러져 들어오고 열린 직후의 누름이 0.4초 안팎 삼켜진다(`Ui.swallow_arrival_press`). 여러 번 오가면 굼뜨게 느껴질 수 있다. → 처음 값으로 두고 판 M-1. 되돌리기: 카운터 안에서 말풍선 · 사람만 바꾸는 길(`_build`를 다시 부른다 — 노드를 지우는 일이 생겨 이 계획에서는 하지 않는다).
- **R2 플래그가 결과를 모른다**: 그의 편을 들어 대련을 망쳐도 다음 날 그녀가 "빵장수 편으로 제 앞에 섰잖아요?"라고 온다 — 참이지만, 망친 판의 뒷맛이 해낸 판과 같다. → 결정 752(결과 플래그는 칸 하나로 더할 수 있다), 판 M-7.
- **R3 5일차 귀족 → 6일차 제빵사**: 결정 763, BACKLOG 047-2, 판 M-8.
- **R4 표를 빠뜨린다**: 의뢰 넷이 열 곳 남짓의 표를 건드린다. → 작업 0 ④의 Grep, 작업 6의 완료 확인이 전체 묶음이다.
- **R5 봇이 못 재는 판**: 티 안 나게 지기(지는 봇이 없다), 속는 사람의 대련(봇의 `-Bite`는 무작위 — 사람은 버릇으로 속는다). → T152 ④의 기록 셈, `pairspar` · `pairsparclean`의 차, 판 M-4 · M-6.
- **R6 모자 쓴 굴리엘모**: 그가 물러나 멀리로 가면 모자가 작아지고, 밀착에서는 모자 꼭대기가 HUD에 닿을 수 있다(041이 세라피나에게 모자를 씌우지 않은 까닭). → V3의 결투 장, 판 M-3. 걸리면 `opponent_wears_hat`은 그대로 두고 045b의 모자 한계를 보고서에 적는다(그림 · 그림 데이터는 고치지 않는다).
- **R7 못 해냄의 글이 거짓인 드문 판**: "의뢰의 데이터" 끝의 줄. `hit_penalty`를 높이면 줄지만 부분의 구간이 사라진다 — 고치지 않는다.
- **R8 의뢰인 열셋에 하나 모자란다**: 이 계획 뒤 12. 049의 "토마소가 데려온 손님"이 열셋째다. 049가 그 자리를 비우면 051이 미달로 적는다(BACKLOG 047-3).
- **R9 일정이 이레를 돈다**: 8일차부터 `day_01`이고 대련이 11일차로 밀린다. 7일차에 로렌초를 거는 의뢰가 둘(뒷이야기 · 비토리오)이고 지기가 셋(뒷이야기 · 가스파로 · 이네스) 설 수 있다. → (v2) 겹치는 셋을 `day_07`의 끝(덤 자리)으로 밀었다(결정 758). 049가 다시 짠다, 판 M-9.
- **R10 같은 이름이 둘씩**: 연습 화면의 목록에 "제빵사 굴리엘모" · "모자 가게 베아트리체"가 두 줄씩 선다(조건 글로 갈린다). 이름이 겹치면 안 된다는 테스트가 있으면 작업 0 ④가 찾고 멈춘다(이름을 바꾸지 않는다 — 같은 사람이다).
- **R11 다른 곳의 R02b**: 그 계획이 실행되면 이 계획의 판 길이가 바뀐다 — 그쪽이 V2의 다섯 단계를 다시 돌린다(BACKLOG 047-4).

## 멈출 조건

- 작업 0 ③(윗줄의 칼 쪽 베기가 모자 / 칼 든 손이 아님) · ⑤(쥔 채 맞음이 `WRONG_GUARD`가 아님)이 근거와 다르면 — 뒷이야기 둘의 귀띔이 거짓이 된다. 멈추고 보고한다.
- `.tres`의 짝(`partner`)이 가져오기에서 돌거나 오류를 내면 — 짝을 경로 글(`partner_path`)로 바꾸는 것은 구현 전제가 바뀌는 일이다. 멈추고 보고한다.
- 표 밖의 기존 테스트가 걸리면 그 테스트를 "손"으로 옮기지 말고 멈춰 적는다.
- 사다리를 두 번 밟아도 띠 밖이면 그 의뢰는 가장 가까운 값으로 두고 수를 보고한다(계획은 이어 간다).

## 넘기는 것

- **048**: 버티기(굴리엘모) · 클라라의 맞수(베아트리체)의 사연은 6일차의 다툼을 몰라도 참이어야 한다 — 또는 `requires_flags`로 엮는다(그 계획이 정한다). T136 · T141 ⑥의 목록에 그 파일을 더한다.
- **049**: `day_06` · `day_07`을 다시 짠다(뒷이야기와 같은 날의 로렌초 · 지기 겹침, 귀족을 둘이 함께 뒤로), 의뢰인 열셋째, 날별 봇 통계에 이 다섯 단계, 도움말의 줄.
- BACKLOG에 남길 줄: 047-1 번갈아 듣기를 씬을 다시 열지 않고(R1) · 047-2 귀족과 제빵사의 이음(결정 763) · 047-3 의뢰인 열셋째(R8) · 047-4 R02b가 실행되면 V2를 다시.

## 나중에 사용자가 볼 판 — 판 M(HANDOFF 3번으로. 계획을 막지 않는다)

6일차의 첫 손님을 만나거나, 처음 화면의 "연습"에서 의뢰 넷을 골라 본다. 뒷이야기는 6일차에 한쪽 편을 들고 7일차로 넘어가야 카운터에 선다(연습에서는 바로).

- **M-1 번갈아 듣기**: 뒤에 흐리게 선 사람이 읽히는가, "○○의 말을 듣는다"로 오갈 때 다시 미끄러져 들어오는 것이 연출인가 굼뜸인가, 흥정하면 그 편으로 굳는 것이 납득되는가. 뒤집는 길: 결정 751의 상수, BACKLOG 047-1.
- **M-2 누구 편을 드는가**: 돈(50 · 25 대 30 · 15), 평판(6일차 흠 없이 둘 다 +6과 덤), 싸움(쫓아 모자 대 헛손질 읽으며 세 번)이 고민이 되는가, 한쪽이 뻔한가. 뒤집는 길: 두 `.tres`의 값.
- **M-3 모자 쓴 굴리엘모를 쫓기**: 클라라의 깃털과 다르게 느껴지는가, 모자가 멀리 · 밀착에서 읽히는가(위험 R6).
- **M-4 베아트리체와의 대련**: 아고스티노의 대련과 갈리는가 — 갈리는 것이 "참기"가 아니라 헛손질 읽기인가. 함께 올리는 수: `pairspar` · `pairsparclean`의 평균 초 · 조건 종료, 사다리를 밟았으면 그 값.
- **M-5 로렌초의 칼 든 손**: "칼 쪽 위를 베야 닿습죠"가 읽히는가, 손을 노리는 맛이 몸통 · 다리와 다른가. `afterhand`의 수.
- **M-6 의뢰인에게 져 주기**: 채점은 이네스의 지기와 같다(틀린 칸을 쥐고 맞으면 5). 헛손질에 일부러 속아 맞는 것이 그래도 다른 손맛인가, 아니면 개성은 이야기(상대가 의뢰인 본인)뿐인가 — 다르지 않으면 049에서 데이터로 바꿀 것(귀띔의 말, 조건의 값), 맡는 값 −1 · 해냄 0 · 55 · 30이 "돈을 받고 평판을 판다"로 읽히는가.
- **M-7 엇갈림**: 그녀 편 → 착한 그가 그녀를 위해 오고, 그의 편 → 그녀가 짜고 치는 판을 내민다. 보이는가, 결과(망친 판)에 따라 갈려야 하는가(위험 R2).
- **M-8 5일차 귀족 → 6일차 제빵사**(결정 763).
- **M-9 일정이 이레를 돈다**(8일차가 1일차의 손님 셋, 대련은 11일차).
- **M-10 같은 의뢰인 이름이 연습 목록에 둘씩**.
- **M-11 두 말투**: 그녀의 되묻는 해요체(클라라 · 오르솔라의 해요체와 갈리는가)와 그의 "-습죠" · 빵 빗댐.

## 사용자 결정 필요

없다(메인이 대신 고름 — 사용자 위임 2026-11-27: 꼴(한 자리 두 쪽), 흥정하면 굳는 것, 플래그가 맡은 것으로만 남는 것, 뒷이야기 둘의 사람 · 조건 · 값 · 글, 두 쪽의 값 · 글, `day_06` · `day_07`과 이레 일정, 039를 따른 어긋남 정리, 재는 띠와 사다리). 손 · 눈이 있어야 아는 것은 판 M에 모았다.

## 검토 대응 기록(1회차 v1 → v2)

1회차: 디자인 APPROVE · 기술 REVISE(T1 · T2). 꼴 · 의뢰 넷 · 값 · 글은 v1 그대로다.

- **번호**: 046이 결정 746을 썼다(`83cf9e7`) — 이 계획의 결정을 747~765로 하나씩 밀었다(본문 · 표 · 작업의 참조 모두). 시작점을 `83cf9e7` · N = 147로 적었다(머리, 작업 0 ①).
- **T1**(T115가 저장의 열쇠를 글자로 견준다): 수용 — "기존 테스트를 고치는 곳"에 T115 줄을 "손"으로 새로 두고(`"flags"`를 정렬된 자리에, 그 파일의 diff는 한 줄), 저장 줄에서 `style_tests`를 뺐다. 작업 6의 대상 · 완료 확인에 `style_tests.gd`, 작업 0 ④의 Grep에 `keys()` · 열쇠 목록의 글.
- **T2**(흥정 직후 지금 열린 카운터의 `SwitchSide`가 켜져 있다): 수용 — 결정 751의 버튼 줄(꺼짐 · 글은 `_refresh_haggle()`이 그 자리에서, 누름은 `switch_side()`가 참일 때만 `_go()`, 멤버 `_switch_button`), 작업 3, T149 ⑥의 같은 카운터 줄.
- 기술 비차단(`restore()`의 차례): 수용 — 결정 753 끝, 작업 2.
- 디자인 비차단: ① 의뢰인에게 져 주기의 단정을 누그러뜨림 — 결정 756 ④, 비교 표의 그 칸, 판 M-6. ② `day_07`에서 겹치는 셋을 끝으로 — 결정 758, T151 ②, 작업 0 ⑤, 위험 R9. ③ 가르지 않는다 — "꼴의 선택" 아래의 버린 길(v1의 보고에 적었던 047b 가르기).
