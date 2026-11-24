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
## 모자 없는 상대의 표다. 칼 든 쪽 세로줄의 상단이 칼 든 손, 중단이 칼 든 팔이다.
## 모자를 쓴 판에서는 상단의 베기 두 칸이 모자다(aim_part가 바꾼다).
## 부위 구성이 다른 상대가 필요해지면 OpponentData로 옮긴다.
const AIM_TABLE := [
	[Part.HEAD, Part.SWORD_HAND, Part.HEAD],
	[Part.TORSO, Part.SWORD_ARM, Part.TORSO],
	[Part.LEGS, Part.LEGS, Part.LEGS],
]

# tick 안에서 같은 시각에 겹친 전이의 처리 순서.
enum _Ev { NONE, OPPONENT, APPROACH, PLAYER, GUARD_COOLDOWN, BIND_FULL, TIME_LIMIT }
# 엉킴 게이지가 지금 어떻게 움직이는가: 그대로 / 차는 중 / 풀리는 중.
enum _Bind { HOLD, FILL, DRAIN }

var rules: DuelRules
var weapon: WeaponData
var opponent_data: OpponentData
var brain: OpponentBrain
var record: DuelRecord
## 의뢰의 조건 목록. 비어 있으면 자유 결투다(어느 쪽이든 유효타 또는 시간 초과로 끝난다).
var conditions: Array[CommissionCondition] = []
## 이 판의 상대가 모자를 쓰는가. 모자는 상대의 고정 부위가 아니라 의뢰가 씌운다.
var opponent_has_hat := false

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
## 진행 중인 공격이 런지(선공)인가. 누른 순간에 정해지고 바뀌지 않는다.
var attack_lunge := false
var step_target: int = Dist.FAR
## 지금의 이동이 엉킴으로 밀려나는 것인가(스스로 움직이는 이동이면 거짓).
var shoved := false

# --- 엉킴 (무기의 close_bind_time이 0 이하면 전부 쓰이지 않는다) ---
# 게이지(0~1)는 값과 그 값을 잰 시각으로 가진다. 매 tick 더하지 않는다(delta에 따라 달라지지 않게).
var _bind_value := 0.0
var _bind_since := 0.0
var _bind_mode: int = _Bind.HOLD
# 게이지가 다 찼는가. 간격이 밀착이 아니게 되면 풀리기 시작한다.
var _bind_full := false
# 게이지가 다 차는 예정 시각. 차는 중이 아니면 INF.
var _bind_full_at := INF

# "간격이 멀리이고 상대가 IDLE"이 시작된 시각 + 접근 지연. 조건이 깨지면 INF.
var _approach_at := INF
var _queue: Array[Dictionary] = []
var _in_tick := false
var _flushing := false


func setup(p_rules: DuelRules, p_weapon: WeaponData, p_opponent: OpponentData,
		rng: RandomNumberGenerator, p_conditions: Array[CommissionCondition] = [],
		p_has_hat := false) -> void:
	rules = p_rules
	weapon = p_weapon
	opponent_data = p_opponent
	conditions = p_conditions
	opponent_has_hat = p_has_hat
	record = DuelRecord.new()
	brain = OpponentBrain.new(opponent_data, rng)
	player_posture = rules.player_posture_max
	distance = Dist.FAR
	brain.start_idle(0.0)
	_refresh_approach(0.0)
	_refresh_bind()


## 조준(방향, 높이)과 상대의 칼 든 쪽으로 노리는 부위를 정한다.
## has_hat이 참이면 상단의 베기 두 칸이 모자에 걸린다(그 판에서는 칼 든 손을 노릴 수 없다).
static func aim_part(direction: int, height: int, sword_side: int, has_hat := false) -> int:
	var column := 0
	if direction != Dir.CENTER:
		column = 1 if direction == sword_side else 2
	if has_hat and height == Hgt.HIGH and column != 0:
		return Part.HAT
	return AIM_TABLE[height][column]


## 지금 좌클릭이 노리는 부위. 런지가 나가는 때에는 가운데 세로줄이다(방향은 쓰지 않고 높이만 쓴다).
func current_aim_part() -> int:
	var direction: int = Dir.CENTER if is_lunge_now() else aim_direction
	return aim_part(direction, aim_height, opponent_data.sword_side, opponent_has_hat)


## 이 무기에 엉킴이 있는가.
func has_bind() -> bool:
	return weapon.close_bind_time > 0.0


## 지금의 엉킴 게이지(0~1). 엉킴이 없는 무기면 늘 0이다.
func bind_gauge() -> float:
	return _bind_at(time)


## 엉킴으로 밀려나는 중인가.
func is_shoved() -> bool:
	return player_state == PlS.STEPPING and shoved


## 지금 공격을 누르면 섣부른 공격인가: 간격이 멀리가 아니고 빈틈 인정 구간 밖이다.
## 런지가 나가는 때에는 "상대가 예비 동작 중인가"다(멀리에서 누르지만 닿는 공격이라 값을 치른다).
## 판정과 표시가 이 함수를 함께 쓴다.
func is_rash_now() -> bool:
	if is_lunge_now():
		return brain.state == OpS.TELL
	return distance != Dist.FAR and not brain.in_opening(time, rules.opening_grace)


## 이 판에 선공이 있는가: 무기에 런지가 있고 상대가 방심하는 상대다.
func has_lunge() -> bool:
	return weapon.lunge_windup > 0.0 and opponent_data.complacent_time > 0.0


## 지금의 방심 게이지(0~1). 선공이 없는 판이면 늘 0이다.
func complacency() -> float:
	return brain.complacency(time) if has_lunge() else 0.0


## 지금 좌클릭하면 런지인가: 선공이 있고, 간격이 멀리이고, 상대가 방심했다.
func is_lunge_now() -> bool:
	return has_lunge() and distance == Dist.FAR and brain.complacency(time) >= 1.0


## 지금 런지로 머리를 노리면 상대가 피하는가: 머리를 지키는 상대이고, 크게 열린 회수도 무너짐도 아니다.
## 조준 글자가 읽는다(판정은 _judge_attack의 같은 조건이다).
func lunge_head_dodged_now() -> bool:
	if not opponent_data.guards_head or brain.state == OpS.STAGGER:
		return false
	return not (brain.state == OpS.RECOVERY and brain.wide_open)


## 지금 타격이 오면 버티기가 되는가: 상대가 표시된 공격의 예비 동작 중이고,
## 내 막기가 그 예비 동작이 시작되기 전부터 이어진 것(들고만 있던 막기)이다.
## 예비 동작이 시작된 시각 이후에 들어간 막기는 경로와 상관없이 올린 막기다.
func would_brace_now() -> bool:
	if brain.state != OpS.TELL or brain.current_attack == null:
		return false
	# 올려 막기는 패턴의 첫 타격에만 쓴다(결정 371).
	if brain.step_index > 0 or not brain.current_attack.needs_raised_guard:
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
	# 런지인지는 누른 순간에 정해지고 그 뒤로 바뀌지 않는다. 런지는 가운데 찌르기이고 높이만 조준을 따른다.
	attack_lunge = is_lunge_now()
	attack_direction = Dir.CENTER if attack_lunge else aim_direction
	attack_height = aim_height
	attack_part = current_aim_part()
	# 섣부른 공격인지도 누른 순간에 정해지고 그 뒤로 바뀌지 않는다.
	attack_rash = is_rash_now()
	attack_pressed_distance = distance
	var windup := weapon.windup_for(attack_direction, attack_height, distance)
	if attack_lunge:
		windup = weapon.lunge_windup
	player_state = PlS.WINDUP
	player_state_start = time
	player_state_end = time + windup
	_emit(DuelRecord.ATTACK_START, {
		"direction": attack_direction, "height": attack_height, "part": attack_part,
		"judge_time": player_state_end, "rash": attack_rash, "lunge": attack_lunge,
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
	shoved = false
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
			_Ev.BIND_FULL:
				_on_bind_full()
			_Ev.TIME_LIMIT:
				_end(End.TIME_UP, "시간 초과")
		# 간격이나 상대의 무너짐이 바뀌었으면 엉킴 게이지의 움직임을 새로 정한다.
		_refresh_bind()
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
		[_Ev.BIND_FULL, _bind_full_at],
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
					# heights는 사본이다: 기록이 이벤트를 그대로 들고 있어 뇌의 배열을 실으면 뒤에 값이 바뀐다(결정 392).
					"height": brain.current_height(), "heights": brain.strike_heights.duplicate(),
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
	# 걸음이 넘어가기 전에 이 타격의 높이를 잡아 둔다. -1이면 높이가 없어 방향만 본다(결정 386).
	var height := brain.current_height()
	var height_ok := height < 0 or aim_height == height
	var guard_miss := &""
	var result: int
	var situation := -1
	var braced := false
	var posture_loss := 0
	if distance == Dist.FAR:
		result = SR.WHIFF
	elif player_state == PlS.GUARD and aim_direction == atk.direction and height_ok and _holds_sweep():
		var in_window := guard_enter_time >= time - weapon.parry_window
		# 휩쓸기에는 패리가 없다: 새로 누른 막기도 막힘이다(결정 372).
		result = SR.PARRIED if (guard_fresh and in_window and not brain.is_sweep()) else SR.BLOCKED
		# 표시된 공격을 들고만 있던 막기로 받으면 막히기는 하지만 빈틈이 없다. 상대는 아직 TELL이다.
		braced = result == SR.BLOCKED and would_brace_now()
	else:
		match player_state:
			PlS.GUARD:
				situation = Sit.WRONG_GUARD
				# 방향은 맞았는데 맞은 까닭(결정 392).
				if aim_direction == atk.direction:
					guard_miss = &"height" if not height_ok else &"regrip"
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
	# 걸음이 남아 상대가 TELL에 머물면 패턴이 이어진다(결정 371·376).
	var chained := brain.state == OpS.TELL
	_emit(DuelRecord.STRIKE, {
		"attack": atk, "result": result, "situation": situation,
		"recovery": recovery, "recovery_end": time + recovery,
		"player_posture": player_posture, "braced": braced, "posture_loss": posture_loss,
		"next_strike": brain.state_end if chained else -1.0,
		"height": height, "guard_miss": guard_miss,
	})
	if chained:
		_emit(DuelRecord.PATTERN_STEP, {
			"attack": brain.current_attack, "root": brain.pattern_root, "index": brain.step_index,
			"count": brain.pattern_count(), "strike_time": brain.state_end, "duration": brain.tell_duration,
			"height": brain.current_height(),
		})
	if result == SR.HIT:
		_end(End.PLAYER_DEFEATED, "유효타를 맞음")


## 휩쓸기의 둘째 점부터는 첫 점 이전부터 쥐고 있던 막기만 받아낸다(떼었다 다시 누르면 뚫린다. 결정 372).
## 휩쓸기가 아니거나 첫 점이면 늘 참이다.
func _holds_sweep() -> bool:
	if not brain.is_sweep() or brain.step_index == 0:
		return true
	return guard_enter_time <= brain.first_strike_time


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
			# 런지는 예비가 끝나는 시각에 교전에 닿으며 판정한다. 예비 중에 상대가 먼저 다가왔으면 간격은 그대로다.
			if attack_lunge and distance == Dist.FAR:
				_set_distance(Dist.ENGAGE, "player")
			_judge_attack()
			if ended:
				return
			player_state = PlS.RECOVER
			player_state_start = time
			player_state_end = time + (weapon.lunge_recover if attack_lunge else weapon.recover_time)
		PlS.RECOVER:
			_to_ready()
		PlS.STEPPING:
			# 간격 값은 이동이 끝나는 시각에 바뀐다(엉킴으로 밀려나는 이동도 같다).
			var by := "bind" if shoved else "player"
			shoved = false
			_set_distance(step_target, by)
			_to_ready()


## 플레이어 공격의 판정(예비가 끝나는 시각).
## 멀리면 헛침, 상대가 RECOVERY/STAGGER이고 그 종료 시각보다 앞이면 닿음, 아니면 막힘.
func _judge_attack() -> void:
	var result: int = AR.BLOCKED
	var staggered := false
	# 이 공격으로 깎인 상대 자세 칸 수(스침이 아니면 0).
	var cells := 0
	# 머리를 노렸는데 상대가 피했는가.
	var dodged := false
	if distance == Dist.FAR:
		result = AR.WHIFF
	elif brain.state == OpS.RECOVERY and time < brain.state_end:
		if attack_part == Part.HEAD and opponent_data.guards_head and not brain.wide_open:
			# 상대는 얼굴을 지킨다. 크게 열리지 않은 빈틈에서 머리를 노리면 피한다.
			# 상대의 자세·상태·타이머는 그대로다(회수는 끝나지 않는다). 그 빈틈을 날릴 뿐이다.
			dodged = true
		else:
			# 자세가 남은 상대에게 닿음 = 스침. 한 빈틈에는 한 번만 닿는다(회수가 여기서 끝난다).
			# 깎이는 칸 수는 부위마다 다르다(상대 데이터).
			result = AR.GRAZE
			var before := brain.posture
			staggered = brain.on_grazed(time, opponent_data.graze_cells(attack_part))
			cells = before - brain.posture
	elif brain.state == OpS.STAGGER and time < brain.state_end:
		result = AR.HIT
	elif attack_lunge and brain.state == OpS.IDLE:
		# 런지(선공): 방심해 대기 중인 상대는 막지 못한다. 머리는 여전히 지킨다(방심은 크게 열림이 아니다).
		if attack_part == Part.HEAD and opponent_data.guards_head:
			dodged = true
		else:
			# 스침과 같은 처리다: 부위의 칸 수만큼 깎이고 상대는 대기를 새로 시작한다(자세가 0이면 무너진다).
			result = AR.GRAZE
			var before := brain.posture
			staggered = brain.on_grazed(time, opponent_data.graze_cells(attack_part))
			cells = before - brain.posture
	if attack_lunge:
		# 판정된 런지는 결과와 상관없이 상대의 경계를 세운다. 닿았으면 찔린 횟수가 오른다.
		brain.on_lunged(time, result == AR.GRAZE or result == AR.HIT)
	# 섣부른 공격이 막히면 상대가 자세를 되찾는다. 상대의 상태·타이머·연속 막힘은 건드리지 않는다.
	# 피한 공격은 빈틈에 누른 것이라 대가가 없다.
	var posture_gain := 0
	if attack_rash and result == AR.BLOCKED and not dodged:
		posture_gain = brain.regain_posture()
	_emit(DuelRecord.ATTACK, {
		"result": result, "direction": attack_direction, "height": attack_height,
		"part": attack_part, "distance": distance, "pressed_distance": attack_pressed_distance,
		"opponent_posture": brain.posture, "opponent_state": brain.state,
		"rash": attack_rash, "posture_gain": posture_gain,
		"cells": cells, "dodged": dodged, "lunge": attack_lunge,
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


# ---------------------------------------------------------------- 엉킴

## now 시각의 게이지. 값을 잰 시각부터 지금의 움직임대로 흘린 것이다.
func _bind_at(now: float) -> float:
	match _bind_mode:
		_Bind.FILL:
			return minf(_bind_value + (now - _bind_since) / weapon.close_bind_time, 1.0)
		_Bind.DRAIN:
			if weapon.close_bind_release_time <= 0.0:
				return 0.0
			return maxf(_bind_value - (now - _bind_since) / weapon.close_bind_release_time, 0.0)
	return _bind_value


## 게이지의 움직임을 지금의 상태에서 새로 정한다. 움직임이 바뀌면 값을 새로 재고 다 차는 예정 시각을 다시 잡는다.
## 차는 것은 "간격이 밀착이고, 상대가 무너져 있지 않고, 아직 다 차지 않았을 때"뿐이다.
## 간격과 무너짐은 tick 안의 전이에서만 바뀌므로 전이마다 부르면 된다.
func _refresh_bind() -> void:
	if not has_bind():
		return
	var mode: int = _Bind.HOLD
	if distance != Dist.CLOSE:
		mode = _Bind.DRAIN
	elif not _bind_full and brain.state != OpS.STAGGER:
		mode = _Bind.FILL
	if mode == _bind_mode:
		return
	_bind_value = _bind_at(time)
	_bind_since = time
	_bind_mode = mode
	if mode == _Bind.DRAIN:
		_bind_full = false
	_bind_full_at = time + (1.0 - _bind_value) * weapon.close_bind_time if mode == _Bind.FILL else INF


## 게이지가 다 찼다. 먼저 값을 1로 고정하고 예정 시각을 없앤다(간격 값은 이동이 끝날 때까지 밀착이라,
## 그러지 않으면 같은 시각의 같은 전이가 다시 후보가 되어 tick의 고리가 끝나지 않는다).
## 스스로 물러나는 중이면 아무 일도 없고, 아니면 교전으로 밀려난다.
func _on_bind_full() -> void:
	_bind_value = 1.0
	_bind_since = time
	_bind_mode = _Bind.HOLD
	_bind_full = true
	_bind_full_at = INF
	# 밀착에서는 더 전진할 수 없으므로, 밀착에서의 이동은 물러나는 이동이다.
	if player_state == PlS.STEPPING:
		return
	# 하던 것(막기, 공격 예비, 공격 회수)이 끊긴다. 예비 중이던 공격은 판정 없이 사라진다.
	# 내 자세와 상대의 상태·타이머·자세는 건드리지 않는다.
	var cancelled := player_state == PlS.WINDUP
	if player_state == PlS.GUARD:
		_leave_guard(time)
	step_target = Dist.ENGAGE
	shoved = true
	player_state = PlS.STEPPING
	player_state_start = time
	player_state_end = time + maxf(weapon.close_shove_time, 0.0)
	_emit(DuelRecord.SHOVE, {"end_time": player_state_end, "cancelled_attack": cancelled})


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
