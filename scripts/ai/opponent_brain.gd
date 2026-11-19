class_name OpponentBrain
extends RefCounted
## 상대의 상태 머신: IDLE → TELL → [타격] → RECOVERY → IDLE, 자세 0이면 STAGGER.
## 시각은 전부 코어가 넘겨 준다. 난수는 주입받은 rng만 쓴다. data는 읽기만 한다.

const S := DuelTypes.OpponentState
const R := DuelTypes.StrikeResult

var data: OpponentData
var rng: RandomNumberGenerator

var state: int = S.IDLE
var state_start := 0.0
## 현재 상태의 예정 종료 시각. INF면 멀리에서 기다리는 중이다.
var state_end := INF
var posture := 0
## 연속으로 막힌 횟수(막기·패리 모두).
var blocked_streak := 0
var current_attack: AttackData = null
## 지금 공격이 버릇 반응으로 나온 것인가.
var current_is_habit := false
## 지금 예비 동작의 길이(밀착 배율 적용 후).
var tell_duration := 0.0
## 가장 최근 빈틈(RECOVERY·STAGGER)이 끝난 시각.
var opening_end := -INF
## 지금의 회수가 크게 열린 것인가: 패리당했거나 큰 공격을 쓴 뒤다. 회수가 시작될 때 정해지고
## 그 회수가 끝날 때까지 바뀌지 않는다. 회수 중이 아니면 거짓이다.
var wide_open := false
## 마지막으로 경계를 세운 시각. 판 처음(0)과 런지가 판정된 시각이다. 방심 게이지는 여기서부터 찬다.
var alert_since := 0.0
## 이 판에서 런지에 찔린(스침·유효타) 횟수.
var lunge_touches := 0
## 공격 가방(data.attack_bag_sets가 1 이상일 때만 쓴다). 판마다 새로 만든다.
var _bag: Array[AttackData] = []


func _init(p_data: OpponentData, p_rng: RandomNumberGenerator) -> void:
	data = p_data
	rng = p_rng
	posture = data.posture_max


## 대기를 새로 시작한다. 대기 시간을 새로 뽑는다.
func start_idle(now: float) -> void:
	# 빈틈에서 나오는 모든 경로(회수의 예정 종료, 스침, 무너짐 종료)가 여기를 지난다.
	if state == S.RECOVERY or state == S.STAGGER:
		opening_end = now
	wide_open = false
	state = S.IDLE
	state_start = now
	state_end = now + rng.randf_range(data.idle_time_min, data.idle_time_max)
	current_attack = null
	current_is_habit = false


## 멀리라서 예비 동작을 시작하지 못하고 기다린다.
func hold_idle() -> void:
	state_end = INF


## 다음 공격을 고르고 예비 동작을 시작한다.
func start_tell(now: float, is_close: bool) -> void:
	_choose_attack()
	tell_duration = current_attack.tell_time
	if is_close:
		tell_duration *= data.close_tell_multiplier
	state = S.TELL
	state_start = now
	state_end = now + tell_duration


## 타격 결과를 받아 회수(또는 대기)로 넘어간다. 회수 시간을 돌려준다.
## braced: 막혔지만 버티기였다(표시된 공격을 들고만 있던 막기로 받음). 막힘으로 세되 빈틈이 없다.
func resolve_strike(now: float, result: int, braced := false) -> float:
	var recovery := 0.0
	match result:
		R.WHIFF:
			recovery = current_attack.recovery_time * data.whiff_recovery_multiplier
		R.BLOCKED:
			recovery = 0.0 if braced else current_attack.recovery_time
			_count_blocked()
		R.PARRIED:
			recovery = current_attack.recovery_time + data.parried_recovery_bonus
			_count_blocked()
		_:
			# 플레이어에게 닿은 공격 뒤에는 빈틈이 없고, 연속 막힘도 끊긴다.
			recovery = 0.0
			blocked_streak = 0
	if recovery > 0.0:
		# 칼을 쳐내졌거나(패리) 온몸을 실은 큰 공격을 쓴 뒤에는 크게 열린다(헛친 큰 공격도 그렇다).
		wide_open = result == R.PARRIED or current_attack.is_big
		state = S.RECOVERY
		state_start = now
		state_end = now + recovery
	else:
		start_idle(now)
	return recovery


## 회수 중에 스침당했다. cells는 그 부위가 깎는 자세 칸 수다. 무너지면 true.
func on_grazed(now: float, cells := 1) -> bool:
	posture = maxi(posture - maxi(cells, 1), 0)
	if posture == 0:
		wide_open = false
		state = S.STAGGER
		state_start = now
		state_end = now + data.stagger_time
		blocked_streak = 0
		current_attack = null
		current_is_habit = false
		return true
	# 버릇 식히기: 닿으면 연속 막힘을 처음부터 다시 센다(그 버릇이 켜 둔 경우에만).
	for habit in data.habits:
		if habit.trigger == HabitData.Trigger.BLOCKED_STREAK and habit.reset_on_touched:
			blocked_streak = 0
			break
	start_idle(now)
	return false


func end_stagger(now: float) -> void:
	posture = data.stagger_recover_posture
	start_idle(now)


## 지금이 빈틈 인정 구간인가: 빈틈(RECOVERY·STAGGER) 동안과 그것이 끝난 뒤 grace초가 지나기 전.
func in_opening(now: float, grace: float) -> bool:
	if state == S.RECOVERY or state == S.STAGGER:
		return true
	return now < opening_end + grace


## now 시각의 방심 게이지(0~1). 1이면 방심했다. 시각과 찔린 횟수만의 함수다(상태·타이머·난수와 무관하다).
## 방심하지 않는 상대이거나 찔린 횟수가 상한에 닿았으면 늘 0이다.
func complacency(now: float) -> float:
	if data.complacent_time <= 0.0 or is_wary():
		return 0.0
	return clampf((now - alert_since) / data.complacent_time, 0.0, 1.0)


## 찔린 횟수가 상한에 닿아 이 판에서는 다시 방심하지 않는가.
func is_wary() -> bool:
	return data.complacent_limit > 0 and lunge_touches >= data.complacent_limit


## 런지가 판정됐다. 닿았든 막혔든 피했든 경계를 세운다(게이지 0). 닿았으면 찔린 횟수가 오른다.
## 상태·타이머·난수는 건드리지 않는다.
func on_lunged(now: float, touched: bool) -> void:
	alert_since = now
	if touched:
		lunge_touches += 1


## 섣부른 공격을 받아넘기고 자세를 되찾는다. 실제로 오른 칸 수를 돌려준다(최대값에서 자른다).
func regain_posture() -> int:
	var before := posture
	posture = mini(posture + maxi(data.rash_attack_posture_gain, 0), data.posture_max)
	return posture - before


func _count_blocked() -> void:
	# 버릇 반응으로 나간 공격은 횟수를 0으로 되돌린 채 둔다(일반 공격만 센다).
	if not current_is_habit:
		blocked_streak += 1


func _choose_attack() -> void:
	for habit in data.habits:
		if habit.trigger == HabitData.Trigger.BLOCKED_STREAK and habit.response != null \
				and blocked_streak >= habit.count:
			blocked_streak = 0
			current_attack = habit.response
			current_is_habit = true
			return
	current_is_habit = false
	# 공격 가방을 쓰면 가방에서 한 장 꺼낸다. 가방을 못 채우는 데이터면 아래의 독립 추첨으로 간다.
	if data.attack_bag_sets > 0:
		if _bag.is_empty():
			_refill_bag()
		if not _bag.is_empty():
			current_attack = _bag.pop_back()
			return
	var total := 0.0
	for atk in data.attacks:
		total += atk.weight
	var pick := rng.randf() * total
	current_attack = data.attacks[data.attacks.size() - 1]
	for atk in data.attacks:
		pick -= atk.weight
		if pick < 0.0:
			current_attack = atk
			break


## 가방에 남은 장 수. 가방을 쓰지 않으면 -1.
func bag_remaining() -> int:
	return _bag.size() if data.attack_bag_sets > 0 else -1


## 가방을 채워 섞는다. 일반 공격마다 "반올림한 가중치 x attack_bag_sets"장이고,
## 가중치가 0보다 크면 적어도 한 장은 넣는다(반올림으로 공격이 말없이 사라지지 않게).
## 섞기는 주입받은 rng만 쓴다(전역 난수를 쓰는 Array.shuffle()은 시드로 재현되지 않는다).
## data의 배열은 고치지 않는다.
func _refill_bag() -> void:
	_bag.clear()
	for atk in data.attacks:
		if atk.weight <= 0.0:
			continue
		var cards := maxi(roundi(atk.weight), 1) * data.attack_bag_sets
		for i in cards:
			_bag.append(atk)
	for i in range(_bag.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := _bag[i]
		_bag[i] = _bag[j]
		_bag[j] = tmp
