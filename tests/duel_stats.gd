extends SceneTree
## 봇이 결투를 여러 판 치르고 수를 낸다(창 없이). 게임 창에서 판을 끝까지 하며 세던 것을 대신한다.
## 실행: tests/run_duel_stats.ps1 [-Runs 20] [-Delay 0.25] [-Counter mid,same,thrust] [-Miss 0.1] [-Opponent res://...tres]
## 봇: 고리의 칸을 막고(miss의 확률로 높이를 틀린다), 빈틈이 열리면 delay초 뒤에 받아치고, 무너지면 가운데 중단을 찌른다.
## 받아치는 조준(counter): same 막은 칸 그대로 / mid 같은 방향 중단 / thrust 가운데 중단.
## 줄: "stat,<상대>,<9칸|가로만>,<counter>,..." 하나가 설정 하나. 판정이 아니라 견줄 수다(통과 기준은 줄이 다 나오는 것뿐).

const DT := preload("res://scripts/duel/duel_types.gd")
const Bot := preload("res://tests/duel_bots.gd")
const Summary := preload("res://scripts/duel/duel_summary.gd")

const RULES_PATH := "res://data/duel_rules.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const TRIAL_DIR := "res://data/opponents/trial"
const DELTA := 1.0 / 60.0
## 제한 시간이 끝내지 못한 판을 끊는다.
const HARD_STOP := 400.0


func _initialize() -> void:
	var runs := 20
	var delay := 0.25
	var miss := 0.0
	var counters: PackedStringArray = ["mid"]
	var paths: PackedStringArray = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--runs="):
			runs = int(arg.trim_prefix("--runs="))
		elif arg.begins_with("--delay="):
			delay = float(arg.trim_prefix("--delay="))
		elif arg.begins_with("--miss="):
			miss = float(arg.trim_prefix("--miss="))
		elif arg.begins_with("--counter="):
			counters = arg.trim_prefix("--counter=").split(",", false)
		elif arg.begins_with("--opponent="):
			paths.append(arg.trim_prefix("--opponent="))
	if paths.is_empty():
		var files := Array(DirAccess.get_files_at(TRIAL_DIR))
		files.sort()
		for file: String in files:
			if file.trim_suffix(".remap").ends_with(".tres"):
				paths.append(TRIAL_DIR.path_join(file.trim_suffix(".remap")))
	var lines := 0
	for path in paths:
		var opponent := load(path) as OpponentData
		if opponent == null:
			print("stat,%s,읽지 못함" % path)
			continue
		var variants: Array = [["9칸", opponent]] if DuelHud.uses_heights(opponent) else []
		variants.append(["가로만", opponent.flat()])
		for variant: Array in variants:
			for counter in counters:
				var summaries: Array = []
				for i in runs:
					summaries.append(_play(variant[1], i + 1, delay, miss, counter))
				_print(path.get_file().get_basename(), variant[0], counter, delay, miss, Summary.merge(summaries))
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


func _print(name: String, kind: String, counter: String, delay: float, miss: float, m: Dictionary) -> void:
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
	print("stat,%s,%s,counter=%s,delay=%.2f,miss=%.2f | 판 %d · 평균 %.1f초 · 끝 %s | 판당 맞음: %s | 빈틈 판당 %.1f: 닿음 %s 머리피함 %s 늦음 %s 안침 %s | 마무리 닿음 %d 놓침 %d | 패턴 판당 %.1f" % [
		name, kind, counter, delay, miss, int(runs), float(m["length"]), str(m["end"]),
		", ".join(hits) if not hits.is_empty() else "없음",
		opened / runs, share.call("닿음"), share.call("머리 피함"), share.call("늦음"), share.call("안 침"),
		int(m["finishers"]["닿음"]), int(m["finishers"]["놓침"]),
		_total(m["patterns"]) / runs])
	print("routes,%s,%s | %s" % [name, kind, ", ".join(routes) if not routes.is_empty() else "없음"])


func _total(counts: Dictionary) -> int:
	var n := 0
	for key in counts:
		n += int(counts[key])
	return n
