extends RefCounted
## T145~T147: 법정 대리와 귀족의 궂은일(계획 046, 결정 733~745). 의뢰 둘의 데이터와 판·카운터·정산, 하루 일정과 평판 항목의 이름.
## 판은 씬 없이 코어와 봇만 건다. States.put을 쓰지 않고, 화면은 붙인 뒤 advance·tick 없이 글만 읽는다(계획 043 T1).
## 값(감점·보수·평판)은 .tres에서 읽는다: 결정 741의 사다리가 자세 칸을 옮겨도 이 파일은 그대로다.

const Bot := preload("res://tests/duel_bots.gd")
const DT := preload("res://scripts/duel/duel_types.gd")
const Session := preload("res://scripts/game_session.gd")
const Ui := preload("res://scripts/day_ui.gd")
const Counter := preload("res://scripts/commission/counter.gd")

const COURT_PATH := "res://data/commissions/variants/court_beehive.tres"
const NOBLE_PATH := "res://data/commissions/variants/noble_baker.tres"
const SERAFINA_PATH := "res://data/opponents/opponent_04.tres"
const GUGLIELMO_PATH := "res://data/opponents/opponent_07.tres"
const COMMISSION_DIR := "res://data/commissions"
const RULES_PATH := "res://data/duel_rules.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const REPUTATION_PATH := "res://data/reputation_rules.tres"
const SCHEDULE_PATH := "res://data/day_schedule.tres"
const DAY_DIR := "res://data/days/"
const DELTA := 1.0 / 60.0
const HARD_STOP := 400.0
const TIP_FLOOR := 70
## 5일차의 평판 배율(%): 3일차부터 200이다.
const SCALE_DAY5 := 200

var _tree: SceneTree


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T145", "name": "법정 대리 의뢰: 데이터와 판돈, 가슴 높이로 고쳐 찌르는 봇과 막은 칸 그대로 받아치는 봇, 5일차 카운터, 정산의 세 구간", "fn": t145_court},
		{"id": "T146", "name": "귀족의 궂은일: 데이터와 값, 다리만 끝내는 판, 해내는 것이 깎이는 평판, 5일차 카운터, 정산의 세 구간", "fn": t146_noble},
		{"id": "T147", "name": "일정과 평판 항목의 이름: 다섯째 날, 법정이 오는 별, settle_items의 '궂은일을 해냈다'", "fn": t147_schedule_and_items},
	]


func cleanup() -> void:
	_tree = null


# ================================================================ 도우미

func _ok(errs: Array[String]) -> String:
	return "OK" if errs.is_empty() else ", ".join(errs)


func _expect(errs: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		errs.append(msg)


func _all_commissions() -> Array[Commission]:
	return CommissionLibrary.load_tree(COMMISSION_DIR)


## 막고(쥐고 있다), 빈틈에 aim_kind의 칸으로 받아치고, 무너지면 finisher로 끝내는 봇의 설정. chase가 참이면 치고 빠진 빈틈에도 늘 따라붙는다.
## aim_kind: "mid"(가운데 중단), "same"(막은 칸 그대로 — 패턴이면 마지막 타격의 칸), "side"(그 방향 중단).
func _cfg(aim_kind: String, finisher: Array, chase: bool) -> Dictionary:
	var hold := func(_atk: AttackData, _index: int) -> StringName:
		return &"hold"
	var aim := func(ev: Dictionary) -> Variant:
		if float(ev["recovery"]) <= 0.0:
			return null
		var atk := ev["attack"] as AttackData
		var height := int(ev.get("height", -1))
		match aim_kind:
			"same":
				return [atk.direction, height if height >= 0 else DT.Height.MID]
			"side":
				return [atk.direction, DT.Height.MID]
		return [DT.Direction.CENTER, DT.Height.MID]
	var cfg := {
		"guard_fn": hold, "step_fn": hold, "counter_fn": aim, "counter_delay": 0.25,
		"finisher": finisher, "want_distance": DT.Distance.ENGAGE,
	}
	if chase:
		cfg["chase_fn"] = func(_ev: Dictionary) -> bool:
			return true
	return cfg


## 의뢰의 조건 · 상대(빈틈 1.0 + 의뢰의 자세 칸)로 판 하나를 끝까지 돌린다. 점수 · 끝 · 부위별 스침을 돌려준다.
func _duel(commission: Commission, cfg: Dictionary, seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var fitted := commission.fit_opponent(commission.opponent.with_opening(1.0))
	var core := DuelCore.new()
	core.setup(load(RULES_PATH), load(WEAPON_PATH), fitted, rng, commission.conditions, commission.opponent_wears_hat)
	var bot := Bot.new(core, cfg)
	while not core.ended and core.time < HARD_STOP:
		core.tick(DELTA)
		bot.update()
	var target := (commission.conditions[0] as TargetPartCondition).target_part
	var off_grazes := 0
	var off_hits := 0
	var head_grazes := 0
	var leg_grazes := 0
	for ev in core.record.events:
		if ev["type"] != DuelRecord.ATTACK:
			continue
		var part := int(ev["part"])
		if ev["result"] == DT.AttackResult.GRAZE:
			if part != target:
				off_grazes += 1
			if part == DT.Part.HEAD:
				head_grazes += 1
			elif part == DT.Part.LEGS:
				leg_grazes += 1
		elif ev["result"] == DT.AttackResult.HIT and part != target:
			off_hits += 1
	return {
		"ended": core.ended, "reason": core.record.end_reason, "score": commission.evaluate(core.record), "time": core.time,
		"off_grazes": off_grazes, "off_hits": off_hits, "head": head_grazes, "legs": leg_grazes,
	}


## 손으로 만든 기록: 내 ATTACK 이벤트 [결과, 부위] 목록과 끝.
func _rec(attacks: Array, end_reason: int) -> DuelRecord:
	var rec := DuelRecord.new()
	var t := 5.0
	for row: Array in attacks:
		rec.add({"type": DuelRecord.ATTACK, "t": t, "result": row[0], "part": row[1]})
		t += 1.0
	rec.ended = true
	rec.end_reason = end_reason
	rec.elapsed = t + 5.0
	return rec


## 5일차의 하루(평판 규칙을 실음). 손님은 주어진 의뢰 하나다.
func _day(commission_path: String, day_number: int) -> DayState:
	var data := DayData.new()
	var one: Array[Commission] = [load(commission_path) as Commission]
	data.commissions = one
	var day := DayState.new(load(Session.ECONOMY_PATH) as EconomyRules, data, load(Session.CATALOG_PATH), null, load(REPUTATION_PATH) as ReputationRules)
	day.day_number = day_number
	return day


## 카운터 화면의 글 전부. 붙인 뒤 advance·tick 없이 읽는다.
func _counter_text(commission_path: String, day_number: int) -> Dictionary:
	var counter: Node = (load(Session.COUNTER_PATH) as PackedScene).instantiate()
	counter.set("day", _day(commission_path, day_number))
	_tree.root.add_child(counter)
	var haggle := counter.find_child("HaggleLine", true, false) as Label
	var hint := counter.find_child("ReputationHint", true, false) as Label
	var out := {"text": Ui.all_text(counter), "haggle": haggle.text if haggle != null else "(없음)", "hint": hint.text if hint != null else ""}
	counter.free()
	return out


## 한 손님의 하루를 그 기록으로 정산한다. 점수 · 항목 · 정산 화면의 한마디를 돌려준다.
func _settle(commission_path: String, record: DuelRecord, day_number: int) -> Dictionary:
	var day := _day(commission_path, day_number)
	day.accept()
	day.finish_duel(record)
	var result := day.last_result()
	var settlement: Node = (load(Session.SETTLEMENT_PATH) as PackedScene).instantiate()
	settlement.set("day", day)
	_tree.root.add_child(settlement)
	var reaction := settlement.find_child("Reaction", true, false) as Label
	var out := {"score": int(result["score"]), "items": result.get("reputation_items", []), "reaction": reaction.text if reaction != null else "(없음)"}
	settlement.free()
	return out


func _names(items: Array) -> Array[String]:
	var names: Array[String] = []
	for item: Array in items:
		names.append(String(item[0]))
	return names


## 의뢰의 자세 칸이 0이면 fit_opponent는 같은 객체, 아니면 1 ≤ 되찾는 자세 ≤ 자세 ≤ 9(결정 741의 사다리가 칸을 옮길 수 있다).
func _check_posture_cells(errs: Array[String], label: String, commission: Commission) -> void:
	var base := commission.opponent
	var fitted := commission.fit_opponent(base)
	if commission.opponent_posture_max == 0 and commission.opponent_recover_posture == 0:
		_expect(errs, fitted == base, "[⑥ %s] 자세 칸이 0인데 fit_opponent가 다른 객체다" % label)
	else:
		var posture := commission.opponent_posture_max
		var recover := commission.opponent_recover_posture
		_expect(errs, recover >= 1 and recover <= posture and posture <= 9, "[⑥ %s] 자세 칸 %d · %d (기대 1 ≤ 되찾는 ≤ 자세 ≤ 9)" % [label, posture, recover])
		_expect(errs, fitted != base, "[⑥ %s] 자세 칸이 있는데 상대가 사본이 아니다" % label)


# ================================================================ T145 법정 대리

func t145_court() -> String:
	var errs: Array[String] = []
	var court := load(COURT_PATH) as Commission
	if court == null:
		return "court_beehive.tres가 Commission으로 로드되지 않는다"
	_check_court_data(errs, court)
	_check_court_duels(errs, court)
	_check_court_counter(errs, court)
	_check_court_settle(errs, court)
	_check_posture_cells(errs, "법정", court)
	return _ok(errs)


func _check_court_data(errs: Array[String], court: Commission) -> void:
	var serafina := load(SERAFINA_PATH) as OpponentData
	_expect(errs, court.opponent != null and court.opponent.resource_path == SERAFINA_PATH, "[①] 상대가 opponent_04.tres가 아니다")
	_expect(errs, court.conditions.size() == 1 and court.conditions[0] is TargetPartCondition, "[①] 조건이 TargetPartCondition 하나가 아니다")
	if court.conditions.size() == 1 and court.conditions[0] is TargetPartCondition:
		var cond := court.conditions[0] as TargetPartCondition
		_expect(errs, cond.target_part == DT.Part.TORSO, "[①] 지정 부위가 몸통이 아니다")
		_expect(errs, cond.graze_penalty > 0, "[①] 스침을 채점하지 않는다(graze_penalty %d)" % cond.graze_penalty)
	_expect(errs, not court.opponent_wears_hat, "[①] 모자를 씌운다")
	_expect(errs, court.stage != null and court.stage.resource_path.get_file() == "court.tres", "[①] 무대가 안뜰이 아니다")
	_expect(errs, court.haggle_min_stars == 0 and court.haggle_agree_line == "" and court.haggle_refuse_line == "", "[①] 눈높이 0인데 흥정의 대답이 있다")
	var effect := court.reputation_effect
	_expect(errs, int(effect.get("success", 0)) > 0 and int(effect.get("fail", 0)) < 0 and int(effect.get("win", 0)) > 0, "[①] 해냄 > 0 · 못 해냄 < 0 · 이김 > 0이 아니다")
	_expect(errs, court.dialogue.contains(serafina.display_name), "[①] 사연에 세라피나의 이름이 없다")
	# 판돈: 못 해냈을 때의 값이 다른 모든 의뢰 이하이고, 보수가 맡는 값이 0 이상인 다른 모든 의뢰보다 크다.
	for other in _all_commissions():
		if other.resource_path == COURT_PATH:
			continue
		_expect(errs, int(effect.get("fail", 0)) <= int(other.reputation_effect.get("fail", 0)),
			"[①] 못 해냄 %d가 %s의 %d보다 크다" % [int(effect.get("fail", 0)), other.resource_path.get_file(), int(other.reputation_effect.get("fail", 0))])
		if int(other.reputation_effect.get("accept", 0)) >= 0:
			_expect(errs, court.base_reward > other.base_reward, "[①] 보수 %d가 %s의 %d 이하다" % [court.base_reward, other.resource_path.get_file(), other.base_reward])


## ② 가슴 봇은 몸통 밖에 닿지 않고 끝낸다. ③ 막은 칸 그대로 받아치는 봇은 머리 · 다리를 스쳐 점수를 잃는다.
func _check_court_duels(errs: Array[String], court: Commission) -> void:
	var chest_done := 0
	var naive_off := 0
	var naive_below := 0
	for seed_value in range(1, 6):
		var chest := _duel(court, _cfg("mid", [DT.Direction.CENTER, DT.Height.MID], false), seed_value)
		var naive := _duel(court, _cfg("same", [DT.Direction.CENTER, DT.Height.MID], false), seed_value)
		print("  INFO 법정 씨앗 %d: 가슴 봇 %.1f초 끝 %d 점수 %d 몸통 밖 스침 %d | 고지식한 봇 %.1f초 끝 %d 점수 %d 머리 스침 %d 다리 스침 %d" % [
			seed_value, chest["time"], chest["reason"], chest["score"], chest["off_grazes"],
			naive["time"], naive["reason"], naive["score"], naive["head"], naive["legs"]])
		_expect(errs, int(chest["off_grazes"]) == 0 and int(chest["off_hits"]) == 0, "[② 씨앗 %d] 가슴 봇이 몸통 밖을 쳤다(스침 %d · 유효타 %d)" % [seed_value, chest["off_grazes"], chest["off_hits"]])
		if int(chest["reason"]) == DT.EndReason.CONDITION and int(chest["score"]) == 100:
			chest_done += 1
		if int(naive["off_grazes"]) > 0:
			naive_off += 1
			if int(naive["score"]) < 100:
				naive_below += 1
	_expect(errs, chest_done >= 1, "[②] 가슴 봇이 씨앗 1~5에서 100점으로 끝낸 판이 없다")
	_expect(errs, naive_off >= 1 and naive_below >= 1, "[③] 막은 칸 그대로 받아치는 봇이 몸통 밖 스침(%d판)으로 100점 아래가 된 판(%d판)이 없다" % [naive_off, naive_below])


func _check_court_counter(errs: Array[String], court: Commission) -> void:
	var five := _counter_text(COURT_PATH, 5)
	_expect(errs, String(five["text"]).contains(court.client_name), "[④ 5일차] 카운터에 의뢰인 이름이 없다")
	_expect(errs, String(five["text"]).contains("상대: 세라피나 · 층층 찌르기"), "[④ 5일차] 카운터에 '상대: 세라피나 · 층층 찌르기'가 없다")
	_expect(errs, String(five["haggle"]).contains(Counter.HAGGLE_HINTS[0]), "[④ 5일차] 흥정 줄 '%s'에 성향 줄 0이 없다" % five["haggle"])
	var seven := _counter_text(COURT_PATH, 7)
	_expect(errs, String(seven["text"]).contains("상대: 세라피나 · 층층 찌르기 2단"), "[④ 7일차] 카운터에 '… 2단'이 없다")


func _check_court_settle(errs: Array[String], court: Commission) -> void:
	var effect := court.reputation_effect
	var G := DT.AttackResult.GRAZE
	var H := DT.AttackResult.HIT
	var T := DT.Part.TORSO
	var L := DT.Part.LEGS
	# 몸통 유효타 하나: 100점, 해냈다 · 흠 없이 · 이겼다.
	var full := _settle(COURT_PATH, _rec([[H, T]], DT.EndReason.CONDITION), 5)
	var full_items: Array = full["items"]
	_expect(errs, int(full["score"]) == 100, "[⑤ 100점] 충족도 %d" % int(full["score"]))
	_expect(errs, _names(full_items).has(ReputationRules.ITEM_SUCCESS) and _names(full_items).has(ReputationRules.ITEM_PERFECT) and _names(full_items).has(ReputationRules.ITEM_WIN), "[⑤ 100점] 평판 항목 %s (기대 해냈다 · 흠 없이 · 이겼다)" % str(_names(full_items)))
	for item: Array in full_items:
		if item[0] == ReputationRules.ITEM_SUCCESS:
			_expect(errs, int(item[1]) == ReputationRules.scaled(int(effect["success"]), SCALE_DAY5), "[⑤ 100점] 해냈다 %d (기대 scaled)" % int(item[1]))
	_expect(errs, full["reaction"] == court.success_line, "[⑤ 100점] 한마디 '%s' (기대 success_line)" % full["reaction"])
	# 몸통 유효타 + 다리 스침 셋: 70점(문턱 이하), 부분의 말, 해냈다 · 해내지 못했다 없음.
	var part := _settle(COURT_PATH, _rec([[G, L], [G, L], [G, L], [H, T]], DT.EndReason.CONDITION), 5)
	var part_names := _names(part["items"])
	_expect(errs, int(part["score"]) == 100 - 3 * (court.conditions[0] as TargetPartCondition).graze_penalty, "[⑤ 70점] 충족도 %d" % int(part["score"]))
	_expect(errs, int(part["score"]) <= TIP_FLOOR and int(part["score"]) > 0, "[⑤ 70점] 충족도 %d가 부분 구간(1~70)이 아니다" % int(part["score"]))
	_expect(errs, not part_names.has(ReputationRules.ITEM_SUCCESS) and not part_names.has(ReputationRules.ITEM_FAIL), "[⑤ 70점] 평판 항목 %s (기대 해냈다 · 해내지 못했다 없음)" % str(part_names))
	_expect(errs, part["reaction"] == court.partial_line, "[⑤ 70점] 한마디 '%s' (기대 partial_line)" % part["reaction"])
	# 시간 초과 · 공격 없음: 0점, 해내지 못했다.
	var zero := _settle(COURT_PATH, _rec([], DT.EndReason.TIME_UP), 5)
	var zero_items: Array = zero["items"]
	_expect(errs, int(zero["score"]) == 0, "[⑤ 0점] 충족도 %d" % int(zero["score"]))
	var has_fail := false
	for item: Array in zero_items:
		if item[0] == ReputationRules.ITEM_FAIL:
			has_fail = true
			_expect(errs, int(item[1]) == ReputationRules.scaled(int(effect["fail"]), SCALE_DAY5), "[⑤ 0점] 해내지 못했다 %d (기대 scaled)" % int(item[1]))
	_expect(errs, has_fail, "[⑤ 0점] 평판 항목 %s (기대 해내지 못했다)" % str(_names(zero_items)))
	_expect(errs, zero["reaction"] == court.fail_line, "[⑤ 0점] 한마디 '%s' (기대 fail_line)" % zero["reaction"])


# ================================================================ T146 귀족의 궂은일

func t146_noble() -> String:
	var errs: Array[String] = []
	var noble := load(NOBLE_PATH) as Commission
	if noble == null:
		return "noble_baker.tres가 Commission으로 로드되지 않는다"
	_check_noble_data(errs, noble)
	_check_noble_duels(errs, noble)
	_check_noble_reputation(errs, noble)
	_check_noble_counter(errs, noble)
	_check_noble_settle(errs, noble)
	_check_posture_cells(errs, "귀족", noble)
	return _ok(errs)


func _check_noble_data(errs: Array[String], noble: Commission) -> void:
	var gul := load(GUGLIELMO_PATH) as OpponentData
	var serafina := load(SERAFINA_PATH) as OpponentData
	var court := load(COURT_PATH) as Commission
	_expect(errs, noble.opponent != null and noble.opponent.resource_path == GUGLIELMO_PATH, "[①] 상대가 opponent_07.tres가 아니다")
	_expect(errs, noble.conditions.size() == 1 and noble.conditions[0] is TargetPartCondition, "[①] 조건이 TargetPartCondition 하나가 아니다")
	if noble.conditions.size() == 1 and noble.conditions[0] is TargetPartCondition:
		var cond := noble.conditions[0] as TargetPartCondition
		_expect(errs, cond.target_part == DT.Part.LEGS, "[①] 지정 부위가 다리가 아니다")
		_expect(errs, cond.graze_penalty == 0, "[①] 스침을 채점한다(graze_penalty %d)" % cond.graze_penalty)
		_expect(errs, cond.hit_penalty > 0 and cond.hit_penalty < 30, "[①] hit_penalty %d (기대 0 초과 30 미만)" % cond.hit_penalty)
	_expect(errs, not noble.opponent_wears_hat, "[①] 모자를 씌운다")
	_expect(errs, noble.stage != null and noble.stage.resource_path.get_file() == "alley.tres", "[①] 무대가 뒷골목이 아니다")
	var effect := noble.reputation_effect
	var accept := int(effect.get("accept", 0))
	var success := int(effect.get("success", 0))
	var fail := int(effect.get("fail", 0))
	_expect(errs, accept < 0 and success < 0 and success < fail and fail < 0, "[①] 평판 값 %d · %d · %d (기대 맡음 < 0 · 해냄 < 못 해냄 < 0)" % [accept, success, fail])
	_expect(errs, int(effect.get("win", 0)) == 0, "[①] win이 있다")
	_expect(errs, noble.haggle_min_stars >= 1 and noble.haggle_min_stars <= 2, "[①] 눈높이 %d (기대 1~2)" % noble.haggle_min_stars)
	_expect(errs, noble.dialogue.contains(gul.display_name) and noble.dialogue.contains(serafina.display_name), "[①] 사연에 굴리엘모나 세라피나의 이름이 없다")
	if court != null:
		var last_word := court.dialogue.contains(noble.client_name.split(" ")[-1])
		_expect(errs, last_word, "[①] 체칠리아의 사연에 레안드로의 이름이 없다")
	for other in _all_commissions():
		if other.resource_path != NOBLE_PATH:
			_expect(errs, noble.base_reward > other.base_reward, "[①] 보수 %d가 %s의 %d 이하다" % [noble.base_reward, other.resource_path.get_file(), other.base_reward])


## ② 다리 봇만 끝낸다. 가슴 봇은 100점도 조건 종료도 없다(다리만이 끝낸다).
func _check_noble_duels(errs: Array[String], noble: Commission) -> void:
	var legs_done := 0
	for seed_value in range(1, 6):
		var legs := _duel(noble, _cfg("side", [DT.Direction.CENTER, DT.Height.LOW], true), seed_value)
		print("  INFO 귀족 씨앗 %d: 다리 봇 %.1f초 끝 %d 점수 %d" % [seed_value, legs["time"], legs["reason"], legs["score"]])
		if int(legs["reason"]) == DT.EndReason.CONDITION and int(legs["score"]) == 100:
			legs_done += 1
	_expect(errs, legs_done >= 1, "[②] 다리 봇이 씨앗 1~5에서 100점으로 끝낸 판이 없다")
	for seed_value in range(1, 4):
		var chest := _duel(noble, _cfg("side", [DT.Direction.CENTER, DT.Height.MID], true), seed_value)
		_expect(errs, int(chest["score"]) != 100 and int(chest["reason"]) != DT.EndReason.CONDITION, "[② 씨앗 %d] 가슴 봇이 끝냈다(끝 %d 점수 %d)" % [seed_value, chest["reason"], chest["score"]])


## ③ 5일차 배율 200: 100점은 [맡았다 −4, 해냈다 −8], 0점은 [맡았다 −4, 못 해냈다 −2]. 해낸 쪽이 더 깎인다.
func _check_noble_reputation(errs: Array[String], noble: Commission) -> void:
	var effect := noble.reputation_effect
	var H := DT.AttackResult.HIT
	var full := _settle(NOBLE_PATH, _rec([[H, DT.Part.LEGS]], DT.EndReason.CONDITION), 5)
	var want_full := [
		[ReputationRules.ITEM_ACCEPT_BAD, ReputationRules.scaled(int(effect["accept"]), SCALE_DAY5)],
		[ReputationRules.ITEM_SUCCESS_BAD, ReputationRules.scaled(int(effect["success"]), SCALE_DAY5)],
	]
	_expect(errs, full["items"] == want_full, "[③ 100점] 항목 %s (기대 %s — 이겼다 · 흠 없이 없음)" % [str(full["items"]), str(want_full)])
	var zero := _settle(NOBLE_PATH, _rec([], DT.EndReason.TIME_UP), 5)
	var want_zero := [
		[ReputationRules.ITEM_ACCEPT_BAD, ReputationRules.scaled(int(effect["accept"]), SCALE_DAY5)],
		[ReputationRules.ITEM_FAIL, ReputationRules.scaled(int(effect["fail"]), SCALE_DAY5)],
	]
	_expect(errs, zero["items"] == want_zero, "[③ 0점] 항목 %s (기대 %s)" % [str(zero["items"]), str(want_zero)])
	_expect(errs, ReputationRules.items_total(full["items"]) < ReputationRules.items_total(zero["items"]), "[③] 해낸 판이 못 해낸 판보다 덜 깎인다")


func _check_noble_counter(errs: Array[String], noble: Commission) -> void:
	var five := _counter_text(NOBLE_PATH, 5)
	_expect(errs, String(five["text"]).contains(noble.client_name), "[④ 5일차] 카운터에 의뢰인 이름이 없다")
	_expect(errs, String(five["text"]).contains("상대: 굴리엘모 · 치고 빠지기"), "[④ 5일차] 카운터에 '상대: 굴리엘모 · 치고 빠지기'가 없다")
	_expect(errs, String(five["text"]).contains(Counter.HINT_BAD), "[④ 5일차] 카운터에 소문 줄이 없다")
	_expect(errs, String(five["haggle"]).contains(Counter.HAGGLE_HINTS[1]), "[④ 5일차] 흥정 줄 '%s'에 성향 줄 1이 없다" % five["haggle"])
	var eight := _counter_text(NOBLE_PATH, 8)
	_expect(errs, String(eight["text"]).contains("상대: 굴리엘모 · 치고 빠지기 2단"), "[④ 8일차] 카운터에 '… 2단'이 없다")


## ⑤ 정산의 한마디가 세 구간(100 · 다리 유효타 + 다른 부위 유효타 둘 = 70 · 0)에서 그 글이다.
func _check_noble_settle(errs: Array[String], noble: Commission) -> void:
	var H := DT.AttackResult.HIT
	var legs := DT.Part.LEGS
	var full := _settle(NOBLE_PATH, _rec([[H, legs]], DT.EndReason.CONDITION), 5)
	_expect(errs, int(full["score"]) == 100 and full["reaction"] == noble.success_line, "[⑤ 100점] 충족도 %d · 한마디 '%s'" % [int(full["score"]), full["reaction"]])
	var hit_penalty := (noble.conditions[0] as TargetPartCondition).hit_penalty
	var part := _settle(NOBLE_PATH, _rec([[H, DT.Part.TORSO], [H, DT.Part.TORSO], [H, legs]], DT.EndReason.CONDITION), 5)
	_expect(errs, int(part["score"]) == 100 - 2 * hit_penalty and int(part["score"]) <= TIP_FLOOR, "[⑤ 부분] 충족도 %d (기대 %d)" % [int(part["score"]), 100 - 2 * hit_penalty])
	_expect(errs, part["reaction"] == noble.partial_line, "[⑤ 부분] 한마디 '%s' (기대 partial_line)" % part["reaction"])
	var zero := _settle(NOBLE_PATH, _rec([], DT.EndReason.TIME_UP), 5)
	_expect(errs, int(zero["score"]) == 0 and zero["reaction"] == noble.fail_line, "[⑤ 0점] 충족도 %d · 한마디 '%s'" % [int(zero["score"]), zero["reaction"]])


# ================================================================ T147 일정과 항목의 이름

func t147_schedule_and_items() -> String:
	var errs: Array[String] = []
	_check_schedule(errs)
	_check_item_names(errs)
	_check_other_commissions(errs)
	return _ok(errs)


func _check_schedule(errs: Array[String]) -> void:
	var schedule := load(SCHEDULE_PATH) as DaySchedule
	_expect(errs, schedule != null and schedule.days.size() >= 5, "[①] 일정에 날이 다섯 미만이다")
	if schedule == null or schedule.days.size() < 5:
		return
	var fifth: DayData = schedule.days[4]
	_expect(errs, fifth.resource_path == DAY_DIR + "day_05.tres", "[①] 다섯째 날이 day_05.tres가 아니다(%s)" % fifth.resource_path)
	_expect(errs, fifth.commissions.size() >= 1 and fifth.commissions[0].resource_path == COURT_PATH, "[①] day_05의 첫째가 법정이 아니다")
	_expect(errs, fifth.base_guests <= fifth.commissions.size(), "[①] day_05의 기준 손님 수 %d가 목록 %d보다 크다" % [fifth.base_guests, fifth.commissions.size()])
	var rules := load(REPUTATION_PATH) as ReputationRules
	var economy := load(Session.ECONOMY_PATH) as EconomyRules
	for star in range(1, rules.max_stars() + 1):
		var count := ReputationRules.guest_count(fifth.commissions.size(), fifth.base_guests, rules.guest_change(star), economy.duels_per_day)
		_expect(errs, count >= 2, "[①] 별 %d의 손님 %d (기대 법정이 온다 — 2 이상)" % [star, count])
	for c in fifth.commissions:
		_expect(errs, c.resource_path != "res://data/commissions/spar.tres", "[①] day_05에 spar.tres가 있다")
	for n in [1, 2, 3, 4, 5, 6, 7]:
		var other := load(DAY_DIR + "day_0%d.tres" % n) as DayData
		for c in other.commissions:
			_expect(errs, n == 5 or c.resource_path != COURT_PATH, "[①] day_0%d에 법정이 있다" % n)
			_expect(errs, n == 7 or c.resource_path != NOBLE_PATH, "[①] day_0%d에 귀족이 있다(귀족은 7일차 — 결정 785, 자리는 T157)" % n)


func _check_item_names(errs: Array[String]) -> void:
	var rules := load(REPUTATION_PATH) as ReputationRules
	var bad := rules.settle_items({"success": -3}, 100, TIP_FLOOR)
	_expect(errs, bad == [[ReputationRules.ITEM_SUCCESS_BAD, -3]], "[② success −3] 항목 %s (기대 [[궂은일을 해냈다, -3]] — 흠 없이 없음)" % str(bad))
	var good := rules.settle_items({"success": 3}, 100, TIP_FLOOR)
	_expect(errs, good == [[ReputationRules.ITEM_SUCCESS, 3], [ReputationRules.ITEM_PERFECT, rules.perfect_bonus]], "[② success 3] 항목 %s (기대 해냈다 · 흠 없이)" % str(good))
	var none := rules.settle_items({"success": 0}, 100, TIP_FLOOR)
	_expect(errs, none.is_empty(), "[② success 0] 항목 %s (기대 없음)" % str(none))
	_expect(errs, ReputationRules.ITEM_SUCCESS_BAD != ReputationRules.ITEM_SUCCESS, "[②] 두 항목의 이름이 같다")


## ③ success가 0 이상인 의뢰는 100 · 85 · 0점 어디서도 '궂은일을 해냈다'가 붙지 않는다(이름 · 값 · 차례 그대로).
func _check_other_commissions(errs: Array[String]) -> void:
	var rules := load(REPUTATION_PATH) as ReputationRules
	var checked := 0
	for c in _all_commissions():
		if int(c.reputation_effect.get("success", 0)) < 0:
			continue
		checked += 1
		for score in [100, 85, 0]:
			var items := rules.settle_items(c.reputation_effect, score, TIP_FLOOR, score > 0, SCALE_DAY5)
			_expect(errs, not _names(items).has(ReputationRules.ITEM_SUCCESS_BAD), "[③] %s의 %d점에 '궂은일을 해냈다'가 붙었다" % [c.resource_path.get_file(), score])
	_expect(errs, checked >= 9, "[③] success ≥ 0인 의뢰 %d개 (기대 9 이상)" % checked)
