class_name DuelCore
extends RefCounted
## 결투 규칙 코어. Node에 의존하지 않는다.
##
## 시간 처리:
## - 자체 시계(time, 초)를 가진다. 모든 상태의 종료 시각은 "시작 시각 + 길이"로 미리 정해 두고,
##   tick(delta)은 시계를 올리면서 그 사이에 지난 전이를 예정 시각 순으로 처리한다.
## - 판정은 tick 시각이 아니라 예정 시각끼리 비교한다. 같은 시각이면 상대 쪽을 먼저 처리한다.
## - 이벤트는 tick 안에서 모아 두었다가 전이 처리가 끝난 뒤 순서대로 내보낸다.
## - 입력은 받은 즉시 현재 시계의 시각으로 적용한다.

signal event(ev: Dictionary)

const Dir := DuelTypes.Direction
const Hgt := DuelTypes.Height
const Dist := DuelTypes.Distance
const Part := DuelTypes.Part
const OpS := DuelTypes.OpponentState
const PlS := DuelTypes.PlayerState
const SR := DuelTypes.StrikeResult
const AR := DuelTypes.AttackResult
const Sit := DuelTypes.Situation
const End := DuelTypes.EndReason

## 조준 → 부위 표. 행은 높이(상/중/하), 열은 [찌르기, 상대 칼 든 쪽 베기, 반대쪽 베기].
## 칼 든 손은 조준 대상이 아니다. 부위 구성이 다른 상대가 필요해지면 OpponentData로 옮긴다.
const AIM_TABLE := [
	[Part.HEAD, Part.HAT, Part.HAT],
	[Part.TORSO, Part.SWORD_ARM, Part.TORSO],
	[Part.LEGS, Part.LEGS, Part.LEGS],
]

# tick 안에서 같은 시각에 겹친 전이의 처리 순서.
enum _Ev { NONE, OPPONENT, APPROACH, PLAYER, GUARD_COOLDOWN, TIME_LIMIT }

var rules: DuelRules
var weapon: WeaponData
var opponent_data: OpponentData
var brain: OpponentBrain
var record: DuelRecord
## 의뢰의 조건 목록. 비어 있으면 자유 결투다(어느 쪽이든 유효타 또는 시간 초과로 끝난다).
var conditions: Array[CommissionCondition] = []

var time := 0.0
var distance: int = Dist.FAR
var ended := false
var end_reason: int = End.NONE

# --- 플레이어 ---
var player_state: int = PlS.READY
var player_state_start := 0.0
var player_state_end := INF
var player_posture := 0
var aim_direction: int = Dir.CENTER
var aim_height: int = Hgt.MID
## 막기 버튼이 눌려 있는가(입력 그대로).
var guard_held := false
## 지금의 GUARD가 "새로 누름"으로 들어온 것인가(패리 가능).
var guard_fresh := false
var guard_enter_time := -INF
var guard_cooldown_end := -INF
# 진행 중인 공격(좌클릭 순간에 고정).
var attack_direction: int = Dir.CENTER
var attack_height: int = Hgt.MID
var attack_part: int = Part.TORSO
## 진행 중인 공격이 섣부른 공격인가(빈틈이 아닌 상대에게 누름).
var attack_rash := false
## 진행 중인 공격을 누른 순간의 간격.
var attack_pressed_distance: int = Dist.FAR
var step_target: int = Dist.FAR

# "간격이 멀리이고 상대가 IDLE"이 시작된 시각 + 접근 지연. 조건이 깨지면 INF.
var _approach_at := INF
var _queue: Array[Dictionary] = []
var _in_tick := false
var _flushing := false


func setup(p_rules: DuelRules, p_weapon: WeaponData, p_opponent: OpponentData,
		rng: RandomNumberGenerator, p_conditions: Array[CommissionCondition] = []) -> void:
	rules = p_rules
	weapon = p_weapon
	opponent_data = p_opponent
	conditions = p_conditions
	record = DuelRecord.new()
	brain = OpponentBrain.new(opponent_data, rng)
	player_posture = rules.player_posture_max
	distance = Dist.FAR
	brain.start_idle(0.0)
	_refresh_approach(0.0)


## 조준(방향, 높이)과 상대의 칼 든 쪽으로 노리는 부위를 정한다.
static func aim_part(direction: int, height: int, sword_side: int) -> int:
	var column := 0
	if direction != Dir.CENTER:
		column = 1 if direction == sword_side else 2
	return AIM_TABLE[height][column]


## 지금 조준이 노리는 부위.
func current_aim_part() -> int:
	return aim_part(aim_direction, aim_height, opponent_data.sword_side)


## 지금 공격을 누르면 섣부른 공격인가: 간격이 멀리가 아니고 빈틈 인정 구간 밖이다.
func is_rash_now() -> bool:
	return distance != Dist.FAR and not brain.in_opening(time, rules.opening_grace)


## 지금 타격이 오면 버티기가 되는가: 상대가 표시된 공격의 예비 동작 중이고,
## 내 막기가 그 예비 동작이 시작되기 전부터 이어진 것(들고만 있던 막기)이다.
## 예비 동작이 시작된 시각 이후에 들어간 막기는 경로와 상관없이 올린 막기다.
func would_brace_now() -> bool:
	if brain.state != OpS.TELL or brain.current_attack == null:
		return false
	if not brain.current_attack.needs_raised_guard:
		return false
	return player_state == PlS.GUARD and guard_enter_time < brain.state_start


# ---------------------------------------------------------------- 입력

func set_aim(direction: int, height: int) -> void:
	if ended:
		return
	aim_direction = direction
	aim_height = height


func press_attack() -> void:
	if ended:
		return
	if player_state != PlS.READY and player_state != PlS.GUARD:
		return
	if player_state == PlS.GUARD:
		_leave_guard(time)
	attack_direction = aim_direction
	attack_height = aim_height
	attack_part = current_aim_part()
	# 섣부른 공격인지도 누른 순간에 정해지고 그 뒤로 바뀌지 않는다.
	attack_rash = is_rash_now()
	attack_pressed_distance = distance
	var windup := weapon.windup_for(attack_direction, attack_height, distance)
	player_state = PlS.WINDUP
	player_state_start = time
	player_state_end = time + windup
	_emit(DuelRecord.ATTACK_START, {
		"direction": attack_direction, "height": attack_height, "part": attack_part,
		"judge_time": player_state_end, "rash": attack_rash,
	})


func set_guard(held: bool) -> void:
	if ended or held == guard_held:
		return
	guard_held = held
	if held:
		# 쿨다운 안의 누름은 받지 않는다. 쿨다운이 끝났을 때 아직 누르고 있으면
		# tick이 GUARD로 넣되 "새로 누름"으로 치지 않는다.
		if player_state == PlS.READY and time >= guard_cooldown_end:
			_enter_guard(time, true)
	elif player_state == PlS.GUARD:
		_leave_guard(time)
		player_state = PlS.READY
		player_state_start = time
		player_state_end = INF


## 간격 이동. direction은 +1(전진) 또는 -1(후퇴).
func step(direction: int) -> void:
	if ended or player_state != PlS.READY:
		return
	var target := distance + signi(direction)
	if target < Dist.FAR or target > Dist.CLOSE:
		return
	step_target = target
	player_state = PlS.STEPPING
	player_state_start = time
	player_state_end = time + weapon.step_time
	_emit(DuelRecord.STEP_START, {"target": step_target, "end_time": player_state_end})


# ---------------------------------------------------------------- 시간

func tick(delta: float) -> void:
	if ended:
		return
	_in_tick = true
	var target := time + delta
	while not ended:
		var next := _next_event(target)
		var kind: int = next[0]
		if kind == _Ev.NONE:
			break
		time = next[1]
		match kind:
			_Ev.OPPONENT:
				_on_opponent_state_end()
			_Ev.APPROACH:
				_set_distance(Dist.ENGAGE, "opponent")
			_Ev.PLAYER:
				_on_player_state_end()
			_Ev.GUARD_COOLDOWN:
				_enter_guard(time, false)
			_Ev.TIME_LIMIT:
				_end(End.TIME_UP, "시간 초과")
		# 조건은 전이마다 묻는다. 종료 시각이 tick 경계가 아니라 그 전이의 시각이 되게 한다.
		_check_conditions()
	if not ended:
		time = target
	record.elapsed = time
	_in_tick = false
	_flush()


## target 시각까지 예정된 전이 중 가장 이른 것. 같은 시각이면 enum 순서가 앞선 것.
func _next_event(target: float) -> Array:
	var best_kind: int = _Ev.NONE
	var best_time := INF
	var candidates := [
		[_Ev.OPPONENT, brain.state_end],
		[_Ev.APPROACH, _approach_at],
		[_Ev.PLAYER, player_state_end],
		[_Ev.GUARD_COOLDOWN, _pending_guard_time()],
		[_Ev.TIME_LIMIT, rules.time_limit],
	]
	for c in candidates:
		var t: float = c[1]
		if t <= target and t < best_time:
			best_kind = c[0]
			best_time = t
	return [best_kind, best_time]


## 막기 버튼을 누른 채 쿨다운이 끝나기를 기다리는 중이면 그 시각.
func _pending_guard_time() -> float:
	if guard_held and player_state == PlS.READY:
		return maxf(guard_cooldown_end, time)
	return INF


# ---------------------------------------------------------------- 상대

func _on_opponent_state_end() -> void:
	match brain.state:
		OpS.IDLE:
			if distance == Dist.FAR:
				brain.hold_idle()
			else:
				brain.start_tell(time, distance == Dist.CLOSE)
				_emit(DuelRecord.TELL_START, {
					"attack": brain.current_attack, "strike_time": brain.state_end,
					"duration": brain.tell_duration, "is_habit": brain.current_is_habit,
				})
		OpS.TELL:
			_resolve_strike()
		OpS.RECOVERY:
			brain.start_idle(time)
		OpS.STAGGER:
			brain.end_stagger(time)
			_emit(DuelRecord.STAGGER_END, {"posture": brain.posture})
	_refresh_approach(time)


## 타격 순간(TELL이 끝나는 시각)의 판정. ATTACK 상태는 길이 0이다.
## 순서: ① 멀리면 헛침 ② GUARD이고 방향이 맞으면 막힘/패리 ③ 그 밖에는 닿음.
func _resolve_strike() -> void:
	var atk := brain.current_attack
	var result: int
	var situation := -1
	var braced := false
	var posture_loss := 0
	if distance == Dist.FAR:
		result = SR.WHIFF
	elif player_state == PlS.GUARD and aim_direction == atk.direction:
		var in_window := guard_enter_time >= time - weapon.parry_window
		result = SR.PARRIED if (guard_fresh and in_window) else SR.BLOCKED
		# 표시된 공격을 들고만 있던 막기로 받으면 막히기는 하지만 빈틈이 없다. 상대는 아직 TELL이다.
		braced = result == SR.BLOCKED and would_brace_now()
	else:
		match player_state:
			PlS.GUARD:
				situation = Sit.WRONG_GUARD
			PlS.WINDUP, PlS.RECOVER:
				situation = Sit.IN_ATTACK
			_:
				situation = Sit.UNGUARDED
		if player_posture > 0:
			# 밀착에서 맞으면 더 많이 깎인다(상대 데이터의 값). 0 아래로는 내려가지 않는다.
			var loss := 1
			if distance == Dist.CLOSE:
				loss = maxi(opponent_data.close_hit_posture_loss, 1)
			posture_loss = mini(loss, player_posture)
			player_posture -= posture_loss
			result = SR.GRAZE
		else:
			result = SR.HIT
	var recovery := brain.resolve_strike(time, result, braced)
	_emit(DuelRecord.STRIKE, {
		"attack": atk, "result": result, "situation": situation,
		"recovery": recovery, "recovery_end": time + recovery,
		"player_posture": player_posture, "braced": braced, "posture_loss": posture_loss,
	})
	if result == SR.HIT:
		_end(End.PLAYER_DEFEATED, "유효타를 맞음")


func _refresh_approach(now: float) -> void:
	if distance == Dist.FAR and brain.state == OpS.IDLE:
		if _approach_at == INF:
			_approach_at = now + opponent_data.approach_delay
	else:
		_approach_at = INF


func _set_distance(new_distance: int, by: String) -> void:
	var old := distance
	if new_distance == old:
		return
	distance = new_distance
	_emit(DuelRecord.DISTANCE, {"distance": distance, "by": by})
	# 멀리를 벗어나면(누가 움직였든) 대기 시간을 새로 잰다.
	if old == Dist.FAR and brain.state == OpS.IDLE:
		brain.start_idle(time)
	_refresh_approach(time)


# ---------------------------------------------------------------- 플레이어

func _on_player_state_end() -> void:
	match player_state:
		PlS.WINDUP:
			_judge_attack()
			if ended:
				return
			player_state = PlS.RECOVER
			player_state_start = time
			player_state_end = time + weapon.recover_time
		PlS.RECOVER:
			_to_ready()
		PlS.STEPPING:
			# 간격 값은 이동이 끝나는 시각에 바뀐다.
			_set_distance(step_target, "player")
			_to_ready()


## 플레이어 공격의 판정(예비가 끝나는 시각).
## 멀리면 헛침, 상대가 RECOVERY/STAGGER이고 그 종료 시각보다 앞이면 닿음, 아니면 막힘.
func _judge_attack() -> void:
	var result: int = AR.BLOCKED
	var staggered := false
	if distance == Dist.FAR:
		result = AR.WHIFF
	elif brain.state == OpS.RECOVERY and time < brain.state_end:
		# 자세가 남은 상대에게 닿음 = 스침. 한 빈틈에는 한 번만 닿는다(회수가 여기서 끝난다).
		result = AR.GRAZE
		staggered = brain.on_grazed(time)
	elif brain.state == OpS.STAGGER and time < brain.state_end:
		result = AR.HIT
	# 섣부른 공격이 막히면 상대가 자세를 되찾는다. 상대의 상태·타이머·연속 막힘은 건드리지 않는다.
	var posture_gain := 0
	if attack_rash and result == AR.BLOCKED:
		posture_gain = brain.regain_posture()
	_emit(DuelRecord.ATTACK, {
		"result": result, "direction": attack_direction, "height": attack_height,
		"part": attack_part, "distance": distance, "pressed_distance": attack_pressed_distance,
		"opponent_posture": brain.posture, "opponent_state": brain.state,
		"rash": attack_rash, "posture_gain": posture_gain,
	})
	if staggered:
		_emit(DuelRecord.STAGGER_START, {"end_time": brain.state_end})
	_refresh_approach(time)
	if result == AR.HIT and conditions.is_empty():
		# 조건이 없는 자유 결투는 상대가 유효타를 맞으면 끝난다. 의뢰가 있으면 조건이 정한다.
		_end(End.OPPONENT_HIT, "상대에게 유효타")


func _to_ready() -> void:
	player_state = PlS.READY
	player_state_start = time
	player_state_end = INF
	if guard_held and time >= guard_cooldown_end:
		_enter_guard(time, false)


func _enter_guard(now: float, fresh: bool) -> void:
	player_state = PlS.GUARD
	player_state_start = now
	player_state_end = INF
	guard_fresh = fresh
	guard_enter_time = now
	_emit(DuelRecord.GUARD_START, {"fresh": fresh})


## GUARD를 어떤 경로로 벗어나든 재입력 쿨다운이 돈다. 상태 전환은 호출한 쪽이 한다.
func _leave_guard(now: float) -> void:
	guard_cooldown_end = now + weapon.guard_cooldown
	guard_fresh = false
	_emit(DuelRecord.GUARD_END, {})


# ---------------------------------------------------------------- 종료와 이벤트

## 의뢰 조건 중 하나라도 종료를 말하면 끝낸다.
func _check_conditions() -> void:
	if ended:
		return
	for condition in conditions:
		if condition == null:
			continue
		var reason := condition.check_end(record)
		if reason != "":
			_end(End.CONDITION, reason)
			return


func _end(reason: int, detail: String) -> void:
	if ended:
		return
	ended = true
	end_reason = reason
	record.ended = true
	record.end_reason = reason
	record.end_detail = detail
	record.elapsed = time
	_emit(DuelRecord.END, {"reason": reason, "detail": detail})


func _emit(type: StringName, data: Dictionary) -> void:
	data["type"] = type
	data["t"] = time
	record.add(data)
	_queue.append(data)
	if not _in_tick and not _flushing:
		_flush()


func _flush() -> void:
	if _flushing:
		return
	_flushing = true
	var i := 0
	while i < _queue.size():
		event.emit(_queue[i])
		i += 1
	_queue.clear()
	_flushing = false
