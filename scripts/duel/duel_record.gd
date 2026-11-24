class_name DuelRecord
extends RefCounted
## 결투 한 판의 기록. 조건 판정과 결과 화면은 이것만 읽는다.
## 이벤트는 Dictionary이고 공통 키는 "type"(StringName)과 "t"(코어 시각, 초)다.

# --- 이벤트 종류 ---
## 상대 예비 동작 시작. attack, strike_time, duration, is_habit,
## height(첫 타격의 높이, 없으면 -1), heights(패턴 모든 타격의 높이)
const TELL_START := &"tell_start"
## 상대 타격 판정. attack, result(StrikeResult), situation(Situation 또는 -1),
## recovery(초), recovery_end, player_posture,
## braced(들고만 있던 막기로 표시된 공격을 버텼는가. 버티기면 recovery는 0),
## posture_loss(이 타격으로 실제로 깎인 내 자세 칸 수. 닿지 않았거나 유효타면 0),
## next_strike(패턴이 이어지면 다음 타격 시각, 아니면 -1.0),
## height(이 타격의 높이, 없으면 -1), guard_miss(막고 있었고 방향도 맞았는데 맞은 까닭: &"height" 높이가 틀림, &"regrip" 휩쓸기에서 떼었다 누름, 아니면 &"")
const STRIKE := &"strike"
## 패턴의 다음 타격(걸음)이 시작됨. attack(걸음), root(뿌리), index(1부터), count(패턴의 타격 수), strike_time, duration, height.
## TELL_START는 뿌리에만 낸다(가방을 TELL_START로 세는 테스트가 있다. 결정 376).
const PATTERN_STEP := &"pattern_step"
## 플레이어 공격 시작. direction, height, part, judge_time, rash(섣부른 공격인가), lunge(런지인가)
const ATTACK_START := &"attack_start"
## 플레이어 공격 판정. result(AttackResult), direction, height, part, distance(판정 시각의 간격),
## pressed_distance(누른 순간의 간격), opponent_posture, opponent_state(판정 직후), rash, posture_gain(섣부른 공격으로 상대가 되찾은 칸 수),
## cells(이 공격으로 실제로 깎인 상대 자세 칸 수. 스침이 아니면 0),
## dodged(머리를 노렸는데 상대가 피했는가. 피했으면 result는 BLOCKED다),
## lunge(런지인가. 런지는 멀리에서 눌러 교전에 닿으며 판정한다: pressed_distance는 멀리, distance는 교전이다)
const ATTACK := &"attack"
## 간격 변경. distance, by("player"/"opponent"/"bind" — bind는 엉킴으로 밀려난 것)
const DISTANCE := &"distance"
## 엉킴이 다 차서 밀려나기 시작함. end_time(교전에 닿는 시각),
## cancelled_attack(예비 중이던 공격이 판정 없이 사라졌는가)
const SHOVE := &"shove"
## 상대 무너짐 시작. end_time
const STAGGER_START := &"stagger_start"
## 상대 무너짐 끝. posture(회복된 자세)
const STAGGER_END := &"stagger_end"
## 막기 시작. fresh(새로 누름인가)
const GUARD_START := &"guard_start"
const GUARD_END := &"guard_end"
## 간격 이동 시작. target, end_time
const STEP_START := &"step_start"
## 결투 종료. reason(EndReason), detail
const END := &"end"

var events: Array[Dictionary] = []
## 경과 시간(초). 코어가 매 tick 갱신한다.
var elapsed := 0.0
var ended := false
var end_reason: int = DuelTypes.EndReason.NONE
## 조건이 낸 종료 사유 문구 등.
var end_detail := ""


func add(ev: Dictionary) -> void:
	events.append(ev)


## 해당 종류의 이벤트만 순서대로 돌려준다.
func of_type(type: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for ev in events:
		if ev["type"] == type:
			out.append(ev)
	return out


## 해당 종류이고 key 값이 value인 이벤트의 수.
func count_where(type: StringName, key: String, value: Variant) -> int:
	var n := 0
	for ev in events:
		if ev["type"] == type and ev.get(key) == value:
			n += 1
	return n
