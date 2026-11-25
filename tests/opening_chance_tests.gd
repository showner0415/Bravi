extends RefCounted
## T86~T88: 빈틈이 될 확률(계획 036c). 판정, 굴림·셈·회귀, 날·업그레이드·연습·글.
## 판 돌리기는 pattern_tests.gd의 상대 만들기(대기 1.0초)를 쓰고, 규칙만 사본을 받는다.
## T86은 난수에 기대지 않는다: 상대의 확률 0.0(굴림으로는 절대 안 열림)에 상한과 패리 덤만으로 차례를 만든다.

const Patterns := preload("res://tests/pattern_tests.gd")
const Bot := preload("res://tests/duel_bots.gd")
const DT := preload("res://scripts/duel/duel_types.gd")
const Summary := preload("res://scripts/duel/duel_summary.gd")
const Session := preload("res://scripts/game_session.gd")
const Title := preload("res://scripts/title.gd")

const RULES_PATH := "res://data/duel_rules.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const CATALOG_PATH := "res://data/upgrade_catalog.tres"
const DAY_OPPONENTS: Array[String] = ["res://data/opponents/opponent_01.tres", "res://data/opponents/opponent_02.tres"]
const TRIAL_PATHS: Array[String] = [
	"res://data/opponents/trial/bartolo_patterns.tres",
	"res://data/opponents/trial/bruno_patterns.tres",
]
const DELTA := 1.0 / 60.0

var _tree: SceneTree
var _p := Patterns.new()


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T86", "name": "빈틈의 확률 판정: 상한, 패리 덤, 걸리지 않는 것, 패턴은 끝에서, 봐주기, 버릇", "fn": t86_rules},
		{"id": "T87", "name": "빈틈의 확률 굴림·셈: 날의 배율과 바닥, 예비 동작마다 한 번, 1.0이면 난수 불변, 몫", "fn": t87_rolls},
		{"id": "T88", "name": "빈틈의 확률의 길: 하루의 날, 업그레이드 칸, 하루 데이터 그대로, 연습의 날 버튼, 글, 요약", "fn": t88_paths},
		{"id": "T89", "name": "빈틈의 확률을 하루에: 하루의 상대 값, 규칙의 값, 물건, 날과 물건이 뇌까지, 글", "fn": t89_day_values},
	]


func cleanup() -> void:
	_tree = null
	_p = null


## 바닥 0의 규칙 사본. 덤을 바꿀 수 있다.
func _rules(parry_bonus := 0.25) -> DuelRules:
	var rules := (load(RULES_PATH) as DuelRules).duplicate() as DuelRules
	rules.opening_chance_floor = 0.0
	rules.parry_opening_bonus = parry_bonus
	return rules


func _opp(pattern: AttackData, chance: float, limit: int) -> OpponentData:
	var o: OpponentData = _p._opp(pattern)
	o.opening_chance = chance
	o.opening_miss_limit = limit
	return o


func _cut(recovery := 0.55) -> AttackData:
	return _p._atk(DT.Direction.RIGHT, 0.9, recovery)


func _core(opp: OpponentData, rules: DuelRules) -> DuelCore:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var weapon := (load(WEAPON_PATH) as WeaponData).duplicate() as WeaponData
	weapon.close_bind_time = 0.0
	var core := DuelCore.new()
	var none: Array[CommissionCondition] = []
	core.setup(rules, weapon, opp, rng, none, false)
	return core


func _run(opp: OpponentData, rules: DuelRules, cfg: Dictionary, until: float) -> DuelCore:
	var core := _core(opp, rules)
	var bot := Bot.new(core, cfg)
	core.step(1)
	while not core.ended and core.time < until:
		core.tick(DELTA)
		bot.update()
	return core


func _mode(mode: StringName) -> Callable:
	return func(_a: AttackData, _i: int) -> StringName: return mode


func _strikes(core: DuelCore) -> Array[Dictionary]:
	return core.record.of_type(DuelRecord.STRIKE)


func _key_list(strikes: Array[Dictionary], key: String, count: int) -> Array:
	var out: Array = []
	for i in mini(count, strikes.size()):
		out.append(strikes[i].get(key))
	return out


func t86_rules() -> String:
	var errs: Array[String] = []
	var SR := DT.StrikeResult
	# 1. 단발 베기, 확률 0.0, 상한 2: 안·안·열림이 되풀이된다.
	var core := _run(_opp(_cut(), 0.0, 2), _rules(), {}, 30.0)
	var strikes := _strikes(core)
	if strikes.size() < 6:
		return "타격이 %d번뿐 (기대 6번 이상)" % strikes.size()
	if _key_list(strikes, "closed", 6) != [true, true, false, true, true, false]:
		errs.append("상한 2의 closed: %s" % str(_key_list(strikes, "closed", 6)))
	if _key_list(strikes, "closed_streak", 6) != [1, 2, 0, 1, 2, 0] or _key_list(strikes, "miss_limit", 1) != [2]:
		errs.append("연속 수: %s" % str(_key_list(strikes, "closed_streak", 6)))
	for i in 6:
		var want := 0.0 if strikes[i]["closed"] else 0.55
		if strikes[i]["result"] != SR.BLOCKED or not is_equal_approx(float(strikes[i]["recovery"]), want):
			errs.append("%d번째: 결과 %d · 회수 %.2f (기대 막힘 · %.2f)" % [i + 1, strikes[i]["result"], float(strikes[i]["recovery"]), want])
	# 2. 상한 0이면 늘 안 열리고, 확률 1.0이면 늘 열린다.
	var no_limit := _strikes(_run(_opp(_cut(), 0.0, 0), _rules(), {}, 30.0))
	var always := _strikes(_run(_opp(_cut(), 1.0, 2), _rules(), {}, 30.0))
	if _key_list(no_limit, "closed", 6) != [true, true, true, true, true, true]:
		errs.append("상한 0: %s" % str(_key_list(no_limit, "closed", 6)))
	if _key_list(always, "closed", 6) != [false, false, false, false, false, false]:
		errs.append("확률 1.0: %s" % str(_key_list(always, "closed", 6)))
	# 3. 패리의 덤: 덤 1.0이면 패리는 늘 열리고 들고 막기는 늘 안 열린다. 덤 0.0이면 패리도 안 열린다.
	var parry := _strikes(_run(_opp(_cut(), 0.0, 0), _rules(1.0), {"guard_fn": _mode(&"parry")}, 20.0))
	var held := _strikes(_run(_opp(_cut(), 0.0, 0), _rules(1.0), {}, 20.0))
	var parry_none := _strikes(_run(_opp(_cut(), 0.0, 0), _rules(0.0), {"guard_fn": _mode(&"parry")}, 20.0))
	if parry.size() < 3 or _key_list(parry, "result", 3) != [SR.PARRIED, SR.PARRIED, SR.PARRIED] or _key_list(parry, "closed", 3) != [false, false, false]:
		errs.append("덤 1.0의 패리: %s" % str(_key_list(parry, "closed", 3)))
	if _key_list(held, "closed", 3) != [true, true, true]:
		errs.append("덤 1.0의 들고 막기: %s" % str(_key_list(held, "closed", 3)))
	if _key_list(parry_none, "closed", 3) != [true, true, true]:
		errs.append("덤 0.0의 패리: %s" % str(_key_list(parry_none, "closed", 3)))
	# 4. 걸리지 않는 것: 막힌 찌르기(회수 0), 버티기, 헛침.
	var thrust := _strikes(_run(_opp(_p._atk(DT.Direction.CENTER, 0.9, 0.0), 0.0, 2), _rules(), {}, 20.0))
	if thrust.is_empty() or _key_list(thrust, "closed", 3) != [false, false, false] or _key_list(thrust, "closed_streak", 3) != [0, 0, 0]:
		errs.append("막힌 찌르기: %s" % str(_key_list(thrust, "closed", 3)))
	var big := _cut(1.6)
	big.is_big = true
	big.needs_raised_guard = true
	# 버티기는 예비 동작 전부터 든 막기여야 한다: T79처럼 guard_at으로 먼저 든다(기본 규칙이라 확률은 바닥 0.4지만 버티기는 굴리지 않는다).
	var braced: Array[Dictionary] = _p._run(_opp(big, 0.0, 0), {"guard_fn": _mode(&"keep"), "guard_at": 1.0}, 2.5).record.of_type(DuelRecord.STRIKE)
	if braced.is_empty() or not braced[0]["braced"] or braced[0]["closed"]:
		errs.append("버티기: %s" % str(braced.slice(0, 1)))
	var whiff := _strikes(_run(_opp(_cut(), 0.0, 0), _rules(), {"guard_fn": _mode(&"retreat")}, 8.0))
	if whiff.is_empty() or whiff[0]["result"] != SR.WHIFF or float(whiff[0]["recovery"]) <= 0.0 or whiff[0]["closed"]:
		errs.append("헛침: %s" % str(whiff.slice(0, 1)))
	# 5. 패턴은 끝에서 한 번만 본다.
	for pattern: AttackData in [_p._chain(), _p._sweep()]:
		var steps := _strikes(_run(_opp(pattern, 0.0, 0), _rules(), {}, 6.0))
		if steps.size() < 3 or _key_list(steps, "closed", 3) != [false, false, true] \
				or float(steps[0]["next_strike"]) < 0.0 or float(steps[1]["next_strike"]) < 0.0:
			errs.append("패턴(휩쓸기 %s): %s" % [pattern.sweep, str(_key_list(steps, "closed", 3))])
	_check_grace(errs)
	# 7. 버릇: 안 열린 막힘도 연속 막힘으로 센다.
	var habit_opp := _opp(_cut(), 0.0, 0)
	var habit := HabitData.new()
	habit.count = 3
	habit.response = _p._atk(DT.Direction.LEFT, 0.9, 1.6)
	var habits: Array[HabitData] = [habit]
	habit_opp.habits = habits
	var tells := _run(habit_opp, _rules(), {}, 15.0).record.of_type(DuelRecord.TELL_START)
	if tells.size() < 4 or tells[3]["is_habit"] != true:
		errs.append("넷째 예비 동작이 버릇 반응이 아님 (%d번)" % tells.size())
	return "OK" if errs.is_empty() else ", ".join(errs)


## 6. 봐주기(결정 402): 막기만 든 채로 돌리다가 첫 타격 뒤 lead초에 가운데 중단을 찌른다. 공격 판정 이벤트를 돌려준다.
func _press_after_strike(chance: float, lead: float) -> Dictionary:
	var core := _core(_opp(_cut(), chance, 0), _rules())
	core.step(1)
	core.set_aim(DT.Direction.RIGHT, DT.Height.MID)
	core.set_guard(true)
	var pressed_at := INF
	while not core.ended and core.time < 10.0:
		core.tick(DELTA)
		var strikes := _strikes(core)
		if pressed_at == INF and not strikes.is_empty() and core.time >= float(strikes[0]["t"]) + lead:
			pressed_at = core.time
			core.set_guard(false)
			core.set_aim(DT.Direction.CENTER, DT.Height.MID)
			core.press_attack()
		var attacks := core.record.of_type(DuelRecord.ATTACK)
		if not attacks.is_empty():
			return attacks[0]
	return {}


func _check_grace(errs: Array[String]) -> void:
	var soon := _press_after_strike(0.0, 0.1)
	if soon.is_empty() or soon["rash"] or soon["result"] != DT.AttackResult.BLOCKED or int(soon["posture_gain"]) != 0:
		errs.append("안 열린 뒤 0.1초의 반격: %s" % str(soon))
	var late := _press_after_strike(0.0, 0.7)
	if late.is_empty() or not late["rash"]:
		errs.append("안 열린 뒤 0.7초의 공격이 섣부르지 않음: %s" % str(late))
	var opened := _press_after_strike(1.0, 0.1)
	if opened.is_empty() or opened["result"] != DT.AttackResult.GRAZE:
		errs.append("열린 뒤 0.1초의 반격이 스침이 아님: %s" % str(opened))


func t87_rolls() -> String:
	var errs: Array[String] = []
	# 1. 셈: 날의 배율, 바닥, 꺼짐, 덤, 빈 배열.
	var rules := load(RULES_PATH) as DuelRules
	var bonus := rules.duplicate() as DuelRules
	bonus.opening_chance_bonus = 0.15
	var flat_scale := rules.duplicate() as DuelRules
	var none: Array[float] = []
	flat_scale.opening_day_scale = none
	var table := [
		[rules, 0.8, 0, 0.8], [rules, 0.8, 2, 0.72], [rules, 0.8, 3, 0.64], [rules, 0.8, 9, 0.64],
		[rules, 1.0, 3, 1.0], [rules, 0.3, 3, 0.4], [bonus, 0.8, 3, 0.79], [flat_scale, 0.8, 3, 0.8],
	]
	for row: Array in table:
		var got := (row[0] as DuelRules).opening_chance_for(row[1], row[2])
		if not is_equal_approx(got, row[3]):
			errs.append("(%.2f, %d일차) = %.3f (기대 %.2f)" % [row[1], row[2], got, row[3]])
	# 2. 굴림은 예비 동작마다 한 번: 확률 1.0인 뇌의 rng를 한 번 더 부르면 0.5인 뇌의 rng와 같은 자리에 선다.
	var rng_half := RandomNumberGenerator.new()
	var rng_full := RandomNumberGenerator.new()
	rng_half.seed = 5
	rng_full.seed = 5
	var half := OpponentBrain.new(_opp(_cut(), 0.5, 0), rng_half)
	half.opening_chance = 0.5
	var full := OpponentBrain.new(_opp(_cut(), 1.0, 0), rng_full)
	half.start_tell(0.0, false)
	full.start_tell(0.0, false)
	rng_full.randf()
	if rng_half.randf() != rng_full.randf():
		errs.append("확률 0.5의 예비 동작이 난수를 한 번이 아니게 부름")
	# 3. 난수 불변: 확률 1.0인 상대는 날과 덤이 실린 규칙에서도 시각이 같고 한 번도 닫히지 않는다.
	var loaded := (load(RULES_PATH) as DuelRules).duplicate() as DuelRules
	loaded.stage_day = 3
	loaded.opening_chance_bonus = 0.3
	var plain_opp := _opp(_cut(), 1.0, 2)
	plain_opp.idle_time_max = 1.6
	var a := _run(plain_opp, load(RULES_PATH), {}, 20.0)
	var b := _run(plain_opp, loaded, {}, 20.0)
	var times := func(core: DuelCore, type: StringName) -> Array[float]: return _p._times(core.record.of_type(type))
	if times.call(a, DuelRecord.TELL_START) != times.call(b, DuelRecord.TELL_START) \
			or times.call(a, DuelRecord.STRIKE) != times.call(b, DuelRecord.STRIKE) or times.call(a, DuelRecord.STRIKE).size() < 5:
		errs.append("확률 1.0인 상대의 시각이 규칙에 따라 다름")
	if b.record.count_where(DuelRecord.STRIKE, "closed", true) > 0:
		errs.append("확률 1.0인 상대가 닫힘")
	# 4. 몫: 확률 0.5·상한 0이면 열린 몫이 0.4~0.6, 상한 2면 셋 연달아 닫히지 않는다, 같은 시드는 같은 열.
	var first := _shares(0.5, 0, 9)
	var again := _shares(0.5, 0, 9)
	var share := float(first.count(true)) / first.size()
	if share < 0.4 or share > 0.6:
		errs.append("확률 0.5의 열린 몫 %.2f" % share)
	if first != again:
		errs.append("같은 시드인데 열림의 열이 다름")
	var capped := _shares(0.5, 2, 9)
	for i in range(2, capped.size()):
		if not capped[i] and not capped[i - 1] and not capped[i - 2]:
			errs.append("상한 2인데 %d번째까지 셋 연달아 닫힘" % (i + 1))
			break
	return "OK" if errs.is_empty() else ", ".join(errs)


## 뇌를 직접 600번: 예비 동작 → 막힘 → (열렸으면) 대기. 열렸는가의 열.
func _shares(chance: float, limit: int, seed_value: int) -> Array[bool]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var brain := OpponentBrain.new(_opp(_cut(), chance, limit), rng)
	brain.opening_chance = chance
	var out: Array[bool] = []
	for i in 600:
		var now := float(i) * 4.0
		brain.start_tell(now, false)
		brain.resolve_strike(now + 1.0, DT.StrikeResult.BLOCKED)
		out.append(not brain.last_closed)
		if brain.state == DT.OpponentState.RECOVERY:
			brain.start_idle(now + 2.0)
	return out


func t88_paths() -> String:
	var errs: Array[String] = []
	# 1. 하루의 날이 사본에 실린다. 받은 규칙은 그대로다.
	var base := load(RULES_PATH) as DuelRules
	var day := DayState.new(EconomyRules.new(), DayData.new())
	day.day_number = 2
	var day_rules := day.effective_duel_rules(base)
	if day_rules.stage_day != 2 or base.stage_day != 0:
		errs.append("날: 사본 %d · 원본 %d (기대 2 · 0)" % [day_rules.stage_day, base.stage_day])
	# 2. 업그레이드가 올릴 칸이 있다(물건은 036d).
	var upgrade := UpgradeData.new()
	upgrade.target = UpgradeData.Target.DUEL
	upgrade.property = &"opening_chance_bonus"
	upgrade.amount = 0.15
	var upgrades: Array[UpgradeData] = [upgrade]
	var upgraded := UpgradeData.applied(base, UpgradeData.Target.DUEL, upgrades) as DuelRules
	if not is_equal_approx(upgraded.opening_chance_bonus, 0.15) or not is_equal_approx(upgraded.opening_chance_for(0.8, 3), 0.79):
		errs.append("업그레이드의 덤: %.2f · %.3f" % [upgraded.opening_chance_bonus, upgraded.opening_chance_for(0.8, 3)])
	# 3. 시험용 상대: 바닥과 1.0 사이, 사본은 원본을 고치지 않고 값을 물려받는다.
	for path in TRIAL_PATHS:
		var trial := load(path) as OpponentData
		var chance := trial.opening_chance
		if chance <= base.opening_chance_floor or chance >= 1.0:
			errs.append("%s의 확률 %.2f" % [path.get_file(), chance])
		var copy := trial.with_opening(0.3)
		if not is_equal_approx(copy.opening_chance, 0.3) or not is_equal_approx(trial.opening_chance, chance):
			errs.append("%s의 with_opening이 원본을 고침" % path.get_file())
		if not is_equal_approx(trial.flat().opening_chance, chance) or not is_equal_approx(trial.drill(trial.attacks[0]).opening_chance, chance):
			errs.append("%s의 flat·drill이 확률을 물려받지 않음" % path.get_file())
		if not DuelHud.help_text(trial).contains("틈을 안 줄 때가 있다"):
			errs.append("%s의 막는 법에 빈틈의 글이 없음" % path.get_file())
	# 4. 연습 화면: 날 버튼 넷, 처음에는 1일차만 눌려 있다(넘침은 창에서 본다).
	var select: Node = (load(Session.SELECT_PATH) as PackedScene).instantiate()
	_tree.root.add_child(select)
	for d in 4:
		var button := select.find_child("OpeningDay%d" % d, true, false) as Button
		if button == null:
			errs.append("OpeningDay%d 버튼이 없음" % d)
		elif button.button_pressed != (d == 1):
			errs.append("OpeningDay%d의 눌림 %s" % [d, button.button_pressed])
	select.free()
	# 5. 기록의 글: 안 열림과 상한.
	var hud := DuelHud.new()
	var ev := {"type": DuelRecord.STRIKE, "result": DT.StrikeResult.BLOCKED, "closed": true, "closed_streak": 1, "miss_limit": 2,
		"braced": false, "attack": _cut(), "situation": -1}
	var first := hud._describe(ev)
	ev["closed_streak"] = 2
	ev["result"] = DT.StrikeResult.PARRIED
	var second := hud._describe(ev)
	hud.free()
	if not first.contains("틈을 안 줬다") or first.contains("다음은 열린다") or not second.begins_with("패리") or not second.contains("다음은 열린다"):
		errs.append("기록의 글: \"%s\" / \"%s\"" % [first, second])
	# 6. 요약: T86의 1의 판이면 열림 2 · 안 열림 4.
	var core := _run(_opp(_cut(), 0.0, 2), _rules(), {}, 15.5)
	var guards: Dictionary = Summary.summarize(core.record)["guards"]
	var closed := core.record.count_where(DuelRecord.STRIKE, "closed", true)
	if int(guards["안 열림"]) != closed or int(guards["열림"]) + closed != _strikes(core).size() or closed < 2:
		errs.append("요약의 guards %s (타격 %d · 닫힘 %d)" % [str(guards), _strikes(core).size(), closed])
	return "OK" if errs.is_empty() else ", ".join(errs)


## 하루의 상대에 실은 확률이 날과 물건을 거쳐 뇌까지 닿았을 때의 값.
func _brain_chance(day: DayState, base: DuelRules, opp: OpponentData) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var core := DuelCore.new()
	var none: Array[CommissionCondition] = []
	core.setup(day.effective_duel_rules(base), load(WEAPON_PATH) as WeaponData, opp, rng, none, false)
	return core.brain.opening_chance


func t89_day_values() -> String:
	var errs: Array[String] = []
	var rules := load(RULES_PATH) as DuelRules
	# 1. 하루의 상대 둘: 0.80, 바닥과 1.0 사이, 연속 상한 없음(결정 413).
	for path in DAY_OPPONENTS:
		var day_opp := load(path) as OpponentData
		if not is_equal_approx(day_opp.opening_chance, 0.8) or day_opp.opening_chance <= rules.opening_chance_floor \
				or day_opp.opening_chance >= 1.0 or day_opp.opening_miss_limit != 0:
			errs.append("%s: 확률 %.2f · 상한 %d (기대 0.80 · 0)" % [path.get_file(), day_opp.opening_chance, day_opp.opening_miss_limit])
	# 2. 규칙의 값이 .tres에 적혀 있다(결정 414). 기본값에 기대지 않고 글에서도 본다.
	var scale := rules.opening_day_scale
	if scale.size() != 3 or not is_equal_approx(scale[0], 1.0) or not is_equal_approx(scale[1], 0.9) or not is_equal_approx(scale[2], 0.8):
		errs.append("배율 %s (기대 [1.0, 0.9, 0.8])" % str(scale))
	if not is_equal_approx(rules.opening_chance_floor, 0.4) or not is_equal_approx(rules.parry_opening_bonus, 0.25) \
			or not is_equal_approx(rules.closed_counter_grace, 0.6):
		errs.append("바닥 %.2f · 패리 덤 %.2f · 봐주는 시간 %.2f (기대 0.40 · 0.25 · 0.60)" % [
			rules.opening_chance_floor, rules.parry_opening_bonus, rules.closed_counter_grace])
	if not is_zero_approx(rules.opening_chance_bonus) or rules.stage_day != 0:
		errs.append("덤 %.2f · 날 %d (기대 0 · 0)" % [rules.opening_chance_bonus, rules.stage_day])
	var rules_text := FileAccess.get_file_as_string(RULES_PATH)
	for key in ["opening_day_scale", "opening_chance_floor", "parry_opening_bonus", "closed_counter_grace"]:
		if not rules_text.contains(key):
			errs.append("duel_rules.tres에 %s가 적혀 있지 않음" % key)
	# 3. 물건: 빈틈을 올리는 물건은 하나이고 목록의 끝이다(결정 415).
	var catalog := load(CATALOG_PATH) as UpgradeCatalog
	var found: Array[UpgradeData] = []
	for item in catalog.upgrades:
		if item.property == &"opening_chance_bonus":
			found.append(item)
	var manual: UpgradeData = found[0] if found.size() == 1 else null
	if manual == null or catalog.upgrades.back() != manual:
		errs.append("빈틈을 올리는 물건 %d개 · 끝에 있는가 %s (기대 1개 · 끝)" % [found.size(), str(manual != null and catalog.upgrades.back() == manual)])
	else:
		var digits := RegEx.new()
		digits.compile("[0-9]")
		if manual.id != &"fencing_manual" or manual.target != UpgradeData.Target.DUEL or manual.branch != UpgradeData.Branch.TRAINING \
				or not is_equal_approx(manual.amount, 0.15) or manual.price != 120:
			errs.append("물건: %s · 대상 %d · 갈래 %d · 양 %.2f · 값 %d" % [manual.id, manual.target, manual.branch, manual.amount, manual.price])
		if digits.search(manual.description) != null:
			errs.append("물건의 설명에 숫자가 있음(결정 404): %s" % manual.description)
	# 4. 길(날): 상대 0.80 × 배율. 받은 규칙은 그대로다.
	var opp := load(DAY_OPPONENTS[0]) as OpponentData
	var shop_day := DayState.new(EconomyRules.new(), DayData.new(), catalog)
	var by_day := {1: 0.8, 2: 0.72, 3: 0.64, 5: 0.64}
	for d: int in by_day:
		shop_day.day_number = d
		var got := _brain_chance(shop_day, rules, opp)
		if not is_equal_approx(got, by_day[d]):
			errs.append("%d일차의 뇌 확률 %.3f (기대 %.2f)" % [d, got, by_day[d]])
	if rules.stage_day != 0:
		errs.append("읽은 규칙의 날이 %d로 바뀜" % rules.stage_day)
	# 5. 길(물건): 가진 날은 덤이 든다. 3일차 0.8 × 0.8 + 0.15, 1일차 0.8 + 0.15.
	if manual != null:
		var owner := DayState.new(EconomyRules.new(), DayData.new(), catalog)
		owner.owned.append(manual.id)
		for row: Array in [[3, 0.79], [1, 0.95]]:
			owner.day_number = row[0]
			var got := _brain_chance(owner, rules, opp)
			if not is_equal_approx(got, row[1]):
				errs.append("물건을 가진 %d일차의 뇌 확률 %.3f (기대 %.2f)" % [row[0], got, row[1]])
	# 6. 글과 판: 도움말에 안내가 있고(상한 0이라 "반드시"는 없다), 3일차의 확률로는 안 열린 막기가 나온다.
	var help := DuelHud.help_text(opp)
	var screen := "\n".join(PackedStringArray(Title.help_groups()))
	if not help.contains("틈을 안 줄 때가 있다") or help.contains("반드시 열린다"):
		errs.append("하루의 바르톨로의 막는 법 글: \"%s\"" % help)
	if not screen.contains("틈을 안 줄 때가 있다"):
		errs.append("도움말 화면에 빈틈의 글이 없음")
	shop_day.day_number = 3
	var third := shop_day.effective_duel_rules(rules)
	var live := _run(opp, third, {}, 60.0).record.count_where(DuelRecord.STRIKE, "closed", true)
	var pinned := _run(opp.with_opening(1.0), third, {}, 60.0).record.count_where(DuelRecord.STRIKE, "closed", true)
	if live < 1 or pinned != 0:
		errs.append("3일차 60초의 안 열린 막기 %d개 · 끈 사본 %d개 (기대 1개 이상 · 0개)" % [live, pinned])
	return "OK" if errs.is_empty() else ", ".join(errs)
