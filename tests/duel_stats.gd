extends SceneTree
## 봇이 결투를 여러 판 치르고 수를 낸다(창 없이). 게임 창에서 판을 끝까지 하며 세던 것을 대신한다.
## 실행: tests/run_duel_stats.ps1 [-Runs 20] [-Delay 0.25] [-Counter mid,same,thrust] [-Miss 0.1] [-Opponent res://...tres] [-Opening base,off,1,2,3] [-Bonus 0.15]
## 빈틈(opening): base 상대 그대로 / off 늘 열린다 / 1·2·3 그 날의 확률(결정 408). bonus는 1·2·3에만 든다(결정 420).
## 봇: 고리의 칸을 막고(miss의 확률로 높이를 틀린다), 빈틈이 열리면 delay초 뒤에 받아치고, 무너지면 가운데 중단을 찌른다.
## 받아치는 조준(counter): same 막은 칸 그대로 / mid 같은 방향 중단 / thrust 가운데 중단.
## 줄: "stat,<상대>,<9칸|가로만>,<counter>,..." 하나가 설정 하나. 판정이 아니라 견줄 수다(통과 기준은 줄이 다 나오는 것뿐).

const DT := preload("res://scripts/duel/duel_types.gd")
const Bot := preload("res://tests/duel_bots.gd")
const Summary := preload("res://scripts/duel/duel_summary.gd")

const RULES_PATH := "res://data/duel_rules.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const OPPONENT_DIR := "res://data/opponents"
const DELTA := 1.0 / 60.0
## 제한 시간이 끝내지 못한 판을 끊는다.
const HARD_STOP := 400.0


func _initialize() -> void:
	var runs := 20
	var delay := 0.25
	var miss := 0.0
	var counters: PackedStringArray = ["mid"]
	var paths: PackedStringArray = []
	var openings: PackedStringArray = ["base"]
	var bonus := 0.0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--runs="):
			runs = int(arg.trim_prefix("--runs="))
		elif arg.begins_with("--delay="):
			delay = float(arg.trim_prefix("--delay="))
		elif arg.begins_with("--miss="):
			miss = float(arg.trim_prefix("--miss="))
		elif arg.begins_with("--counter="):
			counters = arg.trim_prefix("--counter=").split(",", false)
		elif arg.begins_with("--opening="):
			openings = arg.trim_prefix("--opening=").split(",", false)
		elif arg.begins_with("--bonus="):
			bonus = float(arg.trim_prefix("--bonus="))
		elif arg.begins_with("--opponent="):
			paths.append(arg.trim_prefix("--opponent="))
	if paths.is_empty():
		var files := Array(DirAccess.get_files_at(OPPONENT_DIR))
		files.sort()
		for file: String in files:
			var found := OPPONENT_DIR.path_join(file.trim_suffix(".remap"))
			# 폴더에는 상대의 그림 데이터(*_art.tres)도 있어 OpponentData만 담는다.
			if found.ends_with(".tres") and load(found) is OpponentData:
				paths.append(found)
	# 덤은 날 숫자 갈래에서만 든다: _chance와 _play는 덤 없는 규칙이라 확률을 두 번 세지 않는다(결정 420).
	var bonus_rules := (load(RULES_PATH) as DuelRules).duplicate() as DuelRules
	bonus_rules.opening_chance_bonus = bonus
	var lines := 0
	for path in paths:
		var opponent := load(path) as OpponentData
		if opponent == null:
			print("stat,%s,읽지 못함" % path)
			continue
		var variants: Array = [["9칸", opponent]] if DuelHud.uses_heights(opponent) else []
		variants.append(["가로만", opponent.flat()])
		for variant: Array in variants:
			for opening in openings:
				var played := _with_opening(variant[1], opening, bonus_rules)
				var label := "%s(%.3f)" % [opening, _chance(played)]
				for counter in counters:
					var summaries: Array = []
					for i in runs:
						summaries.append(_play(played, i + 1, delay, miss, counter))
					_print(path.get_file().get_basename(), variant[0], label, counter, delay, miss, Summary.merge(summaries))
					lines += 1
	print("DUEL STATS OK %d" % lines)
	quit(0)


func _play(opponent: OpponentData, seed_value: int, delay: float, miss: float, counter: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	# 봇의 실수는 판의 난수와 따로 뽑는다(판의 차례를 건드리지 않게).
	var hand := RandomNumberGenerator.new()
	hand.seed = 1000 + seed_value
	var core := DuelCore.new()
	var none: Array[CommissionCondition] = []
	core.setup(load(RULES_PATH), load(WEAPON_PATH), opponent, rng, none, false)
	var guard := func(_atk: AttackData, _index: int) -> StringName:
		return &"wrong_height" if hand.randf() < miss else &"hold"
	var aim := func(ev: Dictionary) -> Variant:
		if float(ev["recovery"]) <= 0.0:
			return null
		var atk := ev["attack"] as AttackData
		var height := int(ev.get("height", -1))
		match counter:
			"same":
				return [atk.direction, height if height >= 0 else DT.Height.MID]
			"thrust":
				return [DT.Direction.CENTER, DT.Height.MID]
		return [atk.direction, DT.Height.MID]
	var bot := Bot.new(core, {
		"guard_fn": guard, "step_fn": guard, "counter_fn": aim, "counter_delay": delay,
		"finisher": [DT.Direction.CENTER, DT.Height.MID], "want_distance": DT.Distance.ENGAGE,
	})
	while not core.ended and core.time < HARD_STOP:
		core.tick(DELTA)
		bot.update()
	return Summary.summarize(core.record)


## 빈틈 설정의 사본. base는 그대로, off는 늘 열린다, 숫자는 그 날의 확률(연습의 날 고르기와 같은 셈).
func _with_opening(opponent: OpponentData, opening: String, rules: DuelRules) -> OpponentData:
	if opening == "off":
		return opponent.with_opening(1.0)
	if opening.is_valid_int() and int(opening) > 0:
		return opponent.with_opening(rules.opening_chance_for(opponent.opening_chance, int(opening)))
	return opponent


func _chance(opponent: OpponentData) -> float:
	return (load(RULES_PATH) as DuelRules).opening_chance_for(opponent.opening_chance, 0)


func _print(name: String, kind: String, opening: String, counter: String, delay: float, miss: float, m: Dictionary) -> void:
	var runs := float(m["runs"])
	var opened := 0
	for key: String in m["openings"]:
		opened += int(m["openings"][key])
	var share := func(key: String) -> String:
		return "%d%%" % roundi(100.0 * int(m["openings"][key]) / maxf(1.0, opened))
	var hits: PackedStringArray = []
	for key: String in m["hits"]:
		hits.append("%s %.1f" % [key, int(m["hits"][key]) / runs])
	var routes: PackedStringArray = []
	for key: String in m["routes"]:
		routes.append("%s×%d" % [key, int(m["routes"][key])])
	var guards: Dictionary = m.get("guards", {})
	print("stat,%s,%s,opening=%s,counter=%s,delay=%.2f,miss=%.2f | 막아서 열림 %d · 안 열림 %d | 판 %d · 평균 %.1f초 · 끝 %s | 판당 맞음: %s | 빈틈 판당 %.1f: 닿음 %s 머리피함 %s 늦음 %s 안침 %s | 마무리 닿음 %d 놓침 %d | 패턴 판당 %.1f" % [
		name, kind, opening, counter, delay, miss, int(guards.get("열림", 0)), int(guards.get("안 열림", 0)), int(runs), float(m["length"]), str(m["end"]),
		", ".join(hits) if not hits.is_empty() else "없음",
		opened / runs, share.call("닿음"), share.call("머리 피함"), share.call("늦음"), share.call("안 침"),
		int(m["finishers"]["닿음"]), int(m["finishers"]["놓침"]),
		_total(m["patterns"]) / runs])
	print("routes,%s,%s,opening=%s | %s" % [name, kind, opening, ", ".join(routes) if not routes.is_empty() else "없음"])


func _total(counts: Dictionary) -> int:
	var n := 0
	for key in counts:
		n += int(counts[key])
	return n
