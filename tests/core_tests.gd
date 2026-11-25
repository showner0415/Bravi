extends RefCounted
## T1~T13: 결투 규칙 코어 테스트 (씬 없음).
## 시나리오는 봇이 코어 이벤트에 반응해 입력하는 방식으로 돌린다(절대 시각 입력 없음).
## 상대의 공격 순서는 공격이 하나뿐인 테스트용 OpponentData로 고정한다.

const Plain := preload("res://tests/plain_opponent.gd")
const Bot := preload("res://tests/duel_bots.gd")
const DT := preload("res://scripts/duel/duel_types.gd")

const RULES_PATH := "res://data/duel_rules.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const OPPONENT_PATH := "res://data/opponents/opponent_01.tres"

const DELTAS: Array[float] = [1.0 / 30.0, 1.0 / 60.0, 1.0 / 144.0]
const BASE_DELTA := 1.0 / 60.0
## 여유 조건(초): 빈틈 창과 공격 예비 시간의 차이가 이보다 커야 한다.
const MARGIN := 0.1
const EPS := 1e-6

# 판 길이 시뮬레이션 상수. 수치 조정 전후를 비교할 수 있게 고정한다.
const SIM_SEEDS := 30  # 시드 1..30
const SIM_DELTA := 1.0 / 60.0
## T13 통과 기준(초): "막기만 하고 베기 뒤에만 받아치는 봇"의 평균 판 길이.
## 상대 자세 9에 맞춰 40~60초에서 옮겼다(계획 009). 하한은 설계 원칙 1의 아래쪽(30초)이고 폭은 그대로다.
const GUARD_MEAN_MIN := 30.0
const GUARD_MEAN_MAX := 50.0
## "막을 때마다 받아치는 봇"의 평균이 막기 봇의 평균보다 이만큼(초) 이상 길어야 한다.
const RASH_MEAN_GAP := 15.0
## "막기를 누르고만 있는 봇"의 평균이 막기 봇의 평균보다 이만큼(초) 이상 길어야 한다(올려 막기).
const KEEP_MEAN_GAP := 15.0
## 막기 봇의 판 길이 폭(최대 − 최소, 초)의 상한(공격 가방).
const GUARD_SPREAD_MAX := 20.0

const AIM_MID_THRUST := [DT.Direction.CENTER, DT.Height.MID]
const AIM_HIGH_CUT := [DT.Direction.RIGHT, DT.Height.HIGH]

var _scenarios: Array[Dictionary] = []
var _pinned_opponent: OpponentData


class Run:
	var core: DuelCore
	var bot: RefCounted
	## 시나리오가 멈춘 이벤트의 인덱스. 못 찾으면 -1.
	var stop_index := -1


func list(_tree: SceneTree) -> Array:
	_build_scenarios()
	return [
		{"id": "T1", "name": "방어: 막기 / 스침당함 / 패배", "fn": _group_test.bind("T1")},
		{"id": "T2", "name": "받아치기: 막힌 베기 뒤 스침, 막힌 찌르기 뒤 막힘", "fn": _group_test.bind("T2")},
		{"id": "T3", "name": "막힌 베기 뒤 상단 베기: 교전 불가, 밀착 가능", "fn": _group_test.bind("T3")},
		{"id": "T4", "name": "패리 뒤 받아치기", "fn": _group_test.bind("T4")},
		{"id": "T5", "name": "버릇: 3연속 막힘 뒤 큰 베기", "fn": _group_test.bind("T5")},
		{"id": "T6", "name": "대기·예비 중 공격은 막힘, 공격 중 피격 상황", "fn": _group_test.bind("T6")},
		{"id": "T7", "name": "간격: 멀리 헛침, 접근, 헛친 뒤 전진", "fn": _group_test.bind("T7")},
		{"id": "T8", "name": "무너짐과 유효타", "fn": _group_test.bind("T8")},
		{"id": "T9", "name": "90초 시간 초과", "fn": t9_time_up},
		{"id": "T10", "name": "delta 1/30, 1/60, 1/144에서 같은 결과", "fn": t10_delta_invariance},
		{"id": "T11", "name": "빈틈 창과 여유 0.1초", "fn": t11_margins},
		{"id": "T12", "name": "플레이어 상태표", "fn": t12_player_states},
		{"id": "T13", "name": "판 길이 (자유 결투, 시드 %d개)" % SIM_SEEDS, "fn": t13_duel_length},
		{"id": "T23", "name": "섣부른 공격: 빈틈이 아닐 때 낸 공격은 상대 자세를 돌려줌", "fn": t23_rash_attack},
		{"id": "T25", "name": "올려 막기: 표시된 공격은 들고만 있던 막기로는 버티기만", "fn": t25_raised_guard},
		{"id": "T26", "name": "밀착 피격: 밀착에서 맞으면 자세가 더 깎임", "fn": _group_test.bind("T26")},
		{"id": "T27", "name": "공격 가방: 묶음마다 같은 구성, 시드로 재현, 데이터는 그대로", "fn": t27_attack_bag},
	]


## 러너가 끝날 때 부른다. 시나리오의 람다가 self를 붙잡고 있어 순환 참조가 생기므로 끊는다.
func cleanup() -> void:
	_scenarios.clear()
	_pinned_opponent = null


# ================================================================ 도우미

func _base_opponent() -> OpponentData:
	if _pinned_opponent == null:
		# 다른 규칙을 보는 테스트다: 패턴·높이·확률을 끈 옛 규칙 사본이다(결정 416·426). 하루의 판 길이는 T90.
		_pinned_opponent = Plain.of(load(OPPONENT_PATH) as OpponentData)
	return _pinned_opponent


## 실제 상대 데이터를 베껴 새 OpponentData를 만든다. 캐시된 원본은 건드리지 않는다.
func _copy_opponent() -> OpponentData:
	var base := _base_opponent()
	var o := OpponentData.new()
	o.display_name = base.display_name
	o.sword_side = base.sword_side
	o.posture_max = base.posture_max
	o.stagger_time = base.stagger_time
	o.stagger_recover_posture = base.stagger_recover_posture
	o.rash_attack_posture_gain = base.rash_attack_posture_gain
	o.close_hit_posture_loss = base.close_hit_posture_loss
	o.idle_time_min = base.idle_time_min
	o.idle_time_max = base.idle_time_max
	o.approach_delay = base.approach_delay
	o.parried_recovery_bonus = base.parried_recovery_bonus
	o.whiff_recovery_multiplier = base.whiff_recovery_multiplier
	o.close_tell_multiplier = base.close_tell_multiplier
	o.attack_bag_sets = base.attack_bag_sets
	# 칸을 골라 베끼므로 use_heights를 물려받지 않는다. 하루의 공격에 heights가 적혀 있어도 옛 규칙으로 돌린다(결정 426).
	o.use_heights = false
	# 그림과 포즈(계획 029): 이 상대가 씬에 들어가도 그림 없는 상대가 되지 않게 한다.
	o.art = base.art
	o.idle_pose = base.idle_pose
	o.stagger_pose = base.stagger_pose
	o.complacent_pose = base.complacent_pose
	o.dodge_head_deg = base.dodge_head_deg
	o.dodge_time = base.dodge_time
	o.hold_curve = base.hold_curve
	o.tell_in = base.tell_in
	o.swing_ratio = base.swing_ratio
	o.swing_margin = base.swing_margin
	o.return_time = base.return_time
	o.strike_art_on_return = base.strike_art_on_return
	var attacks: Array[AttackData] = []
	attacks.append_array(base.attacks)
	o.attacks = attacks
	var habits: Array[HabitData] = []
	habits.append_array(base.habits)
	o.habits = habits
	return o


func _find_attack(direction: int) -> AttackData:
	for atk in _base_opponent().attacks:
		if atk.direction == direction and not atk.is_big:
			return atk
	return null


func _big_attack() -> AttackData:
	for habit in _base_opponent().habits:
		if habit.response != null and habit.response.is_big:
			return habit.response
	return null


## 공격이 하나뿐이고 대기 시간이 고정(1초)인 테스트용 상대.
## kind: "thrust"(찌르기) 또는 "cut"(왼쪽 베기).
func _make_opp(kind: String, with_habit := false, posture := -1) -> OpponentData:
	var o := _copy_opponent()
	o.idle_time_min = 1.0
	o.idle_time_max = 1.0
	var only: Array[AttackData] = []
	only.append(_find_attack(DT.Direction.CENTER if kind == "thrust" else DT.Direction.LEFT))
	o.attacks = only
	# 버릇은 .tres의 것을 그대로 쓰지 않고 베껴서 횟수 3, 식히기 끔을 직접 적는다.
	# 스위치 표의 버릇 값을 바꿔도 "네 번째가 큰 베기"인 시나리오가 흔들리지 않는다.
	var habits: Array[HabitData] = []
	if with_habit:
		var habit := o.habits[0].duplicate() as HabitData
		habit.count = 3
		habit.reset_on_touched = false
		habits.append(habit)
	o.habits = habits
	if posture >= 0:
		o.posture_max = posture
	return o


## _make_opp에 섣부른 공격 회복량을 직접 적은 것(.tres 값을 조정해도 시나리오가 흔들리지 않게).
func _make_rash_opp(kind: String, gain: int, with_habit := false) -> OpponentData:
	var o := _make_opp(kind, with_habit)
	o.rash_attack_posture_gain = gain
	return o


## _make_opp(버릇 포함)의 버릇과 큰 베기를 베껴 표시 여부(올려 막기)를 직접 적은 것.
## .tres의 스위치 값을 바꿔도 시나리오가 흔들리지 않는다. 로드한 Resource는 고치지 않는다.
func _make_marked_opp(kind: String, marked: bool) -> OpponentData:
	var o := _make_opp(kind, true)
	var habit := o.habits[0].duplicate() as HabitData
	var big := habit.response.duplicate() as AttackData
	big.needs_raised_guard = marked
	habit.response = big
	var habits: Array[HabitData] = [habit]
	o.habits = habits
	return o


## _make_opp(버릇 포함)에 버릇 식히기와 횟수를 직접 적은 것.
func _make_habit_opp(kind: String, reset_on_touched: bool, count := 3) -> OpponentData:
	var o := _make_opp(kind, true)
	o.habits[0].count = count
	o.habits[0].reset_on_touched = reset_on_touched
	return o


## 실제 상대를 베껴 버릇만 바꾼 것(참고 수치용). 버릇은 베낀 것을 고친다.
func _real_with_habit(reset_on_touched: bool, count: int) -> OpponentData:
	var o := _copy_opponent()
	var habits: Array[HabitData] = []
	for h in o.habits:
		var habit := h.duplicate() as HabitData
		habit.count = count
		habit.reset_on_touched = reset_on_touched
		habits.append(habit)
	o.habits = habits
	return o


## 찌르기만 하는 테스트용 상대에 밀착 피격 값을 직접 적은 것.
func _make_close_hit_opp(loss: int) -> OpponentData:
	var o := _make_opp("thrust")
	o.close_hit_posture_loss = loss
	return o


## 막지 않고 끝까지 맞은 판: 스침마다 per_hit칸(남은 만큼만) 깎이고, 자세 0에서 유효타로 진다.
func _check_hit_sequence(r: Run, e: Array[String], per_hit: int, want_distance: int) -> void:
	var want_losses: Array[int] = []
	var posture := r.core.rules.player_posture_max
	while posture > 0:
		var loss := mini(per_hit, posture)
		want_losses.append(loss)
		posture -= loss
	var strikes := r.core.record.of_type(DuelRecord.STRIKE)
	_expect(e, r.core.distance == want_distance, "간격 %d (기대 %d)" % [r.core.distance, want_distance])
	_expect(e, strikes.size() == want_losses.size() + 1, "타격 수 %d (기대 %d)" % [strikes.size(), want_losses.size() + 1])
	for i in mini(strikes.size(), want_losses.size()):
		_expect(e, strikes[i]["result"] == DT.StrikeResult.GRAZE, "%d번째 타격이 스침당함이 아님" % (i + 1))
		_expect(e, strikes[i]["posture_loss"] == want_losses[i], "%d번째 타격에 깎인 칸 %d (기대 %d)" % [
			i + 1, strikes[i]["posture_loss"], want_losses[i]])
	if strikes.size() == want_losses.size() + 1:
		var last := strikes[strikes.size() - 1]
		_expect(e, last["result"] == DT.StrikeResult.HIT and last["posture_loss"] == 0, "마지막 타격이 (깎인 칸 0인) 유효타가 아님")
	_expect(e, r.core.end_reason == DT.EndReason.PLAYER_DEFEATED, "종료 사유가 패배가 아님")


## 전부 막고, 첫 받아치기는 중단 찌르기, 둘째는 상단 베기.
func _cfg_mid_then_high() -> Dictionary:
	var calls: Array[int] = [0]
	var counter := func(_ev: Dictionary) -> Variant:
		calls[0] += 1
		return AIM_MID_THRUST if calls[0] == 1 else AIM_HIGH_CUT
	return {"counter_fn": counter, "max_counters": 2}


## 로드한 무기의 사본에 엉킴의 세 값을 직접 적은 것. 차는 시간이 0이면 엉킴 없는 무기다.
## 로드한 Resource는 고치지 않는다.
func _weapon(bind_time := 0.0, release_time := 0.0, shove_time := 0.45) -> WeaponData:
	var w := (load(WEAPON_PATH) as WeaponData).duplicate() as WeaponData
	w.close_bind_time = bind_time
	w.close_bind_release_time = release_time
	w.close_shove_time = shove_time
	return w


## has_hat: 상대가 모자를 쓴 판인가. 기본은 참이다 — 이 파일과 commission_tests의 시나리오는
## 상단 베기 = 모자를 전제로 한다. 모자 없는 판(게임의 기본)은 거짓을 넘겨 만든다.
## weapon: 내 무기. null이면 엉킴 없는 무기다 — 기존 시나리오와 측정은 "엉킴 없는 판"이다.
## 엉킴을 보는 테스트는 값을 직접 적은 무기를 넘긴다.
func _make_core(opp: OpponentData, seed_value: int,
		conditions: Array[CommissionCondition] = [], has_hat := true, weapon: WeaponData = null) -> DuelCore:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var core := DuelCore.new()
	core.setup(load(RULES_PATH), weapon if weapon != null else _weapon(), opp, rng, conditions, has_hat)
	return core


func _run(opp: OpponentData, cfg: Dictionary, stop: Callable, delta := BASE_DELTA,
		max_time := 40.0, seed_value := 1, conditions: Array[CommissionCondition] = [],
		has_hat := true, weapon: WeaponData = null) -> Run:
	var r := Run.new()
	r.core = _make_core(opp, seed_value, conditions, has_hat, weapon)
	r.bot = Bot.new(r.core, cfg)
	while not r.core.ended and r.core.time < max_time:
		r.core.tick(delta)
		r.bot.update()
		r.stop_index = stop.call(r.core.record)
		if r.stop_index >= 0:
			break
	return r


## n번째(1부터) type 이벤트의 인덱스. 없으면 -1.
func _nth_index(record: DuelRecord, type: StringName, n: int) -> int:
	var seen := 0
	for i in record.events.size():
		if record.events[i]["type"] == type:
			seen += 1
			if seen == n:
				return i
	return -1


func _stop_at(type: StringName, n: int = 1) -> Callable:
	return func(record: DuelRecord) -> int: return _nth_index(record, type, n)


## 멈춘 지점까지의 이벤트 중 n번째(1부터) type 이벤트. 없으면 빈 Dictionary.
func _ev(r: Run, type: StringName, n: int = 1) -> Dictionary:
	var seen := 0
	for i in range(r.stop_index + 1):
		var ev := r.core.record.events[i]
		if ev["type"] == type:
			seen += 1
			if seen == n:
				return ev
	return {}


## 판정에 의미 있는 이벤트(스침, 유효타, 막힘, 패리, 헛침, 간격 변경, 무너짐, 종료)의 종류와 순서.
func _signature(r: Run) -> Array[String]:
	var out: Array[String] = []
	if r.stop_index < 0:
		out.append("NO_STOP")
		return out
	for i in range(r.stop_index + 1):
		var ev := r.core.record.events[i]
		match ev["type"]:
			DuelRecord.STRIKE:
				out.append("strike:%d:%s:%d" % [ev["result"], ev["braced"], ev["posture_loss"]])
			DuelRecord.ATTACK:
				out.append("attack:%d:%d:%s:%d" % [ev["result"], ev["part"], ev["rash"], ev["posture_gain"]])
			DuelRecord.DISTANCE:
				out.append("distance:%d" % ev["distance"])
			DuelRecord.STAGGER_START:
				out.append("stagger_start")
			DuelRecord.STAGGER_END:
				out.append("stagger_end")
			DuelRecord.END:
				out.append("end:%d" % ev["reason"])
	return out


## 통과면 "OK". 빈 문자열은 통과가 아니다(런타임 오류로 함수가 중단되면 ""가 돌아오므로).
func _result(errs: Array[String], sep: String) -> String:
	return "OK" if errs.is_empty() else sep.join(errs)


func _expect(errs: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		errs.append(msg)


func _run_scenario(s: Dictionary, delta: float) -> Run:
	return _run(s["opp"].call(), s["cfg"].call(), s["stop"], delta, s.get("max_time", 40.0))


func _check_scenario(s: Dictionary, r: Run) -> String:
	if r.stop_index < 0:
		return "멈출 이벤트가 나오지 않음"
	var errs: Array[String] = []
	s["check"].call(r, errs)
	return ", ".join(errs)  # 내부용: 빈 문자열이 통과


func _group_test(group: String) -> String:
	var errs: Array[String] = []
	var ran := 0
	for s in _scenarios:
		if s["group"] != group:
			continue
		ran += 1
		var msg := _check_scenario(s, _run_scenario(s, BASE_DELTA))
		if msg != "":
			errs.append("[%s] %s" % [s["id"], msg])
	if ran == 0:
		errs.append("시나리오 없음")
	return _result(errs, " / ")


# ================================================================ 시나리오

func _add(id: String, group: String, opp: Callable, cfg: Callable, stop: Callable,
		check: Callable, max_time := 40.0) -> void:
	_scenarios.append({
		"id": id, "group": group, "opp": opp, "cfg": cfg, "stop": stop,
		"check": check, "max_time": max_time,
	})


func _build_scenarios() -> void:
	_scenarios.clear()
	var SR := DT.StrikeResult
	var AR := DT.AttackResult
	var guard_all := func(_a: AttackData, _i: int) -> StringName: return &"hold"
	var parry_all := func(_a: AttackData, _i: int) -> StringName: return &"parry"
	var counter_mid := func(_ev: Dictionary) -> Variant: return AIM_MID_THRUST
	var counter_high := func(_ev: Dictionary) -> Variant: return AIM_HIGH_CUT

	# ---------------- T1 방어
	_add("1a 올바른 방향 막기", "T1",
		func() -> OpponentData: return _make_opp("thrust"),
		func() -> Dictionary: return {"guard_fn": guard_all},
		_stop_at(DuelRecord.STRIKE),
		func(r: Run, e: Array[String]) -> void:
			_expect(e, _ev(r, DuelRecord.STRIKE)["result"] == SR.BLOCKED, "막힘이 아님")
			_expect(e, r.core.player_posture == r.core.rules.player_posture_max, "내 자세가 변함")
			_expect(e, r.core.brain.posture == r.core.opponent_data.posture_max, "상대 자세가 변함"))

	_add("1b 틀린 방향 막기", "T1",
		func() -> OpponentData: return _make_opp("thrust"),
		func() -> Dictionary:
			return {"guard_fn": func(_a: AttackData, _i: int) -> StringName: return &"wrong"},
		_stop_at(DuelRecord.STRIKE),
		func(r: Run, e: Array[String]) -> void:
			var ev := _ev(r, DuelRecord.STRIKE)
			_expect(e, ev["result"] == SR.GRAZE, "스침당함이 아님")
			_expect(e, ev["situation"] == DT.Situation.WRONG_GUARD, "상황이 WRONG_GUARD가 아님")
			_expect(e, r.core.player_posture == r.core.rules.player_posture_max - 1, "내 자세 -1이 아님")
			_expect(e, not r.core.ended, "결투가 끝남")
			_expect(e, is_zero_approx(ev["recovery"]), "닿은 공격에 회수가 있음")
			_expect(e, r.core.brain.state == DT.OpponentState.IDLE, "상대가 IDLE이 아님"))

	_add("1c 자세 0에서 맞으면 패배", "T1",
		func() -> OpponentData: return _make_opp("thrust"),
		func() -> Dictionary:
			return {"guard_fn": func(_a: AttackData, _i: int) -> StringName: return &"none"},
		_stop_at(DuelRecord.END),
		func(r: Run, e: Array[String]) -> void:
			var strikes := r.core.record.of_type(DuelRecord.STRIKE)
			var n := r.core.rules.player_posture_max
			_expect(e, strikes.size() == n + 1, "타격 수 %d (기대 %d)" % [strikes.size(), n + 1])
			for i in strikes.size():
				var want: int = SR.GRAZE if i < n else SR.HIT
				_expect(e, strikes[i]["result"] == want, "%d번째 타격 결과가 다름" % (i + 1))
				_expect(e, strikes[i]["situation"] == DT.Situation.UNGUARDED, "상황이 UNGUARDED가 아님")
			_expect(e, r.core.end_reason == DT.EndReason.PLAYER_DEFEATED, "종료 사유가 패배가 아님"))

	# ---------------- T2 받아치기
	_add("2a 막힌 베기 뒤 중단 찌르기", "T2",
		func() -> OpponentData: return _make_opp("cut"),
		func() -> Dictionary: return {"guard_fn": guard_all, "counter_fn": counter_mid, "max_counters": 1},
		_stop_at(DuelRecord.ATTACK),
		func(r: Run, e: Array[String]) -> void:
			var ev := _ev(r, DuelRecord.ATTACK)
			_expect(e, _ev(r, DuelRecord.STRIKE)["result"] == SR.BLOCKED, "막힘이 아님")
			_expect(e, ev["result"] == AR.GRAZE, "스침이 아님")
			_expect(e, ev["part"] == DT.Part.TORSO, "부위가 몸통이 아님")
			_expect(e, ev["opponent_posture"] == r.core.opponent_data.posture_max - 1, "상대 자세 -1이 아님")
			_expect(e, ev["opponent_state"] == DT.OpponentState.IDLE, "스침 시각에 회수가 끝나지 않음")
			_expect(e, ev["rash"] == false, "빈틈에 낸 공격이 섣부른 공격으로 판단됨"))

	_add("2b 막힌 찌르기 뒤 중단 찌르기", "T2",
		func() -> OpponentData: return _make_opp("thrust"),
		func() -> Dictionary: return {"guard_fn": guard_all, "counter_fn": counter_mid, "max_counters": 1},
		_stop_at(DuelRecord.ATTACK),
		func(r: Run, e: Array[String]) -> void:
			var ev := _ev(r, DuelRecord.ATTACK)
			_expect(e, ev["result"] == AR.BLOCKED, "막힘이 아님")
			_expect(e, ev["opponent_posture"] == r.core.opponent_data.posture_max, "상대 자세가 변함")
			_expect(e, ev["rash"] == true, "막힌 찌르기 뒤 공격이 섣부른 공격이 아님")
			_expect(e, ev["posture_gain"] == 0, "자세가 가득인데 칸이 돌아옴"))

	# ---------------- T3 막힌 베기 뒤 상단 베기
	_add("3a 교전에서는 닿지 않음", "T3",
		func() -> OpponentData: return _make_opp("cut"),
		func() -> Dictionary: return {"guard_fn": guard_all, "counter_fn": counter_high, "max_counters": 1},
		_stop_at(DuelRecord.ATTACK),
		func(r: Run, e: Array[String]) -> void:
			var ev := _ev(r, DuelRecord.ATTACK)
			_expect(e, ev["distance"] == DT.Distance.ENGAGE, "간격이 교전이 아님")
			_expect(e, ev["result"] == AR.BLOCKED, "막힘이 아님")
			_expect(e, ev["opponent_posture"] == r.core.opponent_data.posture_max, "상대 자세가 변함")
			_expect(e, ev["rash"] == false, "빈틈에 누른 느린 공격이 섣부른 공격으로 판단됨"))

	_add("3b 밀착에서는 모자 스침", "T3",
		func() -> OpponentData: return _make_opp("cut"),
		func() -> Dictionary:
			return {"guard_fn": guard_all, "counter_fn": counter_high, "max_counters": 1,
				"want_distance": DT.Distance.CLOSE},
		_stop_at(DuelRecord.ATTACK),
		func(r: Run, e: Array[String]) -> void:
			var ev := _ev(r, DuelRecord.ATTACK)
			_expect(e, ev["distance"] == DT.Distance.CLOSE, "간격이 밀착이 아님")
			_expect(e, ev["result"] == AR.GRAZE, "스침이 아님")
			_expect(e, ev["part"] == DT.Part.HAT, "부위가 모자가 아님"))

	# ---------------- T4 패리
	_add("4a 패리당한 베기 뒤 상단 베기", "T4",
		func() -> OpponentData: return _make_opp("cut"),
		func() -> Dictionary: return {"guard_fn": parry_all, "counter_fn": counter_high, "max_counters": 1},
		_stop_at(DuelRecord.ATTACK),
		func(r: Run, e: Array[String]) -> void:
			var ev := _ev(r, DuelRecord.ATTACK)
			_expect(e, _ev(r, DuelRecord.STRIKE)["result"] == SR.PARRIED, "패리가 아님")
			_expect(e, ev["result"] == AR.GRAZE, "스침이 아님")
			_expect(e, ev["part"] == DT.Part.HAT, "부위가 모자가 아님")
			_expect(e, ev["rash"] == false, "패리 뒤 공격이 섣부른 공격으로 판단됨"))

	_add("4b 패리당한 찌르기 뒤 중단 찌르기", "T4",
		func() -> OpponentData: return _make_opp("thrust"),
		func() -> Dictionary: return {"guard_fn": parry_all, "counter_fn": counter_mid, "max_counters": 1},
		_stop_at(DuelRecord.ATTACK),
		func(r: Run, e: Array[String]) -> void:
			_expect(e, _ev(r, DuelRecord.STRIKE)["result"] == SR.PARRIED, "패리가 아님")
			_expect(e, _ev(r, DuelRecord.ATTACK)["result"] == AR.GRAZE, "스침이 아님"))

	_add("4c 패리당한 찌르기 뒤 상단 베기", "T4",
		func() -> OpponentData: return _make_opp("thrust"),
		func() -> Dictionary: return {"guard_fn": parry_all, "counter_fn": counter_high, "max_counters": 1},
		_stop_at(DuelRecord.ATTACK),
		func(r: Run, e: Array[String]) -> void:
			var strike := _ev(r, DuelRecord.STRIKE)
			_expect(e, strike["result"] == SR.PARRIED, "패리가 아님")
			# 닿는 쪽인지는 데이터가 정한다: 패리당한 찌르기의 빈틈이 상단 베기의 예비 시간보다 길면 스침이다.
			var windup := r.core.weapon.windup_for(AIM_HIGH_CUT[0], AIM_HIGH_CUT[1], DT.Distance.ENGAGE)
			var reaches: bool = float(strike["recovery"]) > windup
			var want: int = AR.GRAZE if reaches else AR.BLOCKED
			_expect(e, _ev(r, DuelRecord.ATTACK)["result"] == want, "빈틈 %.2f초에 상단 베기 %.2f초인데 %s이 아님" % [
				strike["recovery"], windup, "스침" if reaches else "막힘"]))

	# ---------------- T5 버릇
	_add("5a 3연속 막힘 뒤 큰 베기, 막고 상단 베기", "T5",
		func() -> OpponentData: return _make_opp("cut", true),
		func() -> Dictionary:
			return {"guard_fn": guard_all,
				"counter_fn": func(ev: Dictionary) -> Variant:
					return AIM_HIGH_CUT if (ev["attack"] as AttackData).is_big else null}
			,
		_stop_at(DuelRecord.ATTACK),
		func(r: Run, e: Array[String]) -> void:
			var tells := r.core.record.of_type(DuelRecord.TELL_START)
			_expect(e, tells.size() == 4, "예비 동작 수 %d (기대 4)" % tells.size())
			for i in tells.size():
				_expect(e, (tells[i]["attack"] as AttackData).is_big == (i == 3), "%d번째 공격의 종류가 다름" % (i + 1))
			var ev := _ev(r, DuelRecord.ATTACK)
			_expect(e, ev["result"] == AR.GRAZE, "스침이 아님")
			_expect(e, ev["part"] == DT.Part.HAT, "부위가 모자가 아님"))

	_add("5b 스침당하면 연속 횟수가 0으로", "T5",
		func() -> OpponentData: return _make_opp("thrust", true),
		func() -> Dictionary:
			return {"guard_fn": func(_a: AttackData, i: int) -> StringName:
				return &"none" if i == 3 else &"hold"},
		_stop_at(DuelRecord.TELL_START, 7),
		func(r: Run, e: Array[String]) -> void:
			var tells := r.core.record.of_type(DuelRecord.TELL_START)
			for i in mini(tells.size(), 7):
				_expect(e, (tells[i]["attack"] as AttackData).is_big == (i == 6), "%d번째 공격의 종류가 다름" % (i + 1))
			_expect(e, _ev(r, DuelRecord.STRIKE, 3)["result"] == SR.GRAZE, "3번째 타격이 스침당함이 아님"))

	_add("5c 헛침은 횟수를 바꾸지 않음", "T5",
		func() -> OpponentData: return _make_opp("cut", true),
		func() -> Dictionary:
			return {"guard_fn": func(_a: AttackData, i: int) -> StringName:
				return &"retreat" if i == 3 else &"hold"},
		_stop_at(DuelRecord.TELL_START, 5),
		func(r: Run, e: Array[String]) -> void:
			var tells := r.core.record.of_type(DuelRecord.TELL_START)
			for i in mini(tells.size(), 5):
				_expect(e, (tells[i]["attack"] as AttackData).is_big == (i == 4), "%d번째 공격의 종류가 다름" % (i + 1))
			_expect(e, _ev(r, DuelRecord.STRIKE, 3)["result"] == SR.WHIFF, "3번째 타격이 헛침이 아님"))

	_add("5d 식히기를 켜면 닿을 때마다 박자가 다시 시작", "T5",
		func() -> OpponentData: return _make_habit_opp("cut", true),
		func() -> Dictionary: return {"guard_fn": guard_all, "counter_fn": counter_mid},
		_stop_at(DuelRecord.TELL_START, 6),
		func(r: Run, e: Array[String]) -> void:
			var tells := r.core.record.of_type(DuelRecord.TELL_START)
			for i in mini(tells.size(), 6):
				_expect(e, not (tells[i]["attack"] as AttackData).is_big, "%d번째 공격이 큰 베기임" % (i + 1))
			var grazes := r.core.record.count_where(DuelRecord.ATTACK, "result", AR.GRAZE)
			_expect(e, grazes == 5, "스침 %d번 (기대 5: 막을 때마다 닿음)" % grazes))

	_add("5e 식히기를 켜도 닿지 않으면 네 번째가 큰 베기", "T5",
		func() -> OpponentData: return _make_habit_opp("cut", true),
		func() -> Dictionary: return {"guard_fn": guard_all},
		_stop_at(DuelRecord.TELL_START, 4),
		func(r: Run, e: Array[String]) -> void:
			var tells := r.core.record.of_type(DuelRecord.TELL_START)
			for i in mini(tells.size(), 4):
				_expect(e, (tells[i]["attack"] as AttackData).is_big == (i == 3), "%d번째 공격의 종류가 다름" % (i + 1)))

	# ---------------- T6 대기·예비 중 공격
	_add("6a 대기 중 공격은 막힘", "T6",
		func() -> OpponentData: return _make_opp("thrust"),
		func() -> Dictionary:
			return {"guard_fn": func(_a: AttackData, _i: int) -> StringName: return &"none",
				"attack_at": {"time": 2.0, "aim": AIM_MID_THRUST}},
		_stop_at(DuelRecord.ATTACK),
		func(r: Run, e: Array[String]) -> void:
			var ev := _ev(r, DuelRecord.ATTACK)
			_expect(e, ev["distance"] == DT.Distance.ENGAGE, "간격이 교전이 아님")
			_expect(e, ev["result"] == AR.BLOCKED, "막힘이 아님")
			_expect(e, ev["opponent_posture"] == r.core.opponent_data.posture_max, "상대 자세가 변함")
			_expect(e, ev["rash"] == true, "대기 중 공격이 섣부른 공격이 아님"))

	_add("6b 예비 중 낸 공격은 막히고, 맞으면 IN_ATTACK", "T6",
		func() -> OpponentData: return _make_opp("thrust"),
		func() -> Dictionary:
			return {"guard_fn": func(_a: AttackData, _i: int) -> StringName: return &"none",
				"attack_before_strike": {"index": 1, "lead": 0.15, "aim": AIM_MID_THRUST}},
		_stop_at(DuelRecord.ATTACK),
		func(r: Run, e: Array[String]) -> void:
			var strike := _ev(r, DuelRecord.STRIKE)
			_expect(e, not strike.is_empty(), "공격 판정 전에 타격이 없음")
			if not strike.is_empty():
				_expect(e, strike["result"] == SR.GRAZE, "스침당함이 아님")
				_expect(e, strike["situation"] == DT.Situation.IN_ATTACK, "상황이 IN_ATTACK이 아님")
			var ev := _ev(r, DuelRecord.ATTACK)
			_expect(e, ev["result"] == AR.BLOCKED, "내 공격이 막힘이 아님")
			_expect(e, ev["opponent_posture"] == r.core.opponent_data.posture_max, "상대 자세가 변함")
			_expect(e, ev["rash"] == true, "예비 중 공격이 섣부른 공격이 아님"))

	# ---------------- T7 간격
	_add("7a 멀리에서 헛침, 상대 접근", "T7",
		func() -> OpponentData: return _make_opp("thrust"),
		func() -> Dictionary:
			return {"guard_fn": guard_all, "attack_at": {"time": 0.2, "aim": AIM_MID_THRUST}},
		_stop_at(DuelRecord.DISTANCE),
		func(r: Run, e: Array[String]) -> void:
			_expect(e, _ev(r, DuelRecord.ATTACK).get("result") == AR.WHIFF, "멀리에서 낸 공격이 헛침이 아님")
			_expect(e, _ev(r, DuelRecord.ATTACK).get("rash") == false, "멀리에서 낸 공격이 섣부른 공격으로 판단됨")
			var ev := _ev(r, DuelRecord.DISTANCE)
			_expect(e, ev["distance"] == DT.Distance.ENGAGE, "교전으로 바뀌지 않음")
			_expect(e, ev["by"] == "opponent", "상대가 접근한 것이 아님")
			_expect(e, is_equal_approx(ev["t"], r.core.opponent_data.approach_delay), "접근 시각이 접근 지연과 다름"))

	_add("7b 헛친 베기 뒤 전진+찌르기", "T7",
		func() -> OpponentData: return _make_opp("cut"),
		func() -> Dictionary:
			return {"guard_fn": func(_a: AttackData, i: int) -> StringName:
					return &"retreat" if i == 1 else &"hold",
				"whiff_fn": counter_mid},
		_stop_at(DuelRecord.ATTACK),
		func(r: Run, e: Array[String]) -> void:
			_expect(e, _ev(r, DuelRecord.STRIKE)["result"] == SR.WHIFF, "상대 공격이 헛침이 아님")
			var ev := _ev(r, DuelRecord.ATTACK)
			_expect(e, ev["distance"] == DT.Distance.ENGAGE, "전진하지 않음")
			_expect(e, ev["result"] == AR.BLOCKED, "닿지 않음(막힘)이 아님")
			# 헛친 빈틈이 끝난 직후지만 유예 안이라 섣부른 공격이 아니다.
			_expect(e, ev["rash"] == false, "헛친 베기 뒤 전진 + 찌르기가 섣부른 공격으로 판단됨"))

	var retreat_on_big := func(a: AttackData, _i: int) -> StringName:
		return &"retreat" if a.is_big else &"hold"

	_add("7c 헛친 큰 베기 뒤 전진+찌르기", "T7",
		func() -> OpponentData: return _make_opp("cut", true),
		func() -> Dictionary: return {"guard_fn": retreat_on_big, "whiff_fn": counter_mid},
		_stop_at(DuelRecord.ATTACK),
		func(r: Run, e: Array[String]) -> void:
			var strike := _ev(r, DuelRecord.STRIKE, 4)
			_expect(e, not strike.is_empty() and strike["result"] == SR.WHIFF, "큰 베기가 헛침이 아님")
			_expect(e, _ev(r, DuelRecord.ATTACK)["result"] == AR.GRAZE, "스침이 아님"))

	_add("7d 헛친 큰 베기 뒤 전진+상단 베기", "T7",
		func() -> OpponentData: return _make_opp("cut", true),
		func() -> Dictionary: return {"guard_fn": retreat_on_big, "whiff_fn": counter_high},
		_stop_at(DuelRecord.ATTACK),
		func(r: Run, e: Array[String]) -> void:
			var strike := _ev(r, DuelRecord.STRIKE, 4)
			_expect(e, not strike.is_empty() and strike["result"] == SR.WHIFF, "큰 베기가 헛침이 아님")
			_expect(e, _ev(r, DuelRecord.ATTACK)["result"] == AR.BLOCKED, "닿지 않음(막힘)이 아님"))

	# ---------------- T8 무너짐 (자세 1짜리 상대)
	_add("8a 무너진 상대에게 중단 찌르기", "T8",
		func() -> OpponentData: return _make_opp("cut", false, 1),
		func() -> Dictionary:
			return {"guard_fn": guard_all, "counter_fn": counter_mid, "finisher": AIM_MID_THRUST},
		_stop_at(DuelRecord.END),
		func(r: Run, e: Array[String]) -> void:
			var graze := _ev(r, DuelRecord.ATTACK, 1)
			var stagger := _ev(r, DuelRecord.STAGGER_START)
			_expect(e, graze["result"] == AR.GRAZE, "첫 공격이 스침이 아님")
			_expect(e, not stagger.is_empty() and is_equal_approx(stagger["t"], graze["t"]), "무너짐이 스침과 같은 시각에 시작하지 않음")
			var hit := _ev(r, DuelRecord.ATTACK, 2)
			_expect(e, not hit.is_empty() and hit["result"] == AR.HIT, "두 번째 공격이 유효타가 아님")
			_expect(e, hit.get("part") == DT.Part.TORSO, "부위가 몸통이 아님")
			_expect(e, graze.get("rash") == false and hit.get("rash") == false, "빈틈·무너짐에 낸 공격이 섣부른 공격으로 판단됨")
			_expect(e, r.core.end_reason == DT.EndReason.OPPONENT_HIT, "자유 결투가 유효타로 끝나지 않음"))

	_add("8b 무너진 상대에게 상단 베기", "T8",
		func() -> OpponentData: return _make_opp("cut", false, 1),
		func() -> Dictionary:
			return {"guard_fn": guard_all, "counter_fn": counter_mid, "finisher": AIM_HIGH_CUT},
		_stop_at(DuelRecord.END),
		func(r: Run, e: Array[String]) -> void:
			var hit := _ev(r, DuelRecord.ATTACK, 2)
			_expect(e, not hit.is_empty() and hit["result"] == AR.HIT, "두 번째 공격이 유효타가 아님")
			_expect(e, hit.get("part") == DT.Part.HAT, "부위가 모자가 아님"))

	_add("8c 무너짐을 놓치면 자세 회복", "T8",
		func() -> OpponentData: return _make_opp("cut", false, 1),
		func() -> Dictionary: return {"guard_fn": guard_all, "counter_fn": counter_mid, "max_counters": 1},
		_stop_at(DuelRecord.STAGGER_END),
		func(r: Run, e: Array[String]) -> void:
			var start := _ev(r, DuelRecord.STAGGER_START)
			var done := _ev(r, DuelRecord.STAGGER_END)
			var data := r.core.opponent_data
			_expect(e, is_equal_approx(done["t"] - start["t"], data.stagger_time), "무너짐 길이가 다름")
			_expect(e, done["posture"] == data.stagger_recover_posture, "회복 자세가 다름")
			_expect(e, r.core.brain.state == DT.OpponentState.IDLE, "무너짐 뒤 IDLE이 아님")
			_expect(e, not r.core.ended, "결투가 끝남"))

	# ---------------- T23 섣부른 공격
	var parry_first := func(_a: AttackData, i: int) -> StringName: return &"parry" if i == 1 else &"hold"

	_add("23a 막힌 찌르기 뒤 공격은 칸을 돌려줌", "T23",
		func() -> OpponentData: return _make_rash_opp("thrust", 1),
		func() -> Dictionary: return {"guard_fn": parry_first, "counter_fn": counter_mid, "max_counters": 2},
		_stop_at(DuelRecord.ATTACK, 2),
		func(r: Run, e: Array[String]) -> void:
			var top := r.core.opponent_data.posture_max
			var first := _ev(r, DuelRecord.ATTACK, 1)
			var second := _ev(r, DuelRecord.ATTACK, 2)
			_expect(e, first["result"] == AR.GRAZE and first["rash"] == false, "패리 뒤 첫 공격이 섣부르지 않은 스침이 아님")
			_expect(e, first["opponent_posture"] == top - 1, "첫 공격 뒤 상대 자세 -1이 아님")
			_expect(e, _ev(r, DuelRecord.STRIKE, 2)["result"] == SR.BLOCKED, "둘째 찌르기가 막힘이 아님")
			_expect(e, second["result"] == AR.BLOCKED, "둘째 공격이 막힘이 아님")
			_expect(e, second["rash"] == true, "둘째 공격이 섣부른 공격이 아님")
			_expect(e, second["posture_gain"] == 1, "돌아온 칸 %d (기대 1)" % second["posture_gain"])
			_expect(e, second["opponent_posture"] == top, "상대 자세가 최대로 돌아오지 않음")
			_expect(e, r.core.player_posture == r.core.rules.player_posture_max, "내 자세가 변함"))

	_add("23b 빈틈에 누른 느린 공격은 대가 없음", "T23",
		func() -> OpponentData: return _make_rash_opp("cut", 1),
		_cfg_mid_then_high,
		_stop_at(DuelRecord.ATTACK, 2),
		func(r: Run, e: Array[String]) -> void:
			var second := _ev(r, DuelRecord.ATTACK, 2)
			_expect(e, _ev(r, DuelRecord.ATTACK, 1)["result"] == AR.GRAZE, "첫 공격이 스침이 아님")
			_expect(e, second["distance"] == DT.Distance.ENGAGE, "간격이 교전이 아님")
			_expect(e, second["result"] == AR.BLOCKED, "둘째 공격이 막힘이 아님")
			_expect(e, second["rash"] == false, "빈틈에 누른 공격이 섣부른 공격으로 판단됨")
			_expect(e, second["posture_gain"] == 0, "칸이 돌아옴")
			_expect(e, second["opponent_posture"] == r.core.opponent_data.posture_max - 1, "상대 자세가 최대 -1이 아님"))

	_add("23c 스침 뒤 같은 빈틈에 한 번 더", "T23",
		func() -> OpponentData: return _make_rash_opp("cut", 1),
		func() -> Dictionary:
			return {"guard_fn": guard_all, "counter_fn": counter_mid, "max_counters": 1,
				"follow_up": {"aim": AIM_MID_THRUST, "max": 1}},
		_stop_at(DuelRecord.ATTACK, 2),
		func(r: Run, e: Array[String]) -> void:
			var second := _ev(r, DuelRecord.ATTACK, 2)
			_expect(e, _ev(r, DuelRecord.ATTACK, 1)["result"] == AR.GRAZE, "첫 공격이 스침이 아님")
			_expect(e, second["result"] == AR.BLOCKED, "둘째 공격이 막힘이 아님")
			_expect(e, second["rash"] == true, "둘째 공격이 섣부른 공격이 아님")
			_expect(e, second["posture_gain"] == 1, "돌아온 칸 %d (기대 1)" % second["posture_gain"])
			_expect(e, second["opponent_posture"] == r.core.opponent_data.posture_max, "상대 자세가 최대로 돌아오지 않음"))

	_add("23d 섣부른 공격은 연속 막힘을 바꾸지 않음", "T23",
		func() -> OpponentData: return _make_rash_opp("thrust", 1, true),
		func() -> Dictionary: return {"guard_fn": guard_all, "counter_fn": counter_mid, "max_counters": 3},
		_stop_at(DuelRecord.TELL_START, 4),
		func(r: Run, e: Array[String]) -> void:
			var attacks := r.core.record.of_type(DuelRecord.ATTACK)
			_expect(e, attacks.size() == 3, "공격 수 %d (기대 3)" % attacks.size())
			for a in attacks:
				_expect(e, a["result"] == AR.BLOCKED and a["rash"] == true, "막힌 찌르기 뒤 공격이 섣부른 막힘이 아님")
			var tells := r.core.record.of_type(DuelRecord.TELL_START)
			for i in mini(tells.size(), 4):
				_expect(e, (tells[i]["attack"] as AttackData).is_big == (i == 3), "%d번째 공격의 종류가 다름" % (i + 1)))

	_add("23e 회복량 0이면 규칙이 꺼짐", "T23",
		func() -> OpponentData: return _make_rash_opp("thrust", 0),
		func() -> Dictionary: return {"guard_fn": parry_first, "counter_fn": counter_mid, "max_counters": 2},
		_stop_at(DuelRecord.ATTACK, 2),
		func(r: Run, e: Array[String]) -> void:
			var second := _ev(r, DuelRecord.ATTACK, 2)
			_expect(e, second["result"] == AR.BLOCKED and second["rash"] == true, "둘째 공격이 섣부른 막힘이 아님")
			_expect(e, second["posture_gain"] == 0, "회복량 0인데 칸이 돌아옴")
			_expect(e, second["opponent_posture"] == r.core.opponent_data.posture_max - 1, "상대 자세가 최대 -1이 아님"))

	# ---------------- T25 올려 막기 (네 번째 공격이 큰 베기인 상대, 표시 여부는 직접 적는다)
	var keep_all := func(_a: AttackData, _i: int) -> StringName: return &"keep"
	var counter_big_mid := func(ev: Dictionary) -> Variant:
		return AIM_MID_THRUST if (ev["attack"] as AttackData).is_big else null
	var counter_big_high := func(ev: Dictionary) -> Variant:
		return AIM_HIGH_CUT if (ev["attack"] as AttackData).is_big else null

	_add("25a 누르고만 있으면 큰 베기는 버티기", "T25",
		func() -> OpponentData: return _make_marked_opp("cut", true),
		func() -> Dictionary: return {"guard_fn": keep_all, "counter_fn": counter_big_mid},
		_stop_at(DuelRecord.ATTACK),
		func(r: Run, e: Array[String]) -> void:
			var strike := _ev(r, DuelRecord.STRIKE, 4)
			_expect(e, (strike["attack"] as AttackData).is_big, "네 번째 공격이 큰 베기가 아님")
			_expect(e, strike["result"] == SR.BLOCKED, "큰 베기가 막힘이 아님")
			_expect(e, strike["braced"] == true, "들고만 있던 막기인데 버티기가 아님")
			_expect(e, is_zero_approx(strike["recovery"]), "버티기에 빈틈이 있음 (%.2f)" % strike["recovery"])
			var ev := _ev(r, DuelRecord.ATTACK)
			_expect(e, ev["result"] == AR.BLOCKED and ev["rash"] == true, "버티기 뒤 공격이 섣부른 막힘이 아님")
			_expect(e, ev["opponent_state"] == DT.OpponentState.IDLE, "버티기 뒤 상대가 IDLE이 아님")
			_expect(e, r.core.player_posture == r.core.rules.player_posture_max, "내 자세가 변함")
			_expect(e, r.core.brain.posture == r.core.opponent_data.posture_max, "상대 자세가 변함"))

	_add("25b 뗐다 다시 올리면 받아냄", "T25",
		func() -> OpponentData: return _make_marked_opp("cut", true),
		func() -> Dictionary: return {"guard_fn": guard_all, "counter_fn": counter_big_high},
		_stop_at(DuelRecord.ATTACK),
		func(r: Run, e: Array[String]) -> void:
			var strike := _ev(r, DuelRecord.STRIKE, 4)
			var big := strike["attack"] as AttackData
			_expect(e, strike["result"] == SR.BLOCKED and strike["braced"] == false, "올린 막기가 버티기로 처리됨")
			_expect(e, is_equal_approx(strike["recovery"], big.recovery_time), "빈틈 %.2f (기대 %.2f)" % [strike["recovery"], big.recovery_time])
			var ev := _ev(r, DuelRecord.ATTACK)
			_expect(e, ev["result"] == AR.GRAZE and ev["part"] == DT.Part.HAT, "상단 베기가 모자 스침이 아님"))

	_add("25c 큰 베기를 패리", "T25",
		func() -> OpponentData: return _make_marked_opp("cut", true),
		func() -> Dictionary: return {"guard_fn": parry_all},
		_stop_at(DuelRecord.STRIKE, 4),
		func(r: Run, e: Array[String]) -> void:
			var strike := _ev(r, DuelRecord.STRIKE, 4)
			var big := strike["attack"] as AttackData
			var want: float = big.recovery_time + r.core.opponent_data.parried_recovery_bonus
			_expect(e, big.is_big, "네 번째 공격이 큰 베기가 아님")
			_expect(e, strike["result"] == SR.PARRIED and strike["braced"] == false, "패리가 아니거나 버티기로 처리됨")
			_expect(e, is_equal_approx(strike["recovery"], want), "빈틈 %.2f (기대 %.2f)" % [strike["recovery"], want]))

	# 첫 타격의 막기는 예비 시작 때 처음 눌려 표시 여부와 무관하게 올린 막기다.
	# 그래서 첫 예비부터 들고 있던 막기로 받는 둘째 베기로 본다.
	_add("25d 표시되지 않은 베기는 누르고만 있어도 그대로", "T25",
		func() -> OpponentData: return _make_marked_opp("cut", true),
		func() -> Dictionary:
			var calls: Array[int] = [0]
			var counter := func(_ev: Dictionary) -> Variant:
				calls[0] += 1
				return AIM_MID_THRUST if calls[0] == 2 else null
			return {"guard_fn": keep_all, "counter_fn": counter},
		_stop_at(DuelRecord.ATTACK),
		func(r: Run, e: Array[String]) -> void:
			var strike := _ev(r, DuelRecord.STRIKE, 2)
			var cut := strike["attack"] as AttackData
			var guard_starts := 0
			for ev in r.core.record.of_type(DuelRecord.GUARD_START):
				if ev["t"] <= strike["t"]:
					guard_starts += 1
			_expect(e, guard_starts == 1, "둘째 타격까지 막기 시작 %d번 (기대 1: 들고만 있던 막기)" % guard_starts)
			_expect(e, not cut.is_big and not cut.needs_raised_guard, "둘째 공격이 일반 베기가 아님")
			_expect(e, strike["result"] == SR.BLOCKED and strike["braced"] == false, "일반 베기가 버티기로 처리됨")
			_expect(e, is_equal_approx(strike["recovery"], cut.recovery_time), "빈틈 %.2f (기대 %.2f)" % [strike["recovery"], cut.recovery_time])
			_expect(e, _ev(r, DuelRecord.ATTACK)["result"] == AR.GRAZE, "받아친 찌르기가 스침이 아님"))

	_add("25e 표시를 끄면 누르고만 있어도 받아냄", "T25",
		func() -> OpponentData: return _make_marked_opp("cut", false),
		func() -> Dictionary: return {"guard_fn": keep_all, "counter_fn": counter_big_high},
		_stop_at(DuelRecord.ATTACK),
		func(r: Run, e: Array[String]) -> void:
			var strike := _ev(r, DuelRecord.STRIKE, 4)
			var big := strike["attack"] as AttackData
			_expect(e, big.is_big, "네 번째 공격이 큰 베기가 아님")
			_expect(e, strike["result"] == SR.BLOCKED and strike["braced"] == false, "표시를 껐는데 버티기가 됨")
			_expect(e, is_equal_approx(strike["recovery"], big.recovery_time), "빈틈 %.2f (기대 %.2f)" % [strike["recovery"], big.recovery_time])
			var ev := _ev(r, DuelRecord.ATTACK)
			_expect(e, ev["result"] == AR.GRAZE and ev["part"] == DT.Part.HAT, "상단 베기가 모자 스침이 아님"))

	_add("25f 타격 0.35초 전에 뗐다 다시 누름", "T25",
		func() -> OpponentData: return _make_marked_opp("cut", true),
		func() -> Dictionary:
			return {"guard_fn": keep_all, "regrip_before_strike": {"index": 4, "lead": 0.35}},
		_stop_at(DuelRecord.STRIKE, 4),
		func(r: Run, e: Array[String]) -> void:
			var strike := _ev(r, DuelRecord.STRIKE, 4)
			var big := strike["attack"] as AttackData
			# 쿨다운 뒤 돌아온 막기는 새로 누름이 아니라 패리는 아니지만, 올린 막기다.
			_expect(e, strike["result"] == SR.BLOCKED, "막힘이 아님 (결과 %d)" % strike["result"])
			_expect(e, strike["braced"] == false, "다시 올린 막기가 버티기로 처리됨")
			_expect(e, is_equal_approx(strike["recovery"], big.recovery_time), "빈틈 %.2f (기대 %.2f)" % [strike["recovery"], big.recovery_time]))

	_add("25g 타격 0.08초 전에 떼면 맞음", "T25",
		func() -> OpponentData: return _make_marked_opp("cut", true),
		func() -> Dictionary:
			return {"guard_fn": keep_all, "regrip_before_strike": {"index": 4, "lead": 0.08}},
		_stop_at(DuelRecord.STRIKE, 4),
		func(r: Run, e: Array[String]) -> void:
			var strike := _ev(r, DuelRecord.STRIKE, 4)
			_expect(e, strike["result"] == SR.GRAZE, "스침당함이 아님 (결과 %d)" % strike["result"])
			_expect(e, strike["situation"] == DT.Situation.UNGUARDED, "상황이 UNGUARDED가 아님")
			_expect(e, strike["braced"] == false, "맞았는데 버티기로 처리됨")
			_expect(e, r.core.player_posture == r.core.rules.player_posture_max - 1, "내 자세 -1이 아님"))

	_add("25h 공격 회수 뒤 돌아온 막기도 올린 막기", "T25",
		func() -> OpponentData: return _make_marked_opp("cut", true),
		func() -> Dictionary:
			return {"guard_fn": keep_all,
				"attack_before_strike": {"index": 4, "lead": 0.70, "aim": AIM_MID_THRUST}},
		_stop_at(DuelRecord.STRIKE, 4),
		func(r: Run, e: Array[String]) -> void:
			var ev := _ev(r, DuelRecord.ATTACK)
			_expect(e, not ev.is_empty() and ev["result"] == AR.BLOCKED and ev["rash"] == true, "예비 중 낸 공격이 섣부른 막힘이 아님")
			var strike := _ev(r, DuelRecord.STRIKE, 4)
			var big := strike["attack"] as AttackData
			_expect(e, strike["result"] == SR.BLOCKED and strike["braced"] == false, "회수 뒤 돌아온 막기가 버티기로 처리됨")
			_expect(e, is_equal_approx(strike["recovery"], big.recovery_time), "빈틈 %.2f (기대 %.2f)" % [strike["recovery"], big.recovery_time]))

	# ---------------- T26 밀착 피격 (값은 테스트용 상대에 직접 적는다)
	var none_all := func(_a: AttackData, _i: int) -> StringName: return &"none"
	var wrong_all := func(_a: AttackData, _i: int) -> StringName: return &"wrong"

	_add("26a 값 2, 밀착에서 막지 않음", "T26",
		func() -> OpponentData: return _make_close_hit_opp(2),
		func() -> Dictionary: return {"guard_fn": none_all, "want_distance": DT.Distance.CLOSE},
		_stop_at(DuelRecord.END),
		func(r: Run, e: Array[String]) -> void:
			_check_hit_sequence(r, e, 2, DT.Distance.CLOSE))

	_add("26b 값 2, 교전에서 막지 않음", "T26",
		func() -> OpponentData: return _make_close_hit_opp(2),
		func() -> Dictionary: return {"guard_fn": none_all},
		_stop_at(DuelRecord.END),
		func(r: Run, e: Array[String]) -> void:
			_check_hit_sequence(r, e, 1, DT.Distance.ENGAGE))

	_add("26c 값 1, 밀착에서 막지 않음 (끄면 교전과 같음)", "T26",
		func() -> OpponentData: return _make_close_hit_opp(1),
		func() -> Dictionary: return {"guard_fn": none_all, "want_distance": DT.Distance.CLOSE},
		_stop_at(DuelRecord.END),
		func(r: Run, e: Array[String]) -> void:
			_check_hit_sequence(r, e, 1, DT.Distance.CLOSE))

	_add("26d 값 2, 밀착에서 틀린 방향 막기", "T26",
		func() -> OpponentData: return _make_close_hit_opp(2),
		func() -> Dictionary: return {"guard_fn": wrong_all, "want_distance": DT.Distance.CLOSE},
		_stop_at(DuelRecord.STRIKE),
		func(r: Run, e: Array[String]) -> void:
			var strike := _ev(r, DuelRecord.STRIKE)
			var want := mini(2, r.core.rules.player_posture_max)
			_expect(e, r.core.distance == DT.Distance.CLOSE, "간격이 밀착이 아님")
			_expect(e, strike["result"] == SR.GRAZE, "스침당함이 아님")
			_expect(e, strike["situation"] == DT.Situation.WRONG_GUARD, "상황이 WRONG_GUARD가 아님")
			_expect(e, strike["posture_loss"] == want, "깎인 칸 %d (기대 %d)" % [strike["posture_loss"], want]))


# ================================================================ 개별 테스트

func t9_time_up() -> String:
	var errs: Array[String] = []
	var cfg := {"guard_fn": func(_a: AttackData, _i: int) -> StringName: return &"hold"}
	var r := _run(_make_opp("thrust"), cfg, _stop_at(DuelRecord.END), 1.0 / 30.0, 200.0)
	var limit: float = r.core.rules.time_limit
	_expect(errs, r.core.ended, "끝나지 않음")
	_expect(errs, r.core.end_reason == DT.EndReason.TIME_UP, "종료 사유가 시간 초과가 아님")
	_expect(errs, is_equal_approx(r.core.record.elapsed, limit), "경과 시간 %.3f (기대 %.1f)" % [r.core.record.elapsed, limit])
	return _result(errs, ", ")


func t10_delta_invariance() -> String:
	var errs: Array[String] = []
	var groups := ["T2", "T3", "T4", "T5", "T7", "T8", "T23", "T25", "T26"]
	var ran := 0
	for s in _scenarios:
		if not groups.has(s["group"]):
			continue
		ran += 1
		var first: Array[String] = []
		for i in DELTAS.size():
			var r := _run_scenario(s, DELTAS[i])
			var msg := _check_scenario(s, r)
			if msg != "":
				errs.append("[%s @1/%d] %s" % [s["id"], roundi(1.0 / DELTAS[i]), msg])
			var sig := _signature(r)
			if i == 0:
				first = sig
			elif sig != first:
				errs.append("[%s] delta 1/%d의 이벤트 순서가 1/%d와 다름: %s vs %s" % [
					s["id"], roundi(1.0 / DELTAS[i]), roundi(1.0 / DELTAS[0]), str(sig), str(first)])
	if ran == 0:
		errs.append("시나리오 없음")
	return _result(errs, " / ")


func t11_margins() -> String:
	var w: WeaponData = load(WEAPON_PATH)
	var o := _base_opponent()
	var thrust := _find_attack(DT.Direction.CENTER)
	var cut := _find_attack(DT.Direction.LEFT)
	var cut_r := _find_attack(DT.Direction.RIGHT)
	var big := _big_attack()
	if thrust == null or cut == null or cut_r == null or big == null:
		return "상대 데이터에 찌르기/왼쪽 베기/오른쪽 베기/큰 베기가 없음"

	var C := DT.Direction.CENTER
	var L := DT.Direction.LEFT
	var HI := DT.Height.HIGH
	var MID := DT.Height.MID
	var E := DT.Distance.ENGAGE
	var CL := DT.Distance.CLOSE
	var mid_thrust := w.windup_for(C, MID, E)
	var mid_cut := w.windup_for(L, MID, E)
	var high_thrust := w.windup_for(C, HI, E)
	var high_cut := w.windup_for(L, HI, E)
	var close_thrust := w.windup_for(C, MID, CL)
	var close_high_cut := w.windup_for(L, HI, CL)
	var step := w.step_time

	# [빈틈 이름, 창, 공격 이름, 걸리는 시간, 닿아야 하는가] — 계획의 "빈틈 창과 여유" 표의 행.
	var rows: Array = []
	for c in [cut, cut_r]:
		var blocked: float = c.recovery_time
		var parried: float = c.recovery_time + o.parried_recovery_bonus
		var whiffed: float = c.recovery_time * o.whiff_recovery_multiplier
		rows.append(["막힌 %s" % c.attack_name, blocked, "중단 찌르기", mid_thrust, true])
		rows.append(["막힌 %s" % c.attack_name, blocked, "중단 베기", mid_cut, true])
		rows.append(["막힌 %s" % c.attack_name, blocked, "상단 찌르기", high_thrust, true])
		rows.append(["막힌 %s" % c.attack_name, blocked, "밀착 상단 베기", close_high_cut, true])
		rows.append(["막힌 %s" % c.attack_name, blocked, "상단 베기", high_cut, false])
		rows.append(["패리당한 %s" % c.attack_name, parried, "상단 베기", high_cut, true])
		rows.append(["헛친 %s" % c.attack_name, whiffed, "전진 + 찌르기", step + mid_thrust, false])
	var thrust_blocked := thrust.recovery_time
	var thrust_parried := thrust.recovery_time + o.parried_recovery_bonus
	rows.append(["막힌 찌르기", thrust_blocked, "밀착 찌르기(가장 빠름)", close_thrust, false])
	rows.append(["패리당한 찌르기", thrust_parried, "중단 찌르기", mid_thrust, true])
	rows.append(["패리당한 찌르기", thrust_parried, "중단 베기", mid_cut, true])
	rows.append(["패리당한 찌르기", thrust_parried, "상단 찌르기", high_thrust, true])
	rows.append(["패리당한 찌르기", thrust_parried, "밀착 상단 베기", close_high_cut, true])
	# 닿는 쪽인지는 패리 덧붙임이 정한다(조율값). 어느 쪽이든 여유 0.1초는 지켜야 한다.
	rows.append(["패리당한 찌르기", thrust_parried, "상단 베기", high_cut, thrust_parried > high_cut])
	var big_whiffed := big.recovery_time * o.whiff_recovery_multiplier
	rows.append(["큰 베기(막힘)", big.recovery_time, "상단 베기", high_cut, true])
	rows.append(["헛친 큰 베기", big_whiffed, "전진 + 찌르기", step + mid_thrust, true])
	rows.append(["헛친 큰 베기", big_whiffed, "전진 + 상단 찌르기", step + high_thrust, true])
	rows.append(["헛친 큰 베기", big_whiffed, "전진 + 상단 베기", step + high_cut, false])
	rows.append(["무너짐", o.stagger_time, "내 회수 + 상단 베기", w.recover_time + high_cut, true])

	var errs: Array[String] = []
	for row in rows:
		var window: float = row[1]
		var needed: float = row[3]
		var reaches: bool = row[4]
		var margin := (window - needed) if reaches else (needed - window)
		if margin < MARGIN - EPS:
			errs.append("%s (창 %.3f) × %s (%.3f): %s쪽 여유 %.3f" % [
				row[0], window, row[2], needed, "닿는" if reaches else "닿지 않는", margin])
	# 섣부른 공격 판단의 경계 — 계획 002의 추가 행.
	# [상황, 누르는 시각, 빈틈 인정이 끝나는 시각, 섣부른 공격이어야 하는가]
	var grace: float = (load(RULES_PATH) as DuelRules).opening_grace
	var fastest_tell := INF
	for a in o.attacks:
		fastest_tell = minf(fastest_tell, a.tell_time * o.close_tell_multiplier)
	var rash_rows: Array = []
	for c in [cut, cut_r]:
		rash_rows.append(["헛친 %s 뒤 전진을 마치자마자 누름" % c.attack_name, step,
			c.recovery_time * o.whiff_recovery_multiplier + grace, false])
	rash_rows.append(["스침 뒤 가장 빨리 다시 누름", w.recover_time, grace, true])
	rash_rows.append(["다음 타격을 막고 곧바로 누름", o.idle_time_min + fastest_tell, grace, true])
	for row in rash_rows:
		var pressed: float = row[1]
		var closes: float = row[2]
		var rash: bool = row[3]
		var rash_margin := (pressed - closes) if rash else (closes - pressed)
		if rash_margin < MARGIN - EPS:
			errs.append("%s (누름 %.4f, 빈틈 인정 끝 %.4f): %s쪽 여유 %.4f" % [
				row[0], pressed, closes, "섣부른" if rash else "섣부르지 않은", rash_margin])
	# 올려 막기 — 계획 003의 추가 행: 표시된 공격의 예비 시작부터 막기를 떼야 하는 마지막 시각까지(밀착)가
	# 이 게임이 이미 요구하는 가장 빠른 읽기(가장 짧은 일반 예비, 밀착)보다 급하지 않아야 한다.
	var marked: Array[AttackData] = []
	for a in o.attacks:
		if a.needs_raised_guard:
			marked.append(a)
	for habit in o.habits:
		if habit.response != null and habit.response.needs_raised_guard:
			marked.append(habit.response)
	for a in marked:
		var time_to_release := a.tell_time * o.close_tell_multiplier - w.guard_cooldown
		var regrip_margin := time_to_release - fastest_tell
		if regrip_margin < MARGIN - EPS:
			errs.append("%s: 막기를 떼기까지 %.3f초 (밀착), 가장 짧은 일반 예비 %.3f초: 여유 %.3f" % [
				a.attack_name, time_to_release, fastest_tell, regrip_margin])
	# 쿨다운이 패리 창보다 짧으면 한 패리 창 안에 "새로 누름"이 두 번 들어간다.
	if w.guard_cooldown < w.parry_window:
		errs.append("막기 재입력 쿨다운 %.2f < 패리 창 %.2f" % [w.guard_cooldown, w.parry_window])
	return _result(errs, " / ")


func t12_player_states() -> String:
	var errs: Array[String] = []
	var PS := DT.PlayerState
	# 상대가 아무것도 하지 않도록 접근 지연을 길게 둔다.
	var opp := _make_opp("thrust")
	opp.approach_delay = 1000.0
	var core := _make_core(opp, 1)
	var w := core.weapon
	var d := BASE_DELTA

	# --- STEPPING: 입력 무시, 간격은 끝나는 시각에 바뀜
	_advance(core, 0.1, d)
	var t0 := core.time
	core.step(1)
	_expect(errs, core.player_state == PS.STEPPING, "W 뒤 STEPPING이 아님")
	core.press_attack()
	core.step(1)
	_expect(errs, core.player_state == PS.STEPPING, "STEPPING 중 입력이 상태를 바꿈")
	_expect(errs, core.record.of_type(DuelRecord.ATTACK_START).is_empty(), "STEPPING 중 공격이 받아들여짐")
	_expect(errs, core.record.of_type(DuelRecord.STEP_START).size() == 1, "STEPPING 중 이동이 또 받아들여짐")
	_advance(core, w.step_time - 3.0 * d, d)
	_expect(errs, core.distance == DT.Distance.FAR, "이동이 끝나기 전에 간격이 바뀜")
	_advance(core, 6.0 * d, d)
	_expect(errs, core.distance == DT.Distance.ENGAGE, "이동이 끝난 뒤 간격이 교전이 아님")
	_expect(errs, core.player_state == PS.READY, "이동 뒤 READY가 아님")
	var dist_ev := core.record.of_type(DuelRecord.DISTANCE)
	_expect(errs, dist_ev.size() == 1 and is_equal_approx(dist_ev[0]["t"], t0 + w.step_time), "간격 변경 시각이 이동 종료 시각과 다름")

	# --- WINDUP / RECOVER: 입력 무시
	core.set_aim(DT.Direction.CENTER, DT.Height.MID)
	core.press_attack()
	_expect(errs, core.player_state == PS.WINDUP, "좌클릭 뒤 WINDUP이 아님")
	core.press_attack()
	core.step(-1)
	_expect(errs, core.player_state == PS.WINDUP, "WINDUP 중 입력이 상태를 바꿈")
	_expect(errs, core.record.of_type(DuelRecord.ATTACK_START).size() == 1, "WINDUP 중 공격이 또 받아들여짐")
	_advance(core, w.thrust_windup + 2.0 * d, d)
	_expect(errs, core.player_state == PS.RECOVER, "판정 뒤 RECOVER가 아님")
	core.press_attack()
	core.step(-1)
	_expect(errs, core.player_state == PS.RECOVER, "RECOVER 중 입력이 상태를 바꿈")
	_expect(errs, core.record.of_type(DuelRecord.ATTACK_START).size() == 1, "RECOVER 중 공격이 받아들여짐")
	_expect(errs, core.record.of_type(DuelRecord.STEP_START).size() == 1, "WINDUP/RECOVER 중 이동이 받아들여짐")
	_advance(core, w.recover_time + 2.0 * d, d)
	_expect(errs, core.player_state == PS.READY, "회수 뒤 READY가 아님")

	# --- GUARD를 뗌으로 벗어남: 쿨다운, 쿨다운 뒤에는 "새로 누름"이 아님
	core.set_guard(true)
	_expect(errs, core.player_state == PS.GUARD and core.guard_fresh, "우클릭 뒤 새로 누른 GUARD가 아님")
	var t1 := core.time
	core.set_guard(false)
	_expect(errs, core.player_state == PS.READY, "뗀 뒤 READY가 아님")
	_expect(errs, is_equal_approx(core.guard_cooldown_end, t1 + w.guard_cooldown), "뗀 뒤 쿨다운이 돌지 않음")
	core.set_guard(true)
	_expect(errs, core.player_state == PS.READY, "쿨다운 안의 누름이 받아들여짐")
	_advance(core, w.guard_cooldown * 0.5, d)
	_expect(errs, core.player_state == PS.READY, "쿨다운 중간에 GUARD가 됨")
	_advance(core, w.guard_cooldown, d)
	_expect(errs, core.player_state == PS.GUARD, "쿨다운 뒤 누르고 있는데 GUARD가 아님")
	_expect(errs, not core.guard_fresh, "쿨다운 뒤 들어간 GUARD가 새로 누름으로 처리됨")

	# --- GUARD를 공격으로 벗어남: 쿨다운, 회수 뒤 누르고 있으면 새로 누름이 아닌 GUARD
	core.set_guard(false)
	_advance(core, w.guard_cooldown + 2.0 * d, d)
	core.set_guard(true)
	_expect(errs, core.player_state == PS.GUARD and core.guard_fresh, "다시 누른 GUARD가 새로 누름이 아님")
	var t2 := core.time
	core.press_attack()
	_expect(errs, core.player_state == PS.WINDUP, "GUARD에서 공격하면 WINDUP이 아님")
	_expect(errs, is_equal_approx(core.guard_cooldown_end, t2 + w.guard_cooldown), "공격으로 막기가 풀릴 때 쿨다운이 돌지 않음")
	_advance(core, w.thrust_windup + w.recover_time + 3.0 * d, d)
	_expect(errs, core.player_state == PS.GUARD and not core.guard_fresh, "회수 뒤 누르고 있는데 (새로 누름이 아닌) GUARD가 아님")
	return _result(errs, ", ")


func t23_rash_attack() -> String:
	var errs: Array[String] = []
	var scenarios := _group_test("T23")
	if scenarios != "OK":
		errs.append(scenarios)

	# 빈틈이 끝나는 세 경로(회수의 예정 종료, 스침, 무너짐 종료)가 모두 빈틈 인정 유예를 시작한다.
	var grace := 0.15
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var S := DT.OpponentState
	for from: int in [S.RECOVERY, S.STAGGER]:
		var from_name: String = DT.OPPONENT_STATE_NAMES[from]
		var brain := OpponentBrain.new(_make_opp("cut", false, 3), rng)
		_expect(errs, not brain.in_opening(0.0, grace), "시작하자마자 빈틈 인정 구간임")
		brain.state = from
		_expect(errs, brain.in_opening(5.0, 0.0), "%s인데 빈틈 인정 구간이 아님" % from_name)
		if from == S.STAGGER:
			brain.end_stagger(5.0)
		else:
			brain.start_idle(5.0)
		_expect(errs, brain.in_opening(5.0 + grace - 0.01, grace), "%s 종료 뒤 유예 안인데 빈틈 인정이 아님" % from_name)
		_expect(errs, not brain.in_opening(5.0 + grace, grace), "유예와 같은 시각이 빈틈 인정 구간임")
		# 대기 시간만 새로 재는 것(멀리를 벗어날 때)은 유예를 다시 시작하지 않는다.
		brain.start_idle(9.0)
		_expect(errs, not brain.in_opening(9.0, grace), "IDLE에서 다시 잰 대기가 유예를 시작함")
	var grazed := OpponentBrain.new(_make_opp("cut", false, 3), rng)
	grazed.state = S.RECOVERY
	grazed.on_grazed(5.0)
	_expect(errs, grazed.in_opening(5.1, grace) and not grazed.in_opening(5.0 + grace, grace), "스침으로 끝난 빈틈의 유예가 다름")
	return _result(errs, " / ")


func t25_raised_guard() -> String:
	var errs: Array[String] = []
	var scenarios := _group_test("T25")
	if scenarios != "OK":
		errs.append(scenarios)

	# "지금 타격이 오면 버티기가 되는가"를 코어를 직접 몰아 확인한다(표시와 판정이 함께 쓰는 함수).
	var keep := func(_a: AttackData, _i: int) -> StringName: return &"keep"
	var r := _run(_make_marked_opp("cut", true), {"guard_fn": keep}, _stop_at(DuelRecord.TELL_START, 4))
	var core := r.core
	_expect(errs, core.brain.current_attack != null and core.brain.current_attack.is_big, "네 번째 예비 동작이 큰 베기가 아님")
	_expect(errs, core.would_brace_now(), "큰 베기 예비 중 누르고만 있는데 버티기가 아님")
	core.set_guard(false)
	_expect(errs, not core.would_brace_now(), "막고 있지 않은데 버티기로 판단됨")
	core.set_guard(true)
	_advance(core, core.weapon.guard_cooldown + 2.0 * BASE_DELTA, BASE_DELTA)
	_expect(errs, core.player_state == DT.PlayerState.GUARD, "쿨다운 뒤 막기로 돌아오지 않음")
	_expect(errs, not core.would_brace_now(), "뗐다 다시 누른 막기가 버티기로 판단됨")

	# 표시되지 않은 공격의 예비 중에는 누르고만 있어도 버티기가 아니다.
	var plain := _run(_make_marked_opp("cut", true), {"guard_fn": keep}, _stop_at(DuelRecord.TELL_START, 2))
	_expect(errs, not plain.core.would_brace_now(), "일반 베기 예비 중인데 버티기로 판단됨")
	return _result(errs, " / ")


func t27_attack_bag() -> String:
	var errs: Array[String] = []
	var opp := _copy_opponent()
	opp.attack_bag_sets = 1
	var attack_count := opp.attacks.size()
	# 한 가방의 구성: 공격마다 반올림한 가중치(0보다 크면 적어도 1)장.
	var want := {}
	var bag_size := 0
	for atk in opp.attacks:
		if atk.weight <= 0.0:
			continue
		want[atk] = maxi(roundi(atk.weight), 1)
		bag_size += int(want[atk])
	_expect(errs, bag_size > 0, "가방이 비는 상대 데이터")
	if bag_size == 0:
		return _result(errs, " / ")

	var never := func(_record: DuelRecord) -> int: return -1
	# 전역 난수의 시드를 서로 다르게 두고 같은 판을 두 번 돌린다.
	var orders: Array = []
	for global_seed in [111, 222]:
		seed(global_seed)
		var r := _run(opp, _cfg_guard_only(), never, SIM_DELTA, 10000.0, 1)
		var normal: Array[AttackData] = []
		var order: Array[String] = []
		for ev in r.core.record.of_type(DuelRecord.TELL_START):
			order.append((ev["attack"] as AttackData).attack_name)
			if not ev["is_habit"]:
				normal.append(ev["attack"])
		orders.append(order)
		# 버릇 반응이 아닌 공격을 가방 크기씩 묶으면(끝의 덜 찬 묶음은 뺀다) 묶음마다 구성이 같다.
		var full_bags := normal.size() / bag_size
		_expect(errs, full_bags >= 2, "다 찬 가방이 %d개뿐 (기대 2개 이상)" % full_bags)
		for b in full_bags:
			var got := {}
			for i in bag_size:
				var atk := normal[b * bag_size + i]
				got[atk] = int(got.get(atk, 0)) + 1
			for atk: AttackData in want:
				if int(got.get(atk, 0)) != int(want[atk]):
					errs.append("%d번째 가방의 %s %d장 (기대 %d)" % [b + 1, atk.attack_name, int(got.get(atk, 0)), int(want[atk])])
	randomize()
	_expect(errs, orders[0] == orders[1], "전역 난수 시드에 따라 공격 순서가 달라짐")
	_expect(errs, opp.attacks.size() == attack_count, "판이 끝난 뒤 상대 데이터의 공격 배열 길이가 바뀜")
	_expect(errs, _base_opponent().attacks.size() == attack_count, "로드한 상대 데이터의 공격 배열 길이가 바뀜")
	return _result(errs, " / ")


func _advance(core: DuelCore, seconds: float, delta: float) -> void:
	var until := core.time + seconds
	while core.time + delta * 0.5 < until:
		core.tick(delta)


# ---------------------------------------------------------------- 판 길이

## 전부 패리하고 받아치는 봇.
func _cfg_parry_all() -> Dictionary:
	return {
		"guard_fn": func(_a: AttackData, _i: int) -> StringName: return &"parry",
		"counter_fn": func(_ev: Dictionary) -> Variant: return AIM_MID_THRUST,
		"finisher": AIM_MID_THRUST,
	}


## 막기만 하고, 빈틈이 생기는 공격(베기와 큰 베기) 뒤에만 받아치는 봇.
func _cfg_guard_only() -> Dictionary:
	return {
		"guard_fn": func(_a: AttackData, _i: int) -> StringName: return &"hold",
		"counter_fn": func(ev: Dictionary) -> Variant:
			return AIM_MID_THRUST if float(ev["recovery"]) > 0.0 else null,
		"finisher": AIM_MID_THRUST,
	}


## 막기 봇과 같되 막기를 누르고만 있는 봇. 표시된 공격(큰 베기)의 예비 동작에도 떼지 않는다.
func _cfg_guard_keep() -> Dictionary:
	return {
		"guard_fn": func(_a: AttackData, _i: int) -> StringName: return &"keep",
		"counter_fn": func(ev: Dictionary) -> Variant:
			return AIM_MID_THRUST if float(ev["recovery"]) > 0.0 else null,
		"finisher": AIM_MID_THRUST,
	}


## 막을 때마다(찌르기든 베기든) 받아치는 봇. 막힌 찌르기 뒤의 공격은 섣부른 공격이다.
func _cfg_always_counter() -> Dictionary:
	return {
		"guard_fn": func(_a: AttackData, _i: int) -> StringName: return &"hold",
		"counter_fn": func(_ev: Dictionary) -> Variant: return AIM_MID_THRUST,
		"finisher": AIM_MID_THRUST,
	}


## 베기 뒤에는 늘 받아치고, 막힌 찌르기 뒤에는 세 번에 한 번 섣불리 치는 봇(난수 없이 순번으로).
func _cfg_rash_one_in_three() -> Dictionary:
	var thrusts: Array[int] = [0]
	var counter := func(ev: Dictionary) -> Variant:
		if float(ev["recovery"]) > 0.0:
			return AIM_MID_THRUST
		thrusts[0] += 1
		return AIM_MID_THRUST if thrusts[0] % 3 == 0 else null
	return {"counter_fn": counter, "finisher": AIM_MID_THRUST}


## 시드 1..SIM_SEEDS로 판을 돌려 길이 통계를 낸다.
## lengths는 시드 순서의 판 길이, rash와 regained는 판당 평균 섣부른 공격 수와 상대가 되찾은 칸 수.
func _simulate(opp: OpponentData, cfg_fn: Callable,
		conditions: Array[CommissionCondition] = [], has_hat := true, weapon: WeaponData = null) -> Dictionary:
	var total := 0.0
	var shortest := INF
	var longest := 0.0
	var timeouts := 0
	var wins := 0
	var losses := 0
	var lengths: Array[float] = []
	var rash := 0
	var regained := 0
	var habit_tells := 0
	var big_grazes := 0
	var dodges := 0
	var never := func(_record: DuelRecord) -> int: return -1
	for s in range(1, SIM_SEEDS + 1):
		var r := _run(opp, cfg_fn.call(), never, SIM_DELTA, 10000.0, s, conditions, has_hat, weapon)
		var length := r.core.record.elapsed
		lengths.append(length)
		habit_tells += r.core.record.count_where(DuelRecord.TELL_START, "is_habit", true)
		for ev in r.core.record.of_type(DuelRecord.ATTACK):
			if ev["rash"]:
				rash += 1
			regained += int(ev["posture_gain"])
			if int(ev["cells"]) >= 2:
				big_grazes += 1
			if ev["dodged"]:
				dodges += 1
		total += length
		shortest = minf(shortest, length)
		longest = maxf(longest, length)
		match r.core.end_reason:
			DT.EndReason.TIME_UP:
				timeouts += 1
			DT.EndReason.OPPONENT_HIT, DT.EndReason.CONDITION:
				# 의뢰 조건이 끝낸 판도 상대의 유효타로 끝난 것이다.
				wins += 1
			DT.EndReason.PLAYER_DEFEATED:
				losses += 1
	return {
		"mean": total / SIM_SEEDS, "min": shortest, "max": longest,
		"timeouts": timeouts, "wins": wins, "losses": losses,
		"lengths": lengths, "rash": float(rash) / SIM_SEEDS, "regained": float(regained) / SIM_SEEDS,
		"big": float(habit_tells) / SIM_SEEDS,
		# 판당 2칸 이상 깎은 스침의 수, 머리를 노렸다가 피해진 공격의 수.
		"big_grazes": float(big_grazes) / SIM_SEEDS, "dodges": float(dodges) / SIM_SEEDS,
	}


func _stat_line(label: String, st: Dictionary) -> String:
	return "  INFO %s: 평균 %.1f초 (최소 %.1f, 최대 %.1f), 승 %d / 패 %d / 시간 초과 %d" % [
		label, st["mean"], st["min"], st["max"], st["wins"], st["losses"], st["timeouts"]]


func _rash_suffix(st: Dictionary) -> String:
	return ", 섣부른 공격 %.1f회/판, 상대가 되찾은 칸 %.1f/판" % [st["rash"], st["regained"]]


func t13_duel_length() -> String:
	var errs: Array[String] = []
	var real := _base_opponent()
	var rules: DuelRules = load(RULES_PATH)
	print("  INFO 판 길이 시뮬레이션: 시드 1..%d, delta 1/%d, 상대 자세 %d" % [
		SIM_SEEDS, roundi(1.0 / SIM_DELTA), real.posture_max])

	# 패리 봇은 참고용이다(통과 조건 아님). 기준은 막기 봇의 평균이다.
	var parry := _simulate(real, _cfg_parry_all)
	print(_stat_line("전부 패리하고 받아치는 봇", parry))

	var guard := _simulate(real, _cfg_guard_only)
	print(_stat_line("막기만 하고 베기 뒤에만 받아치는 봇", guard))
	_expect(errs, guard["mean"] >= GUARD_MEAN_MIN and guard["mean"] <= GUARD_MEAN_MAX,
		"막기 봇 평균 %.1f초가 %.0f~%.0f초 밖" % [guard["mean"], GUARD_MEAN_MIN, GUARD_MEAN_MAX])
	_expect(errs, guard["timeouts"] * 10 <= SIM_SEEDS, "막기 봇 시간 초과 %d판 (10%% 초과)" % guard["timeouts"])
	# 공격 가방: 베기가 몇 번 나오느냐에 따라 판 길이가 갈리지 않아야 한다.
	_expect(errs, guard["max"] - guard["min"] <= GUARD_SPREAD_MAX,
		"막기 봇의 판 길이 폭 %.1f초가 %.0f초를 넘음" % [guard["max"] - guard["min"], GUARD_SPREAD_MAX])

	# 섣부른 공격의 대가: 막을 때마다 받아치면 가려서 받아치는 것보다 분명히 나빠야 한다.
	var always := _simulate(real, _cfg_always_counter)
	print(_stat_line("막을 때마다 받아치는 봇", always) + _rash_suffix(always))
	var shorter := 0
	for i in SIM_SEEDS:
		if always["lengths"][i] < guard["lengths"][i] - EPS:
			shorter += 1
	_expect(errs, shorter == 0, "막을 때마다 받아치는 봇이 막기 봇보다 짧은 시드 %d개" % shorter)
	_expect(errs, always["mean"] >= guard["mean"] + RASH_MEAN_GAP,
		"막을 때마다 받아치는 봇 평균 %.1f초가 막기 봇 평균 + %.0f초(%.1f초)보다 짧음" % [
			always["mean"], RASH_MEAN_GAP, guard["mean"] + RASH_MEAN_GAP])
	# 참고용(통과 조건 아님): 가끔 잘못 읽는 플레이.
	var sometimes := _simulate(real, _cfg_rash_one_in_three)
	print(_stat_line("(참고) 막힌 찌르기 세 번에 한 번 섣불리 치는 봇", sometimes) + _rash_suffix(sometimes))

	# 올려 막기의 대가: 막기를 누르고만 있으면 큰 베기의 빈틈을 받지 못해 가려서 막는 것보다 분명히 느려야 한다.
	var keep := _simulate(real, _cfg_guard_keep)
	print(_stat_line("막기를 누르고만 있는 봇", keep))
	var keep_shorter := 0
	for i in SIM_SEEDS:
		if keep["lengths"][i] < guard["lengths"][i] - EPS:
			keep_shorter += 1
	_expect(errs, keep_shorter == 0, "누르고만 있는 봇이 막기 봇보다 짧은 시드 %d개" % keep_shorter)
	_expect(errs, keep["mean"] >= guard["mean"] + KEEP_MEAN_GAP,
		"누르고만 있는 봇 평균 %.1f초가 막기 봇 평균 + %.0f초(%.1f초)보다 짧음" % [
			keep["mean"], KEEP_MEAN_GAP, guard["mean"] + KEEP_MEAN_GAP])
	# 참고용(통과 조건 아님): 버릇이 한 판에 몇 번 반복되는가.
	print("  INFO 판당 큰 베기: 패리 봇 %.1f회 / 막기 봇 %.1f회 / 누르고만 있는 봇 %.1f회 / 막을 때마다 받아치는 봇 %.1f회" % [
		parry["big"], guard["big"], keep["big"], always["big"]])

	# 참고용(통과 조건 아님): 받아치기를 타격 0.20초 뒤에 누르는 손. 교전의 막힌 베기(빈틈 0.55초)에는 여전히 닿는다.
	var late_cfg := func() -> Dictionary:
		var cfg := _cfg_guard_only()
		cfg["counter_delay"] = 0.20
		return cfg
	print(_stat_line("(참고) 막기 봇 · 0.20초 늦게 누름", _simulate(real, late_cfg)))

	# 참고용(통과 조건 아님): 버릇 식히기(장치 D)를 켰을 때의 수치. 실제 상대를 베껴 버릇만 바꾼다.
	for count in [3, 2]:
		var cooled := _real_with_habit(true, count)
		var cooled_guard := _simulate(cooled, _cfg_guard_only)
		var cooled_parry := _simulate(cooled, _cfg_parry_all)
		print(_stat_line("(참고) 식히기 켬 · 횟수 %d · 막기 봇" % count, cooled_guard) + ", 큰 베기 %.1f회/판" % cooled_guard["big"])
		print(_stat_line("(참고) 식히기 켬 · 횟수 %d · 패리 봇" % count, cooled_parry) + ", 큰 베기 %.1f회/판" % cooled_parry["big"])

	# 참고용(통과 조건 아님): 상대 자세 칸 수에 따른 판 길이.
	for posture in [8, 11, 14]:
		if posture == real.posture_max:
			continue
		var alt := _copy_opponent()
		alt.posture_max = posture
		print(_stat_line("(참고) 자세 %d칸 · 패리 봇" % posture, _simulate(alt, _cfg_parry_all)))
		print(_stat_line("(참고) 자세 %d칸 · 막기 봇" % posture, _simulate(alt, _cfg_guard_only)))
	return _result(errs, ", ")
