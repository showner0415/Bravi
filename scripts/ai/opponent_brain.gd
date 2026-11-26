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
## 지금 패턴의 뿌리(가방에서 꺼낸 공격). 단발이면 current_attack과 같고, 공격 중이 아니면 null이다(결정 370).
var pattern_root: AttackData = null
## 지금이 패턴의 몇째 타격인가. 0이 뿌리의 타격이다.
var step_index := 0
## 패턴의 첫 타격의 예정 시각. 휩쓸기의 "쥐고 끌기"가 이 시각을 기준으로 삼는다(결정 372).
var first_strike_time := 0.0
## 지금 패턴의 타격마다 뽑힌 높이(-1은 높이 없음). 예비 동작이 시작될 때 한 번에 정해진다(결정 385).
## 지난 이벤트가 든 값이 바뀌지 않게 늘 새 배열을 넣는다.
var strike_heights: Array[int] = []
## 지금 예비 동작의 길이(밀착 배율 적용 후).
var tell_duration := 0.0
## 가장 최근 빈틈(RECOVERY·STAGGER)이 끝난 시각.
var opening_end := -INF
## 지금의 회수가 크게 열린 것인가: 패리당했거나 큰 공격을 쓴 뒤다. 회수가 시작될 때 정해지고
## 그 회수가 끝날 때까지 바뀌지 않는다. 회수 중이 아니면 거짓이다.
var wide_open := false
## 지금의 회수가 뿌리가 큰 공격이었는가(패리만으로는 켜지지 않는다). wide_open과 같은 자리에서 정해지고 지워진다(계획 R02).
var big_open := false
## 마지막으로 경계를 세운 시각. 판 처음(0)과 런지가 판정된 시각이다. 방심 게이지는 여기서부터 찬다.
var alert_since := 0.0
## 이 판에서 런지에 찔린(스침·유효타) 횟수.
var lunge_touches := 0
## 이 판에서 막힘·패리가 빈틈이 될 확률과 패리의 덤. 코어가 setup에서 넣는다(1.0이면 꺼짐. 결정 398).
var opening_chance := 1.0
var parry_opening_bonus := 0.0
## 예비 동작이 시작될 때 굴린 값. 막은 순간에 드러난다(결정 398).
var opening_roll := 0.0
## 연속으로 안 열린 수. 열리면 0으로 돌아간다(결정 401).
var closed_streak := 0
## 바로 앞 resolve_strike가 막혔는데 빈틈을 주지 않았는가.
var last_closed := false
## 칼 든 팔을 스쳐 앞으로 길어질 예비 동작의 남은 횟수(계획 R02 D4). 패턴 하나가 1회다.
var slow_tells_left := 0
## 지금 패턴이 길어진 예비 동작인가. 공격이 끝나면 지워진다.
var pattern_slowed := false
## 다리를 스쳐 다음 패리에 붙을 덤의 남은 횟수(D5).
var parry_charges := 0
## 바로 앞 resolve_strike가 쓴 다리 덤: &"opened" / &"time" / &"none" / &""(덤 없음).
var last_leg_bonus := &""
## 바로 앞 resolve_strike가 다리 덤으로 더한 빈틈의 초.
var last_leg_time := 0.0
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
	big_open = false
	pattern_slowed = false
	state = S.IDLE
	state_start = now
	state_end = now + rng.randf_range(data.idle_time_min, data.idle_time_max)
	current_attack = null
	current_is_habit = false
	pattern_root = null
	step_index = 0
	strike_heights = []


## 멀리라서 예비 동작을 시작하지 못하고 기다린다.
func hold_idle() -> void:
	state_end = INF


## 다음 공격을 고르고 예비 동작을 시작한다.
func start_tell(now: float, is_close: bool) -> void:
	_choose_attack()
	# 변주: 바탕(0)과 변주들 가운데 하나. 변주가 없으면 난수를 부르지 않는다(하루 데이터의 난수 차례가 그대로다. 결정 383).
	if not current_attack.variants.is_empty():
		var pick := rng.randi_range(0, current_attack.variants.size())
		if pick > 0:
			current_attack = current_attack.variants[pick - 1] as AttackData
	tell_duration = current_attack.tell_time
	if is_close:
		tell_duration *= data.close_tell_multiplier
	# 난수를 부르지 않는다: 팔 효과는 횟수만 센다.
	pattern_slowed = slow_tells_left > 0 and data.part_effects != null
	if pattern_slowed:
		slow_tells_left -= 1
		tell_duration *= data.part_effects.arm_tell_multiplier
	state = S.TELL
	state_start = now
	state_end = now + tell_duration
	pattern_root = current_attack
	step_index = 0
	first_strike_time = state_end
	var drawn: Array[int] = [_draw_height(current_attack)]
	for step: AttackData in current_attack.chain:
		drawn.append(_draw_height(step))
	strike_heights = drawn
	# 확률이 1.0이면 부르지 않는다: 하루 데이터의 난수 차례가 그대로다(결정 396).
	if opening_chance < 1.0:
		opening_roll = rng.randf()


## 타격 결과를 받아 회수(또는 대기)로 넘어간다. 회수 시간을 돌려준다.
## braced: 막혔지만 버티기였다(표시된 공격을 들고만 있던 막기로 받음). 막힘으로 세되 빈틈이 없다.
func resolve_strike(now: float, result: int, braced := false) -> float:
	last_closed = false
	last_leg_bonus = &""
	last_leg_time = 0.0
	# 단발이면 뿌리가 곧 지금 공격이라 아래 셈이 전과 같다.
	var root := pattern_root if pattern_root != null else current_attack
	# 막힌 타격 뒤에 걸음이 남았으면 빈틈 없이 다음 타격으로 간다. 패리도 중간에서는 패턴을 끊지 않는다(결정 371).
	# 버틴 첫 타격은 단발처럼 패턴을 끝낸다(버티기의 대가가 사라지지 않게).
	if (result == R.BLOCKED or result == R.PARRIED) and not braced and step_index < root.chain.size():
		current_attack = root.chain[step_index] as AttackData
		step_index += 1
		tell_duration = _step_tell(current_attack)
		state_start = now
		state_end = now + tell_duration
		return 0.0
	var recovery := 0.0
	match result:
		R.WHIFF:
			recovery = root.recovery_time * data.whiff_recovery_multiplier
		R.BLOCKED:
			recovery = 0.0 if braced else root.recovery_time
			_count_blocked()
		R.PARRIED:
			recovery = root.recovery_time + data.parried_recovery_bonus
			_count_blocked()
		_:
			# 플레이어에게 닿은 공격 뒤에는 빈틈이 없고, 연속 막힘도 끊긴다.
			recovery = 0.0
			blocked_streak = 0
	# 헛친 뛰어들기도 확률을 굴린다(결정 451).
	if recovery > 0.0 and (result == R.BLOCKED or result == R.PARRIED or (root.dive and result == R.WHIFF)):
		if _opens_with_legs(result, recovery):
			closed_streak = 0
			recovery += last_leg_time
		else:
			recovery = 0.0
			last_closed = true
			closed_streak += 1
	if recovery > 0.0:
		# 칼을 쳐내졌거나(패리) 온몸을 실은 큰 공격을 쓴 뒤에는 크게 열린다(헛친 큰 공격도 그렇다).
		wide_open = result == R.PARRIED or root.is_big
		big_open = root.is_big
		state = S.RECOVERY
		state_start = now
		state_end = now + recovery
	else:
		start_idle(now)
	return recovery


## 막힘·패리가 빈틈이 되는가(결정 399~401).
func _opens(parried: bool) -> bool:
	if opening_chance >= 1.0:
		return true
	if data.opening_miss_limit > 0 and closed_streak >= data.opening_miss_limit:
		return true
	return opening_roll < opening_chance + (parry_opening_bonus if parried else 0.0)


## 막힘·패리가 빈틈이 되는가에 다리 덤을 얹는다(계획 R02 D5). 덤은 패리로 끝난 공격에서 한 번 쓴다.
## 덤 없이는 안 열릴 굴림이 열리면 "opened", 덤 없이도 열렸을 패리는 빈틈 시간을 더해 "time", 덤을 더해도 안 열리면 "none".
## 난수는 부르지 않는다(opening_roll은 start_tell에서 이미 뽑혀 있다).
func _opens_with_legs(result: int, recovery: float) -> bool:
	var fx := data.part_effects
	var natural := _opens(result == R.PARRIED)
	if result != R.PARRIED or parry_charges <= 0 or fx == null or recovery <= 0.0:
		return natural
	parry_charges -= 1
	if natural:
		last_leg_bonus = &"time"
		last_leg_time = fx.legs_open_time_bonus
		return true
	if opening_roll < opening_chance + parry_opening_bonus + fx.legs_parry_opening_bonus:
		last_leg_bonus = &"opened"
		return true
	last_leg_bonus = &"none"
	return false


## 패턴의 뒤따르는 타격 하나의 간격. 길어진 패턴이면 같은 배율을 곱한다.
func _step_tell(step: AttackData) -> float:
	return step.tell_time * data.part_effects.arm_tell_multiplier if pattern_slowed else step.tell_time


## 지금 타격의 높이. 높이가 없거나 공격 중이 아니면 -1이다.
func current_height() -> int:
	if pattern_root == null or step_index < 0 or step_index >= strike_heights.size():
		return -1
	return strike_heights[step_index]


## 한 타격의 높이를 뽑는다. 뽑을 것이 둘 이상일 때만 난수를 부른다(결정 383·385).
func _draw_height(atk: AttackData) -> int:
	if not data.use_heights or atk.heights.is_empty():
		return -1
	if atk.heights.size() == 1:
		return atk.heights[0]
	return atk.heights[rng.randi_range(0, atk.heights.size() - 1)]


## 지금 패턴의 타격 수. 단발이거나 공격 중이 아니면 1이다.
func pattern_count() -> int:
	return 1 + pattern_root.chain.size() if pattern_root != null else 1


## 지금 패턴이 휩쓸기인가.
func is_sweep() -> bool:
	return pattern_root != null and pattern_root.sweep and not pattern_root.chain.is_empty()


## 지금 패턴의 타격 시각들(첫 타격부터 걸음의 간격을 더해 간다). 공격 중이 아니면 빈 배열이다.
func pattern_strike_times() -> Array[float]:
	var times: Array[float] = []
	if pattern_root == null:
		return times
	var at := first_strike_time
	times.append(at)
	for step: AttackData in pattern_root.chain:
		at += _step_tell(step)
		times.append(at)
	return times


## 회수 중에 스침당했다. cells는 그 부위가 깎는 자세 칸 수다. 무너지면 true.
func on_grazed(now: float, cells := 1) -> bool:
	posture = maxi(posture - maxi(cells, 1), 0)
	if posture == 0:
		wide_open = false
		big_open = false
		pattern_slowed = false
		state = S.STAGGER
		state_start = now
		state_end = now + data.stagger_time
		blocked_streak = 0
		current_attack = null
		current_is_habit = false
		pattern_root = null
		step_index = 0
		strike_heights = []
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
