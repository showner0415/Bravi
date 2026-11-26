extends SceneTree
## 부위별 "타격 뒤 얼마나 늦게 눌러도 닿는가"를 실제 DuelCore로 잰다(창 없이. 계획 R02 작업 1).
## 실행: tests/run_part_reach.ps1 [-Opponent res://...tres] [-Attack 왼쪽_베기] [-Distance engage,close] [-All]
## 상대의 공격 하나만 되풀이하는 사본(빈틈의 확률 1.0, 방심 끔)과 엉킴을 끈 무기로, 막거나 패리한 타격 뒤 d초에 누르는 판을
## d=0부터 1/120초씩 치르고 마지막으로 닿은 d를 적는다. 셈(빈틈 - 예비)과 한 걸음 넘게 다르면 줄 끝에 MISMATCH를 붙인다.
## 줄: reach,<옛|새>,<상대>,<공격>,<막음|패리>,<간격>,<부위>,<조준>,<예비>,<빈틈>,<가장 늦은 누름|없음>,<닿음|피함|닿을 수 없음>[,MISMATCH]

const DT := preload("res://scripts/duel/duel_types.gd")
const Bot := preload("res://tests/duel_bots.gd")

const RULES_PATH := "res://data/duel_rules.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const OPPONENT_DIR := "res://data/opponents"
const DEFAULT_OPPONENT := "res://data/opponents/opponent_01.tres"
const DEFAULT_ATTACK := "왼쪽 베기"
const EFFECTS_PATH := "res://data/part_effects.tres"
const DISTANCE_KEYS := {"engage": DT.Distance.ENGAGE, "close": DT.Distance.CLOSE}
const STEP := 1.0 / 120.0
const DELTA := 1.0 / 60.0
const SEED := 1
## 타격 시각 위에 얹어 같은 시각 비교(d + 예비 = 빈틈)가 부동소수 잡음에 흔들리지 않게 한다: 같으면 늦은 것이다.
const PRESS_EPS := 1e-7
const SETTLE := 1e-9
const GIVE_UP := 12.0


func _initialize() -> void:
	var paths: PackedStringArray = []
	var attack_name := ""
	var distances: PackedStringArray = ["engage"]
	var all := false
	var distance_given := false
	var effects_arg: PackedStringArray = ["off", "on"]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--opponent="):
			paths.append(arg.trim_prefix("--opponent="))
		elif arg.begins_with("--attack="):
			attack_name = arg.trim_prefix("--attack=").replace("_", " ")
		elif arg.begins_with("--distance="):
			distances = arg.trim_prefix("--distance=").split(",", false)
			distance_given = true
		elif arg.begins_with("--effects="):
			effects_arg = arg.trim_prefix("--effects=").split(",", false)
		elif arg == "--all":
			all = true
	if all and not distance_given:
		distances = ["engage", "close"]
	if paths.is_empty():
		if all:
			var files := Array(DirAccess.get_files_at(OPPONENT_DIR))
			files.sort()
			for file: String in files:
				var found := OPPONENT_DIR.path_join(file.trim_suffix(".remap"))
				if found.ends_with(".tres") and load(found) is OpponentData:
					paths.append(found)
		else:
			paths.append(DEFAULT_OPPONENT)
	if attack_name == "" and not all:
		attack_name = DEFAULT_ATTACK
	var lines := 0
	var mismatches := 0
	var fx := load(EFFECTS_PATH) as PartEffectData
	var by_effect := {}
	for path in paths:
		var opponent := load(path) as OpponentData
		if opponent == null:
			print("reach,읽지 못함,%s" % path)
			continue
		var attacks := _attacks_of(opponent, attack_name)
		if attacks.is_empty():
			print("reach,건너뜀,%s,%s,그 이름의 공격이 없다" % [path.get_file().get_basename(), attack_name])
		for atk in attacks:
			for parry in [false, true]:
				for distance_key in distances:
					if not DISTANCE_KEYS.has(distance_key):
						continue
					for height in 3:
						for direction in 3:
							for effect in effects_arg:
								var row := _measure(opponent if effect != "on" else opponent.with_part_effects(fx), atk, parry, int(DISTANCE_KEYS[distance_key]), direction, height, effect == "on")
								if row.is_empty():
									continue
								by_effect[effect] = by_effect.get(effect, PackedStringArray()) + PackedStringArray(["reach,%s,%s,%s,%s,%s,%s,%s,%.2f,%.2f,%s,%s%s" % [
									"새" if effect == "on" else "옛",
									path.get_file().get_basename(), atk.attack_name.replace(",", " "), "패리" if parry else "막음",
									DT.DISTANCE_NAMES[int(DISTANCE_KEYS[distance_key])], DT.PART_NAMES[int(row["part"])],
									"%s %s" % [DT.DIRECTION_NAMES[direction], DT.HEIGHT_NAMES[height]],
									float(row["windup"]), float(row["recovery"]), row["last"], row["outcome"],
									",MISMATCH" if bool(row["mismatch"]) else ""]])
								lines += 1
								if bool(row["mismatch"]):
									mismatches += 1
	for effect in effects_arg:
		for line: String in by_effect.get(effect, PackedStringArray()):
			print(line)
	print("PART REACH OK %d" % lines)
	if mismatches > 0:
		print("PART REACH MISMATCH %d" % mismatches)
	quit(0)


## 이 이름의 공격(이름이 비면 전부). 일반 공격과 버릇의 반응을 겹치지 않게 담는다.
func _attacks_of(opponent: OpponentData, name_filter: String) -> Array[AttackData]:
	var found: Array[AttackData] = []
	var pool: Array[AttackData] = opponent.attacks.duplicate()
	for habit in opponent.habits:
		if habit.response != null and not pool.has(habit.response):
			pool.append(habit.response)
	for atk in pool:
		if name_filter == "" or atk.attack_name == name_filter:
			found.append(atk)
	return found


## 조준 한 칸의 d 훑기. 타격 뒤에 빈틈이 열리지 않는 공격이면 빈 사전을 돌려준다.
func _measure(opponent: OpponentData, atk: AttackData, parry: bool, want: int, direction: int, height: int, new_rule := false) -> Dictionary:
	var drilled := opponent.drill(atk)
	drilled.opening_chance = 1.0
	drilled.complacent_time = 0.0
	var first := _trial(drilled, atk, parry, want, direction, height, 0.0)
	if not bool(first["gap"]):
		return {}
	var recovery := float(first["recovery"])
	var windup := float(first["windup"])
	var last := -1.0
	var hit_any := false
	var dodge_any := false
	var error := bool(first["error"])
	for k in int(ceil(recovery / STEP)) + 2:
		var trial: Dictionary = first if k == 0 else _trial(drilled, atk, parry, want, direction, height, k * STEP)
		error = error or bool(trial["error"])
		match str(trial["result"]):
			"hit":
				hit_any = true
				last = k * STEP
			"dodge":
				dodge_any = true
	var part := int(first["part"])
	# 머리: 지키는 상대는 옛 규칙에서 패리·큰 공격 뒤에만, 새 규칙(head_big_only)에서는 큰 공격 뒤 head_exposed_time 안에만 닿는다.
	var guarded := false
	var reach_len := recovery
	var fx := opponent.part_effects
	if part == DT.Part.HEAD and opponent.guards_head:
		if new_rule and fx != null and fx.head_big_only:
			guarded = not atk.is_big
			if fx.head_exposed_time > 0.0:
				reach_len = minf(recovery, fx.head_exposed_time)
		else:
			guarded = not (parry or atk.is_big)
	var expected := reach_len - windup
	var mismatch := error
	if guarded:
		mismatch = mismatch or hit_any or (expected > 0.0 and not dodge_any)
	elif expected > 0.0:
		mismatch = mismatch or not hit_any or last > expected + 1e-6 or last < expected - STEP - 1e-6
	else:
		mismatch = mismatch or hit_any
	return {
		"part": part, "windup": windup, "recovery": recovery,
		"last": "%.3f" % last if hit_any else "없음",
		"outcome": "닿음" if hit_any else ("피함" if dodge_any else "닿을 수 없음"),
		"mismatch": mismatch,
	}


## 한 판: 상대가 공격 하나를 내고 내가 막거나 패리한다. 그 타격 d초 뒤에 조준대로 누르고 판정을 읽는다.
func _trial(opponent: OpponentData, atk: AttackData, parry: bool, want: int, direction: int, height: int, d: float) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var weapon := (load(WEAPON_PATH) as WeaponData).duplicate() as WeaponData
	weapon.close_bind_time = 0.0
	var core := DuelCore.new()
	var none: Array[CommissionCondition] = []
	core.setup(load(RULES_PATH), weapon, opponent, rng, none, false)
	var seen := {"tell_end": -1.0, "struck": false, "strike_t": 0.0, "recovery": 0.0, "result": -1, "attack": null}
	core.event.connect(func(ev: Dictionary) -> void: _note(ev, seen))
	var guard := func(_atk: AttackData, _index: int) -> StringName:
		return &"parry" if parry else &"hold"
	var bot := Bot.new(core, {"guard_fn": guard, "want_distance": want})
	while not bool(seen["struck"]) and not core.ended and core.time < GIVE_UP:
		var step := DELTA
		var tell_end := float(seen["tell_end"])
		if tell_end > core.time and tell_end - core.time < DELTA:
			step = tell_end - core.time + SETTLE
		core.tick(step)
		bot.update()
	var wanted := DT.StrikeResult.PARRIED if parry else DT.StrikeResult.BLOCKED
	var recovery := float(seen["recovery"])
	if not bool(seen["struck"]) or int(seen["result"]) != wanted or recovery <= 0.0:
		return {"gap": false, "error": false}
	var press_at := float(seen["strike_t"]) + d + PRESS_EPS
	if press_at > core.time:
		core.tick(press_at - core.time)
	core.set_aim(direction, height)
	core.press_attack()
	if core.player_state != DT.PlayerState.WINDUP:
		return {"gap": true, "error": true, "recovery": recovery, "windup": 0.0, "part": core.current_aim_part(), "result": "none"}
	var windup := core.attack_windup(core.attack_direction, core.attack_height)
	var part := core.attack_part
	var until := core.time + GIVE_UP
	while seen["attack"] == null and not core.ended and core.time < until:
		core.tick(DELTA)
	var result := "miss"
	var ev: Variant = seen["attack"]
	if ev != null:
		if bool(ev["dodged"]):
			result = "dodge"
		elif int(ev["result"]) == DT.AttackResult.GRAZE or int(ev["result"]) == DT.AttackResult.HIT:
			result = "hit"
	return {"gap": true, "error": false, "recovery": recovery, "windup": windup, "part": part, "result": result}


func _note(ev: Dictionary, seen: Dictionary) -> void:
	match ev["type"]:
		DuelRecord.TELL_START, DuelRecord.PATTERN_STEP:
			seen["tell_end"] = float(ev["strike_time"])
		DuelRecord.STRIKE:
			# 패턴의 중간 타격(다음 타격이 예정됨)은 빈틈이 없으니 마지막 타격만 센다.
			if float(ev["next_strike"]) < 0.0:
				seen["struck"] = true
				seen["strike_t"] = float(ev["t"])
				seen["recovery"] = float(ev["recovery"])
				seen["result"] = int(ev["result"])
		DuelRecord.ATTACK:
			seen["attack"] = ev
