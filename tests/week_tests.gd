extends RefCounted
## T157~T160: 1주차 일정(계획 049, 결정 782~798). 이레의 목록, 이레 걷기, 빨래터의 판, 도움말의 안내.
## 판은 씬 없이 코어와 봇만 건다. States.put을 쓰지 않고, 화면은 붙인 뒤 advance·tick 없이 글만 읽는다(계획 043 T1).
## 하루의 목록은 객체가 아니라 파일 이름 배열로 견준다: DayData.for_flags가 거르면 새 객체다(계획 049 T1).
## 값(받아냄 수·자세 칸)은 .tres에서 읽는다: 결정 792의 사다리가 값을 옮겨도 이 파일은 그대로다.

const Bot := preload("res://tests/duel_bots.gd")
const DT := preload("res://scripts/duel/duel_types.gd")
const Session := preload("res://scripts/game_session.gd")
const Counter := preload("res://scripts/commission/counter.gd")
const Ui := preload("res://scripts/day_ui.gd")
const Title := preload("res://scripts/title.gd")

const VARIANT_DIR := "res://data/commissions/variants/"
const WASHER_PATH := VARIANT_DIR + "washer_ledger.tres"
const POOR_PATH := VARIANT_DIR + "first_blood_poor.tres"
const OPPONENT_DIR := "res://data/opponents/"
const LORENZO_PATH := OPPONENT_DIR + "opponent_03.tres"
const RULES_PATH := "res://data/duel_rules.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const REPUTATION_PATH := "res://data/reputation_rules.tres"
const DAY_DIR := "res://data/days/"
const DELTA := 1.0 / 60.0
const HARD_STOP := 400.0
const TIP_FLOOR := 70
## 6일차의 평판 배율(%): 3일차부터 200이다.
const SCALE_DAY := 200
## 막는 봇과 물러서는 봇의 받아냄을 견주는 때(초). 이때까지의 STRIKE만 센다.
const HORIZON := 20.0

## 결정 788의 하루 일곱(파일 이름, 확장자 없이). day_01 · day_02는 048 뒤 그대로다.
const WEEK := [
	["first_blood", "feather_cut", "throw_match"],
	["first_blood_poor", "legs_only", "throw_bet", "feather_cut", "first_blood", "throw_match", "first_blood_usurer"],
	["first_blood_usurer", "close_baker", "throw_match", "feather_cut", "first_blood_poor", "throw_bet", "first_blood", "legs_only"],
	["spar", "feather_cut", "first_blood", "throw_bet", "first_blood_usurer", "throw_match", "first_blood_poor", "legs_only"],
	["court_beehive", "first_blood_poor", "rival_milliner", "throw_match", "first_blood", "throw_bet", "legs_only", "first_blood_usurer"],
	["pair_hatter", "dun_master", "washer_ledger", "throw_match", "first_blood", "throw_bet", "feather_cut", "legs_only"],
	["after_hatter", "after_baker", "first_blood", "noble_baker", "first_blood_poor", "feather_cut", "throw_bet", "first_blood_usurer", "throw_match"],
]
## 한 의뢰가 서는 날(결정 788). 그 밖의 날에는 없다.
const HOME_DAY := {
	"close_baker": 3, "spar": 4, "court_beehive": 5, "rival_milliner": 5, "pair_hatter": 6, "dun_master": 6,
	"washer_ledger": 6, "after_hatter": 7, "after_baker": 7, "noble_baker": 7,
}
const ENDED_FLAGS := ["baker_helped", "hatter_rematch", "dunned_master", "washer_done"]

var _tree: SceneTree


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T157", "name": "이레의 목록: 일곱 날의 차례, 플래그 갈래마다 한날에 같은 의뢰인이 둘 없고 손님 셋 이상, 귀족 · 넬라가 셋째 안, 한 의뢰가 서는 날, 그날의 단, 스침도 보는 판 2 · 5일차뿐", "fn": t157_week_lists},
		{"id": "T158", "name": "이레 걷기: 1~8일차의 첫 손님과 목록, 플래그 셋이 목록을 바꾸고 저장 · 이어 하기를 지남, 8일차가 day_01, 토마소를 안 맡으면 넬라가 없음", "fn": t158_week_walk},
		{"id": "T159", "name": "빨래터의 판: 데이터의 칸, 뛰어들기를 막아 받는 봇이 로렌초 1단을 받아 낸 뒤 100점, 곧장 받아치면 100점 아님, 물러서면 받아냄이 적음, 정산 세 구간, 카운터", "fn": t159_washer},
		{"id": "T160", "name": "도움말의 안내: 마지막 묶음이 연습 · 둘이 함께를 말하고 그 앞의 묶음은 그대로", "fn": t160_help_guide},
	]


func cleanup() -> void:
	_tree = null


# ================================================================ 도우미

func _ok(errs: Array[String]) -> String:
	return "OK" if errs.is_empty() else ", ".join(errs)


func _expect(errs: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		errs.append(msg)


func _economy() -> EconomyRules:
	return load(Session.ECONOMY_PATH) as EconomyRules


func _reputation() -> ReputationRules:
	return load(REPUTATION_PATH) as ReputationRules


func _commission(path: String) -> Commission:
	return load(path) as Commission


func _stem(commission: Commission) -> String:
	return commission.resource_path.get_file().get_basename()


func _stems(list_value: Array) -> PackedStringArray:
	var out := PackedStringArray()
	for item in list_value:
		out.append(_stem(item as Commission))
	return out


func _opponent(number: int) -> OpponentData:
	return load(OPPONENT_DIR + "opponent_0%d.tres" % number) as OpponentData


## 플래그의 갈래: 맡은 편 · 토마소 · 대련의 조합과 그 위에 끝난 플래그를 더한 것. 두 편이 함께 서는 갈래는 없다(pair_hatter가 둘을 막는다).
func _flag_sets() -> Array:
	var base: Array = [[], ["tomaso_helped"], ["sparred_master"], ["sided_hatter"], ["sided_baker"],
		["tomaso_helped", "sparred_master", "sided_hatter"], ["tomaso_helped", "sparred_master", "sided_baker"]]
	var all: Array = []
	for flags: Array in base:
		all.append(flags)
		all.append(flags + ENDED_FLAGS)
	for flag: String in ENDED_FLAGS:
		all.append(base[5] + [flag])
		all.append(base[6] + [flag])
	return all


# ================================================================ T157 이레의 목록

func t157_week_lists() -> String:
	var errs: Array[String] = []
	var schedule := load(Session.SCHEDULE_PATH) as DaySchedule
	_check_list_order(errs, schedule)
	_check_flag_branches(errs, schedule)
	_check_home_days(errs, schedule)
	_check_tiers(errs)
	_check_graze_days(errs, schedule)
	return _ok(errs)


## ① 일정이 day_01~day_07 차례이고 목록이 결정 788의 파일 이름 차례다. 8일차는 day_01이다.
func _check_list_order(errs: Array[String], schedule: DaySchedule) -> void:
	_expect(errs, schedule.days.size() == 7, "[①] 일정에 날이 %d (기대 7)" % schedule.days.size())
	if schedule.days.size() < 7:
		return
	for i in 7:
		var day: DayData = schedule.days[i]
		_expect(errs, day.resource_path == DAY_DIR + "day_0%d.tres" % (i + 1), "[①] %d번째 날이 day_0%d.tres가 아님(%s)" % [i + 1, i + 1, day.resource_path])
		var got := _stems(day.commissions)
		var want := PackedStringArray(WEEK[i])
		_expect(errs, got == want, "[①] day_0%d의 목록 %s (기대 %s)" % [i + 1, str(got), str(want)])
	_expect(errs, schedule.day_for(8) == schedule.days[0], "[①] 8일차가 day_01이 아님")


## ② 플래그의 갈래마다 일곱 날 모두 같은 의뢰인이 둘 없고 별 1~5 모두 손님 셋 이상. ③ 귀족과 넬라가 거른 목록의 셋째 안.
func _check_flag_branches(errs: Array[String], schedule: DaySchedule) -> void:
	var rules := _reputation()
	var economy := _economy()
	for flag_value: Array in _flag_sets():
		var flags := PackedStringArray(flag_value)
		for n in range(1, 8):
			var filtered := schedule.day_for(n).for_flags(flags)
			var names := {}
			for c in filtered.commissions:
				_expect(errs, not names.has(c.client_name), "[②] day_0%d · 플래그 %s에 %s가 둘" % [n, str(flags), c.client_name])
				names[c.client_name] = true
			for star in range(1, rules.max_stars() + 1):
				var count := ReputationRules.guest_count(filtered.commissions.size(), filtered.base_guests, rules.guest_change(star), economy.duels_per_day)
				_expect(errs, count >= 3, "[②] day_0%d · 플래그 %s · 별 %d의 손님 %d (기대 3 이상)" % [n, str(flags), star, count])
		var seventh := _stems(schedule.day_for(7).for_flags(flags).commissions)
		_expect(errs, seventh.find("noble_baker") >= 0 and seventh.find("noble_baker") < 3, "[③] 플래그 %s의 7일차 목록 %s에서 귀족이 셋째 안이 아님" % [str(flags), str(seventh)])
		if flags.has("tomaso_helped") and not flags.has("washer_done"):
			var sixth := _stems(schedule.day_for(6).for_flags(flags).commissions)
			_expect(errs, sixth.find("washer_ledger") >= 0 and sixth.find("washer_ledger") < 3, "[③] 플래그 %s의 6일차 목록 %s에서 넬라가 셋째 안이 아님" % [str(flags), str(sixth)])


## ④ 한 의뢰가 서는 날과 토마소의 날(6일차에 없다).
func _check_home_days(errs: Array[String], schedule: DaySchedule) -> void:
	for n in range(1, 8):
		var stems := _stems(schedule.day_for(n).commissions)
		for stem: String in HOME_DAY:
			_expect(errs, (stems.find(stem) >= 0) == (int(HOME_DAY[stem]) == n), "[④] %s가 day_0%d에 %s (기대 %d일차에만)" % [stem, n, "있다" if stems.find(stem) >= 0 else "없다", int(HOME_DAY[stem])])
		_expect(errs, (stems.find("first_blood_poor") >= 0) == (n != 6 and n != 1), "[④] first_blood_poor가 day_0%d에 %s (기대 2 · 3 · 4 · 5 · 7일차에만)" % [n, "있다" if stems.find("first_blood_poor") >= 0 else "없다"])


## ⑤ 그날의 단(style_label). 1단은 이름만, 2단부터 숫자가 붙는다.
func _check_tiers(errs: Array[String]) -> void:
	var rows: Array = [
		[3, 2, "브루노 · 휩쓸기"], [3, 3, "로렌초 · 뛰어드는 찌르기"],
		[4, 5, "아고스티노 · 엇박 찌르기"], [4, 1, "바르톨로 · 이어 베기 2단"],
		[5, 4, "세라피나 · 층층 찌르기"], [5, 6, "베아트리체 · 속임 베기"],
		[6, 7, "굴리엘모 · 치고 빠지기"], [6, 3, "로렌초 · 뛰어드는 찌르기"], [6, 5, "아고스티노 · 엇박 찌르기 2단"],
		[7, 3, "로렌초 · 뛰어드는 찌르기 2단"], [7, 6, "베아트리체 · 속임 베기 2단"], [7, 7, "굴리엘모 · 치고 빠지기"], [7, 1, "바르톨로 · 이어 베기 5단"],
		[8, 1, "바르톨로 · 이어 베기 5단"],
	]
	for row: Array in rows:
		var label := _opponent(int(row[1])).style_label(int(row[0]))
		_expect(errs, label == String(row[2]), "[⑤ %d일차] '%s' (기대 '%s')" % [int(row[0]), label, String(row[2])])


## ⑥ 기준 다섯 안에 스침도 보는 의뢰가 서는 날은 2일차와 5일차뿐(플래그 없음). ⑦ 한날의 기준 다섯에 새 상대 다섯을 거는 의뢰가 상대마다 하나까지(모든 갈래).
func _check_graze_days(errs: Array[String], schedule: DaySchedule) -> void:
	var days_with: Array[int] = []
	for n in range(1, 8):
		for c in _base_five(schedule.day_for(n)):
			for condition in c.conditions:
				if condition is TargetPartCondition and (condition as TargetPartCondition).graze_penalty > 0 and not days_with.has(n):
					days_with.append(n)
	_expect(errs, str(days_with) == "[2, 5]", "[⑥] 기준 다섯 안에 스침도 보는 의뢰가 서는 날 %s (기대 [2, 5])" % str(days_with))
	var named := [3, 4, 5, 6, 7]
	for flag_value: Array in _flag_sets():
		var flags := PackedStringArray(flag_value)
		for n in range(1, 8):
			var counts := {}
			for c in _base_five(schedule.day_for(n).for_flags(flags)):
				if c.opponent == null:
					continue
				var path := c.opponent.resource_path
				for number: int in named:
					if path == OPPONENT_DIR + "opponent_0%d.tres" % number:
						counts[number] = int(counts.get(number, 0)) + 1
			for number: int in counts:
				_expect(errs, int(counts[number]) <= 1, "[⑦] day_0%d · 플래그 %s의 기준 다섯에 opponent_0%d를 거는 의뢰가 %d" % [n, str(flags), number, int(counts[number])])


## 하루의 기준 다섯(기준 손님 수가 0이면 목록 전부).
func _base_five(day: DayData) -> Array[Commission]:
	var out: Array[Commission] = []
	var limit := day.base_guests if day.base_guests > 0 else day.commissions.size()
	for i in mini(limit, day.commissions.size()):
		out.append(day.commissions[i])
	return out


# ================================================================ T158 이레 걷기

func _saved_morning(day_number: int, flags_value: Array) -> Dictionary:
	return {"version": DayState.SAVE_VERSION, "day": day_number, "money": 999, "owned": [], "reputation": 20, "dice_seed": 7, "flags": flags_value}


func _real_day() -> DayState:
	return DayState.new(_economy(), load(Session.DAY_PATH) as DayData, load(Session.CATALOG_PATH) as UpgradeCatalog,
		load(Session.SCHEDULE_PATH) as DaySchedule, _reputation())


func _end_record(reason: int) -> DuelRecord:
	var rec := DuelRecord.new()
	rec.ended = true
	rec.end_reason = reason
	rec.elapsed = 90.0
	return rec


## 1일차 아침에서 8일차 아침까지: 날마다 현재 손님을 맡아 0점 기록(시간 초과)으로 정산하고, 결투 셋을 채우거나 손님이 다 하면 폐점,
## 저장(JSON을 지난다) 뒤 다음 날 아침을 이어 연다. skip_poor면 현재 손님이 first_blood_poor일 때 돌려보낸다.
func _walk(skip_poor: bool) -> Array:
	var schedule := load(Session.SCHEDULE_PATH) as DaySchedule
	var rows: Array = []
	var flags_value: Array = []
	for n in range(1, 9):
		var day := _real_day()
		var readable := day.restore(_saved_morning(n, flags_value))
		var morning := PackedStringArray(flags_value)
		var current := day.current_commission()
		var taken := PackedStringArray()
		var after := PackedStringArray()
		if n < 8 and readable:
			var guard := 0
			while day.phase != DayState.Phase.CLOSING and guard < 60:
				if day.phase == DayState.Phase.COUNTER:
					var now := day.current_commission()
					if skip_poor and now != null and _stem(now) == "first_blood_poor":
						day.decline()
					else:
						taken.append(_stem(now))
						day.accept()
				elif day.phase == DayState.Phase.DUEL:
					day.finish_duel(_end_record(DT.EndReason.TIME_UP))
				elif day.phase == DayState.Phase.SETTLEMENT:
					day.proceed()
				else:
					break
				guard += 1
			var loaded: Variant = JSON.parse_string(JSON.stringify(day.saved_state()))
			flags_value = (loaded as Dictionary).get("flags", []) if loaded is Dictionary else []
			after = PackedStringArray(flags_value)
		rows.append({"day": n, "readable": readable, "morning": morning, "after": after, "taken": taken,
			"first": _stem(current) if current != null else "",
			"list": _stems(day.data.commissions) if day.data != null else PackedStringArray(),
			"want": _stems(schedule.day_for(n).for_flags(morning).commissions)})
	return rows


func t158_week_walk() -> String:
	var errs: Array[String] = []
	var schedule := load(Session.SCHEDULE_PATH) as DaySchedule
	# ①②③④ 모든 손님을 맡는 걷기.
	var rows := _walk(false)
	for row: Dictionary in rows:
		var n := int(row["day"])
		_expect(errs, bool(row["readable"]), "[①] %d일차 아침의 저장을 읽지 못함" % n)
		_expect(errs, String(row["first"]) != "", "[①] %d일차에 첫 손님이 없다" % n)
		_expect(errs, row["list"] == row["want"], "[①] %d일차의 목록 %s (기대 일정을 플래그로 거른 %s)" % [n, str(row["list"]), str(row["want"])])
	if rows.size() < 8:
		return _ok(errs)
	_expect(errs, String(rows[1]["first"]) == "first_blood_poor", "[②] 2일차 첫 손님 '%s' (기대 first_blood_poor)" % rows[1]["first"])
	_expect(errs, (rows[2]["morning"] as PackedStringArray).has("tomaso_helped"), "[②] 3일차 아침에 tomaso_helped가 없다 %s" % str(rows[2]["morning"]))
	_expect(errs, String(rows[3]["first"]) == "spar" and (rows[4]["morning"] as PackedStringArray).has("sparred_master"), "[②] 4일차 첫 손님 '%s' · 5일차 아침 %s (기대 spar · sparred_master)" % [rows[3]["first"], str(rows[4]["morning"])])
	_expect(errs, rows[5]["taken"] == PackedStringArray(["pair_hatter", "dun_master", "washer_ledger"]), "[②] 6일차의 앞 셋 %s (기대 pair_hatter · dun_master · washer_ledger)" % str(rows[5]["taken"]))
	for flag: String in ["sided_hatter", "dunned_master", "washer_done"]:
		_expect(errs, (rows[5]["after"] as PackedStringArray).has(flag), "[②] 6일차를 마친 뒤 %s가 없다 %s" % [flag, str(rows[5]["after"])])
	_expect(errs, rows[6]["taken"] == PackedStringArray(["after_hatter", "first_blood", "noble_baker"]), "[③] 7일차의 앞 셋 %s (기대 after_hatter · first_blood · noble_baker)" % str(rows[6]["taken"]))
	_expect(errs, rows[7]["list"] == _stems(schedule.days[0].commissions) and rows[7]["list"] == PackedStringArray(WEEK[0]), "[④] 8일차의 목록 %s (기대 day_01의 셋)" % str(rows[7]["list"]))
	# ⑤ 토마소를 맡지 않는 걷기.
	var skipped := _walk(true)
	for row: Dictionary in skipped:
		var n := int(row["day"])
		_expect(errs, not (row["morning"] as PackedStringArray).has("tomaso_helped") and not (row["after"] as PackedStringArray).has("tomaso_helped"), "[⑤] %d일차에 tomaso_helped가 있다" % n)
		_expect(errs, (row["list"] as PackedStringArray).find("washer_ledger") < 0, "[⑤] %d일차의 목록에 washer_ledger가 있다" % n)
		_expect(errs, not (row["taken"] as PackedStringArray).has("first_blood_poor"), "[⑤] %d일차에 토마소를 맡았다(돌려보내야 한다)" % n)
	if skipped.size() >= 6:
		_expect(errs, skipped[5]["taken"] == PackedStringArray(["pair_hatter", "dun_master", "throw_match"]), "[⑤] 토마소를 안 맡은 6일차의 앞 셋 %s (기대 pair_hatter · dun_master · throw_match)" % str(skipped[5]["taken"]))
	return _ok(errs)


# ================================================================ T159 빨래터의 판

## 의뢰의 조건 · 모자 · 상대(빈틈 1.0 + 의뢰의 자세 칸)로 판 하나를 끝까지 돌린다. ctx["core"]에 코어를 실어 봇의 함수가 기록을 읽게 한다.
func _duel(commission: Commission, opponent: OpponentData, cfg: Dictionary, seed_value: int, ctx: Dictionary) -> Dictionary:
	var fitted := commission.fit_opponent(opponent.with_opening(1.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var core := DuelCore.new()
	core.setup(load(RULES_PATH), load(WEAPON_PATH), fitted, rng, commission.conditions, commission.opponent_wears_hat)
	ctx["core"] = core
	var bot := Bot.new(core, cfg)
	while not core.ended and core.time < HARD_STOP:
		core.tick(DELTA)
		bot.update()
	var early := (commission.conditions[0] as HoldCondition).early_touches(core.record)
	return {"reason": core.record.end_reason, "score": commission.evaluate(core.record), "time": core.time, "early": early, "record": core.record}


## 막고(쥐고), 빈틈에 가운데 중단으로 받아치고, 무너지면 가운데 중단으로 끝내는 봇. cond가 있으면(참는 봇) 받아냄이 다 찰 때까지 받아치지 않는다.
## retreat면 뛰어드는 찌르기에 막기를 떼고 물러선다. in_out이면 엉킴이 차오르면(0.6) 밀착에서 교전으로 한 걸음 뺀다(들어가지는 않는다).
func _cfg(cond: HoldCondition, ctx: Dictionary, retreat := false, in_out := false) -> Dictionary:
	var guard := func(atk: AttackData, _index: int) -> StringName:
		if retreat and atk.dive:
			return &"retreat"
		return &"hold"
	var aim := func(ev: Dictionary) -> Variant:
		if float(ev["recovery"]) <= 0.0:
			return null
		if cond != null and cond.counted_blocks((ctx["core"] as DuelCore).record) < cond.blocks_needed:
			return null
		return [DT.Direction.CENTER, DT.Height.MID]
	var cfg := {"guard_fn": guard, "step_fn": guard, "counter_fn": aim, "counter_delay": 0.25,
		"finisher": [DT.Direction.CENTER, DT.Height.MID], "want_distance": DT.Distance.ENGAGE}
	if retreat:
		cfg["whiff_fn"] = aim
	if in_out:
		cfg["in_out"] = {"enter": -1.0, "leave": 0.6}
	return cfg


## horizon초까지의 STRIKE만 담은 기록으로 센 받아냄(물러선 헛침은 세지 않는다).
func _blocks_by(record: DuelRecord, cond: HoldCondition, horizon: float) -> int:
	var cut := DuelRecord.new()
	for ev: Dictionary in record.events:
		if float(ev.get("t", 0.0)) <= horizon:
			cut.add(ev)
	return cond.counted_blocks(cut)


func t159_washer() -> String:
	var errs: Array[String] = []
	var washer := _commission(WASHER_PATH)
	if washer == null:
		return "washer_ledger.tres가 Commission으로 로드되지 않는다"
	_check_washer_data(errs, washer)
	_check_washer_duels(errs, washer)
	_check_washer_settle(errs, washer)
	_check_washer_counter(errs, washer)
	return _ok(errs)


func _check_washer_data(errs: Array[String], washer: Commission) -> void:
	_expect(errs, washer.client_name == "세탁부 넬라", "[①] 이름 '%s'" % washer.client_name)
	_expect(errs, washer.opponent != null and washer.opponent.resource_path == LORENZO_PATH, "[①] 상대가 로렌초(opponent_03)가 아님")
	_expect(errs, washer.stage != null and washer.stage.resource_path.get_file() == "piazza.tres", "[①] 무대가 광장이 아님")
	_expect(errs, washer.client_portrait == null and not washer.opponent_wears_hat, "[①] 그림이 있거나 모자를 쓴다")
	_expect(errs, washer.conditions.size() == 1 and washer.conditions[0] is HoldCondition, "[①] 조건이 받아 주기 하나가 아님")
	if washer.conditions.size() == 1 and washer.conditions[0] is HoldCondition:
		var hold := washer.conditions[0] as HoldCondition
		_expect(errs, hold.blocks_needed >= 1 and hold.early_touch_penalty == 35, "[①] 받아냄 %d · 먼저 댄 칼 %d (기대 1 이상 · 35)" % [hold.blocks_needed, hold.early_touch_penalty])
		_expect(errs, hold.early_hint == "아직이에요" and hold.ready_text == "이제 쳐요", "[①] 게이지 글 '%s' · '%s'" % [hold.early_hint, hold.ready_text])
		_expect(errs, hold.describe().begins_with("받아 주기") and not hold.describe().contains("접전"), "[①] describe '%s'" % hold.describe())
	var posture := washer.opponent_posture_max
	var recover := washer.opponent_recover_posture
	_expect(errs, (posture == 0 and recover == 0) or (recover >= 1 and recover <= posture and posture <= 9), "[①] 자세 칸 %d · %d (기대 0 · 0 또는 1 ≤ 되찾는 ≤ 자세 ≤ 9)" % [posture, recover])
	_expect(errs, washer.base_reward == 40 and washer.tip_max == 20 and washer.haggle_min_stars == 2, "[①] 보수 %d · 팁 %d · 눈높이 %d" % [washer.base_reward, washer.tip_max, washer.haggle_min_stars])
	_expect(errs, washer.reputation_effect == {"accept": 1, "success": 3, "fail": -1, "win": 1}, "[①] 평판 %s" % str(washer.reputation_effect))
	_expect(errs, washer.requires_flags == PackedStringArray(["tomaso_helped"]) and washer.excluded_flags == PackedStringArray(["washer_done"]) and washer.sets_flags == PackedStringArray(["washer_done"]) and washer.partner == null,
		"[①] 플래그 칸 %s · %s · %s" % [str(washer.requires_flags), str(washer.excluded_flags), str(washer.sets_flags)])
	var paragraphs := washer.dialogue.split("\n")
	_expect(errs, paragraphs.size() == 2 and washer.dialogue.length() <= 280, "[①] 사연이 문단 %d · %d자 (기대 둘 · 280자 안)" % [paragraphs.size(), washer.dialogue.length()])
	for word: String in ["로렌초", "세라피나", "토마소", "물러서지"]:
		_expect(errs, washer.dialogue.contains(word), "[①] 사연에 '%s'가 없다" % word)
	for line: String in [washer.success_line, washer.partial_line, washer.fail_line, washer.decline_line, washer.haggle_agree_line, washer.haggle_refuse_line]:
		_expect(errs, line != "", "[①] 한마디 글이 비어 있다")
	var poor := _commission(POOR_PATH)
	_expect(errs, poor.sets_flags == PackedStringArray(["tomaso_helped"]) and poor.requires_flags.is_empty() and poor.excluded_flags.is_empty() and poor.partner == null,
		"[①] first_blood_poor의 플래그 칸 %s" % str(poor.sets_flags))


## ② 판. 로렌초 1단(for_day(6))에 엉킴이 켜진 게임의 레이피어.
func _check_washer_duels(errs: Array[String], washer: Commission) -> void:
	var hold := washer.conditions[0] as HoldCondition
	var lorenzo := washer.opponent.for_day(6)
	var done := 0
	for seed_value in range(1, 6):
		for in_out: bool in [false, true]:
			var ctx := {}
			var r := _duel(washer, lorenzo, _cfg(hold, ctx, false, in_out), seed_value, ctx)
			print("  INFO 넬라 막는 참는 봇%s 씨앗 %d: %.1f초 끝 %d 점수 %d 먼저 댄 칼 %d" % [" (엉킴 전에 빼기)" if in_out else "", seed_value, r["time"], r["reason"], r["score"], r["early"]])
			if int(r["reason"]) == DT.EndReason.CONDITION and int(r["score"]) == 100:
				done += 1
	_expect(errs, done >= 1, "[②] 막는 참는 봇이 씨앗 1~5(제자리 · 엉킴 전에 빼기)에서 100점으로 끝낸 판이 없다")
	for seed_value in range(1, 4):
		var ctx := {}
		var r := _duel(washer, lorenzo, _cfg(null, ctx), seed_value, ctx)
		print("  INFO 넬라 곧장 받아치는 봇 씨앗 %d: %.1f초 끝 %d 점수 %d 먼저 댄 칼 %d" % [seed_value, r["time"], r["reason"], r["score"], r["early"]])
		_expect(errs, int(r["score"]) != 100, "[② 씨앗 %d] 곧장 받아치는 봇이 100점(먼저 댄 칼 %d)" % [seed_value, r["early"]])
	var block_sum := 0
	var retreat_sum := 0
	for seed_value in range(1, 4):
		var ctx_block := {}
		var block := _duel(washer, lorenzo, _cfg(hold, ctx_block), seed_value, ctx_block)
		var ctx_retreat := {}
		var retreat := _duel(washer, lorenzo, _cfg(hold, ctx_retreat, true), seed_value, ctx_retreat)
		var block_count := _blocks_by(block["record"] as DuelRecord, hold, HORIZON)
		var retreat_count := _blocks_by(retreat["record"] as DuelRecord, hold, HORIZON)
		print("  INFO 넬라 %.0f초까지의 받아냄 씨앗 %d: 막는 봇 %d · 물러서는 봇 %d" % [HORIZON, seed_value, block_count, retreat_count])
		block_sum += block_count
		retreat_sum += retreat_count
	_expect(errs, retreat_sum < block_sum, "[②] 물러서는 봇의 받아냄 합 %d가 막는 봇의 합 %d보다 적지 않다(물러선 헛침은 세지 않는다)" % [retreat_sum, block_sum])


## 끝난 기록: 받아냄 n개를 넣고, 먼저 댄 스침 g개를 앞에, 유효타를 뒤에.
func _hold_rec(blocks: int, grazes: int, hit: bool, end_reason: int) -> DuelRecord:
	var rec := DuelRecord.new()
	var t := 1.0
	for i in grazes:
		rec.add({"type": DuelRecord.ATTACK, "t": t, "result": DT.AttackResult.GRAZE, "part": DT.Part.TORSO, "lunge": false})
		t += 0.2
	for i in blocks:
		rec.add({"type": DuelRecord.STRIKE, "t": t, "result": DT.StrikeResult.BLOCKED, "braced": false})
		t += 1.0
	if hit:
		rec.add({"type": DuelRecord.ATTACK, "t": t, "result": DT.AttackResult.HIT, "part": DT.Part.TORSO, "lunge": false})
	rec.ended = true
	rec.end_reason = end_reason
	rec.elapsed = 60.0
	return rec


## 평판 규칙을 실은 하루로 정산한다. 점수 · 항목 · 정산 화면의 한마디.
func _settle(commission: Commission, record: DuelRecord, day_number: int) -> Dictionary:
	var data := DayData.new()
	var one: Array[Commission] = [commission]
	data.commissions = one
	var day := DayState.new(_economy(), data, null, null, _reputation())
	day.day_number = day_number
	day.accept()
	day.finish_duel(record)
	var result := day.last_result()
	var settlement: Node = (load(Session.SETTLEMENT_PATH) as PackedScene).instantiate()
	settlement.set("day", day)
	_tree.root.add_child(settlement)
	var reaction := settlement.find_child("Reaction", true, false) as Label
	var out := {"score": int(result["score"]), "items": result.get("reputation_items", []), "won": bool(result["won"]),
		"reaction": reaction.text if reaction != null else "(없음)"}
	settlement.free()
	return out


## ③ 정산의 세 구간(100 · 먼저 하나 · 0은 패배 · 시간 초과 · 먼저 댄 칼 셋)과 평판 항목(6일차 배율 200).
func _check_washer_settle(errs: Array[String], washer: Commission) -> void:
	var rep := _reputation()
	_expect(errs, rep.scale_for_day(6) == SCALE_DAY, "[③] 6일차의 배율이 200이 아님")
	var n := (washer.conditions[0] as HoldCondition).blocks_needed
	var C := DT.EndReason.CONDITION
	var sections: Array = [
		[washer.success_line, [_hold_rec(n, 0, true, C)]],
		[washer.partial_line, [_hold_rec(n, 1, true, C)]],
		[washer.fail_line, [_hold_rec(n, 0, false, DT.EndReason.PLAYER_DEFEATED), _hold_rec(n, 0, false, DT.EndReason.TIME_UP), _hold_rec(n, 3, true, C)]],
	]
	var names := ["해냄", "부분", "못 해냄"]
	for k in 3:
		for record: DuelRecord in sections[k][1]:
			var r := _settle(washer, record, 6)
			var score := int(r["score"])
			_expect(errs, r["reaction"] == sections[k][0], "[③ %s] 한마디 '%s' (기대 그 구간의 글)" % [names[k], r["reaction"]])
			if k == 0:
				_expect(errs, score > TIP_FLOOR, "[③] 해냄 구간의 점수 %d가 팁 문턱 이하" % score)
			elif k == 1:
				_expect(errs, score > 0 and score <= TIP_FLOOR, "[③] 부분 구간의 점수 %d가 1~70이 아님" % score)
			else:
				_expect(errs, score == 0, "[③] 못 해냄 구간의 점수 %d가 0이 아님" % score)
			var want_items := rep.settle_items(washer.reputation_effect, score, TIP_FLOOR, bool(r["won"]), SCALE_DAY)
			_expect(errs, r["items"] == want_items, "[③ %s] 평판 항목 %s (기대 reputation_effect × 2 → %s)" % [names[k], str(r["items"]), str(want_items)])


## ④ 카운터(6일차, 플래그 tomaso_helped): 붙인 뒤 advance·tick 없이 글만 읽는다.
func _check_washer_counter(errs: Array[String], washer: Commission) -> void:
	var data := DayData.new()
	var one: Array[Commission] = [washer]
	data.commissions = one
	var day := DayState.new(_economy(), data, load(Session.CATALOG_PATH) as UpgradeCatalog, null, _reputation())
	day.day_number = 6
	day.flags = PackedStringArray(["tomaso_helped"])
	var counter: Node = (load(Session.COUNTER_PATH) as PackedScene).instantiate()
	counter.set("day", day)
	_tree.root.add_child(counter)
	var text := Ui.all_text(counter)
	counter.free()
	var hold := washer.conditions[0] as HoldCondition
	_expect(errs, text.contains(washer.client_name), "[④] 카운터에 의뢰인 이름이 없다")
	_expect(errs, text.contains("상대: 로렌초 · 뛰어드는 찌르기"), "[④] 카운터에 '상대: 로렌초 · 뛰어드는 찌르기'가 없다")
	_expect(errs, text.contains("받아 주기 —") and text.contains("%d번" % hold.blocks_needed), "[④] 카운터의 조건 글에 '받아 주기 — … %d번'이 없다" % hold.blocks_needed)
	_expect(errs, text.contains(Counter.HINT_GOOD), "[④] 카운터에 소문 줄(오를 일)이 없다")


# ================================================================ T160 도움말의 안내

func t160_help_guide() -> String:
	var errs: Array[String] = []
	var groups := Title.help_groups()
	var opponent := load(DuelScene.DEFAULT_OPPONENT_PATH) as OpponentData
	var weapon := load(DuelScene.WEAPON_PATH) as WeaponData
	var lines := DuelHud.help_text(opponent, false, false, weapon).split("\n")
	_expect(errs, groups.size() == lines.size() + 1, "[①] 묶음 %d개 (기대 바르톨로의 줄 %d + 안내 하나)" % [groups.size(), lines.size()])
	if groups.size() != lines.size() + 1:
		return _ok(errs)
	for i in lines.size():
		var items := PackedStringArray()
		for item in lines[i].split(" · "):
			items.append("· " + item)
		_expect(errs, groups[i] == "\n".join(items), "[①] %d번째 묶음이 바르톨로의 줄과 다르다" % (i + 1))
	var last := groups[groups.size() - 1]
	var guide := PackedStringArray()
	for item in Title.HELP_GUIDE.split(" · "):
		guide.append("· " + item)
	_expect(errs, last == "\n".join(guide), "[②] 마지막 묶음 '%s'" % last)
	_expect(errs, last.contains("연습") and last.contains("둘이 함께"), "[②] 마지막 묶음에 '연습' · '둘이 함께'가 없다")
	return _ok(errs)
