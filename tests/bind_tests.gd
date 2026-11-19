extends RefCounted
## T47, T48: 밀착의 엉킴 — 게이지, 밀려남, 시간 제한의 구조, 판 길이 측정, 표시.
## 결투는 core_tests.gd의 도우미로 돌린다. 무기는 로드한 것의 사본에 엉킴의 값을 직접 적어 넘긴다
## (도우미의 기본 무기는 엉킴 없는 무기다). 모자 없는 판이 기본이다.
## 통과 조건은 테스트가 값을 적은 무기와 상대로 본다. 로드한 .tres의 값으로 잰 것은 INFO 줄이다.

const Core := preload("res://tests/core_tests.gd")
const Bot := preload("res://tests/duel_bots.gd")
const DT := preload("res://scripts/duel/duel_types.gd")

const OPPONENT_PATH := "res://data/opponents/opponent_01.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const FEATHER_PATH := "res://data/commissions/feather_cut.tres"
const DUEL_PATH := "res://scenes/duel/duel.tscn"

const AIM_MID_THRUST := [DT.Direction.CENTER, DT.Height.MID]

## 테스트가 적는 엉킴의 값(초): 차는 시간, 풀리는 시간, 밀려나는 시간.
const BIND_TIME := 6.0
const RELEASE_TIME := 9.0
const SHOVE_TIME := 0.45
## 예정 시각을 견줄 때의 여유(초).
const TIME_EPS := 0.001
## 들어갔다 나오는 봇: 게이지가 이 값 이하면 들어가고, 이 값 이상이면 나온다.
const ENTER_GAUGE := 0.2
const LEAVE_GAUGE := 0.8
## 측정에 쓰는 늦은 손(초).
const LATE_HAND := 0.20

var _tree: SceneTree
var _h := Core.new()


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T47", "name": "밀착의 엉킴: 게이지, 밀려남, 시간으로 제한된다", "fn": t47_bind},
		{"id": "T48", "name": "엉킴의 판 길이와 표시 (시드 %d개)" % Core.SIM_SEEDS, "fn": t48_lengths_and_display},
	]


func cleanup() -> void:
	_h.cleanup()
	_h = null
	_tree = null


# ================================================================ 도우미

func _expect(errs: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		errs.append(msg)


func _result(errs: Array[String]) -> String:
	return "OK" if errs.is_empty() else " / ".join(errs)


func _near(a: float, b: float, eps := TIME_EPS) -> bool:
	return absf(a - b) <= eps


## 엉킴이 있는 테스트용 무기.
func _bind_weapon(bind_time := BIND_TIME) -> WeaponData:
	return _h._weapon(bind_time, RELEASE_TIME, SHOVE_TIME)


func _core(opp: OpponentData, weapon: WeaponData, seed_value := 1) -> DuelCore:
	var no_conditions: Array[CommissionCondition] = []
	return _h._make_core(opp, seed_value, no_conditions, false, weapon)


## 아무것도 하지 않는 상대(대기가 아주 길다). 내 입력만으로 간격과 게이지를 본다.
func _idle_opp() -> OpponentData:
	var o := _h._make_opp("thrust")
	o.idle_time_min = 1000.0
	o.idle_time_max = 1000.0
	o.approach_delay = 1000.0
	return o


func _hold_all() -> Callable:
	return func(_a: AttackData, _i: int) -> StringName: return &"hold"


## cond가 참이 될 때까지 tick을 돌린다. 참이 됐으면 true.
func _tick_until(core: DuelCore, bot: RefCounted, cond: Callable, max_time := 60.0, delta := Core.BASE_DELTA) -> bool:
	while not cond.call():
		if core.ended or core.time >= max_time:
			return false
		core.tick(delta)
		if bot != null:
			bot.call("update")
	return true


func _tick_for(core: DuelCore, bot: RefCounted, seconds: float, delta := Core.BASE_DELTA) -> void:
	var until := core.time + seconds
	_tick_until(core, bot, func() -> bool: return core.time + delta * 0.5 >= until, until + 1.0, delta)


## 코어 시각이 at 이상이 될 때까지 돌린다.
func _tick_to(core: DuelCore, bot: RefCounted, at: float, delta := Core.BASE_DELTA) -> void:
	_tick_until(core, bot, func() -> bool: return core.time >= at, at + 1.0, delta)


## 내 입력만으로 멀리에서 밀착까지 걸어 들어간다. 간격이 밀착이 된 시각을 돌려준다(실패하면 -1).
func _walk_in(core: DuelCore) -> float:
	for i in 2:
		core.step(1)
		_tick_for(core, null, core.weapon.step_time + 0.05)
	if core.distance != DT.Distance.CLOSE:
		return -1.0
	return _last_distance_time(core.record, DT.Distance.CLOSE)


## 간격이 distance가 된 마지막 이벤트의 시각. 없으면 -1.
func _last_distance_time(record: DuelRecord, distance: int) -> float:
	var t := -1.0
	for ev in record.of_type(DuelRecord.DISTANCE):
		if ev["distance"] == distance:
			t = ev["t"]
	return t


## 간격이 distance가 된 첫 이벤트. 없으면 빈 Dictionary.
func _first_distance(record: DuelRecord, distance: int, after := -1.0) -> Dictionary:
	for ev in record.of_type(DuelRecord.DISTANCE):
		if ev["distance"] == distance and float(ev["t"]) > after:
			return ev
	return {}


## 기록에서 "밀착에서 싸울 수 있던 구간"을 뽑는다(계획 008의 정의. T47의 통과 조건과 T48의 INFO가 함께 쓴다).
## 싸울 수 있던 시간 = 간격이 밀착이고, 밀려나는 중도 스스로 물러나는 이동 중도 아니고, 상대가 무너져 있지 않은 시간.
## - 구간의 시작: 간격이 밀착이 된 시각.
## - 구간의 끝: 그 뒤 가장 먼저 오는 밀려남의 시작, 물러나는 이동의 시작(STEP_START), 판의 끝.
## - 구간의 길이: (끝 − 시작) − 그 구간과 겹친 무너짐 시간.
## 돌려주는 것: {"lengths": 구간마다의 길이, "longest": 가장 긴 길이, "total": 길이의 합, "stagger": 뺀 무너짐 시간의 합}
func _close_spans(record: DuelRecord) -> Dictionary:
	var finish := record.elapsed
	var staggers: Array = []
	var stagger_start := -1.0
	for ev in record.events:
		if ev["type"] == DuelRecord.STAGGER_START:
			stagger_start = ev["t"]
		elif ev["type"] == DuelRecord.STAGGER_END and stagger_start >= 0.0:
			staggers.append([stagger_start, float(ev["t"])])
			stagger_start = -1.0
	if stagger_start >= 0.0:
		staggers.append([stagger_start, finish])

	var spans: Array = []
	var span_start := -1.0
	for ev in record.events:
		var t: float = ev["t"]
		match ev["type"]:
			DuelRecord.DISTANCE:
				if ev["distance"] == DT.Distance.CLOSE:
					span_start = t
				elif span_start >= 0.0:
					spans.append([span_start, t])
					span_start = -1.0
			DuelRecord.SHOVE, DuelRecord.STEP_START:
				if span_start >= 0.0:
					spans.append([span_start, t])
					span_start = -1.0
	if span_start >= 0.0:
		spans.append([span_start, finish])

	var lengths: Array[float] = []
	var longest := 0.0
	var total := 0.0
	var removed := 0.0
	for span: Array in spans:
		var overlap := 0.0
		for stagger: Array in staggers:
			overlap += maxf(minf(span[1], stagger[1]) - maxf(span[0], stagger[0]), 0.0)
		var length: float = span[1] - span[0] - overlap
		lengths.append(length)
		longest = maxf(longest, length)
		total += length
		removed += overlap
	return {"lengths": lengths, "longest": longest, "total": total, "stagger": removed}


## 2칸 상대: 실제 상대의 리듬에 자세 11칸, 칼 든 팔 2칸을 직접 적은 것.
## 자세를 이보다 낮게 적지 않는다(한 빈틈에 많아야 2칸이라 첫 6초 안에 무너지지 않는다).
func _two_cell_opp() -> OpponentData:
	var o := _h._copy_opponent()
	o.posture_max = 11
	o.graze_sword_arm = 2
	return o


## 막기만 하고, 빈틈이 생기면 칼 든 팔을 친다. 무너지면 finisher로 끝낸다. extra로 간격의 키를 붙인다.
func _cfg_arm(opp: OpponentData, extra: Dictionary = {}, finisher: Array = AIM_MID_THRUST) -> Callable:
	var arm_aim := [opp.sword_side, DT.Height.MID]
	return func() -> Dictionary:
		var cfg := {
			"guard_fn": func(_a: AttackData, _i: int) -> StringName: return &"hold",
			"counter_fn": func(ev: Dictionary) -> Variant:
				return arm_aim if float(ev["recovery"]) > 0.0 else null,
			"finisher": finisher,
		}
		cfg.merge(extra)
		return cfg


## 머무는 봇: 한 번 밀착으로 들어가 밀려날 때까지 머문다. 밀려난 뒤에는 다시 들어가지 않는다
## (want_distance는 막기를 누르고 있지 않을 때만 전진하고, 이 봇은 막기를 계속 누른다).
func _cfg_stay(opp: OpponentData, delay := 0.0) -> Callable:
	return _cfg_arm(opp, _with_delay({"want_distance": DT.Distance.CLOSE}, delay))


## 들어갔다 나오는 봇.
func _cfg_in_out(opp: OpponentData, delay := 0.0) -> Callable:
	return _cfg_arm(opp, _with_delay({"in_out": {"enter": ENTER_GAUGE, "leave": LEAVE_GAUGE}}, delay))


func _with_delay(extra: Dictionary, delay: float) -> Dictionary:
	if delay > 0.0:
		extra["counter_delay"] = delay
	return extra


## 한 판을 끝까지 돌린 기록.
func _play(opp: OpponentData, cfg_fn: Callable, weapon: WeaponData, seed_value: int,
		conditions: Array[CommissionCondition] = [], has_hat := false) -> DuelCore:
	var never := func(_record: DuelRecord) -> int: return -1
	return _h._run(opp, cfg_fn.call(), never, Core.SIM_DELTA, 10000.0, seed_value, conditions, has_hat, weapon).core


# ================================================================ T47

func t47_bind() -> String:
	var errs: Array[String] = []
	var PS := DT.PlayerState
	var close_cfg := {"guard_fn": _hold_all(), "want_distance": DT.Distance.CLOSE}

	# ---- 엉킴이 없는 무기: 밀착에 30초 있어도 밀려남이 없고 게이지가 0이다
	var plain := _core(_h._make_opp("thrust"), _h._weapon())
	var plain_bot: RefCounted = Bot.new(plain, close_cfg.duplicate())
	_tick_to(plain, plain_bot, 31.0)
	var plain_enter := _last_distance_time(plain.record, DT.Distance.CLOSE)
	_expect(errs, plain.distance == DT.Distance.CLOSE and plain_enter >= 0.0 and plain.time - plain_enter >= 30.0,
		"[엉킴 없음] 밀착에 30초 머물지 못함")
	_expect(errs, plain.record.of_type(DuelRecord.SHOVE).is_empty() and is_zero_approx(plain.bind_gauge()) and not plain.has_bind(),
		"[엉킴 없음] 밀려났거나 게이지가 0이 아님 (%.3f)" % plain.bind_gauge())

	# ---- 찌르기만 하는 상대를 전부 막으며 머문다: 밀착에 들어선 시각 + 6.0초에 밀려나고 + 0.45초에 교전
	#      delta 셋에서 같다(밀착에 들어선 시각 자체는 delta마다 다르므로 그 시각을 기준으로 견준다).
	for delta: float in Core.DELTAS:
		var label := "[머문다 @1/%d]" % roundi(1.0 / delta)
		var stay := _core(_h._make_opp("thrust"), _bind_weapon())
		var stay_bot: RefCounted = Bot.new(stay, close_cfg.duplicate())
		var posture_before := stay.player_posture
		var shoved := _tick_until(stay, stay_bot, func() -> bool: return not stay.record.of_type(DuelRecord.SHOVE).is_empty(), 30.0, delta)
		var entered := _last_distance_time(stay.record, DT.Distance.CLOSE)
		if not shoved or entered < 0.0:
			errs.append("%s 밀려남이 일어나지 않음" % label)
			continue
		var shove: Dictionary = stay.record.of_type(DuelRecord.SHOVE)[0]
		_expect(errs, _near(shove["t"], entered + BIND_TIME), "%s 밀려남의 시작 %.4f (기대 %.4f = 밀착 %.4f + %.1f)" % [
			label, shove["t"], entered + BIND_TIME, entered, BIND_TIME])
		_expect(errs, _near(shove["end_time"], entered + BIND_TIME + SHOVE_TIME) and shove["cancelled_attack"] == false,
			"%s 밀려남 이벤트의 끝 시각이나 사라진 공격 표시가 다름: %s" % [label, str(shove)])
		_expect(errs, stay.player_state == PS.STEPPING and stay.is_shoved() and stay.distance == DT.Distance.CLOSE,
			"%s 밀려나는 중인데 내 상태가 이동이 아니거나 간격이 이미 바뀜" % label)
		_expect(errs, is_equal_approx(stay.bind_gauge(), 1.0), "%s 밀려나는 중의 게이지 %.3f (기대 1)" % [label, stay.bind_gauge()])
		# 밀려나는 동안에도 tick이 나아간다. 도착한 뒤 2초를 더 돌려도 밀려남은 한 번뿐이다.
		_tick_for(stay, stay_bot, SHOVE_TIME + 2.0, delta)
		var arrived := _first_distance(stay.record, DT.Distance.ENGAGE, entered)
		_expect(errs, not arrived.is_empty() and _near(arrived["t"], entered + BIND_TIME + SHOVE_TIME) and arrived["by"] == "bind",
			"%s 교전에 닿은 시각이나 움직인 쪽이 다름: %s" % [label, str(arrived)])
		_expect(errs, stay.time >= entered + BIND_TIME + SHOVE_TIME + 2.0 - delta, "%s 밀려난 뒤 시계가 나아가지 않음 (%.3f)" % [label, stay.time])
		_expect(errs, stay.record.of_type(DuelRecord.SHOVE).size() == 1 and stay.distance == DT.Distance.ENGAGE and not stay.is_shoved(),
			"%s 밀려남이 한 번이 아니거나 교전에 있지 않음" % label)
		_expect(errs, stay.player_posture == posture_before, "%s 밀려남이 내 자세를 깎음" % label)

	# ---- 게이지: 내 입력만으로 본다(상대는 아무것도 하지 않는다)
	var g := _core(_idle_opp(), _bind_weapon())
	_tick_for(g, null, 2.0)
	_expect(errs, is_zero_approx(g.bind_gauge()), "[게이지] 멀리에서 2초 뒤 %.3f (기대 0)" % g.bind_gauge())
	g.step(1)
	_tick_for(g, null, 3.0)
	_expect(errs, g.distance == DT.Distance.ENGAGE and is_zero_approx(g.bind_gauge()), "[게이지] 교전에서 3초 뒤 %.3f (기대 0)" % g.bind_gauge())
	g.step(1)
	_tick_for(g, null, g.weapon.step_time + 0.05)
	var g_enter := _last_distance_time(g.record, DT.Distance.CLOSE)
	_expect(errs, g_enter >= 0.0, "[게이지] 밀착에 들어서지 못함")
	_tick_to(g, null, g_enter + 3.0)
	_expect(errs, _near(g.bind_gauge(), (g.time - g_enter) / BIND_TIME, 1e-6) and _near(g.bind_gauge(), 0.5, 0.01),
		"[게이지] 밀착 3초에 %.4f (기대 0.5)" % g.bind_gauge())
	# 물러난다: 이동 0.30초 동안은 아직 밀착이라 계속 차고, 간격이 교전이 된 시각부터 풀린다.
	g.step(-1)
	_tick_for(g, null, g.weapon.step_time + 0.05)
	var g_leave := _last_distance_time(g.record, DT.Distance.ENGAGE)
	var g_at_leave := (g_leave - g_enter) / BIND_TIME
	_expect(errs, g.distance == DT.Distance.ENGAGE and g.record.of_type(DuelRecord.SHOVE).is_empty(), "[게이지] 스스로 물러났는데 밀려남이 있거나 교전이 아님")
	_tick_to(g, null, g_leave + 1.8)
	_expect(errs, _near(g.bind_gauge(), g_at_leave - (g.time - g_leave) / RELEASE_TIME, 1e-6) and _near(g.bind_gauge(), g_at_leave - 0.2, 0.01),
		"[게이지] 교전으로 나온 지 1.8초에 %.4f (기대 %.4f − 0.2)" % [g.bind_gauge(), g_at_leave])
	_tick_to(g, null, g_leave + g_at_leave * RELEASE_TIME + 1.0)
	_expect(errs, is_zero_approx(g.bind_gauge()), "[게이지] 다 풀린 뒤 %.4f (기대 0)" % g.bind_gauge())

	# 밀려나 교전에 닿은 순간은 1.0, 그 뒤 4.5초에 0.5. 게이지가 0.5일 때 밀착이 되면 3.0초 뒤에 밀려난다.
	var s := _core(_idle_opp(), _bind_weapon())
	var s_enter := _walk_in(s)
	var brain_before := [s.brain.posture, s.brain.state, s.brain.state_end]
	var s_posture := s.player_posture
	_tick_to(s, null, s_enter + BIND_TIME + 0.1)
	_expect(errs, s.is_shoved() and [s.brain.posture, s.brain.state, s.brain.state_end] == brain_before and s.player_posture == s_posture,
		"[밀려남] 밀려남이 내 자세나 상대의 자세·상태·종료 시각을 바꿈")
	_tick_for(s, null, SHOVE_TIME)
	var s_arrive := _last_distance_time(s.record, DT.Distance.ENGAGE)
	_expect(errs, _near(s_arrive, s_enter + BIND_TIME + SHOVE_TIME), "[밀려남] 교전에 닿은 시각 %.4f (기대 %.4f)" % [s_arrive, s_enter + BIND_TIME + SHOVE_TIME])
	_expect(errs, _near(s.bind_gauge(), 1.0 - (s.time - s_arrive) / RELEASE_TIME, 1e-6), "[밀려남] 교전에 닿은 뒤의 게이지가 1에서 풀리지 않음 (%.4f)" % s.bind_gauge())
	_tick_to(s, null, s_arrive + 4.5 - s.weapon.step_time)
	s.step(1)
	_tick_for(s, null, s.weapon.step_time + 0.05)
	var s_reenter := _last_distance_time(s.record, DT.Distance.CLOSE)
	var g_reenter := 1.0 - (s_reenter - s_arrive) / RELEASE_TIME
	_expect(errs, s_reenter > s_arrive and _near(g_reenter, 0.5, 0.01), "[다시 들어가기] 다시 밀착이 된 순간의 게이지 %.4f (기대 0.5)" % g_reenter)
	var again := _tick_until(s, null, func() -> bool: return s.record.of_type(DuelRecord.SHOVE).size() == 2, s_reenter + BIND_TIME)
	if again:
		var second: Dictionary = s.record.of_type(DuelRecord.SHOVE)[1]
		_expect(errs, _near(second["t"], s_reenter + (1.0 - g_reenter) * BIND_TIME) and _near(second["t"], s_reenter + 3.0, 0.06),
			"[다시 들어가기] 둘째 밀려남 %.4f (기대 %.4f, 다시 밀착 + 3.0초쯤)" % [second["t"], s_reenter + (1.0 - g_reenter) * BIND_TIME])
	else:
		errs.append("[다시 들어가기] 게이지가 남은 채 들어갔는데 다시 밀려나지 않음")

	# ---- 상대가 무너져 있는 동안에는 차지 않는다
	var st := _core(_h._make_opp("cut", false, 1), _bind_weapon())
	var st_bot: RefCounted = Bot.new(st, {
		"guard_fn": _hold_all(), "counter_fn": func(_ev: Dictionary) -> Variant: return AIM_MID_THRUST,
		"max_counters": 1, "want_distance": DT.Distance.CLOSE,
	})
	if _tick_until(st, st_bot, func() -> bool: return not st.record.of_type(DuelRecord.STAGGER_START).is_empty(), 20.0):
		var stagger_at: float = st.record.of_type(DuelRecord.STAGGER_START)[0]["t"]
		var st_enter := _last_distance_time(st.record, DT.Distance.CLOSE)
		var held := (stagger_at - st_enter) / BIND_TIME
		_expect(errs, st.distance == DT.Distance.CLOSE and held > 0.0 and _near(st.bind_gauge(), held, 1e-6),
			"[무너짐] 무너진 순간의 게이지 %.4f (기대 %.4f)" % [st.bind_gauge(), held])
		_tick_for(st, st_bot, 1.0)
		_expect(errs, st.brain.state == DT.OpponentState.STAGGER and _near(st.bind_gauge(), held, 1e-6),
			"[무너짐] 무너져 있는 1초 동안 게이지가 변함 (%.4f, 기대 %.4f)" % [st.bind_gauge(), held])
		if _tick_until(st, st_bot, func() -> bool: return not st.record.of_type(DuelRecord.STAGGER_END).is_empty(), 20.0):
			var resumed_at: float = st.record.of_type(DuelRecord.STAGGER_END)[0]["t"]
			_tick_to(st, st_bot, resumed_at + 1.0)
			_expect(errs, _near(st.bind_gauge(), held + (st.time - resumed_at) / BIND_TIME, 1e-6),
				"[무너짐] 무너짐에서 돌아온 뒤 다시 차지 않음 (%.4f)" % st.bind_gauge())
		else:
			errs.append("[무너짐] 무너짐이 끝나지 않음")
	else:
		errs.append("[무너짐] 밀착에서 상대를 무너뜨리지 못함")

	# ---- 밀려나는 동안 들어온 타격은 밀착에서 무방비로 맞은 것이다
	#      진입 시각을 맞추지 않고, 엉킴 없는 판에서 얻은 타격 시각으로 무기의 차는 시간을 계산해 적는다.
	var hit_opp := _h._make_close_hit_opp(2)
	var probe := _core(hit_opp, _h._weapon())
	var probe_bot: RefCounted = Bot.new(probe, close_cfg.duplicate())
	_tick_until(probe, probe_bot, func() -> bool: return probe.record.of_type(DuelRecord.STRIKE).size() >= 3, 30.0)
	var probe_strikes := probe.record.of_type(DuelRecord.STRIKE)
	var probe_enter := _last_distance_time(probe.record, DT.Distance.CLOSE)
	if probe_strikes.size() < 3 or probe_enter < 0.0:
		errs.append("[밀려나며 맞음] 엉킴 없는 판에서 타격 셋을 얻지 못함")
	else:
		var strike_at: float = probe_strikes[2]["t"]
		_expect(errs, probe_strikes[2]["result"] == DT.StrikeResult.BLOCKED, "[밀려나며 맞음] 엉킴 없는 판의 셋째 타격이 막힘이 아님")
		var timed := _core(hit_opp, _bind_weapon(strike_at - 0.2 - probe_enter))
		var timed_bot: RefCounted = Bot.new(timed, close_cfg.duplicate())
		_tick_until(timed, timed_bot, func() -> bool: return timed.record.of_type(DuelRecord.STRIKE).size() >= 3, 30.0)
		var timed_strikes := timed.record.of_type(DuelRecord.STRIKE)
		var timed_shoves := timed.record.of_type(DuelRecord.SHOVE)
		if timed_strikes.size() < 3 or timed_shoves.size() != 1:
			errs.append("[밀려나며 맞음] 타격 %d개, 밀려남 %d번 (기대 3, 1)" % [timed_strikes.size(), timed_shoves.size()])
		else:
			var hit: Dictionary = timed_strikes[2]
			var want_loss := mini(hit_opp.close_hit_posture_loss, timed.rules.player_posture_max)
			_expect(errs, _near(timed_shoves[0]["t"], strike_at - 0.2) and _near(hit["t"], strike_at), "[밀려나며 맞음] 밀려남 %.4f, 타격 %.4f (기대 %.4f, %.4f)" % [
				timed_shoves[0]["t"], hit["t"], strike_at - 0.2, strike_at])
			_expect(errs, hit["result"] == DT.StrikeResult.GRAZE and hit["situation"] == DT.Situation.UNGUARDED and hit["posture_loss"] == want_loss,
				"[밀려나며 맞음] 결과 %d, 상황 %d, 깎인 칸 %d (기대 스침당함, 무방비, %d)" % [hit["result"], hit["situation"], hit["posture_loss"], want_loss])

	# ---- 공격 예비 중에 다 차면 그 공격은 판정 없이 사라진다
	var w := _core(_idle_opp(), _bind_weapon())
	var w_enter := _walk_in(w)
	_tick_to(w, null, w_enter + BIND_TIME - 0.1)
	w.set_aim(DT.Direction.RIGHT, DT.Height.HIGH)
	w.press_attack()
	_expect(errs, w.player_state == PS.WINDUP and w.player_state_end > w_enter + BIND_TIME, "[예비 중] 다 차기 전에 예비가 끝나는 공격을 골랐음")
	_tick_to(w, null, w_enter + BIND_TIME + SHOVE_TIME + 1.0)
	var w_shoves := w.record.of_type(DuelRecord.SHOVE)
	_expect(errs, w_shoves.size() == 1 and w_shoves[0]["cancelled_attack"] == true, "[예비 중] 밀려남 이벤트가 사라진 공격을 말하지 않음: %s" % str(w_shoves))
	_expect(errs, w.record.of_type(DuelRecord.ATTACK_START).size() == 1 and w.record.of_type(DuelRecord.ATTACK).is_empty(),
		"[예비 중] 사라진 공격에 판정 이벤트가 있음")
	_expect(errs, w.player_state == PS.READY and w.distance == DT.Distance.ENGAGE, "[예비 중] 밀려난 뒤 교전의 READY가 아님")

	# 막기 중에 다 차면 막기 재입력 쿨다운이 돈다.
	var gd := _core(_idle_opp(), _bind_weapon())
	var gd_enter := _walk_in(gd)
	gd.set_guard(true)
	_tick_to(gd, null, gd_enter + BIND_TIME + 0.05)
	_expect(errs, gd.is_shoved() and _near(gd.guard_cooldown_end, gd_enter + BIND_TIME + gd.weapon.guard_cooldown),
		"[막기 중] 밀려나며 막기 쿨다운이 돌지 않음 (%.4f)" % gd.guard_cooldown_end)
	_tick_for(gd, null, SHOVE_TIME + 0.1)
	_expect(errs, gd.player_state == PS.GUARD and not gd.guard_fresh, "[막기 중] 밀려난 뒤 누르고 있는데 (새로 누름이 아닌) 막기로 돌아오지 않음")

	# ---- 물러나는 이동 중에 다 차면 밀려남이 없고 이동이 제 시각에 끝난다. 그 뒤로도 tick이 나아간다
	var r := _core(_idle_opp(), _bind_weapon())
	var r_enter := _walk_in(r)
	_tick_to(r, null, r_enter + BIND_TIME - 0.15)
	r.step(-1)
	var r_step: Dictionary = r.record.of_type(DuelRecord.STEP_START).back()
	_expect(errs, float(r_step["t"]) < r_enter + BIND_TIME and float(r_step["end_time"]) > r_enter + BIND_TIME, "[물러나는 중] 이동이 다 차는 시각을 걸치지 않음")
	_tick_to(r, null, float(r_step["end_time"]) + 2.0)
	var r_leave := _first_distance(r.record, DT.Distance.ENGAGE, r_enter)
	_expect(errs, r.record.of_type(DuelRecord.SHOVE).is_empty(), "[물러나는 중] 스스로 물러나는 중인데 밀려남")
	_expect(errs, not r_leave.is_empty() and _near(r_leave["t"], r_step["end_time"]) and r_leave["by"] == "player",
		"[물러나는 중] 이동이 제 시각에 끝나지 않음: %s" % str(r_leave))
	_expect(errs, r.time >= float(r_step["end_time"]) + 2.0 - Core.BASE_DELTA, "[물러나는 중] 다 찬 뒤 시계가 나아가지 않음 (%.3f)" % r.time)
	_expect(errs, _near(r.bind_gauge(), 1.0 - (r.time - float(r_step["end_time"])) / RELEASE_TIME, 1e-6),
		"[물러나는 중] 이동이 끝난 시각에 1이고 그 뒤로 풀리지 않음 (%.4f)" % r.bind_gauge())

	# ---- 시간으로 제한된다 (시드 1..SIM_SEEDS, 2칸 상대). 통과 조건은 비율이 아니라 구조다:
	#      밀착에서 싸울 수 있던 구간의 길이(물러나는 이동과 무너짐을 뺀 것)가 차는 시간 이하다.
	var opp := _two_cell_opp()
	var stay_cfg := _cfg_stay(opp)
	var in_out_cfg := _cfg_in_out(opp)
	var limit := BIND_TIME + TIME_EPS
	var free_longer := 0
	for seed_value in range(1, Core.SIM_SEEDS + 1):
		var bound := _close_spans(_play(opp, stay_cfg, _bind_weapon(), seed_value).record)
		if bound["longest"] > limit:
			errs.append("[시간 제한] 머무는 봇, 시드 %d: 가장 긴 구간 %.3f초 (차는 시간 %.1f초 이하여야 함)" % [seed_value, bound["longest"], BIND_TIME])
		var free := _close_spans(_play(opp, stay_cfg, _h._weapon(), seed_value).record)
		if free["longest"] > BIND_TIME:
			free_longer += 1
		var moving := _close_spans(_play(opp, in_out_cfg, _bind_weapon(), seed_value).record)
		if moving["longest"] > limit:
			errs.append("[시간 제한] 들어갔다 나오는 봇, 시드 %d: 가장 긴 구간 %.3f초 (차는 시간 %.1f초 이하여야 함)" % [seed_value, moving["longest"], BIND_TIME])
		if (moving["lengths"] as Array).is_empty():
			errs.append("[시간 제한] 들어갔다 나오는 봇, 시드 %d: 밀착에 한 번도 들어가지 않음" % seed_value)
	_expect(errs, free_longer >= 1, "[시간 제한] 엉킴 없는 무기에서 머무는 봇의 가장 긴 구간이 %.1f초를 넘는 판이 없음" % BIND_TIME)

	# ---- 로드한 무기: 범위만 통과 조건이다
	var loaded := load(WEAPON_PATH) as WeaponData
	_expect(errs, loaded.close_bind_time >= 0.0 and loaded.close_bind_release_time >= 0.0 and loaded.close_shove_time >= 0.0,
		"로드한 무기의 엉킴 값에 음수가 있음")
	print("  INFO 로드한 %s의 엉킴: 차는 시간 %.2f초, 풀리는 시간 %.2f초, 밀려나는 시간 %.2f초 / 엉킴 없는 무기에서 머무는 봇의 가장 긴 구간이 %.1f초를 넘는 판 %d/%d" % [
		loaded.weapon_name, loaded.close_bind_time, loaded.close_bind_release_time, loaded.close_shove_time,
		BIND_TIME, free_longer, Core.SIM_SEEDS])
	return _result(errs)


# ================================================================ T48

## 봇 하나를 시드 1..SIM_SEEDS로 돌린 통계. 길이, 밀착에서 싸울 수 있던 시간의 비율, 밀려남과 피격.
func _measure(opp: OpponentData, cfg_fn: Callable, weapon: WeaponData,
		conditions: Array[CommissionCondition] = [], has_hat := false) -> Dictionary:
	var out := {
		"mean": 0.0, "ratio": 0.0, "stagger": 0.0, "shoves": 0.0, "hits_shoved": 0.0, "hits_other": 0.0,
		"wins": 0, "losses": 0, "timeouts": 0, "by_condition": 0, "score": 0.0,
	}
	var n := float(Core.SIM_SEEDS)
	for seed_value in range(1, Core.SIM_SEEDS + 1):
		var core := _play(opp, cfg_fn, weapon, seed_value, conditions, has_hat)
		var record := core.record
		var spans := _close_spans(record)
		out["mean"] += record.elapsed / n
		out["ratio"] += (float(spans["total"]) / record.elapsed if record.elapsed > 0.0 else 0.0) / n
		out["stagger"] += float(spans["stagger"]) / n
		var shoves := record.of_type(DuelRecord.SHOVE)
		out["shoves"] += shoves.size() / n
		for strike in record.of_type(DuelRecord.STRIKE):
			if strike["result"] != DT.StrikeResult.GRAZE and strike["result"] != DT.StrikeResult.HIT:
				continue
			var during_shove := false
			for shove in shoves:
				if float(strike["t"]) >= float(shove["t"]) and float(strike["t"]) <= float(shove["end_time"]):
					during_shove = true
			out["hits_shoved" if during_shove else "hits_other"] += 1.0 / n
		match core.end_reason:
			DT.EndReason.TIME_UP:
				out["timeouts"] += 1
			DT.EndReason.OPPONENT_HIT:
				out["wins"] += 1
			DT.EndReason.CONDITION:
				out["wins"] += 1
				out["by_condition"] += 1
			DT.EndReason.PLAYER_DEFEATED:
				out["losses"] += 1
		for condition in conditions:
			out["score"] += condition.evaluate(record) / n
	return out


func _measure_line(label: String, st: Dictionary) -> String:
	return "  INFO %s: 평균 %.1f초, 밀착에서 싸울 수 있던 시간 %.0f%% (뺀 무너짐 %.1f초/판), 밀려남 %.1f회/판, 밀려나는 동안 맞음 %.2f회/판, 그 밖에 맞음 %.2f회/판, 승 %d / 패 %d / 시간 초과 %d" % [
		label, st["mean"], st["ratio"] * 100.0, st["stagger"], st["shoves"], st["hits_shoved"], st["hits_other"],
		st["wins"], st["losses"], st["timeouts"]]


func t48_lengths_and_display() -> String:
	var errs: Array[String] = []
	var real := load(OPPONENT_PATH) as OpponentData
	var loaded_weapon := load(WEAPON_PATH) as WeaponData

	# ---- INFO (통과 조건 아님): 로드한 무기와 로드한 상대의 사본. 팔을 노리는 봇 넷을 0.20초 늦는 손으로.
	var copy := real.duplicate() as OpponentData
	print("  INFO 엉킴의 판 길이: 시드 1..%d, 모자 없는 자유 결투, 팔을 노리는 봇 · %.2f초 늦게 누름 · 들어가는 게이지 %.1f 이하 / 나오는 게이지 %.1f 이상" % [
		Core.SIM_SEEDS, LATE_HAND, ENTER_GAUGE, LEAVE_GAUGE])
	print("  INFO 로드한 무기의 엉킴 %.2f / %.2f / %.2f초, 상대 자세 %d, 칼 든 팔 %d칸, 패리 덧붙임 %.2f초" % [
		loaded_weapon.close_bind_time, loaded_weapon.close_bind_release_time, loaded_weapon.close_shove_time,
		copy.posture_max, copy.graze_sword_arm, copy.parried_recovery_bonus])
	print(_measure_line("교전에서만 싸우는 봇", _measure(copy, _cfg_arm(copy, _with_delay({}, LATE_HAND)), loaded_weapon)))
	print(_measure_line("머무는 봇 (한 번 들어가 밀려날 때까지)", _measure(copy, _cfg_stay(copy, LATE_HAND), loaded_weapon)))
	print(_measure_line("들어갔다 나오는 봇", _measure(copy, _cfg_in_out(copy, LATE_HAND), loaded_weapon)))
	print(_measure_line("들어갔다 나오되 엉킴이 없는 무기", _measure(copy, _cfg_in_out(copy, LATE_HAND), _h._weapon())))
	print(_measure_line("(참고) 늦지 않는 손 · 들어갔다 나오는 봇", _measure(copy, _cfg_in_out(copy), loaded_weapon)))

	# ---- 깃털(유효타만 본다, 모자를 쓴 판): 막기만, 빈틈에 칼 든 팔, 무너지면 반대쪽 상단 베기(모자)
	#      통과 조건은 조건·상대·무기를 전부 테스트가 만든다.
	var hit_only := TargetPartCondition.new()
	hit_only.target_part = DT.Part.HAT
	hit_only.graze_penalty = 0
	var feather_conditions: Array[CommissionCondition] = [hit_only]
	var feather_opp := _h._copy_opponent()
	feather_opp.posture_max = real.posture_max
	feather_opp.graze_sword_arm = 2
	var off_side: int = DT.Direction.RIGHT if feather_opp.sword_side == DT.Direction.LEFT else DT.Direction.LEFT
	var hat_aim := [off_side, DT.Height.HIGH]
	var feather := _measure(feather_opp, _cfg_arm(feather_opp, {}, hat_aim), _h._weapon(), feather_conditions, true)
	_expect(errs, feather["by_condition"] == Core.SIM_SEEDS and is_equal_approx(feather["score"], 100.0),
		"[깃털·유효타만] 조건으로 끝난 판 %d/%d, 평균 %.1f점 (기대 전부, 100점)" % [feather["by_condition"], Core.SIM_SEEDS, feather["score"]])
	var loaded_feather := load(FEATHER_PATH) as Commission
	var loaded_run := _measure(copy, _cfg_arm(copy, {}, hat_aim), loaded_weapon, loaded_feather.conditions, loaded_feather.opponent_wears_hat)
	print("  INFO 깃털 의뢰(로드한 조건·상대·무기) · 교전에서 막기만, 빈틈에 칼 든 팔, 무너지면 모자: 평균 %.1f초, 평균 %.1f점, 조건으로 끝난 판 %d/%d" % [
		loaded_run["mean"], loaded_run["score"], loaded_run["by_condition"], Core.SIM_SEEDS])

	_scene_display(errs, loaded_weapon)
	return _result(errs)


## 결투 씬을 붙인다(마우스 조준 끔, 시드 1, 의뢰 없음).
func _spawn_duel() -> Node:
	var duel: Node = (load(DUEL_PATH) as PackedScene).instantiate()
	duel.set("mouse_aim_enabled", false)
	duel.set("rng_seed", 1)
	_tree.root.add_child(duel)
	return duel


## cond가 참이 될 때까지 씬을 프레임 단위로 흘린다.
func _advance_until(duel: Node, bot: RefCounted, cond: Callable, max_frames := 3600) -> bool:
	var core: DuelCore = duel.get("core")
	var frames := 0
	while not cond.call():
		if core.ended or frames >= max_frames:
			return false
		duel.call("advance", 1.0 / 60.0)
		if bot != null:
			bot.call("update")
		frames += 1
	return true


## 내 칼의 색. 헤드리스의 advance는 표시를 delta 0으로 갱신해 번쩍임 시계가 멈춰 있다.
## 그래서 보기 직전에 표시를 delta 1.0으로 한 번 직접 갱신해 번쩍임을 넘긴다.
func _sword_color(duel: Node) -> Color:
	var core: DuelCore = duel.get("core")
	var view := duel.get_node("PlayerSwordView") as PlayerSwordView
	view.update_view(core, core.time, (duel as Node2D).get_viewport_rect().size, 1.0)
	return (view.get_node("Sword") as Polygon2D).color


## 씬의 표시 경로: 게이지, 80% 이상의 경고(게이지의 색, 가운데 글자, 내 칼의 경고 표시), 밀려남의 글자.
## 기대값은 로드한 무기에서 끌어온다(엉킴을 끈 데이터에서도 통과해야 한다).
func _scene_display(errs: Array[String], weapon: WeaponData) -> void:
	var duel := _spawn_duel()
	var core: DuelCore = duel.get("core")
	var hud := duel.get_node("HUD")
	hud.call("toggle_debug")
	var bar := hud.get("_bind_bar") as Control
	var center := hud.get("_bind_warning") as Label
	var sword_warning := duel.get_node("PlayerSwordView/Sword/BindWarning") as CanvasItem
	var aim_label := hud.get("_aim_label") as Label
	var log_label := hud.get("_log_label") as Label
	var keep := func(_a: AttackData, _i: int) -> StringName: return &"keep"
	var cfg := {"guard_fn": keep, "want_distance": DT.Distance.CLOSE}

	var bot: RefCounted = Bot.new(core, cfg.duplicate())
	if not _advance_until(duel, bot, func() -> bool: return core.distance == DT.Distance.CLOSE, 600):
		errs.append("[씬] 밀착에 들어서지 못함")
		duel.free()
		return
	duel.call("advance", 1.0 / 60.0)
	bot.call("update")

	if weapon.close_bind_time <= 0.0:
		# 엉킴이 없는 무기 데이터: 게이지가 보이지 않는 것만 본다.
		_expect(errs, not bar.visible and not center.visible and not sword_warning.visible, "[씬] 엉킴이 없는 무기인데 게이지나 경고가 보임")
		_expect(errs, not (hud.get("_help_label") as Label).text.contains("엉킴"), "[씬] 엉킴이 없는 무기인데 조작 안내에 엉킴이 있음")
		duel.free()
		return

	_expect(errs, (hud.get("_help_label") as Label).text.contains("엉킴이 차면 밀려난다"), "[씬] 조작 안내에 엉킴 안내가 없음")
	_expect(errs, bar.visible and is_equal_approx(float(bar.get("ratio")), core.bind_gauge()) and core.bind_gauge() > 0.0,
		"[씬] 밀착에 들어선 뒤 게이지가 보이지 않거나 값이 코어와 다름 (%.3f, 코어 %.3f)" % [float(bar.get("ratio")), core.bind_gauge()])
	_expect(errs, not bar.get("warn") and not center.visible and not sword_warning.visible, "[씬] 80%% 미만인데 경고가 보임")

	# 80% 이상: 게이지의 색, 가운데 글자, 내 칼의 경고 표시. 칼의 색은 막기의 상태 색 그대로다.
	var warn_ratio: float = DuelHud.BIND_WARN_RATIO
	if _advance_until(duel, bot, func() -> bool: return core.bind_gauge() >= warn_ratio + 0.02):
		_expect(errs, core.distance == DT.Distance.CLOSE and not core.is_shoved(), "[씬] 80%% 이상이 됐을 때 이미 밀려나는 중임")
		_expect(errs, bar.get("warn") == true and center.visible and center.text == DuelHud.BIND_WARN_TEXT and sword_warning.visible,
			"[씬] 80%% 이상인데 경고(게이지의 색 %s, 가운데 글자 %s, 내 칼의 경고 %s)가 다 켜지지 않음" % [
				str(bar.get("warn")), str(center.visible), str(sword_warning.visible)])
		var guard_color := _sword_color(duel)
		_expect(errs, core.player_state == DT.PlayerState.GUARD \
			and (guard_color == PlayerSwordView.COLOR_GUARD or guard_color == PlayerSwordView.COLOR_GUARD_FRESH),
			"[씬] 경고가 켜진 동안 내 칼의 색이 막기의 상태 색이 아님 (내 상태 %d, 색 %s)" % [core.player_state, str(guard_color)])
		_expect(errs, sword_warning.visible, "[씬] 표시를 다시 갱신하니 내 칼의 경고가 꺼짐")
	else:
		errs.append("[씬] 밀착에 머물렀는데 게이지가 80%를 넘지 않음")

	# 밀려남: 기록 줄과 "밀려남" 글자
	if _advance_until(duel, bot, func() -> bool: return not core.record.of_type(DuelRecord.SHOVE).is_empty()):
		_expect(errs, core.is_shoved() and aim_label.text.contains("밀려남"), "[씬] 밀려나는 중인데 내 상태 글자가 '밀려남'이 아님: %s" % aim_label.text)
		_expect(errs, log_label.text.contains("칼이 엉켜 밀려났다"), "[씬] 밀려남의 기록 줄이 없음: %s" % log_label.text)
		_advance_until(duel, bot, func() -> bool: return core.distance == DT.Distance.ENGAGE, 120)
		duel.call("advance", 1.0 / 60.0)
		_expect(errs, core.distance == DT.Distance.ENGAGE and not center.visible and not sword_warning.visible and not bar.get("warn"),
			"[씬] 교전으로 밀려난 뒤에도 경고가 남아 있음")
		_expect(errs, not aim_label.text.contains("밀려남"), "[씬] 밀려남이 끝났는데 내 상태 글자가 남아 있음")
	else:
		errs.append("[씬] 밀착에 머물렀는데 밀려나지 않음")

	# 예비 중에 밀려남: 다 차기 직전에 공격을 눌러, 예비 중이던 공격이 사라지게 한다.
	duel.call("start_duel")
	core = duel.get("core")
	bot = Bot.new(core, cfg.duplicate())
	var off_side: int = DT.Direction.RIGHT if core.opponent_data.sword_side == DT.Direction.LEFT else DT.Direction.LEFT
	var windup := weapon.windup_for(off_side, DT.Height.HIGH, DT.Distance.CLOSE)
	var press_when := func() -> bool:
		return core.distance == DT.Distance.CLOSE and core.player_state == DT.PlayerState.GUARD \
			and (1.0 - core.bind_gauge()) * weapon.close_bind_time < windup * 0.5
	if _advance_until(duel, bot, press_when):
		core.set_aim(off_side, DT.Height.HIGH)
		core.press_attack()
		if _advance_until(duel, bot, func() -> bool: return not core.record.of_type(DuelRecord.SHOVE).is_empty(), 120):
			var shove: Dictionary = core.record.of_type(DuelRecord.SHOVE)[0]
			_expect(errs, shove["cancelled_attack"] == true, "[씬] 예비 중에 밀려났는데 사라진 공격 표시가 없음")
			var color := _sword_color(duel)
			_expect(errs, core.player_state == DT.PlayerState.STEPPING and color == PlayerSwordView.COLOR_STEPPING,
				"[씬] 예비 중에 밀려난 뒤 내 상태 %d, 칼의 색 %s (기대 이동, 이동의 색)" % [core.player_state, str(color)])
		else:
			errs.append("[씬] 다 차기 직전에 공격을 눌렀는데 밀려나지 않음")
	else:
		errs.append("[씬] 다 차기 직전의 막기 상태를 만나지 못함")

	# 막지 않고 밀착에서 한 번 맞는다: "(밀착)" 기록 줄의 경로
	duel.call("start_duel")
	core = duel.get("core")
	var none := func(_a: AttackData, _i: int) -> StringName: return &"none"
	bot = Bot.new(core, {"guard_fn": none, "want_distance": DT.Distance.CLOSE})
	var got_hit := func() -> bool:
		return core.record.count_where(DuelRecord.STRIKE, "result", DT.StrikeResult.GRAZE) > 0
	if _advance_until(duel, bot, got_hit, 1200):
		var loss: int = core.record.of_type(DuelRecord.STRIKE).back()["posture_loss"]
		_expect(errs, log_label.text.contains("(밀착)") == (loss >= 2), "[씬] 밀착에서 %d칸 깎였는데 기록 줄이 다름: %s" % [loss, log_label.text])
	else:
		errs.append("[씬] 막지 않았는데 밀착에서 맞지 않음")
	hud.call("toggle_debug")
	duel.free()
