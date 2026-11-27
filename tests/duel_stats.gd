extends SceneTree
## 봇이 결투를 여러 판 치르고 수를 낸다(창 없이). 게임 창에서 판을 끝까지 하며 세던 것을 대신한다.
## 실행: tests/run_duel_stats.ps1 [-Runs 20] [-Delay 0.25] [-Counter mid,same,thrust] [-Miss 0.1] [-Opponent res://...tres] [-Opening base,off,1,2,3] [-Bonus 0.15] [-Dive block|retreat]
## 빈틈(opening): base 상대 그대로 / off 늘 열린다 / 1·2·3 그 날의 확률(결정 408). bonus는 1·2·3에만 든다(결정 420).
## 봇: 고리의 칸을 막고(miss의 확률로 높이를 틀린다), 빈틈이 열리면 delay초 뒤에 받아치고, 무너지면 가운데 중단을 찌른다.
## 뛰어들기(dive): block 막는다 / retreat 막기를 떼고 물러선 뒤 헛침의 빈틈에 가운데 중단(결정 456). 뛰어들기에만 다르다.
## 받아치는 조준(counter): same 막은 칸 그대로 / mid 같은 방향 중단 / thrust 가운데 중단. arm 칼 든 팔 중단(칼 쪽 베기) / low 가운데 하단(찌르기).
## 부위별 반격(effects): off 옛 규칙 / on 새 규칙(data/part_effects.tres를 실은 사본). nine이 참이면 가로만 줄을 건너뛴다(계획 R02).
## 단(tier): --tier=1,3,last 화면의 "N단"(1부터, last 그 상대의 마지막 단). 줄의 상대 이름이 "opponent_01-t3"이 된다. 안 주면 줄이 옛 그대로다.
## 박자 봇(guard): --guard=hold|parry(안 주면 지금의 봇), parry는 모든 타격을 패리하려 하고 --jitter=<비율>이 누르는 때를 흔든다(어긋남 = 비율 x 기다린 시간 x -1~+1. 계획 042 결정 644). 준 줄에는 ",guard=..,jitter=.."가 붙는다.
## 의뢰(commission): --commission=<res 경로> 그 의뢰의 조건·모자·fit_opponent로 돈다(상대를 안 주면 의뢰의 상대 하나). --finisher=off 무너진 상대를 치지 않는 봇(계획 043 결정 662). 준 줄에는 ",commission=..,finisher=.."가 붙고, --commission이면 설정마다 "score," 줄이 하나 더 나온다.
## 줄: "stat,<상대>,<9칸|가로만>,<counter>,..." 하나가 설정 하나. 판정이 아니라 견줄 수다(통과 기준은 줄이 다 나오는 것뿐).

const DT := preload("res://scripts/duel/duel_types.gd")
const Bot := preload("res://tests/duel_bots.gd")
const Summary := preload("res://scripts/duel/duel_summary.gd")

const RULES_PATH := "res://data/duel_rules.tres"
const EFFECTS_PATH := "res://data/part_effects.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const OPPONENT_DIR := "res://data/opponents"
const DELTA := 1.0 / 60.0
## 제한 시간이 끝내지 못한 판을 끊는다.
const HARD_STOP := 400.0

## 의뢰를 줬을 때만 쓰인다. _play가 판마다 채우고 설정마다 비운다.
var _conditions: Array[CommissionCondition] = []
var _has_hat := false
var _finisher_on := true
var _scores: Array[int] = []
var _topples: Array[int] = []


func _initialize() -> void:
	var runs := 20
	var delay := 0.25
	var miss := 0.0
	var counters: PackedStringArray = ["mid"]
	var paths: PackedStringArray = []
	var openings: PackedStringArray = ["base"]
	var bonus := 0.0
	var dive := "block"
	var effects_list: PackedStringArray = ["off"]
	var nine_only := false
	# 빈 칸 하나는 "단을 안 낀다"(옛 줄 그대로).
	var tiers: PackedStringArray = [""]
	# 안 주면 줄 꼴이 옛 그대로다.
	var guard_mode := ""
	var jitter := 0.0
	# 안 주면 줄 꼴이 옛 그대로다(계획 043).
	var commission_path := ""
	var finisher_arg := ""
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
		elif arg.begins_with("--dive="):
			dive = arg.trim_prefix("--dive=")
		elif arg.begins_with("--effects="):
			effects_list = arg.trim_prefix("--effects=").split(",", false)
		elif arg.begins_with("--tier="):
			tiers = arg.trim_prefix("--tier=").split(",", false)
		elif arg.begins_with("--guard="):
			guard_mode = arg.trim_prefix("--guard=")
		elif arg.begins_with("--jitter="):
			jitter = float(arg.trim_prefix("--jitter="))
		elif arg.begins_with("--commission="):
			commission_path = arg.trim_prefix("--commission=")
		elif arg.begins_with("--finisher="):
			finisher_arg = arg.trim_prefix("--finisher=")
		elif arg == "--nine":
			nine_only = true
		elif arg.begins_with("--opponent="):
			paths.append(arg.trim_prefix("--opponent="))
	var commission: Commission = null
	if commission_path != "":
		commission = load(commission_path) as Commission
		if commission == null or commission.opponent == null:
			print("stat,%s,읽지 못함" % commission_path)
			quit(1)
			return
		_conditions.assign(commission.conditions)
		_has_hat = commission.opponent_wears_hat
		if paths.is_empty():
			paths.append(commission.opponent.resource_path)
	_finisher_on = finisher_arg != "off"
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
	var effects_data := load(EFFECTS_PATH) as PartEffectData
	for path in paths:
		var original := load(path) as OpponentData
		if original == null:
			print("stat,%s,읽지 못함" % path)
			continue
		for token in tiers:
			var opponent := original
			var name_tag := path.get_file().get_basename()
			if token != "":
				# 단은 화면의 "N단"(1부터). at_tier는 0부터라 하나 뺀다. 이름은 사본이 아니라 원본의 경로에서 잡는다.
				var count := original.tier_count()
				var number := count if token == "last" else clampi(int(token), 1, count)
				opponent = original.at_tier(number - 1)
				name_tag += "-t%d" % number
			var guard_tag: String = "" if guard_mode == "" and jitter == 0.0 else ",guard=%s,jitter=%.2f" % ["hold" if guard_mode == "" else guard_mode, jitter]
			var comm_tag := ""
			if commission_path != "" or finisher_arg != "":
				comm_tag = ",commission=%s,finisher=%s" % [commission_path.get_file().get_basename() if commission_path != "" else "none", "on" if _finisher_on else "off"]
				guard_tag += comm_tag
			var variants: Array = [["9칸", opponent]] if DuelHud.uses_heights(opponent) else []
			if not nine_only or variants.is_empty():
				variants.append(["가로만", opponent.flat()])
			for variant: Array in variants:
				for opening in openings:
					var played := _with_opening(variant[1], opening, bonus_rules)
					if commission != null:
						played = commission.fit_opponent(played)
					var label := "%s(%.3f)" % [opening, _chance(played)]
					for effect in effects_list:
						var with_effects := played.with_part_effects(effects_data) if effect == "on" else played
						for counter in counters:
							var summaries: Array = []
							_scores.clear()
							_topples.clear()
							for i in runs:
								summaries.append(_play(with_effects, i + 1, delay, miss, counter, dive, guard_mode, jitter))
							_print(name_tag, variant[0], label, counter, delay, miss, Summary.merge(summaries), "새" if effect == "on" else "옛", guard_tag)
							lines += 1
							if commission != null:
								_print_score(name_tag, variant[0], label, miss, comm_tag)
	print("DUEL STATS OK %d" % lines)
	quit(0)


func _play(opponent: OpponentData, seed_value: int, delay: float, miss: float, counter: String, dive: String, guard_mode: String, jitter: float) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	# 봇의 실수는 판의 난수와 따로 뽑는다(판의 차례를 건드리지 않게).
	var hand := RandomNumberGenerator.new()
	hand.seed = 1000 + seed_value
	# 박자 봇의 흔들림은 손 난수와도 따로 뽑는다(안 준 판의 차례를 건드리지 않게).
	var beat := RandomNumberGenerator.new()
	beat.seed = 2000 + seed_value
	var core := DuelCore.new()
	core.setup(load(RULES_PATH), load(WEAPON_PATH), opponent, rng, _conditions, _has_hat)
	var guard := func(atk: AttackData, _index: int) -> StringName:
		if dive == "retreat" and atk.dive:
			return &"retreat"
		if guard_mode == "parry":
			return &"parry"
		return &"wrong_height" if hand.randf() < miss else &"hold"
	var aim := func(ev: Dictionary) -> Variant:
		if float(ev["recovery"]) <= 0.0:
			return null
		var atk := ev["attack"] as AttackData
		var height := int(ev.get("height", -1))
		match counter:
			"same":
				return [atk.direction, height if height >= 0 else DT.Height.MID]
			"arm":
				return [_direction_of(opponent, DT.Part.SWORD_ARM), DT.Height.MID]
			"low":
				return [DT.Direction.CENTER, DT.Height.LOW]
			"thrust":
				return [DT.Direction.CENTER, DT.Height.MID]
		return [atk.direction, DT.Height.MID]
	var cfg := {
		"guard_fn": guard, "step_fn": guard, "counter_fn": aim, "counter_delay": delay,
		"finisher": [DT.Direction.CENTER, DT.Height.MID], "want_distance": DT.Distance.ENGAGE,
	}
	if not _finisher_on:
		cfg.erase("finisher")
	if dive == "retreat":
		cfg["whiff_fn"] = func(ev: Dictionary) -> Variant:
			return [DT.Direction.CENTER, DT.Height.MID] if float(ev["recovery"]) > 0.0 else null
	if guard_mode == "parry":
		cfg["parry_error_fn"] = func(wait: float) -> float:
			return jitter * wait * (beat.randf() * 2.0 - 1.0)
	var bot := Bot.new(core, cfg)
	while not core.ended and core.time < HARD_STOP:
		core.tick(DELTA)
		bot.update()
	if not _conditions.is_empty():
		var total := 0
		for condition in _conditions:
			total += condition.evaluate(core.record)
		_scores.append(roundi(float(total) / _conditions.size()))
		_topples.append(core.record.of_type(DuelRecord.STAGGER_START).size())
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


func _print(name: String, kind: String, opening: String, counter: String, delay: float, miss: float, m: Dictionary, rule: String, guard_tag: String) -> void:
	var runs := float(m["runs"])
	var opened := 0
	for key: String in m["openings"]:
		opened += int(m["openings"][key])
	var share := func(key: String) -> String:
		return "%d%%" % roundi(100.0 * int(m["openings"][key]) / maxf(1.0, opened))
	var hits: PackedStringArray = []
	var hit_total := 0
	for key: String in m["hits"]:
		hits.append("%s %.1f" % [key, int(m["hits"][key]) / runs])
		hit_total += int(m["hits"][key])
	var routes: PackedStringArray = []
	for key: String in m["routes"]:
		routes.append("%s×%d" % [key, int(m["routes"][key])])
	var guards: Dictionary = m.get("guards", {})
	var fx: Dictionary = m.get("effects", {})
	print("stat,%s,%s,opening=%s,counter=%s,delay=%.2f,miss=%.2f%s | 막아서 열림 %d · 안 열림 %d | 판 %d · 평균 %.1f초 · 끝 %s | 판당 맞음: %s | 빈틈 판당 %.1f: 닿음 %s 머리피함 %s 늦음 %s 안침 %s | 마무리 닿음 %d 놓침 %d | 패턴 판당 %.1f,%s,effects{팔 둔함 %d · 다리 덤 씀 %d · 머리 스침 %d},맞음합계 %.2f" % [
		name, kind, opening, counter, delay, miss, guard_tag, int(guards.get("열림", 0)), int(guards.get("안 열림", 0)), int(runs), float(m["length"]), str(m["end"]),
		", ".join(hits) if not hits.is_empty() else "없음",
		opened / runs, share.call("닿음"), share.call("머리 피함"), share.call("늦음"), share.call("안 침"),
		int(m["finishers"]["닿음"]), int(m["finishers"]["놓침"]),
		_total(m["patterns"]) / runs,
		rule, int(fx.get("팔 둔함", 0)), int(fx.get("다리 덤 씀", 0)), int(fx.get("머리 스침", 0)), hit_total / runs])
	print("routes,%s,%s,opening=%s | %s" % [name, kind, opening, ", ".join(routes) if not routes.is_empty() else "없음"])


## 의뢰의 충족도 갈림. 부분 점수는 100도 0도 아닌 판이다.
func _print_score(name: String, kind: String, opening: String, miss: float, tag: String) -> void:
	var full := 0
	var zero := 0
	var sum := 0
	var topple_sum := 0
	for score in _scores:
		sum += score
		if score >= 100:
			full += 1
		elif score <= 0:
			zero += 1
	for count in _topples:
		topple_sum += count
	var n := maxi(_scores.size(), 1)
	print("score,%s,%s,opening=%s%s,miss=%.2f | 판 %d · 100점 %d · 부분 %d · 0점 %d · 평균 충족도 %.1f | 무너뜨림 판당 %.2f" % [
		name, kind, opening, tag, miss, _scores.size(), full, _scores.size() - full - zero, zero, float(sum) / n, float(topple_sum) / n])


## 상대의 칼 든 팔이 있는 쪽(그 방향 중단이 칼 든 팔이다).
func _direction_of(opponent: OpponentData, part: int) -> int:
	for direction in 3:
		if DuelCore.aim_part(direction, DT.Height.MID, opponent.sword_side, false) == part:
			return direction
	return DT.Direction.CENTER


func _total(counts: Dictionary) -> int:
	var n := 0
	for key in counts:
		n += int(counts[key])
	return n
