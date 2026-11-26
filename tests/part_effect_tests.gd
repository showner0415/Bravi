extends RefCounted
## T104~T109: 부위별 반격의 손맛(계획 R02) — 데이터와 판정 한 곳.
## T104: part_effects가 빈(또는 모든 값이 꺼진) 상대는 옛 규칙과 이벤트 줄이 한 치도 다르지 않다.
## T105: 조준 미리보기(attack_forecast)는 판정과 같은 함수다. 누르는 시각을 1/60초씩 훑어 미리보기와 실제 판정을 견준다.
## 훑기는 판마다 새 코어를 만들어 같은 입력을 되풀이하고 누르는 순간만 바꾼다(코어는 복제할 수 없다).
## 결투는 core_tests.gd의 도우미로 돌린다. 뒤 작업(T106~T111)이 이 파일에 테스트를 더한다.

const Core := preload("res://tests/core_tests.gd")
const Bot := preload("res://tests/duel_bots.gd")
const DT := preload("res://scripts/duel/duel_types.gd")

const EFFECTS_PATH := "res://data/part_effects.tres"
const OPPONENT_PATHS: Array[String] = [
	"res://data/opponents/opponent_01.tres",
	"res://data/opponents/opponent_02.tres",
	"res://data/opponents/opponent_03.tres",
]
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const DUEL_PATH := "res://scenes/duel/duel.tscn"
const RULES_PATH := "res://data/duel_rules.tres"

const DELTA := 1.0 / 60.0
## 입력 사이를 한 번에 건너뛸 때 사건 시각을 확실히 지나기 위한 여유(초).
const EPS := 1e-6
const RUN_SECONDS := 30.0
const SIM_SEEDS: Array[int] = [1, 2]
## 훑기의 도움: 한 훑기에서 이 수 이상은 나와야 가짜 통과가 아니다(판정 갈래마다 한 번 이상 보였는가).
const MIN_SEEN := 3

const AIM_CENTER_MID := [DT.Direction.CENTER, DT.Height.MID]

var _tree: SceneTree
var _h := Core.new()
## 훑기 전체에서 갈래마다 몇 번 나왔는지(판정 이름 → 수).
var _seen: Dictionary = {}
var _trials := 0


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T104", "name": "부위별 반격 옛 규칙 불변: 같은 씨앗·입력의 이벤트 줄, 몸통의 예비", "fn": t104_old_rule_unchanged},
		{"id": "T105", "name": "조준 미리보기 = 판정: 누르는 시각을 훑어 어긋남 0, UNSURE의 까닭", "fn": t105_forecast_matches_verdict},
		{"id": "T106", "name": "조준 표시: 막은 뒤 몸통 닿는다 -> 팔 늦다, 멀다, 피한다, 옛 규칙은 그대로", "fn": t106_aim_display},
		{"id": "T107", "name": "팔: 스친 뒤 예비 동작 셋이 길어진다, 고리와 타격의 시각, 다른 부위는 걸지 않음, 난수 차례", "fn": t107_arm_slow},
		{"id": "T108", "name": "다리: 다음 패리의 덤 세 갈래, 사슬, 글, 날별 표", "fn": t108_legs_bonus},
		{"id": "T109", "name": "머리: 큰 공격 뒤에만 열림, 무너짐, 모자, 효과 글의 횟수", "fn": t109_head_open},
		{"id": "T110", "name": "의뢰 채점 불변: 첫 피·깃털·다리만·티 안 나게 지기가 효과 칸에 흔들리지 않는다", "fn": t110_commission_scoring},
		{"id": "T111", "name": "연습 화면: 반격 실험의 켬·끔이 버튼의 상대에 실리고 남는다, 베기만, 의뢰 카드는 옛 규칙", "fn": t111_practice_screen},
	]


func cleanup() -> void:
	_h.cleanup()
	_h = null
	_tree = null
	_seen.clear()


# ================================================================ 도우미

func _result(errs: Array[String]) -> String:
	return "OK" if errs.is_empty() else " / ".join(errs.slice(0, 8))


func _rules() -> DuelRules:
	return load(RULES_PATH) as DuelRules


func _zero_effects() -> PartEffectData:
	var fx := PartEffectData.new()
	fx.show_forecast = false
	fx.arm_slow_tells = 0
	fx.arm_tell_multiplier = 0.0
	fx.legs_parry_charges = 0
	fx.legs_parry_opening_bonus = 0.0
	fx.legs_open_time_bonus = 0.0
	fx.arm_windup_extra = 0.0
	fx.legs_windup_extra = 0.0
	fx.head_windup_extra = 0.0
	fx.hand_windup_extra = 0.0
	fx.head_big_only = false
	fx.head_exposed_time = 0.0
	return fx


## 기록의 한 줄을 글로 바꾼다. 자원은 이름으로 줄여 사본이 달라도 견줄 수 있게 한다.
func _line(ev: Dictionary) -> String:
	var parts: PackedStringArray = []
	for key in ev:
		var value: Variant = ev[key]
		if value is AttackData:
			value = "A(%s,%s,%s)" % [value.attack_name, value.direction, value.tell_time]
		parts.append("%s=%s" % [key, str(value)])
	return ",".join(parts)


func _bot_configs() -> Array[Dictionary]:
	var low := [DT.Direction.CENTER, DT.Height.LOW]
	var arm := [DT.Direction.LEFT, DT.Height.MID]
	var head := [DT.Direction.CENTER, DT.Height.HIGH]
	var parry_every_other := func(_atk: AttackData, index: int) -> StringName:
		return &"parry" if index % 2 == 0 else &"hold"
	var low_counter := func(ev: Dictionary) -> Variant:
		return low if float(ev["recovery"]) > 0.0 else null
	var arm_counter := func(ev: Dictionary) -> Variant:
		return arm if float(ev["recovery"]) > 0.0 else null
	return [
		Bot.first_blood_cfg(),
		{"guard_fn": parry_every_other, "counter_fn": low_counter, "finisher": head},
		{"guard_fn": parry_every_other, "counter_fn": arm_counter, "finisher": AIM_CENTER_MID},
		{"lunge": {"height": DT.Height.MID}},
	]


func _run_lines(opponent: OpponentData, cfg: Dictionary, seed_value: int) -> PackedStringArray:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var core := DuelCore.new()
	core.setup(_rules(), load(WEAPON_PATH) as WeaponData, opponent, rng, [], false)
	var bot := Bot.new(core, cfg)
	while not core.ended and core.time < RUN_SECONDS:
		core.tick(DELTA)
		bot.update()
	var lines: PackedStringArray = []
	for ev in core.record.events:
		lines.append(_line(ev))
	return lines


# ================================================================ T104

func t104_old_rule_unchanged() -> String:
	var errs: Array[String] = []
	var zero := _zero_effects()
	var configs := _bot_configs()
	var runs := 0
	for path in OPPONENT_PATHS:
		var plain := load(path) as OpponentData
		var carried := plain.with_part_effects(zero)
		if plain.part_effects != null:
			errs.append("%s: 하루의 상대에 part_effects가 적혀 있다" % path)
		for ci in configs.size():
			for seed_value in SIM_SEEDS:
				var a := _run_lines(plain, configs[ci], seed_value)
				var b := _run_lines(carried, configs[ci], seed_value)
				runs += 1
				if a.size() != b.size():
					errs.append("%s 봇%d 씨앗%d: 이벤트 수 %d != %d" % [path.get_file(), ci, seed_value, a.size(), b.size()])
					continue
				for i in a.size():
					if a[i] != b[i]:
						errs.append("%s 봇%d 씨앗%d: %d번째 줄이 다르다 %s | %s" % [path.get_file(), ci, seed_value, i, a[i], b[i]])
						break
				if a.size() < 8:
					errs.append("%s 봇%d 씨앗%d: 이벤트가 %d줄뿐이라 견줄 것이 없다" % [path.get_file(), ci, seed_value, a.size()])
	# 몸통을 노린 예비는 새 규칙을 켜도 같다. 다리는 +legs_windup_extra, 바닥 0.05초.
	var fx := load(EFFECTS_PATH) as PartEffectData
	if fx == null:
		errs.append("data/part_effects.tres를 읽지 못했다")
		return _result(errs)
	var base := load(OPPONENT_PATHS[0]) as OpponentData
	var old_core := _h._make_core(base, 1, [], false)
	var new_core := _h._make_core(base.with_part_effects(fx), 1, [], false)
	var floor_fx := fx.duplicate() as PartEffectData
	floor_fx.arm_windup_extra = -1.0
	var floor_core := _h._make_core(base.with_part_effects(floor_fx), 1, [], false)
	for dist in [DT.Distance.FAR, DT.Distance.ENGAGE, DT.Distance.CLOSE]:
		old_core.distance = dist
		new_core.distance = dist
		floor_core.distance = dist
		for direction in [DT.Direction.LEFT, DT.Direction.CENTER, DT.Direction.RIGHT]:
			for height in [DT.Height.HIGH, DT.Height.MID, DT.Height.LOW]:
				var part := DuelCore.aim_part(direction, height, base.sword_side, false)
				var old_windup := old_core.attack_windup(direction, height)
				var new_windup := new_core.attack_windup(direction, height)
				var where := "간격%d 방향%d 높이%d" % [dist, direction, height]
				if old_windup != old_core.weapon.windup_for(direction, height, dist):
					errs.append("%s: 빈 상대의 예비가 무기 값과 다르다" % where)
				match part:
					DT.Part.TORSO:
						if new_windup != old_windup:
							errs.append("%s: 몸통의 예비가 새 규칙에서 달라졌다 %f != %f" % [where, old_windup, new_windup])
					DT.Part.LEGS:
						if absf(new_windup - (old_windup + fx.legs_windup_extra)) > 1e-9:
							errs.append("%s: 다리의 예비가 +%f가 아니다 %f -> %f" % [where, fx.legs_windup_extra, old_windup, new_windup])
					DT.Part.SWORD_ARM:
						var floored := floor_core.attack_windup(direction, height)
						if absf(floored - PartEffectData.MIN_WINDUP) > 1e-9:
							errs.append("%s: 팔의 예비가 바닥 0.05초로 잘리지 않았다 %f" % [where, floored])
	if runs != OPPONENT_PATHS.size() * configs.size() * SIM_SEEDS.size():
		errs.append("견준 판의 수가 맞지 않는다 %d" % runs)
	return _result(errs)


# ================================================================ T105

## 훑기의 한 갈래. opp는 사본, mode는 누르기 전까지의 내 입력이다.
##   none: 아무것도 안 함 / block: 예비 동작이 시작되면 막고 타격 직후 뗌 / parry: 타격 0.08초 전에 새로 누르고 타격 직후 뗌
##   whiff: 예비 동작이 시작되면 한 걸음 물러남
## opener는 타격 0.05초 뒤 중단 찌르기로 스쳐 무너뜨린다(상대 자세 1일 때). poke는 무너짐 시작 직후 엉킴 게이지를 0.99로 놓는다.
## from·to는 앵커(strike면 타격 시각, start면 0)에서 누르는 시각의 범위(초)다.
func _scene(label: String, opp: OpponentData, weapon: WeaponData, start: int, mode: StringName, anchor: StringName,
		from: float, to: float, opener := false, poke := false) -> Dictionary:
	return {
		"label": label, "opp": opp, "weapon": weapon, "start": start, "mode": mode, "anchor": anchor,
		"from": from, "to": to, "opener": opener, "poke": poke,
	}


func _cut_opp(guards: bool, big := false, posture := -1) -> OpponentData:
	var o: OpponentData = _h._make_opp("cut", false, posture)
	o.guards_head = guards
	o.graze_head = 2
	if big:
		var atk := o.attacks[0].duplicate() as AttackData
		atk.is_big = true
		atk.recovery_time = 1.6
		var only: Array[AttackData] = [atk]
		o.attacks = only
	return o


func _idle_opp(complacent: float, approach: float, idle := 1000.0) -> OpponentData:
	var o: OpponentData = _h._make_opp("thrust")
	o.guards_head = true
	o.idle_time_min = idle
	o.idle_time_max = idle
	o.approach_delay = approach
	o.complacent_time = complacent
	o.complacent_limit = 0
	return o


func _lunge_weapon(bind := 0.0) -> WeaponData:
	var w: WeaponData = _h._weapon(bind, 3.0, 0.45)
	w.lunge_windup = 0.5
	w.lunge_recover = 0.45
	return w


func _dive_opp() -> OpponentData:
	var base := (load(OPPONENT_PATHS[2]) as OpponentData).flat().with_opening(1.0)
	for atk in base.attacks:
		if atk.dive:
			var o := base.drill(atk)
			o.idle_time_min = 1.0
			o.idle_time_max = 1.0
			return o
	return null


func _scenes() -> Array[Dictionary]:
	var plain: WeaponData = _h._weapon()
	var bind: WeaponData = _h._weapon(2.5, 3.0, 0.45)
	var bind_slow: WeaponData = _h._weapon(4.0, 3.0, 0.45)
	var far := DT.Distance.FAR
	var engage := DT.Distance.ENGAGE
	var close := DT.Distance.CLOSE
	var lunge_idle := _idle_opp(0.3, 1000.0)
	var lunge_far := _idle_opp(0.3, 1.5, 1.0)
	var lunge_whiff := _cut_opp(true, true)
	lunge_whiff.complacent_time = 0.2
	lunge_whiff.complacent_limit = 0
	var scenes: Array[Dictionary] = [
		_scene("막은 뒤(교전)", _cut_opp(true), plain, engage, &"block", &"strike", -0.45, 0.95),
		_scene("패리 뒤(교전)", _cut_opp(true), plain, engage, &"parry", &"strike", -0.45, 1.75),
		_scene("큰 공격 막은 뒤(교전)", _cut_opp(true, true), plain, engage, &"block", &"strike", -0.30, 1.95),
		_scene("헛침 뒤(교전)", _cut_opp(true), plain, engage, &"whiff", &"strike", -0.50, 0.85),
		_scene("무너짐 앞뒤(교전)", _cut_opp(true, false, 1), plain, engage, &"block", &"strike", 0.0, 2.2, true),
		_scene("막은 뒤(밀착, 엉킴)", _cut_opp(true), bind, close, &"block", &"strike", -0.45, 1.0),
		_scene("패리 뒤(밀착)", _cut_opp(true), plain, close, &"parry", &"strike", -0.45, 1.75),
		_scene("무너짐이 예비 안에서 끝남(밀착, 게이지 0.99)", _cut_opp(true, false, 1), bind_slow, close, &"block", &"strike", 0.20, 2.35, true, true),
		_scene("대기(교전)", _cut_opp(true), plain, engage, &"none", &"start", 0.0, 1.35),
		_scene("멀리 대기와 접근", _cut_opp(true), plain, far, &"none", &"start", 0.55, 1.95),
		_scene("뛰어드는 찌르기 물러섬", _dive_opp(), plain, engage, &"whiff", &"strike", -0.60, 1.30),
		_scene("뛰어드는 찌르기 막음", _dive_opp(), plain, engage, &"block", &"strike", -0.30, 1.85),
		_scene("런지 대기", lunge_idle, _lunge_weapon(), far, &"none", &"start", 0.0, 1.0),
		_scene("런지와 접근", lunge_far, _lunge_weapon(), far, &"none", &"start", 0.55, 2.05),
		_scene("런지와 헛침의 회수", lunge_whiff, _lunge_weapon(), engage, &"whiff", &"strike", -0.45, 0.85),
	]
	return scenes


func _new_core(scene: Dictionary) -> DuelCore:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var core := DuelCore.new()
	core.setup(_rules(), scene["weapon"], scene["opp"], rng, [], false)
	var start: int = scene["start"]
	if start != DT.Distance.FAR:
		core.distance = start
		core._refresh_approach(0.0)
		core._refresh_bind()
	return core


func _advance(core: DuelCore, to_time: float) -> void:
	if not core.ended and to_time > core.time:
		core.tick(to_time - core.time)


## 누르기 전까지의 입력(시각순). 타격 시각 S와 예비 동작 시작 Ts는 한 번 돌려 읽는다.
func _script(scene: Dictionary, tell_start: float, strike: float) -> Array[Dictionary]:
	var steps: Array[Dictionary] = []
	var opp: OpponentData = scene["opp"]
	var direction: int = opp.attacks[0].direction
	var mode: StringName = scene["mode"]
	match mode:
		&"block":
			steps.append({"t": tell_start + EPS, "fn": _do_guard_on.bind(direction)})
			steps.append({"t": strike + EPS, "fn": _do_guard_off})
		&"parry":
			steps.append({"t": strike - 0.08, "fn": _do_guard_on.bind(direction)})
			steps.append({"t": strike + EPS, "fn": _do_guard_off})
		&"whiff":
			steps.append({"t": tell_start + EPS, "fn": _do_step_back})
	if scene["opener"]:
		steps.append({"t": strike + 0.05, "fn": _do_opener})
	if scene["poke"]:
		# 스친 공격이 판정되는 시각(+0.25) 직후, 무너짐이 시작되고 게이지가 멈춘 때다.
		steps.append({"t": strike + 0.25 + EPS, "fn": _do_poke_gauge})
	steps.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["t"]) < float(b["t"]))
	return steps


func _do_guard_on(core: DuelCore, direction: int) -> void:
	core.set_aim(direction, DT.Height.MID)
	core.set_guard(true)


func _do_guard_off(core: DuelCore) -> void:
	core.set_guard(false)


func _do_step_back(core: DuelCore) -> void:
	core.step(-1)


func _do_opener(core: DuelCore) -> void:
	core.set_aim(DT.Direction.CENTER, DT.Height.MID)
	core.press_attack()


func _do_poke_gauge(core: DuelCore) -> void:
	core._bind_value = 0.99
	core._bind_since = core.time


func _probe(scene: Dictionary) -> Dictionary:
	var out := {"tell_start": 0.0, "strike": 0.0}
	if scene["mode"] == &"none":
		return out
	var core := _new_core(scene)
	var guard := 0
	while core.brain.state != DT.OpponentState.TELL and guard < 20:
		_advance(core, core.brain.state_end + EPS)
		guard += 1
	out["tell_start"] = core.brain.state_start
	out["strike"] = core.brain.state_end
	return out


func _count(key: String) -> void:
	_seen[key] = int(_seen.get(key, 0)) + 1


## 한 갈래를 훑는다. 어긋남의 글을 errs에 더한다.
func _sweep(scene: Dictionary, rule: String, errs: Array[String], stride := 1) -> void:
	var probe := _probe(scene)
	var tell_start: float = probe["tell_start"]
	var strike: float = probe["strike"]
	var steps := _script(scene, tell_start, strike)
	var anchor_time := strike if scene["anchor"] == &"strike" else 0.0
	var count := int(round((float(scene["to"]) - float(scene["from"])) / DELTA))
	var mismatches := 0
	for k in range(0, count + 1, stride):
		var press_at := anchor_time + float(scene["from"]) + k * DELTA
		for direction in [DT.Direction.LEFT, DT.Direction.CENTER, DT.Direction.RIGHT]:
			for height in [DT.Height.HIGH, DT.Height.MID, DT.Height.LOW]:
				var msg := _trial(scene, steps, press_at, direction, height)
				_trials += 1
				if msg != "" and mismatches < 3:
					errs.append("[%s/%s] %s" % [rule, scene["label"], msg])
					mismatches += 1
				elif msg != "":
					mismatches += 1


## 같은 입력으로 새 코어를 press_at까지 돌려 누르고, 미리보기와 실제 판정을 견준다. 어긋나면 글을, 맞으면 ""를 돌려준다.
func _trial(scene: Dictionary, steps: Array[Dictionary], press_at: float, direction: int, height: int) -> String:
	var core := _new_core(scene)
	for step in steps:
		if float(step["t"]) >= press_at:
			break
		_advance(core, step["t"])
		var fn: Callable = step["fn"]
		fn.call(core)
	_advance(core, press_at)
	if core.ended:
		return ""
	core.set_aim(direction, height)
	var forecast := core.attack_forecast()
	var verdict: int = forecast["verdict"]
	var margin: float = forecast["margin"]
	var where := "누름 %.4f 방향%d 높이%d 판정 %s" % [press_at, direction, height, DT.FORECAST_NAMES[verdict]]
	var pre_state := core.brain.state
	var pre_end := core.brain.state_end
	var pre_distance := core.distance
	var pre_approach := core._approach_at
	var before := core.record.events.size()
	var started_before := core.record.of_type(DuelRecord.ATTACK_START).size()
	core.press_attack()
	var started := core.record.of_type(DuelRecord.ATTACK_START).size() > started_before
	if not started:
		if verdict != DT.Forecast.UNSURE:
			return "%s: 누를 수 없는데 UNSURE가 아니다" % where
		_count("UNSURE(누를 수 없음)")
		return ""
	var judge_at: float = core.player_state_end
	var idle_min := core.opponent_data.idle_time_min
	# 빈틈(회수·무너짐)에서 누를 수 있으면 UNSURE는 없다.
	if verdict == DT.Forecast.UNSURE:
		var tell_first := pre_state == DT.OpponentState.TELL and pre_end <= judge_at
		var after_open := (pre_state == DT.OpponentState.RECOVERY or pre_state == DT.OpponentState.STAGGER) and pre_end <= judge_at
		var approach_at := pre_approach
		if after_open:
			approach_at = pre_end + core.opponent_data.approach_delay
		var approach_idle := pre_distance == DT.Distance.FAR and (pre_state == DT.OpponentState.IDLE or after_open) \
				and approach_at <= judge_at and approach_at + idle_min <= judge_at
		if pre_state == DT.OpponentState.RECOVERY or pre_state == DT.OpponentState.STAGGER:
			if not approach_idle:
				return "%s: 빈틈에서 누를 수 있는데 UNSURE" % where
		if not (tell_first or approach_idle):
			return "%s: UNSURE의 세 경우에 들지 않는다 (상대 %d, 끝 %.4f, 판정 %.4f)" % [where, pre_state, pre_end, judge_at]
		_count("UNSURE(타격이 먼저 또는 접근 뒤 대기)")
		return ""
	_advance(core, judge_at + 0.03)
	if core.ended and verdict != DT.Forecast.BIND_CUT:
		# 판이 먼저 끝났다(조건 밖의 유효타 등). 견줄 판정이 없다.
		var attack_events: Array[Dictionary] = []
		for i in range(before, core.record.events.size()):
			if core.record.events[i]["type"] == DuelRecord.ATTACK:
				attack_events.append(core.record.events[i])
		if attack_events.is_empty():
			return ""
	var attack_event: Dictionary = {}
	var shove_cancelled := false
	for i in range(before, core.record.events.size()):
		var ev: Dictionary = core.record.events[i]
		if ev["type"] == DuelRecord.ATTACK and attack_event.is_empty():
			attack_event = ev
		elif ev["type"] == DuelRecord.SHOVE and bool(ev.get("cancelled_attack", false)):
			shove_cancelled = true
	_count(DT.FORECAST_NAMES[verdict])
	if verdict == DT.Forecast.BIND_CUT:
		if not attack_event.is_empty() or not shove_cancelled:
			return "%s: 엉킴으로 끊긴다고 했는데 판정이 났다 (공격 %s, 끊김 %s)" % [where, str(not attack_event.is_empty()), str(shove_cancelled)]
		return ""
	if attack_event.is_empty():
		return "%s: 공격의 판정 이벤트가 없다" % where
	if shove_cancelled:
		return "%s: 끊긴다고 하지 않았는데 끊겼다" % where
	var result: int = attack_event["result"]
	var dodged: bool = attack_event["dodged"]
	var got := "결과 %d dodged %s" % [result, str(dodged)]
	match verdict:
		DT.Forecast.REACH:
			if result != DT.AttackResult.GRAZE and result != DT.AttackResult.HIT:
				return "%s: 닿는다고 했는데 %s" % [where, got]
			if margin <= 0.0:
				return "%s: 닿는다고 했는데 여유가 %f" % [where, margin]
		DT.Forecast.LATE, DT.Forecast.NO_OPENING:
			if result != DT.AttackResult.BLOCKED or dodged:
				return "%s: 막힌다고 했는데 %s" % [where, got]
		DT.Forecast.HEAD_GUARDED:
			if result != DT.AttackResult.BLOCKED or not dodged:
				return "%s: 피한다고 했는데 %s" % [where, got]
		DT.Forecast.OUT_OF_RANGE:
			if result != DT.AttackResult.WHIFF:
				return "%s: 멀다고 했는데 %s" % [where, got]
	return ""


func t105_forecast_matches_verdict() -> String:
	var errs: Array[String] = []
	var fx := load(EFFECTS_PATH) as PartEffectData
	if fx == null:
		return "data/part_effects.tres를 읽지 못했다"
	var odd := fx.duplicate() as PartEffectData
	odd.arm_windup_extra = -0.15
	odd.head_windup_extra = 0.2
	odd.hand_windup_extra = 0.05
	odd.head_big_only = false
	# 다른 값의 사본은 머리·팔을 보는 앞의 다섯 갈래만, 1/30초 간격으로 훑는다(시간).
	var rules: Array = [["옛", null, 1, 99], ["새", fx, 1, 99], ["새(머리·팔 다른 값)", odd, 2, 5]]
	_seen.clear()
	_trials = 0
	var started := Time.get_ticks_msec()
	for rule in rules:
		var scenes := _scenes()
		for i in mini(scenes.size(), int(rule[3])):
			var scene := scenes[i]
			var opp: OpponentData = scene["opp"]
			_sweep(dict_with_effects(scene, opp, rule[1]), rule[0], errs, int(rule[2]))
	for key in ["닿는다", "늦다", "빈틈 아님", "멀다", "피한다", "엉킴", "UNSURE(누를 수 없음)", "UNSURE(타격이 먼저 또는 접근 뒤 대기)"]:
		if int(_seen.get(key, 0)) < MIN_SEEN:
			errs.append("훑기에서 '%s'가 %d번만 나왔다(가짜 통과 방지: %d번 이상)" % [key, int(_seen.get(key, 0)), MIN_SEEN])
	print("INFO T105 누름 %d번 %d ms, 갈래 %s" % [_trials, Time.get_ticks_msec() - started, str(_seen)])
	return _result(errs)


## 갈래의 상대에 부위별 반격의 값을 실은 복사본.
func dict_with_effects(scene: Dictionary, opp: OpponentData, fx: Variant) -> Dictionary:
	var copy := scene.duplicate()
	copy["opp"] = opp if fx == null else opp.with_part_effects(fx as PartEffectData)
	return copy


# ================================================================ T106

func _spawn_duel(opp: OpponentData) -> Node:
	var commission := Commission.new()
	commission.client_name = "테스트"
	commission.dialogue = "테스트용 사연"
	commission.opponent = opp
	var duel: Node = (load(DUEL_PATH) as PackedScene).instantiate()
	duel.set("commission", commission)
	duel.set("test_weapon", _h._weapon())
	duel.set("mouse_aim_enabled", false)
	duel.set("rng_seed", 1)
	_tree.root.add_child(duel)
	return duel


## 막은 뒤 +0.25초에 멈춘 장면. 상대의 첫 타격을 막고 막기를 뗀 채 시계를 세운다.
func _blocked_duel(opp: OpponentData, after := 0.25) -> Node:
	var duel := _spawn_duel(opp)
	var core: DuelCore = duel.get("core")
	var guard := 0
	while core.brain.state != DT.OpponentState.TELL and guard < 600:
		duel.call("advance", DELTA)
		guard += 1
	core.set_aim(opp.attacks[0].direction, DT.Height.MID)
	core.set_guard(true)
	while core.record.of_type(DuelRecord.STRIKE).is_empty() and guard < 1200:
		duel.call("advance", DELTA)
		guard += 1
	core.set_guard(false)
	duel.call("advance", maxf(core.brain.state_start + after - core.time, 0.0))
	return duel


## 시계를 세운 채 조준만 옮기고 그린다. 조준 글과 꼬리표를 돌려준다.
func _show_aim(duel: Node, direction: int, height: int) -> Dictionary:
	(duel.get("core") as DuelCore).set_aim(direction, height)
	duel.call("advance", 0.0)
	var tag := duel.get_node("OpponentView/ForecastTag") as Label
	return {"note": (duel.get_node("HUD").get("_aim_label") as Label).text, "tag": tag.text, "shown": tag.visible}


func t106_aim_display() -> String:
	var errs: Array[String] = []
	var fx := load(EFFECTS_PATH) as PartEffectData
	if fx == null:
		return "data/part_effects.tres를 읽지 못했다"
	var sword_side: int = _cut_opp(true).sword_side
	var torso := [DT.Direction.CENTER, DT.Height.MID]
	var arm := [sword_side, DT.Height.MID]
	var head := [DT.Direction.CENTER, DT.Height.HIGH]

	# 새 규칙: 막은 뒤 +0.25초
	var duel := _blocked_duel(_cut_opp(true).with_part_effects(fx))
	if (duel.get("core") as DuelCore).distance != DT.Distance.ENGAGE:
		errs.append("교전이 아님")
	var reach := _show_aim(duel, torso[0], torso[1])
	if not (reach["shown"] and reach["tag"] == "닿는다" and str(reach["note"]).contains("(닿는다)")):
		errs.append("[새·몸통] 닿는다가 아님: %s" % str(reach))
	var late := _show_aim(duel, arm[0], arm[1])
	if not (late["shown"] and late["tag"] == "늦다" and str(late["note"]).contains("늦다")):
		errs.append("[새·팔] 늦다가 아님: %s" % str(late))
	duel.free()
	# 머리는 예비가 길어 +0.25초에는 늦다. 막은 직후(+0.05초)에 노리면 피한다.
	duel = _blocked_duel(_cut_opp(true).with_part_effects(fx), 0.05)
	var dodge := _show_aim(duel, head[0], head[1])
	if not (dodge["shown"] and dodge["tag"] == "피한다" and str(dodge["note"]).contains("피한다")):
		errs.append("[새·머리] 피한다가 아님: %s" % str(dodge))
	duel.free()

	# 새 규칙: 멀리
	var far_opp := _cut_opp(true).with_part_effects(fx)
	far_opp.approach_delay = 1000.0
	far_opp.idle_time_min = 1000.0
	far_opp.idle_time_max = 1000.0
	duel = _spawn_duel(far_opp)
	(duel.get("core") as DuelCore).step(-1)
	duel.call("advance", 0.6)
	var far := _show_aim(duel, torso[0], torso[1])
	if (duel.get("core") as DuelCore).distance != DT.Distance.FAR:
		errs.append("멀리에 닿지 못했다")
	if not (far["shown"] and far["tag"] == "멀다" and str(far["note"]).contains("닿지 않음")):
		errs.append("[새·멀리] 멀다가 아님: %s" % str(far))
	duel.free()

	# 옛 규칙: 꼬리표가 없고 덧말이 지금과 같다
	duel = _blocked_duel(_cut_opp(true))
	for aim in [torso, arm, head]:
		var old := _show_aim(duel, aim[0], aim[1])
		if old["shown"] or str(old["note"]).contains("(닿는다)") or str(old["note"]).contains("늦다") or str(old["note"]).contains("피한다"):
			errs.append("[옛] 표시가 보임: %s" % str(old))
	duel.free()
	var old_far_opp := _cut_opp(true)
	old_far_opp.approach_delay = 1000.0
	old_far_opp.idle_time_min = 1000.0
	old_far_opp.idle_time_max = 1000.0
	duel = _spawn_duel(old_far_opp)
	(duel.get("core") as DuelCore).step(-1)
	duel.call("advance", 0.6)
	var old_far := _show_aim(duel, torso[0], torso[1])
	if old_far["shown"] or not str(old_far["note"]).contains("(멀리: 닿지 않음)"):
		errs.append("[옛·멀리] 지금 화면과 다름: %s" % str(old_far))
	duel.free()
	return _result(errs)


# ================================================================ T107~T109 (부위 보상)

const HOLD := &"hold"
const PARRY := &"parry"


func _fx() -> PartEffectData:
	return load(EFFECTS_PATH) as PartEffectData


## 막기(또는 패리)로 받고 setup을 돌린 판. 예비 동작이 시작될 때마다 roll(0 이상이면)을 굴림 값으로 넣는다.
## 마지막 타격(next_strike < 0)이 나올 때까지 돌리고 그 지점의 코어와 이벤트들을 돌려준다.
func _until_final_strike(opp: OpponentData, mode: StringName, has_hat := false, roll := -1.0, setup := Callable()) -> Dictionary:
	var core: DuelCore = _h._make_core(opp, 1, [], has_hat)
	if setup.is_valid():
		setup.call(core)
	var guard := func(_atk: AttackData, _i: int) -> StringName: return mode
	var bot := Bot.new(core, {"guard_fn": guard})
	var tells: Array[Dictionary] = []
	# 람다가 core를 붙잡아 순환 참조가 생기므로 끝나면 끊는다.
	var on_tell := func(ev: Dictionary) -> void:
		if ev["type"] == DuelRecord.TELL_START:
			tells.append(ev)
			if roll >= 0.0:
				core.brain.opening_roll = roll
	core.event.connect(on_tell)
	var strike: Dictionary = {}
	while not core.ended and core.time < 20.0 and strike.is_empty():
		core.tick(DELTA)
		bot.update()
		for ev in core.record.of_type(DuelRecord.STRIKE):
			if float(ev["next_strike"]) < 0.0:
				strike = ev
				break
	core.event.disconnect(on_tell)
	return {"core": core, "strike": strike, "tells": tells}


## until_final_strike의 판에서 타격 d초 뒤에 조준대로 누르고 그 공격의 ATTACK 이벤트를 돌려준다(없으면 빈 사전).
func _press_after(run: Dictionary, direction: int, height: int, d: float) -> Dictionary:
	var core: DuelCore = run["core"]
	var strike: Dictionary = run["strike"]
	var at := float(strike["t"]) + d + EPS
	if at > core.time:
		core.tick(at - core.time)
	core.set_aim(direction, height)
	core.press_attack()
	var guard := 0
	while core.record.of_type(DuelRecord.ATTACK).is_empty() and not core.ended and guard < 600:
		core.tick(DELTA)
		guard += 1
	var found := core.record.of_type(DuelRecord.ATTACK)
	return found[found.size() - 1] if not found.is_empty() else {}


func _plain_cut() -> OpponentData:
	return _cut_opp(true).with_opening(1.0)


func _first_chain(opp: OpponentData) -> AttackData:
	for atk in opp.attacks:
		if not atk.chain.is_empty():
			return atk
	return null


# ---------------------------------------------------------------- T107 팔

func t107_arm_slow() -> String:
	var errs: Array[String] = []
	var fx := _fx()
	var side: int = _cut_opp(true).sword_side
	var arm := [side, DT.Height.MID]
	var base_tell := float(_cut_opp(true).attacks[0].tell_time)
	var mult := fx.arm_tell_multiplier

	# 팔을 한 번 스친 뒤 예비 동작 셋은 ×배율, 넷째는 원래 값.
	var core: DuelCore = _h._make_core(_plain_cut().with_part_effects(fx), 1, [], false)
	var used := [0]
	var counter := func(ev: Dictionary) -> Variant:
		if float(ev["recovery"]) > 0.0 and used[0] == 0:
			used[0] = 1
			return arm
		return null
	var bot := Bot.new(core, {"counter_fn": counter})
	while not core.ended and core.time < 40.0 and bot.tells_seen < fx.arm_slow_tells + 3:
		core.tick(DELTA)
		bot.update()
	var grazes := core.record.of_type(DuelRecord.ATTACK)
	if grazes.is_empty() or grazes[0].get("effect", &"") != &"arm_slow" or int(grazes[0].get("slow_left", -1)) != fx.arm_slow_tells:
		errs.append("팔 스침이 효과를 걸지 않았다: %s" % str(grazes[0] if not grazes.is_empty() else {}))
	else:
		var after: Array[Dictionary] = []
		for ev in core.record.of_type(DuelRecord.TELL_START):
			if float(ev["t"]) > float(grazes[0]["t"]):
				after.append(ev)
		if after.size() < fx.arm_slow_tells + 1:
			errs.append("스친 뒤 예비 동작이 %d번뿐이다" % after.size())
		else:
			for i in fx.arm_slow_tells + 1:
				var ev: Dictionary = after[i]
				var slowed: bool = i < fx.arm_slow_tells
				var want := base_tell * (mult if slowed else 1.0)
				if absf(float(ev["duration"]) - want) > 1e-9:
					errs.append("%d번째 예비 동작 길이 %f != %f" % [i + 1, float(ev["duration"]), want])
				if bool(ev.get("slowed", false)) != slowed:
					errs.append("%d번째 예비 동작의 slowed 칸이 틀리다" % (i + 1))
				if slowed and int(ev.get("slow_left", -1)) != fx.arm_slow_tells - 1 - i:
					errs.append("%d번째 예비 동작의 남은 횟수 %s" % [i + 1, str(ev.get("slow_left"))])

	# 다시 스치면 쌓이지 않고 처음 횟수로 돌아간다.
	var again: DuelCore = _h._make_core(_plain_cut().with_part_effects(fx), 1, [], false)
	var again_bot := Bot.new(again, {"counter_fn": func(ev: Dictionary) -> Variant: return arm if float(ev["recovery"]) > 0.0 else null})
	while not again.ended and again.time < 40.0 and again.record.of_type(DuelRecord.ATTACK).size() < 3:
		again.tick(DELTA)
		again_bot.update()
	var effects := again.record.of_type(DuelRecord.ATTACK).filter(func(ev: Dictionary) -> bool: return ev.get("effect", &"") == &"arm_slow")
	if effects.size() < 2:
		errs.append("연속 팔 스침이 둘 미만이다")
	for ev in effects:
		if int(ev["slow_left"]) != fx.arm_slow_tells:
			errs.append("다시 스쳤을 때 남은 횟수가 %d (쌓임)" % int(ev["slow_left"]))

	# 몸통·다리·손·모자 스침은 팔 효과를 걸지 않는다.
	var cases := [
		["몸통", PARRY, false, DT.Direction.CENTER, DT.Height.MID],
		["다리", HOLD, false, DT.Direction.CENTER, DT.Height.LOW],
		["손", PARRY, false, side, DT.Height.HIGH],
		["모자", PARRY, true, side, DT.Height.HIGH],
	]
	for c in cases:
		var run := _until_final_strike(_plain_cut().with_part_effects(fx), c[1], c[2])
		var shot := _press_after(run, c[3], c[4], 0.05)
		if shot.is_empty() or int(shot["result"]) != DT.AttackResult.GRAZE:
			errs.append("[%s] 스침이 아니다: %s" % [c[0], str(shot.get("result"))])
			continue
		if shot.get("effect", &"") == &"arm_slow" or (run["core"] as DuelCore).brain.slow_tells_left != 0:
			errs.append("[%s] 스침이 팔 효과를 걸었다" % c[0])
	# 팔 유효타: 무너진 상대의 팔.
	var stagger_opp := _cut_opp(true, false, 1).with_opening(1.0).with_part_effects(fx)
	var finish: DuelCore = _h._make_core(stagger_opp, 1, [], false)
	var finish_bot := Bot.new(finish, {
		"counter_fn": func(ev: Dictionary) -> Variant: return [DT.Direction.CENTER, DT.Height.MID] if float(ev["recovery"]) > 0.0 else null,
		"finisher": arm,
	})
	while not finish.ended and finish.time < 30.0:
		finish.tick(DELTA)
		finish_bot.update()
	var hit := finish.record.of_type(DuelRecord.ATTACK).filter(func(ev: Dictionary) -> bool: return ev["result"] == DT.AttackResult.HIT)
	if hit.is_empty() or int(hit[0]["part"]) != DT.Part.SWORD_ARM:
		errs.append("무너진 팔에 유효타를 못 넣었다")
	elif hit[0].has("effect") or finish.brain.slow_tells_left != 0:
		errs.append("팔 유효타가 효과를 걸었다")

	# 패턴: 사슬의 간격과 번호 고리의 시각이 같은 배율이고 타격 사이 0.55초 이상, 패턴 하나가 1회.
	var chain_atk := _first_chain(load(OPPONENT_PATHS[0]) as OpponentData)
	if chain_atk == null:
		errs.append("이어 치기 공격이 없다")
	else:
		var pattern_opp := (load(OPPONENT_PATHS[0]) as OpponentData).drill(chain_atk).with_opening(1.0).with_part_effects(fx)
		var pc: DuelCore = _h._make_core(pattern_opp, 1, [], false)
		pc.brain.slow_tells_left = 2
		var planned: Array = []
		var on_plan := func(ev: Dictionary) -> void:
			if ev["type"] == DuelRecord.TELL_START:
				planned.append(pc.brain.pattern_strike_times())
		pc.event.connect(on_plan)
		var pbot := Bot.new(pc, {})
		while not pc.ended and pc.time < 60.0 and planned.size() < 4:
			pc.tick(DELTA)
			pbot.update()
		pc.event.disconnect(on_plan)
		var strikes := pc.record.of_type(DuelRecord.STRIKE)
		var count := 1 + chain_atk.chain.size()
		if planned.size() < 4 or strikes.size() < count * 3:
			errs.append("패턴 셋을 못 돌렸다 (%d, 타격 %d)" % [planned.size(), strikes.size()])
		else:
			for p in 3:
				var slowed_pattern := p < 2
				for k in count:
					var actual := float(strikes[p * count + k]["t"])
					if absf(actual - float((planned[p] as Array)[k])) > 1e-6:
						errs.append("패턴%d 타격%d: 고리의 시각 %f != 타격 %f" % [p + 1, k + 1, float((planned[p] as Array)[k]), actual])
					if k > 0:
						var gap := actual - float(strikes[p * count + k - 1]["t"])
						var want: float = chain_atk.chain[k - 1].tell_time * (mult if slowed_pattern else 1.0)
						if absf(gap - want) > 1e-6:
							errs.append("패턴%d 타격%d 간격 %f != %f" % [p + 1, k + 1, gap, want])
						if gap < 0.55 - 1e-9:
							errs.append("패턴%d 타격%d 간격 %f < 0.55" % [p + 1, k + 1, gap])

	# 난수: 효과가 있어도 없어도 뽑힌 공격·높이의 차례가 같다(고정 씨앗, 가방을 쓰는 실제 상대).
	var sequences: Array = []
	for with_slow in [false, true]:
		var real := (load(OPPONENT_PATHS[0]) as OpponentData).with_opening(1.0).with_part_effects(fx)
		var rc: DuelCore = _h._make_core(real, 7, [], false)
		if with_slow:
			rc.brain.slow_tells_left = 3
		var rbot := Bot.new(rc, {})
		var seq: Array = []
		rc.event.connect(func(ev: Dictionary) -> void:
			if ev["type"] == DuelRecord.TELL_START:
				seq.append("%s%s" % [(ev["attack"] as AttackData).attack_name, str(ev["heights"])]))
		while not rc.ended and rc.time < 200.0 and seq.size() < 8:
			rc.tick(DELTA)
			rbot.update()
		sequences.append(seq)
	if (sequences[0] as Array).size() < 8 or sequences[0] != sequences[1]:
		errs.append("효과가 난수 차례를 바꿨다: %s | %s" % [str(sequences[0]), str(sequences[1])])
	return _result(errs)


# ---------------------------------------------------------------- T108 다리

## 굴림 값을 고정하고 다리 덤을 실은 채 받은 판의 마지막 타격 이벤트와 코어.
func _leg_strike(opp: OpponentData, mode: StringName, roll: float, charges := 1) -> Dictionary:
	return _until_final_strike(opp, mode, false, roll, func(core: DuelCore) -> void: core.brain.parry_charges = charges)


func t108_legs_bonus() -> String:
	var errs: Array[String] = []
	var fx := _fx()
	var half := _cut_opp(true).with_opening(0.5).with_part_effects(fx)
	var half_plain := _cut_opp(true).with_opening(0.5)
	# 덤 없는 같은 패리의 길이(열릴 굴림)와 결과.
	var base_strike: Dictionary = _leg_strike(half_plain, PARRY, 0.1, 0)["strike"]
	if base_strike.is_empty() or int(base_strike["result"]) != DT.StrikeResult.PARRIED or base_strike.has("leg_bonus"):
		return "덤 없는 기준 패리가 틀리다"
	var base_recovery := float(base_strike["recovery"])

	# 갈래 1: 덤 없이는 안 열릴 굴림 + 덤으로 열림. 길이는 덤 없는 패리 그대로.
	var opened := _leg_strike(half, PARRY, 0.9)
	var s1: Dictionary = opened["strike"]
	if s1.get("leg_bonus", &"") != &"opened" or absf(float(s1["recovery"]) - base_recovery) > 1e-9 or bool(s1["closed"]) or int(s1["result"]) != DT.StrikeResult.PARRIED:
		errs.append("[opened] %s" % str({"b": s1.get("leg_bonus"), "r": s1.get("recovery"), "closed": s1.get("closed")}))
	if (opened["core"] as DuelCore).brain.parry_charges != 0:
		errs.append("[opened] 덤이 남았다")
	var shut: Dictionary = _leg_strike(half_plain, PARRY, 0.9, 0)["strike"]
	if not bool(shut["closed"]):
		errs.append("[opened] 덤 없는 같은 굴림이 열렸다")

	# 갈래 2: 덤 없이도 열릴 굴림 -> +legs_open_time_bonus초.
	var s2: Dictionary = _leg_strike(half, PARRY, 0.1)["strike"]
	if s2.get("leg_bonus", &"") != &"time" or absf(float(s2["recovery"]) - (base_recovery + fx.legs_open_time_bonus)) > 1e-9 \
			or absf(float(s2.get("leg_time", 0.0)) - fx.legs_open_time_bonus) > 1e-9:
		errs.append("[time] %s" % str({"b": s2.get("leg_bonus"), "r": s2.get("recovery"), "base": base_recovery}))
	# 늘 열린다(확률 1.0)와 1일차(0.80 + 0.25)는 굴림이 무엇이든 time이다.
	for chance in [1.0, 0.80]:
		for roll in [0.05, 0.5, 0.95]:
			var sure: Dictionary = _leg_strike(_cut_opp(true).with_opening(chance).with_part_effects(fx), PARRY, roll)["strike"]
			if sure.get("leg_bonus", &"") != &"time":
				errs.append("[확률 %.2f 굴림 %.2f] time이 아니다: %s" % [chance, roll, str(sure.get("leg_bonus"))])

	# 갈래 3: 덤을 더해도 안 열릴 굴림(덤 0.05) -> 안 열리고 none. 덤은 쓰인다.
	var weak := fx.duplicate() as PartEffectData
	weak.legs_parry_opening_bonus = 0.05
	var none := _leg_strike(_cut_opp(true).with_opening(0.5).with_part_effects(weak), PARRY, 0.9)
	var s3: Dictionary = none["strike"]
	if s3.get("leg_bonus", &"") != &"none" or not bool(s3["closed"]) or float(s3["recovery"]) != 0.0:
		errs.append("[none] %s" % str({"b": s3.get("leg_bonus"), "closed": s3.get("closed"), "r": s3.get("recovery")}))
	if (none["core"] as DuelCore).brain.parry_charges != 0:
		errs.append("[none] 덤이 남았다")

	# 막힘으로 끝난 공격은 덤을 쓰지 않고 남긴다. 패리의 결과는 덤과 무관하다.
	var blocked := _leg_strike(half, HOLD, 0.1)
	var s4: Dictionary = blocked["strike"]
	if s4.has("leg_bonus") or (blocked["core"] as DuelCore).brain.parry_charges != 1 or int(s4["result"]) != DT.StrikeResult.BLOCKED:
		errs.append("[막힘] 덤이 쓰였거나 결과가 달라졌다")
	for s in [s1, s2, s3]:
		if int(s["result"]) != DT.StrikeResult.PARRIED:
			errs.append("덤이 패리의 결과를 바꿨다")

	# 사슬 중간의 패리는 덤을 쓰지 않고, 마지막 패리에서 한 번 쓴다.
	var chain_atk := _first_chain(load(OPPONENT_PATHS[0]) as OpponentData)
	if chain_atk != null:
		var pattern_opp := (load(OPPONENT_PATHS[0]) as OpponentData).drill(chain_atk).with_opening(0.5).with_part_effects(fx)
		var run := _leg_strike(pattern_opp, PARRY, 0.1)
		var with_bonus := (run["core"] as DuelCore).record.of_type(DuelRecord.STRIKE).filter(func(ev: Dictionary) -> bool: return ev.has("leg_bonus"))
		var last: Dictionary = run["strike"]
		if with_bonus.size() != 1 or not last.has("leg_bonus") or float(last["next_strike"]) >= 0.0:
			errs.append("[사슬] 덤이 마지막 패리가 아닌 데서 쓰였다 (%d번)" % with_bonus.size())

	# 다리를 스치면 덤이 걸린다.
	var leg_core: DuelCore = _h._make_core(_plain_cut().with_part_effects(fx), 1, [], false)
	var once := [0]
	var leg_bot := Bot.new(leg_core, {"counter_fn": func(ev: Dictionary) -> Variant:
		if float(ev["recovery"]) > 0.0 and once[0] == 0:
			once[0] = 1
			return [DT.Direction.CENTER, DT.Height.LOW]
		return null})
	while not leg_core.ended and leg_core.time < 10.0 and leg_core.record.of_type(DuelRecord.ATTACK).is_empty():
		leg_core.tick(DELTA)
		leg_bot.update()
	var leg_ev := leg_core.record.of_type(DuelRecord.ATTACK)
	if leg_ev.is_empty() or leg_ev[0].get("effect", &"") != &"legs_parry" or leg_core.brain.parry_charges != fx.legs_parry_charges:
		errs.append("다리 스침이 덤을 걸지 않았다")

	# 글: 일어난 일(leg_bonus)만 말한다.
	var duel := _spawn_duel(_cut_opp(true).with_part_effects(fx))
	var hud := duel.get_node("HUD")
	var attack_data := _cut_opp(true).attacks[0]
	var line := func(extra: Dictionary) -> String:
		var full := {"type": DuelRecord.STRIKE, "attack": attack_data, "result": DT.StrikeResult.PARRIED, "braced": false, "closed": false}
		full.merge(extra, true)
		return str(hud.call("_describe", full))
	if not str(line.call({"leg_bonus": &"opened", "leg_time": 0.0})).contains("틈이 열렸다"):
		errs.append("opened 글이 틀리다")
	var timed_text := str(line.call({"leg_bonus": &"time", "leg_time": fx.legs_open_time_bonus}))
	if not timed_text.contains("빈틈 +%s초" % str(snappedf(fx.legs_open_time_bonus, 0.01))):
		errs.append("time 글이 틀리다: %s" % timed_text)
	if str(line.call({})) != "패리!":
		errs.append("덤 없는 패리의 글이 달라졌다")
	var none_text := str(line.call({"leg_bonus": &"none", "closed": true, "leg_time": 0.0, "miss_limit": 0, "closed_streak": 1}))
	if not none_text.contains("틈을 안 줬다") or none_text.contains("다리"):
		errs.append("none 글이 틀리다: %s" % none_text)
	duel.free()

	# 날별 표(D5): 굴림 100개로 opened 수가 0 / 0 / 3 / 11, 나머지는 모두 time이다.
	var rules := _rules()
	var days := [["늘 열린다", 1.0, 0], ["1일차", rules.opening_chance_for(0.80, 1), 0], ["2일차", rules.opening_chance_for(0.80, 2), 3], ["3일차부터", rules.opening_chance_for(0.80, 3), 11]]
	for day in days:
		var opened_count := 0
		var time_count := 0
		var other := 0
		for i in 100:
			var sample: Dictionary = _leg_strike(_cut_opp(true).with_opening(day[1]).with_part_effects(fx), PARRY, (i + 0.5) / 100.0)["strike"]
			match sample.get("leg_bonus", &""):
				&"opened":
					opened_count += 1
				&"time":
					time_count += 1
				_:
					other += 1
		if opened_count != day[2] or time_count != 100 - day[2] or other != 0:
			errs.append("[%s 확률 %.2f] opened %d(기대 %d) time %d 그 밖 %d" % [day[0], day[1], opened_count, day[2], time_count, other])
	return _result(errs)


# ---------------------------------------------------------------- T109 머리

func t109_head_open() -> String:
	var errs: Array[String] = []
	var fx := _fx()
	var side: int = _cut_opp(true).sword_side
	var head := [DT.Direction.CENTER, DT.Height.HIGH]
	var torso := [DT.Direction.CENTER, DT.Height.MID]

	# 패리만 한 빈틈: 새 규칙은 피하고 옛 규칙은 닿는다(지금 그대로).
	var run := _until_final_strike(_plain_cut().with_part_effects(fx), PARRY)
	var shot := _press_after(run, head[0], head[1], 0.1)
	if shot.is_empty() or not bool(shot["dodged"]) or int(shot["result"]) == DT.AttackResult.GRAZE:
		errs.append("[새·패리 뒤] 머리가 피해지지 않았다: %s" % str(shot))
	run = _until_final_strike(_plain_cut(), PARRY)
	shot = _press_after(run, head[0], head[1], 0.1)
	if shot.is_empty() or int(shot["result"]) != DT.AttackResult.GRAZE or int(shot["part"]) != DT.Part.HEAD or int(shot["cells"]) != 2:
		errs.append("[옛·패리 뒤] 머리가 닿지 않았다: %s" % str(shot))

	# 큰 공격 뒤: 회수가 시작되고 head_exposed_time 안의 판정은 닿아 2칸, 그 뒤는 피한다.
	var head_windup := 0.4
	var big := _cut_opp(true, true).with_opening(1.0).with_part_effects(fx)
	run = _until_final_strike(big, HOLD)
	var inside := _press_after(run, head[0], head[1], fx.head_exposed_time - head_windup - 0.2)
	if inside.is_empty() or int(inside["result"]) != DT.AttackResult.GRAZE or int(inside["cells"]) != 2 or bool(inside["dodged"]):
		errs.append("[큰 공격 뒤·안] 머리가 닿지 않았다: %s" % str(inside))
	run = _until_final_strike(big, HOLD)
	var outside := _press_after(run, head[0], head[1], fx.head_exposed_time - head_windup + 0.2)
	if outside.is_empty() or not bool(outside["dodged"]):
		errs.append("[큰 공격 뒤·밖] 머리를 피하지 않았다: %s" % str(outside))
	# 코어가 같은 답을 준다(상대 그림의 파란 물과 상태 글자가 이것을 읽는다).
	run = _until_final_strike(big, HOLD)
	var core: DuelCore = run["core"]
	var start := core.brain.state_start
	if not core.head_open_at(start + fx.head_exposed_time * 0.5) or core.head_open_at(start + fx.head_exposed_time + 0.05):
		errs.append("head_open_at이 노출 시간을 따르지 않는다")

	# 무너짐: 머리에 닿는다(유효타).
	var stagger_opp := _cut_opp(true, false, 1).with_opening(1.0).with_part_effects(fx)
	var sc: DuelCore = _h._make_core(stagger_opp, 1, [], false)
	var sbot := Bot.new(sc, {
		"counter_fn": func(e: Dictionary) -> Variant: return torso if float(e["recovery"]) > 0.0 else null,
		"finisher": head,
	})
	while not sc.ended and sc.time < 30.0:
		sc.tick(DELTA)
		sbot.update()
	var hit := sc.record.of_type(DuelRecord.ATTACK).filter(func(e: Dictionary) -> bool: return e["result"] == DT.AttackResult.HIT)
	if hit.is_empty() or int(hit[0]["part"]) != DT.Part.HEAD:
		errs.append("[무너짐] 머리에 유효타가 닿지 않았다")

	# 모자 쓴 판: 상단 베기는 모자이고 머리 규칙과 효과는 걸리지 않는다.
	run = _until_final_strike(_plain_cut().with_part_effects(fx), PARRY, true)
	shot = _press_after(run, side, DT.Height.HIGH, 0.05)
	if shot.is_empty() or int(shot["part"]) != DT.Part.HAT or int(shot["result"]) != DT.AttackResult.GRAZE or shot.has("effect") or bool(shot["dodged"]):
		errs.append("[모자] 모자 스침이 아니다: %s" % str(shot))

	# 화면: 남은 횟수는 스칠 때 3이고 예비 동작마다 1씩 줄어 0에서 사라진다(HUD의 효과 글).
	var duel := _spawn_duel(_plain_cut().with_part_effects(fx))
	var dcore: DuelCore = duel.get("core")
	dcore.player_posture = 99
	var label := duel.get_node("HUD").find_child("EffectLabel", true, false) as Label
	if label == null:
		return _result(errs + (["효과 글(EffectLabel)이 없다"] as Array[String]))
	dcore.brain.slow_tells_left = fx.arm_slow_tells
	var seen: Array[String] = []
	var guard := 0
	while guard < 3000 and not (seen.size() > fx.arm_slow_tells and seen[seen.size() - 1] == ""):
		duel.call("advance", DELTA)
		var text := label.text if label.visible else ""
		if seen.is_empty() or seen[seen.size() - 1] != text:
			seen.append(text)
		guard += 1
	var want: Array[String] = []
	for left in range(fx.arm_slow_tells, 0, -1):
		want.append("팔 둔함 " + "●".repeat(left))
	want.append("")
	if seen != want:
		errs.append("효과 글의 변화 %s != %s" % [str(seen), str(want)])
	duel.free()
	return _result(errs)


# ================================================================ T110 의뢰 채점 불변

const FIRST_BLOOD_PATH := "res://data/commissions/first_blood.tres"
const FEATHER_PATH := "res://data/commissions/feather_cut.tres"
const LEGS_ONLY_PATH := "res://data/commissions/variants/legs_only.tres"
const THROW_PATHS: Array[String] = [
	"res://data/commissions/throw_match.tres",
	"res://data/commissions/variants/throw_bet.tres",
]
## 새 규칙이 이벤트에 더하는 칸(계획 R02). 채점은 이 칸을 읽지 않아야 한다.
const EFFECT_KEYS: Array[String] = ["effect", "slow_left", "leg_bonus", "leg_time", "slowed"]


func _stripped(record: DuelRecord) -> DuelRecord:
	var out := DuelRecord.new()
	out.elapsed = record.elapsed
	out.ended = record.ended
	out.end_reason = record.end_reason
	out.end_detail = record.end_detail
	for ev in record.events:
		var copy := ev.duplicate()
		for key in EFFECT_KEYS:
			copy.erase(key)
		out.add(copy)
	return out


func _effect_count(record: DuelRecord) -> int:
	var n := 0
	for ev in record.events:
		for key in EFFECT_KEYS:
			if ev.has(key):
				n += 1
				break
	return n


## 받아칠 때마다 aims를 순서대로 쓴다(마지막 것을 되풀이).
func _sequence_cfg(aims: Array, extra := {}) -> Dictionary:
	var calls: Array[int] = [0]
	var counter := func(ev: Dictionary) -> Variant:
		if float(ev["recovery"]) <= 0.0:
			return null
		var aim: Array = aims[mini(calls[0], aims.size() - 1)]
		calls[0] += 1
		return aim
	var cfg := {"counter_fn": counter}
	cfg.merge(extra)
	return cfg


func _graded_run(opp: OpponentData, cfg: Dictionary, commission_path: String, has_hat: bool) -> Dictionary:
	var commission := load(commission_path) as Commission
	var core: DuelCore = _h._make_core(opp.with_part_effects(_fx()), 1, commission.conditions, has_hat)
	var bot := Bot.new(core, cfg)
	while not core.ended and core.time < 200.0:
		core.tick(DELTA)
		bot.update()
	return {"core": core, "commission": commission}


## 같은 기록의 점수와 설명이 효과 칸을 지운 기록과 같다. 효과가 실제로 걸린 판이어야 한다.
func _check_same(errs: Array[String], label: String, run: Dictionary) -> void:
	var core: DuelCore = run["core"]
	var commission: Commission = run["commission"]
	var plain := _stripped(core.record)
	if _effect_count(core.record) == 0:
		errs.append("[%s] 효과가 걸린 판이 아니다" % label)
	if commission.evaluate(core.record) != commission.evaluate(plain):
		errs.append("[%s] 점수가 효과 칸에 흔들린다 %d != %d" % [label, commission.evaluate(core.record), commission.evaluate(plain)])
	if commission.explain(core.record) != commission.explain(plain):
		errs.append("[%s] 설명 줄이 효과 칸에 흔들린다" % label)


func _shot_names(core: DuelCore) -> String:
	var names: Array[String] = []
	for e in core.record.of_type(DuelRecord.ATTACK):
		names.append("%s/%s" % [e["result"], e["part"]])
	return ",".join(names)


func t110_commission_scoring() -> String:
	var errs: Array[String] = []
	var side: int = _cut_opp(true).sword_side
	var arm := [side, DT.Height.MID]
	var low := [DT.Direction.CENTER, DT.Height.LOW]
	var torso := [DT.Direction.CENTER, DT.Height.MID]
	var head := [DT.Direction.CENTER, DT.Height.HIGH]
	var hat_cut := [side, DT.Height.HIGH]
	var AR := DT.AttackResult

	# 첫 피: 팔·다리를 스쳐 효과가 걸려도 몸통 유효타 100, 머리 유효타 40.
	for row in [[torso, 100], [head, 40]]:
		var finisher: Array = row[0]
		var run := _graded_run(_cut_opp(true, false, 3).with_opening(1.0), _sequence_cfg([arm, low], {"finisher": finisher}), FIRST_BLOOD_PATH, false)
		var core: DuelCore = run["core"]
		var shots := core.record.of_type(DuelRecord.ATTACK)
		if core.end_reason != DT.EndReason.CONDITION or shots.size() < 3 or shots[0]["result"] != AR.GRAZE or shots[0]["part"] != DT.Part.SWORD_ARM \
				or shots[1]["part"] != DT.Part.LEGS or shots[shots.size() - 1]["result"] != AR.HIT:
			errs.append("[첫 피 %d] 장면이 계획과 다르다: %s" % [int(row[1]), _shot_names(core)])
			continue
		var score: int = run["commission"].evaluate(core.record)
		if score != int(row[1]):
			errs.append("[첫 피] 점수 %d (기대 %d)" % [score, int(row[1])])
		_check_same(errs, "첫 피 %d" % int(row[1]), run)

	# 깃털 자르기: 효과가 걸려도 감점 없이 모자 유효타 100. 상단 베기는 모자이고 머리가 아니다.
	var other_side: int = DT.Direction.RIGHT if side == DT.Direction.LEFT else DT.Direction.LEFT
	if DuelCore.aim_part(side, DT.Height.HIGH, side, true) != DT.Part.HAT or DuelCore.aim_part(other_side, DT.Height.HIGH, side, true) != DT.Part.HAT \
			or DuelCore.aim_part(DT.Direction.CENTER, DT.Height.HIGH, side, true) != DT.Part.HEAD:
		errs.append("[깃털] 모자 쓴 판의 상단 베기가 모자가 아니거나 찌르기가 머리가 아니다")
	var feather := _graded_run(_cut_opp(true, false, 3).with_opening(1.0), _sequence_cfg([arm, low], {"finisher": hat_cut}), FEATHER_PATH, true)
	var fcore: DuelCore = feather["core"]
	var fshots := fcore.record.of_type(DuelRecord.ATTACK)
	if fcore.end_reason != DT.EndReason.CONDITION or fshots.size() < 3 or fshots[0]["part"] != DT.Part.SWORD_ARM \
			or fshots[fshots.size() - 1]["part"] != DT.Part.HAT or fshots[fshots.size() - 1]["result"] != AR.HIT:
		errs.append("[깃털] 장면이 계획과 다르다: %s" % _shot_names(fcore))
	else:
		if feather["commission"].evaluate(fcore.record) != 100:
			errs.append("[깃털] 점수 %d (기대 100)" % feather["commission"].evaluate(fcore.record))
		_check_same(errs, "깃털", feather)

	# 다리만(스침도 본다): 팔 스침 한 번에 정확히 -graze_penalty, 다리 스침은 감점 없음.
	var legs_commission := load(LEGS_ONLY_PATH) as Commission
	var legs_cond := legs_commission.conditions[0] as TargetPartCondition
	if legs_cond.graze_penalty <= 0:
		errs.append("[다리만] 스침도 보는 의뢰가 아니다")
	var legs := _graded_run(_cut_opp(true, false, 4).with_opening(1.0), _sequence_cfg([arm, low, low], {"finisher": low}), LEGS_ONLY_PATH, false)
	var lcore: DuelCore = legs["core"]
	var lshots := lcore.record.of_type(DuelRecord.ATTACK)
	if lcore.end_reason != DT.EndReason.CONDITION or lshots.size() < 4 or lshots[0]["part"] != DT.Part.SWORD_ARM or lshots[0]["result"] != AR.GRAZE \
			or lshots[1]["part"] != DT.Part.LEGS or lshots[1]["result"] != AR.GRAZE or lshots[lshots.size() - 1]["part"] != DT.Part.LEGS or lshots[lshots.size() - 1]["result"] != AR.HIT:
		errs.append("[다리만] 장면이 계획과 다르다: %s" % _shot_names(lcore))
	else:
		var other_grazes := lshots.filter(func(e: Dictionary) -> bool: return e["result"] == AR.GRAZE and e["part"] != DT.Part.LEGS).size()
		if other_grazes != 1:
			errs.append("[다리만] 다리 아닌 스침이 %d번(기대 1)" % other_grazes)
		var want := 100 - legs_cond.graze_penalty * other_grazes
		if legs["commission"].evaluate(lcore.record) != want:
			errs.append("[다리만] 점수 %d (기대 %d)" % [legs["commission"].evaluate(lcore.record), want])
		_check_same(errs, "다리만", legs)

	# 티 안 나게 지기: 효과가 걸린 판의 의심도가 효과 칸을 지운 기록과 같고, 막아낸·닿은 횟수를 두 번 세지 않는다.
	var fight_then_lose := func(_a: AttackData, i: int) -> StringName:
		return &"hold" if i <= 6 else &"wrong"
	for path in THROW_PATHS:
		var cfg := _sequence_cfg([arm, low], {"guard_fn": fight_then_lose})
		var run := _graded_run(_cut_opp(true, false, 99).with_opening(1.0), cfg, path, false)
		var core: DuelCore = run["core"]
		if core.end_reason != DT.EndReason.PLAYER_DEFEATED:
			errs.append("[%s] 진 판이 아니다(%d)" % [path.get_file(), core.end_reason])
			continue
		_check_same(errs, path.get_file(), run)
		var cond := (run["commission"] as Commission).conditions[0] as ThrowUndetectedCondition
		var tally: Dictionary = cond._tally(core.record)
		var blocks := 0
		for ev in core.record.of_type(DuelRecord.STRIKE):
			if ev["result"] == DT.StrikeResult.BLOCKED or ev["result"] == DT.StrikeResult.PARRIED:
				blocks += 1
		var touches := 0
		for ev in core.record.of_type(DuelRecord.ATTACK):
			if ev["result"] == AR.GRAZE or ev["result"] == AR.HIT:
				touches += 1
		var joined := ""
		for item: Array in tally["items"]:
			joined += str(item[0]) + "\n"
		if blocks < cond.min_blocks and not joined.contains("막아낸 횟수 %d회" % blocks):
			errs.append("[%s] 막아낸 횟수가 %d이 아니다: %s" % [path.get_file(), blocks, joined])
		if touches < cond.min_touches and not joined.contains("닿은 횟수 %d회" % touches):
			errs.append("[%s] 닿은 횟수가 %d이 아니다: %s" % [path.get_file(), touches, joined])
	return _result(errs)


# ================================================================ T111 연습 화면

const SELECT_PATH := "res://scenes/ui/commission_select.tscn"
const SelectScript := preload("res://scripts/commission/commission_select.gd")


## 버튼에 묶인 상대(시험 줄의 버튼은 _start_opponent.bind(상대)로 이어진다).
func _bound_opponent(button: Button) -> OpponentData:
	for connection in button.pressed.get_connections():
		var args: Array = (connection["callable"] as Callable).get_bound_arguments()
		if not args.is_empty() and args[0] is OpponentData:
			return args[0]
	return null


func t111_practice_screen() -> String:
	var errs: Array[String] = []
	SelectScript._part_effects = false
	var select: Node = (load(SELECT_PATH) as PackedScene).instantiate()
	_tree.root.add_child(select)
	var toggle := select.find_child("PartCounterToggle", true, false) as Button
	var slash := select.find_child("SlashDrill", true, false) as Button
	if toggle == null or slash == null:
		select.free()
		return "반격 실험 또는 베기만 버튼이 없다"
	if toggle.button_pressed or toggle.text != "반격 실험":
		errs.append("처음에는 꺼져 있어야 한다")
	var names := ["TrialDuel0", "TrialDuel1", "TrialDuel2", "PatternDrill0", "SlashDrill", "SpareDrill0"]
	for state in [false, true]:
		toggle.button_pressed = state
		for node_name in names:
			var button := select.find_child(node_name, true, false) as Button
			if button == null:
				errs.append("%s 버튼이 없다" % node_name)
				continue
			var bound := _bound_opponent(button)
			if bound == null:
				errs.append("%s에 상대가 묶여 있지 않다" % node_name)
				continue
			var sent: OpponentData = select.call("_trial_copy", bound)
			if (sent.part_effects != null) != state:
				errs.append("%s: 반격 실험 %s인데 part_effects가 %s" % [node_name, state, sent.part_effects])
			if bound.part_effects != null:
				errs.append("%s: 묶인 원본을 고쳤다" % node_name)
	# 베기만: 공격이 단발 베기 하나다.
	var one := _bound_opponent(slash)
	if one == null or one.attacks.size() != 1 or not one.attacks[0].chain.is_empty() or one.attacks[0].direction == DT.Direction.CENTER \
			or one.attacks[0].dive or one.attacks[0].is_big or not one.habits.is_empty():
		errs.append("베기만의 상대가 단발 베기 하나가 아니다")
	# 결투에서 돌아와도 고른 것이 남는다.
	toggle.button_pressed = true
	select.free()
	select = (load(SELECT_PATH) as PackedScene).instantiate()
	_tree.root.add_child(select)
	toggle = select.find_child("PartCounterToggle", true, false) as Button
	if toggle == null or not toggle.button_pressed:
		errs.append("다시 열었을 때 켠 것이 남지 않았다")
	# 의뢰 카드로 시작하는 판에는 실리지 않는다: 카드의 상대는 하루의 상대 그대로다.
	for commission in CommissionLibrary.load_all("res://data/commissions"):
		if commission.opponent != null and commission.opponent.part_effects != null:
			errs.append("%s의 상대에 part_effects가 있다" % commission.client_name)
	select.free()
	SelectScript._part_effects = false
	return _result(errs)
