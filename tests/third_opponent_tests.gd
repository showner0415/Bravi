extends RefCounted
## T93·T94: 셋째 상대 로렌초(계획 037·037b). 공격 밖의 판정 값이 바르톨로와 같다(결정 438), 그림 데이터가 온전하다(결정 442), 비토리오의 의뢰만 건다(결정 461).
## T94는 뛰어드는 찌르기(결정 450~452)와 로렌초의 공격 목록(결정 453)을 코어로 직접 돌려 본다.

const Plain := preload("res://tests/plain_opponent.gd")
const Bot := preload("res://tests/duel_bots.gd")
const DT := preload("res://scripts/duel/duel_types.gd")
const Summary := preload("res://scripts/duel/duel_summary.gd")

const BARTOLO_PATH := "res://data/opponents/opponent_01.tres"
const BRUNO_PATH := "res://data/opponents/opponent_02.tres"
const LORENZO_PATH := "res://data/opponents/opponent_03.tres"
const RULES_PATH := "res://data/duel_rules.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const DELTA := 1.0 / 60.0
const AIM_MID_THRUST := [DT.Direction.CENTER, DT.Height.MID]
const LORENZO_ART_PATH := "res://data/opponents/lorenzo_art.tres"
const LORENZO_ART_DIR := "res://assets/art/opponents/lorenzo/"
## 다를 수 있는 칸: 이름·그림·포즈(표시만이고 판정에 쓰지 않는다. 결정 291·438). 공격 목록은 견줄 때마다 skip으로 따로 뺀다(결정 458).
const FREE_FIELDS := ["display_name", "art", "idle_pose", "stagger_pose", "complacent_pose",
	"tell_pose", "hold_arm_deg", "strike_pose", "recover_arm_deg"]
## 검술 데이터(공격 목록과 같은 갈래): 상대마다 다르다. 결정 425의 "공격 목록 밖의 판정 값"이 아니다(계획 040).
const SWORD_FIELDS := ["style_name", "tiers"]
const PARTS := ["legs", "torso", "head", "head_oops", "head_dizzy", "hat", "feather", "arm", "hand", "sword"]
## 자른 그림의 크기(작업 4·5의 출력).
const SIZES := {
	"head": Vector2i(235, 265), "head_oops": Vector2i(235, 265), "head_dizzy": Vector2i(234, 265), "hat": Vector2i(348, 105),
	"feather": Vector2i(166, 57), "torso": Vector2i(206, 367), "legs": Vector2i(239, 331), "arm": Vector2i(90, 259),
	"hand": Vector2i(90, 81), "sword": Vector2i(133, 388), "arm_up_sword": Vector2i(154, 554), "arm_up": Vector2i(104, 268),
	"arm_up_fist": Vector2i(131, 140), "arm_thrust": Vector2i(250, 136), "arm_thrust_fist": Vector2i(250, 236), "arm_thrust_sword": Vector2i(257, 261),
	"arm_thrust_blade": Vector2i(69, 66), "arm_aim": Vector2i(177, 216), "arm_aim_fist": Vector2i(177, 181), "arm_aim_sword": Vector2i(187, 187),
	"arm_aim_blade": Vector2i(109, 116),
}

var _tree: SceneTree


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T93", "name": "셋째 상대: 공격 밖의 판정 값이 바르톨로와 같다, 그림 데이터가 온전하다, 비토리오의 의뢰만 건다(결정 461)", "fn": t93_third_opponent},
		{"id": "T94", "name": "뛰어드는 찌르기: 멀리까지 물러서면 헛치고 교전에, 막으면 밀착에. 로렌초의 단발은 바르톨로와 같다", "fn": t94_dive},
	]


func cleanup() -> void:
	_tree = null


## 스크립트 칸을 하나씩 견준다. 자원은 같은 규칙으로 들어가 견주고, 배열은 원소마다 견준다.
func _compare(a: Variant, b: Variant, path: String, errs: Array[String], skip: Array) -> void:
	if a is Resource and b is Resource:
		for prop in (a as Resource).get_property_list():
			if not (int(prop["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE):
				continue
			var field: String = prop["name"]
			if skip.has(field):
				continue
			_compare((a as Resource).get(field), (b as Resource).get(field), path + "." + field, errs, skip)
	elif a is Array and b is Array:
		if (a as Array).size() != (b as Array).size():
			errs.append("%s: 원소 %d개 (바르톨로 %d개)" % [path, (b as Array).size(), (a as Array).size()])
			return
		for i in (a as Array).size():
			_compare(a[i], b[i], "%s[%d]" % [path, i], errs, skip)
	elif typeof(a) != typeof(b) or a != b:
		errs.append("%s: %s (바르톨로 %s)" % [path, str(b), str(a)])


func _check_art(art: OpponentArt, errs: Array[String]) -> void:
	var bartolo := (load(BARTOLO_PATH) as OpponentData).art
	for part_name: String in PARTS:
		var part := art.get(part_name) as PartArt
		if part == null or part.texture == null or not part.texture.resource_path.begins_with(LORENZO_ART_DIR):
			errs.append("그림 %s: 없거나 로렌초의 폴더가 아님" % part_name)
		elif part.units_per_px.x <= 0.0 or part.units_per_px.y <= 0.0:
			errs.append("그림 %s: units_per_px %s" % [part_name, part.units_per_px])
	if art.arm_arts.size() != bartolo.arm_arts.size():
		errs.append("따로 그린 팔 %d개 (바르톨로 %d개)" % [art.arm_arts.size(), bartolo.arm_arts.size()])
		return
	for i in art.arm_arts.size():
		var mine := art.arm_arts[i]
		var his := bartolo.arm_arts[i]
		if mine.key != his.key or not is_equal_approx(mine.rotation_deg, his.rotation_deg) or mine.layers.size() != his.layers.size():
			errs.append("팔 %s: 키·회전·층 수가 바르톨로(%s)와 다름" % [mine.key, his.key])
			continue
		for k in mine.layers.size():
			var layer := mine.layers[k]
			if layer.part != his.layers[k].part or layer.texture == null or not layer.texture.resource_path.begins_with(LORENZO_ART_DIR):
				errs.append("팔 %s 층 %d: part·그림이 어긋남" % [mine.key, k])
			elif (layer.part == 4) != (layer.outline.size() >= 6):
				errs.append("팔 %s 층 %d: 주먹의 윤곽선이 없거나 주먹이 아닌데 있음" % [mine.key, k])
	if art.hand.outline.size() < 6:
		errs.append("손의 윤곽선이 없음")
	for file: String in SIZES:
		var tex := load(LORENZO_ART_DIR + file + ".png") as Texture2D
		if tex == null or Vector2i(tex.get_size()) != SIZES[file]:
			errs.append("%s.png의 크기 %s (기대 %s)" % [file, Vector2i(tex.get_size()) if tex != null else Vector2i.ZERO, SIZES[file]])


func t93_third_opponent() -> String:
	var errs: Array[String] = []
	var bartolo := load(BARTOLO_PATH) as OpponentData
	var lorenzo := load(LORENZO_PATH) as OpponentData
	if lorenzo == null or lorenzo.art == null:
		return "opponent_03.tres나 그 그림이 없음"
	if lorenzo.display_name != "로렌초" or lorenzo.display_name == bartolo.display_name:
		errs.append("이름 '%s'" % lorenzo.display_name)
	if lorenzo.art.resource_path != LORENZO_ART_PATH:
		errs.append("그림 데이터 %s" % lorenzo.art.resource_path)
	_compare(bartolo, lorenzo, "opponent", errs, FREE_FIELDS + ["attacks"] + SWORD_FIELDS)
	_check_art(lorenzo.art, errs)
	var all: Array[Commission] = CommissionLibrary.load_all("res://data/commissions")
	all.append_array(CommissionLibrary.load_all("res://data/commissions/variants"))
	var lorenzo_commissions: Array[String] = []
	for c in all:
		if c.opponent != null and c.opponent.resource_path == LORENZO_PATH:
			lorenzo_commissions.append(c.resource_path.get_file())
	if lorenzo_commissions != ["first_blood_usurer.tres"]:
		errs.append("로렌초를 거는 의뢰 %s (기대 first_blood_usurer.tres 하나)" % str(lorenzo_commissions))
	return "OK" if errs.is_empty() else ", ".join(errs)


func _atk_has_dive(atk: AttackData) -> bool:
	if atk == null:
		return false
	if atk.dive:
		return true
	for sub: Array in [atk.chain, atk.variants]:
		for item in sub:
			if _atk_has_dive(item as AttackData):
				return true
	return false


func _opponent_has_dive(opp: OpponentData) -> bool:
	for atk in opp.attacks:
		if _atk_has_dive(atk):
			return true
	for habit in opp.habits:
		if _atk_has_dive(habit.response):
			return true
	return false


## 공격 하나만 되풀이하는 상대(대기 1.0초 고정). 로드한 자원은 고치지 않는다.
func _drill(opp: OpponentData, atk: AttackData, chance: float) -> OpponentData:
	var copy := opp.drill(atk)
	copy.opening_chance = chance
	copy.idle_time_min = 1.0
	copy.idle_time_max = 1.0
	return copy


## 바닥 0의 규칙 사본이면 확률 0.0이 굴림으로 절대 안 열린다(바닥 0.4가 굴림을 자르지 않게. opening_chance_tests의 _rules와 같은 까닭).
func _rules(floor_zero := false) -> DuelRules:
	var rules := (load(RULES_PATH) as DuelRules).duplicate() as DuelRules
	if floor_zero:
		rules.opening_chance_floor = 0.0
	return rules


## 0초에 한 걸음 들어가 교전에서 시작한다. 엉킴을 끈 무기라 밀착에서 밀려나는 일이 판을 흔들지 않는다.
func _play(opp: OpponentData, rules: DuelRules, cfg: Dictionary, stop: Callable, until := 20.0, on_tick := Callable()) -> DuelCore:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var weapon := (load(WEAPON_PATH) as WeaponData).duplicate() as WeaponData
	weapon.close_bind_time = 0.0
	var core := DuelCore.new()
	var none: Array[CommissionCondition] = []
	core.setup(rules, weapon, opp, rng, none, false)
	var bot := Bot.new(core, cfg)
	core.step(1)
	while not core.ended and core.time < until:
		core.tick(DELTA)
		if on_tick.is_valid():
			on_tick.call(core)
		bot.update()
		if stop.call(core):
			break
	return core


func _stop_strikes(count: int) -> Callable:
	return func(core: DuelCore) -> bool: return core.record.of_type(DuelRecord.STRIKE).size() >= count


func _stop_attacks(count: int) -> Callable:
	return func(core: DuelCore) -> bool: return core.record.of_type(DuelRecord.ATTACK).size() >= count


func _mode(mode: StringName) -> Callable:
	return func(_a: AttackData, _i: int) -> StringName: return mode


## 상대가 뛰어들어 좁힌 간격 이동들.
func _dives(core: DuelCore) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for ev in core.record.of_type(DuelRecord.DISTANCE):
		if ev["by"] == "dive":
			out.append(ev)
	return out


func _first(core: DuelCore, type: StringName) -> Dictionary:
	var all := core.record.of_type(type)
	return all[0] if not all.is_empty() else {}


func t94_dive() -> String:
	var errs: Array[String] = []
	var SR := DT.StrikeResult
	var bartolo := load(BARTOLO_PATH) as OpponentData
	var bruno := load(BRUNO_PATH) as OpponentData
	var lorenzo := load(LORENZO_PATH) as OpponentData
	if lorenzo == null or lorenzo.attacks.size() != 4:
		return "로렌초의 공격이 넷이 아님"
	# 1. 공격 목록: 단발 셋은 바르톨로와 판정이 같고 높이만 다르다. 넷째가 뛰어들기다.
	var heights := [[0, 1, 2], [1], [1]]
	for i in 3:
		var mine := lorenzo.attacks[i]
		var his := bartolo.attacks[i]
		if mine.attack_name != his.attack_name or mine.direction != his.direction or not is_equal_approx(mine.tell_time, his.tell_time) \
				or not is_equal_approx(mine.recovery_time, his.recovery_time) or not is_equal_approx(mine.weight, his.weight) \
				or mine.is_big != his.is_big or mine.needs_raised_guard != his.needs_raised_guard or not mine.chain.is_empty() or mine.dive:
			errs.append("공격 %d(%s)가 바르톨로의 %s와 판정이 다름" % [i + 1, mine.attack_name, his.attack_name])
		if str(mine.heights) != str(heights[i]):
			errs.append("공격 %d의 높이 %s (기대 %s)" % [i + 1, str(mine.heights), str(heights[i])])
	var dive := lorenzo.attacks[3]
	if not dive.dive or not dive.chain.is_empty() or dive.needs_raised_guard or dive.is_big or dive.direction != DT.Direction.CENTER \
			or not is_equal_approx(dive.tell_time, 1.2) or not is_equal_approx(dive.recovery_time, 1.6) or not is_equal_approx(dive.weight, 3.0) \
			or dive.tell_time < 0.75 or str(dive.heights) != str([1, 2]):
		errs.append("넷째 공격이 결정 452의 뛰어들기가 아님: %s" % dive.attack_name)
	if _opponent_has_dive(bartolo) or _opponent_has_dive(bruno):
		errs.append("바르톨로나 브루노의 공격에 뛰어들기가 있음")
	var whiff_recovery := dive.recovery_time * lorenzo.whiff_recovery_multiplier
	var close_tell := dive.tell_time * lorenzo.close_tell_multiplier
	var plain_rules := _rules()
	var max_posture := plain_rules.player_posture_max

	# 2. 교전에서 들고 막기: 막힘, 긴 회수, 밀착으로 밀고 들어온다.
	var blocked := _play(_drill(lorenzo, dive, 1.0), plain_rules, {}, _stop_strikes(1))
	var strike := _first(blocked, DuelRecord.STRIKE)
	var moves := _dives(blocked)
	if strike.is_empty() or strike["result"] != SR.BLOCKED or absf(float(strike["recovery"]) - dive.recovery_time) > 0.01:
		errs.append("[막기] 타격 %s (기대 막힘 · 회수 %.2f)" % [str(strike.get("result")), dive.recovery_time])
	elif moves.size() != 1 or moves[0]["distance"] != DT.Distance.CLOSE or absf(float(moves[0]["t"]) - float(strike["t"])) > 1e-6:
		errs.append("[막기] 뛰어들기 이동 %s (기대 타격과 같은 시각의 밀착 하나)" % str(moves))

	# 3. 교전에서 물러서기: 헛침, 짧은 회수, 교전에 떨어지고, 그 빈틈에 내 공격이 스침이다.
	var press_mid := func(_ev: Dictionary) -> Variant: return AIM_MID_THRUST
	var retreat_cfg := {"guard_fn": _mode(&"retreat"), "whiff_fn": press_mid}
	var away := _play(_drill(lorenzo, dive, 1.0), plain_rules, retreat_cfg, _stop_attacks(1))
	strike = _first(away, DuelRecord.STRIKE)
	moves = _dives(away)
	var counter := _first(away, DuelRecord.ATTACK)
	if strike.is_empty() or strike["result"] != SR.WHIFF or absf(float(strike["recovery"]) - whiff_recovery) > 0.01:
		errs.append("[물러서기] 타격 %s (기대 헛침 · 회수 %.2f)" % [str(strike.get("result")), whiff_recovery])
	elif moves.size() != 1 or moves[0]["distance"] != DT.Distance.ENGAGE or absf(float(moves[0]["t"]) - float(strike["t"])) > 1e-6:
		errs.append("[물러서기] 뛰어들기 이동 %s (기대 타격과 같은 시각의 교전 하나)" % str(moves))
	if counter.is_empty() or counter["result"] != DT.AttackResult.GRAZE:
		errs.append("[물러서기] 헛친 빈틈 안의 내 공격 %s (기대 스침)" % str(counter.get("result")))

	# 4. 늦은 물러서기: 타격 0.1초 전의 걸음은 타격 때 아직 걷는 중이라 무방비로 스침을 맞고, 간격은 내 걸음이 정한다.
	var stepped := [false]
	var late_step := func(core: DuelCore) -> void:
		if not stepped[0] and core.brain.state == DT.OpponentState.TELL and core.time >= core.brain.state_end - 0.1:
			stepped[0] = true
			core.step(-1)
	var stop_after_step := func(core: DuelCore) -> bool:
		var all := core.record.of_type(DuelRecord.STRIKE)
		return not all.is_empty() and core.time >= float(all[0]["t"]) + 0.4
	var late := _play(_drill(lorenzo, dive, 1.0), plain_rules, {"guard_fn": _mode(&"none")}, stop_after_step, 20.0, late_step)
	strike = _first(late, DuelRecord.STRIKE)
	if strike.is_empty() or strike["result"] != SR.GRAZE or strike["situation"] != DT.Situation.UNGUARDED \
			or int(strike["player_posture"]) != max_posture - 1:
		errs.append("[늦은 물러서기] 타격 %s (기대 무방비 스침 · 내 자세 %d)" % [str(strike), max_posture - 1])
	if not _dives(late).is_empty() or late.distance != DT.Distance.FAR:
		errs.append("[늦은 물러서기] 뛰어들기 이동 %d개 · 걸음 뒤 간격 %d (기대 0개 · 멀리)" % [_dives(late).size(), late.distance])

	# 5. 밀착에서 시작: 예비가 짧고, 막으면 간격이 그대로, 한 걸음 물러서면 교전이라 스침을 맞은 뒤 밀착으로 밀고 든다.
	var near_cfg := {"want_distance": DT.Distance.CLOSE}
	var near := _play(_drill(lorenzo, dive, 1.0), plain_rules, near_cfg, _stop_strikes(1))
	var tell := _first(near, DuelRecord.TELL_START)
	strike = _first(near, DuelRecord.STRIKE)
	if tell.is_empty() or absf(float(tell["duration"]) - close_tell) > 1e-6:
		errs.append("[밀착] 예비 길이 %s (기대 %.2f)" % [str(tell.get("duration")), close_tell])
	if strike.is_empty() or strike["result"] != SR.BLOCKED or not _dives(near).is_empty() or near.distance != DT.Distance.CLOSE:
		errs.append("[밀착·막기] 타격 %s · 이동 %d개 · 간격 %d (기대 막힘 · 0개 · 밀착)" % [str(strike.get("result")), _dives(near).size(), near.distance])
	near_cfg["guard_fn"] = _mode(&"retreat")
	var near_back := _play(_drill(lorenzo, dive, 1.0), plain_rules, near_cfg, _stop_strikes(1))
	strike = _first(near_back, DuelRecord.STRIKE)
	moves = _dives(near_back)
	if strike.is_empty() or strike["result"] != SR.GRAZE or int(strike["player_posture"]) != max_posture - 1:
		errs.append("[밀착·물러서기] 타격 %s (기대 교전에서 스침 · 내 자세 %d)" % [str(strike), max_posture - 1])
	elif moves.size() != 1 or moves[0]["distance"] != DT.Distance.CLOSE or absf(float(moves[0]["t"]) - float(strike["t"])) > 1e-6:
		errs.append("[밀착·물러서기] 뛰어들기 이동 %s (기대 타격과 같은 시각의 밀착 하나)" % str(moves))

	# 6. 확률: 안 열린 헛침은 회수 0이고 요약·기록 줄이 막기로 읽지 않으며, 그 뒤 0.6초 안의 내 공격은 섣부른 공격이 아니다. 다른 공격은 그대로다.
	var closed_core := _play(_drill(lorenzo, dive, 0.0), _rules(true), retreat_cfg, _stop_attacks(1))
	strike = _first(closed_core, DuelRecord.STRIKE)
	if strike.is_empty() or strike["result"] != SR.WHIFF or strike["closed"] != true or not is_zero_approx(float(strike["recovery"])):
		errs.append("[확률 0] 타격 %s (기대 헛침 · closed · 회수 0)" % str(strike))
	else:
		var grace := _first(closed_core, DuelRecord.ATTACK)
		if grace.is_empty() or grace["rash"] != false or int(grace["posture_gain"]) != 0 or grace["result"] != DT.AttackResult.BLOCKED:
			errs.append("[확률 0] 안 열린 헛침 직후의 내 공격 %s (기대 섣부르지 않은 막힘 · 자세 안 돌려줌)" % str(grace))
		var summary := Summary.summarize(closed_core.record)
		var guards: Dictionary = summary["guards"]
		if int(guards["열림"]) != 0 or int(guards["안 열림"]) != 0 or int(summary["strikes"]["헛침"]) != 1:
			errs.append("[확률 0] 요약 guards %s · 헛침 %s (기대 둘 다 0 · 헛침 1)" % [str(guards), str(summary["strikes"]["헛침"])])
		var hud := DuelHud.new()
		var line := hud._describe(strike)
		hud.free()
		if not line.begins_with("헛침 — 틈을 안 줬다") or line.contains("막음"):
			errs.append("[확률 0] 기록 줄 \"%s\"" % line)
	var cut := bartolo.attacks[1]
	var cut_whiff := _play(_drill(bartolo, cut, 1.0), plain_rules, {"guard_fn": _mode(&"retreat")}, _stop_strikes(1))
	strike = _first(cut_whiff, DuelRecord.STRIKE)
	var cut_recovery := cut.recovery_time * bartolo.whiff_recovery_multiplier
	if strike.is_empty() or strike["result"] != SR.WHIFF or absf(float(strike["recovery"]) - cut_recovery) > 0.01 \
			or not _dives(cut_whiff).is_empty() or cut_whiff.distance != DT.Distance.FAR:
		errs.append("[다른 공격의 헛침] 타격 %s · 이동 %d개 · 간격 %d (기대 헛침 · 회수 %.4f · 0개 · 멀리)" % [str(strike.get("result")), _dives(cut_whiff).size(), cut_whiff.distance, cut_recovery])

	# 7. 옛 규칙 사본: 뛰어들기를 버려 바르톨로의 사본과 판정이 같다(높이는 꺼져 있다).
	var plain_lorenzo := Plain.of(lorenzo)
	if plain_lorenzo.attacks.size() != 3 or _opponent_has_dive(plain_lorenzo):
		errs.append("옛 규칙 사본의 공격 %d개 (기대 뛰어들기 없는 3개)" % plain_lorenzo.attacks.size())
	_compare(Plain.of(bartolo), plain_lorenzo, "plain", errs, FREE_FIELDS + ["heights"] + SWORD_FIELDS)

	# 8. 안내.
	var help := DuelHud.help_text(lorenzo)
	if not help.contains(DuelHud.HELP_DIVE) or help.contains(DuelHud.HELP_CHAIN):
		errs.append("로렌초의 막는 법: 뛰어들기 글 %s · 이어 베기 글 %s" % [help.contains(DuelHud.HELP_DIVE), help.contains(DuelHud.HELP_CHAIN)])
	for other: OpponentData in [bartolo, bruno]:
		if DuelHud.help_text(other).contains(DuelHud.HELP_DIVE):
			errs.append("%s의 막는 법에 뛰어들기 글이 있음" % other.display_name)

	# 9. 실제 로렌초(1일차 확률, 들고 막는 봇, 60초): 뛰어들기가 나오고 간격을 좁힌다.
	var day_rules := _rules()
	day_rules.stage_day = 1
	var never := func(_core: DuelCore) -> bool: return false
	var long_run := _play(lorenzo, day_rules, {}, never, 60.0)
	var dive_tells := 0
	for ev in long_run.record.of_type(DuelRecord.TELL_START):
		if (ev["attack"] as AttackData).dive:
			dive_tells += 1
	if dive_tells < 1 or _dives(long_run).is_empty():
		errs.append("[실제 로렌초] 60초 동안 뛰어들기 예비 %d번 · 좁힘 %d번 (각각 1 이상 기대)" % [dive_tells, _dives(long_run).size()])
	return "OK" if errs.is_empty() else ", ".join(errs)
