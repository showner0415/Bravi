extends RefCounted
## T153~T156: 버티기와 속편(계획 048, 결정 766~781). 받아 주기 조건의 셈, 세 의뢰와 하루, 대련 → 독촉의 플래그, 세 판.
## 판은 씬 없이 코어와 봇만 건다. States.put을 쓰지 않고, 화면은 붙인 뒤 advance·tick 없이 글만 읽는다(계획 043 T1).
## 값(받아냄 수·감점·자세 칸)은 .tres에서 읽는다: 결정 778의 사다리가 값을 옮겨도 이 파일은 그대로다.

const Bot := preload("res://tests/duel_bots.gd")
const DT := preload("res://scripts/duel/duel_types.gd")
const Session := preload("res://scripts/game_session.gd")

const VARIANT_DIR := "res://data/commissions/variants/"
const CLOSE_PATH := VARIANT_DIR + "close_baker.tres"
const RIVAL_PATH := VARIANT_DIR + "rival_milliner.tres"
const DUN_PATH := VARIANT_DIR + "dun_master.tres"
const SPAR_PATH := "res://data/commissions/spar.tres"
const FEATHER_PATH := "res://data/commissions/feather_cut.tres"
const THROW_MATCH_PATH := "res://data/commissions/throw_match.tres"
const USURER_PATH := VARIANT_DIR + "first_blood_usurer.tres"
const PAIR_HATTER_PATH := VARIANT_DIR + "pair_hatter.tres"
const BRUNO_PATH := "res://data/opponents/opponent_02.tres"
const BEATRICE_PATH := "res://data/opponents/opponent_06.tres"
const AGOSTINO_PATH := "res://data/opponents/opponent_05.tres"
const RULES_PATH := "res://data/duel_rules.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const REPUTATION_PATH := "res://data/reputation_rules.tres"
const DAY_DIR := "res://data/days/"
const DELTA := 1.0 / 60.0
const HARD_STOP := 400.0
const TIP_FLOOR := 70
## 4 · 5 · 6일차의 평판 배율(%): 3일차부터 200이다.
const SCALE_DAY := 200

var _tree: SceneTree


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T153", "name": "받아 준 뒤 이김: 받아냄 · 먼저 댄 칼의 셈, 점수 100 · 65 · 30 · 0, 게이지 글의 두 마디, 귀띔, 코어 판의 받아냄 수, 결투 화면의 게이지", "fn": t153_hold_condition},
		{"id": "T154", "name": "세 의뢰와 하루: 데이터의 칸, 플래그, 4 · 5 · 6일차의 자리와 뺀 둘, 한날에 같은 의뢰인이 둘 없음, 단", "fn": t154_data_and_days},
		{"id": "T155", "name": "대련 → 독촉: 대련을 맡아 정산하면 6일차 둘째가 독촉, 돌려보내면 없음, 독촉을 맡으면 다시 안 옴, 0점이어도 플래그가 남음", "fn": t155_flag_chain},
		{"id": "T156", "name": "세 판: 참는 봇은 받아 준 뒤 이기고 곧장 받아치는 봇은 감점, 소매 · 머리를 봇이 끝낸다, 정산의 세 구간과 평판 항목", "fn": t156_duels},
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


func _hold_of(path: String) -> HoldCondition:
	return _commission(path).conditions[0] as HoldCondition


## 손으로 만든 기록의 이벤트. 시각은 넣은 차례대로 오른다.
func _blk(t: float, result := DT.StrikeResult.BLOCKED, braced := false) -> Dictionary:
	return {"type": DuelRecord.STRIKE, "t": t, "result": result, "braced": braced}


func _atk(t: float, result: int, part := DT.Part.TORSO, lunge := false) -> Dictionary:
	return {"type": DuelRecord.ATTACK, "t": t, "result": result, "part": part, "lunge": lunge}


func _record(events: Array, end_reason := DT.EndReason.NONE) -> DuelRecord:
	var rec := DuelRecord.new()
	for ev: Dictionary in events:
		rec.add(ev)
	if end_reason != DT.EndReason.NONE:
		rec.ended = true
		rec.end_reason = end_reason
		rec.elapsed = 60.0
	return rec


func _cond3() -> HoldCondition:
	var cond := HoldCondition.new()
	cond.blocks_needed = 3
	return cond


# ================================================================ T153 받아 준 뒤 이김

func t153_hold_condition() -> String:
	var errs: Array[String] = []
	_check_counting(errs)
	_check_meter(errs)
	_check_core(errs)
	_check_screen(errs)
	return _ok(errs)


func _check_counting(errs: Array[String]) -> void:
	var cond := _cond3()
	var B := DT.StrikeResult.BLOCKED
	var P := DT.StrikeResult.PARRIED
	var G := DT.AttackResult.GRAZE
	var H := DT.AttackResult.HIT
	# ① 막힘 · 받아넘김 · 버티기가 하나씩, 그 뒤 유효타 → 100. 유효타가 있어야 끝난다.
	var three := [_blk(1.0, B), _blk(2.0, P), _blk(3.0, B, true)]
	var won := _record(three + [_atk(4.0, H)])
	_expect(errs, cond.evaluate(won) == 100, "[①] 받아냄 셋 뒤 유효타: 점수 %d (기대 100)" % cond.evaluate(won))
	_expect(errs, cond.check_end(won) != "", "[①] 유효타 뒤 check_end가 빈 글")
	_expect(errs, cond.check_end(_record(three)) == "", "[①] 유효타 없는 기록의 check_end '%s' (기대 빈 글)" % cond.check_end(_record(three)))
	_expect(errs, cond.check_end(_record([])) == "", "[①] 빈 기록의 check_end가 빈 글이 아님")
	# ② 먼저 댄 칼: N번째 받아냄 앞의 스침이 하나에 35. 런지도 센다.
	var one := _record([_blk(1.0, B), _atk(1.5, G), _blk(2.0, B), _atk(2.5, H)])
	_expect(errs, cond.evaluate(one) == 65, "[②] 스침 하나: 점수 %d (기대 65)" % cond.evaluate(one))
	var two := _record([_blk(1.0, B), _atk(1.5, G), _atk(1.8, G), _blk(2.0, B), _atk(2.5, H)])
	_expect(errs, cond.evaluate(two) == 30, "[②] 스침 둘: 점수 %d (기대 30)" % cond.evaluate(two))
	var many := _record([_blk(1.0, B), _atk(1.2, G), _atk(1.4, G), _atk(1.6, G), _blk(2.0, B), _atk(2.5, H)])
	_expect(errs, cond.evaluate(many) == 0, "[②] 스침 셋: 점수 %d (기대 0)" % cond.evaluate(many))
	var late := _record(three + [_atk(3.5, G), _atk(4.0, H)])
	_expect(errs, cond.evaluate(late) == 100, "[②] N번째 받아냄 뒤의 스침이 감점됨: 점수 %d (기대 100)" % cond.evaluate(late))
	var unscored := _record([_blk(1.0, B), _atk(1.1, DT.AttackResult.BLOCKED), _atk(1.2, DT.AttackResult.WHIFF), _blk(2.0, B), _blk(3.0, B), _atk(4.0, H)])
	_expect(errs, cond.evaluate(unscored) == 100, "[②] 막힌 · 헛친 내 공격이 감점됨: 점수 %d (기대 100)" % cond.evaluate(unscored))
	var lunge := _record([_atk(0.5, G, DT.Part.TORSO, true), _blk(1.0, B), _blk(2.0, B), _blk(3.0, B), _atk(4.0, H)])
	_expect(errs, cond.evaluate(lunge) == 65, "[②] 런지 스침: 점수 %d (기대 65)" % cond.evaluate(lunge))
	# ③ 세지 않는 것: 멀리의 헛침, 내가 맞은 스침 · 유효타, 헛손질만 있는 기록.
	var none := _record([_blk(1.0, DT.StrikeResult.WHIFF), _blk(2.0, DT.StrikeResult.GRAZE), _blk(3.0, DT.StrikeResult.HIT),
		{"type": DuelRecord.FEINT, "t": 4.0}, {"type": DuelRecord.FEINT, "t": 5.0}])
	_expect(errs, cond.counted_blocks(none) == 0, "[③] 헛침 · 맞음 · 헛손질이 받아냄으로 셈 %d (기대 0)" % cond.counted_blocks(none))
	# ④ 유효타가 없으면 N을 채워도 0(시간 초과 · 패배).
	for reason: int in [DT.EndReason.TIME_UP, DT.EndReason.PLAYER_DEFEATED]:
		var stuck := _record(three, reason)
		_expect(errs, cond.evaluate(stuck) == 0 and cond.check_end(stuck) == "", "[④] 끝 %d: 점수 %d (기대 0)" % [reason, cond.evaluate(stuck)])
	# ⑥ 공개 함수 셋.
	var mixed := _record([_blk(1.0, B), _atk(2.0, G), _blk(3.0, B), _blk(4.0, P)])
	_expect(errs, cond.counted_blocks(mixed) == 3 and cond.early_touches(mixed) == 1 and is_equal_approx(cond.reach_time(mixed), 4.0),
		"[⑥] 받아냄 %d · 먼저 댄 칼 %d · 채운 시각 %.1f (기대 3 · 1 · 4.0)" % [cond.counted_blocks(mixed), cond.early_touches(mixed), cond.reach_time(mixed)])
	var short := _record([_blk(1.0, B), _blk(2.0, B)])
	_expect(errs, is_equal_approx(cond.reach_time(short), -1.0), "[⑥] 못 채운 기록의 채운 시각 %.1f (기대 -1)" % cond.reach_time(short))


func _check_meter(errs: Array[String]) -> void:
	var cond := _cond3()
	var B := DT.StrikeResult.BLOCKED
	var want_values := [0, 33, 66, 100]
	for k in 4:
		var events: Array = []
		for i in k:
			events.append(_blk(1.0 + i, B))
		var meter := cond.live_meter(_record(events))
		var tail := cond.ready_text if k >= 3 else cond.early_hint
		_expect(errs, int(meter["value"]) == int(want_values[k]), "[⑤] 받아냄 %d: 게이지 값 %d (기대 %d)" % [k, int(meter["value"]), want_values[k]])
		_expect(errs, String(meter["text"]) == "받아냄 %d/3 · %s" % [k, tail], "[⑤] 받아냄 %d: 게이지 글 '%s'" % [k, meter["text"]])
		_expect(errs, int(meter["pending"]) == 0, "[⑤] pending이 0이 아님")
	# 의뢰의 말: 받는 마디 · 다 찬 마디.
	var baker := _hold_of(CLOSE_PATH)
	var five: Array = []
	for i in 5:
		five.append(_blk(1.0 + i, B))
	_expect(errs, String(baker.live_meter(_record(five))["text"]) == "받아냄 5/%d · 아직입죠" % baker.blocks_needed, "[⑤] 버티기의 받는 마디 글 '%s'" % baker.live_meter(_record(five))["text"])
	var full: Array = []
	for i in baker.blocks_needed:
		full.append(_blk(1.0 + i, B))
	_expect(errs, String(baker.live_meter(_record(full))["text"]) == "받아냄 %d/%d · 이제 치십쇼" % [baker.blocks_needed, baker.blocks_needed], "[⑤] 버티기의 다 찬 마디 글 '%s'" % baker.live_meter(_record(full))["text"])
	_expect(errs, not baker.describe().contains("접전") and baker.describe().begins_with("받아 주기"), "[⑤] describe '%s'" % baker.describe())
	# stagger_hint: 끝난 기록은 빈 글, 못 채웠으면 early_hint, 채웠으면 빈 글.
	_expect(errs, cond.stagger_hint(_record([_blk(1.0, B)])) == cond.early_hint, "[⑤] 못 채운 기록의 귀띔 '%s'" % cond.stagger_hint(_record([_blk(1.0, B)])))
	_expect(errs, cond.stagger_hint(_record([_blk(1.0, B), _blk(2.0, B), _blk(3.0, B)])) == "", "[⑤] 다 채운 기록에 귀띔이 있다")
	_expect(errs, cond.stagger_hint(_record([_blk(1.0, B)], DT.EndReason.TIME_UP)) == "", "[⑤] 끝난 기록에 귀띔이 있다")


## ⑦ 코어 판: 쥐고 막기만 하는 봇이 받아낸 수와 기록의 STRIKE가 맞는다. 헛손질은 받아냄이 아니다.
func _check_core(errs: Array[String]) -> void:
	var cond := _cond3()
	cond.blocks_needed = 4
	var hold := func(_atk: AttackData, _index: int) -> StringName:
		return &"hold"
	var cfg := {"guard_fn": hold, "step_fn": hold, "want_distance": DT.Distance.ENGAGE}
	for row: Array in [[BRUNO_PATH, 4, false], [BEATRICE_PATH, 5, true]]:
		var opponent := (load(row[0]) as OpponentData).for_day(int(row[1])).with_opening(1.0)
		var conds: Array[CommissionCondition] = [cond]
		var core := _new_core(opponent, conds)
		var bot := Bot.new(core, cfg)
		while not core.ended and core.time < 40.0:
			core.tick(DELTA)
			bot.update()
		var blocked := 0
		var strikes := 0
		for ev in core.record.of_type(DuelRecord.STRIKE):
			strikes += 1
			if ev["result"] == DT.StrikeResult.BLOCKED or ev["result"] == DT.StrikeResult.PARRIED:
				blocked += 1
		var label := (load(row[0]) as OpponentData).display_name
		_expect(errs, blocked >= 1 and cond.counted_blocks(core.record) == blocked, "[⑦ %s] 받아냄 %d (STRIKE의 막힘 · 받아넘김 %d)" % [label, cond.counted_blocks(core.record), blocked])
		if bool(row[2]):
			var feints := core.record.of_type(DuelRecord.FEINT).size()
			_expect(errs, feints >= 1 and cond.counted_blocks(core.record) <= strikes, "[⑦ %s] 헛손질 %d번 · 받아냄 %d · STRIKE %d (헛손질은 받아냄이 아니다)" % [label, feints, cond.counted_blocks(core.record), strikes])


func _new_core(opponent: OpponentData, conditions: Array[CommissionCondition], seed_value := 1, hat := false) -> DuelCore:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var core := DuelCore.new()
	core.setup(load(RULES_PATH), load(WEAPON_PATH), opponent, rng, conditions, hat)
	return core


## 결투 화면: 처음 게이지는 start가 그린 것이고, 이후는 기록을 늘린 뒤 화면만 한 번 그린다(tick 없음).
func _check_screen(errs: Array[String]) -> void:
	var baker := _hold_of(CLOSE_PATH)
	var duel: Node = (load(Session.DUEL_PATH) as PackedScene).instantiate()
	duel.set("commission", _commission(CLOSE_PATH))
	duel.set("mouse_aim_enabled", false)
	duel.set("rng_seed", 1)
	_tree.root.add_child(duel)
	duel.set_process(false)
	duel.set_physics_process(false)
	var core := duel.get("core") as DuelCore
	var meter := (duel.get_node("HUD") as DuelHud).get("_meter") as DuelHud.Meter
	_expect(errs, meter.visible and meter.shown_text() == "받아냄 0/%d · 아직입죠" % baker.blocks_needed, "[⑦ 화면] 처음 게이지 '%s'(보임 %s)" % [meter.shown_text(), meter.visible])
	for i in 5:
		core.record.add(_blk(1.0 + i))
	duel.call("_update_views", 0.0)
	_expect(errs, meter.shown_text() == String(baker.live_meter(core.record)["text"]) and meter.shown_text() == "받아냄 5/%d · 아직입죠" % baker.blocks_needed, "[⑦ 화면] 받아냄 다섯 뒤 게이지 '%s'" % meter.shown_text())
	for i in range(5, baker.blocks_needed):
		core.record.add(_blk(1.0 + i))
	duel.call("_update_views", 0.0)
	_expect(errs, meter.shown_text() == "받아냄 %d/%d · 이제 치십쇼" % [baker.blocks_needed, baker.blocks_needed], "[⑦ 화면] 다 찬 게이지 '%s'" % meter.shown_text())
	duel.free()


# ================================================================ T154 세 의뢰와 하루

func _check_posture_cells(errs: Array[String], label: String, commission: Commission) -> void:
	var base := commission.opponent
	var fitted := commission.fit_opponent(base)
	if commission.opponent_posture_max == 0 and commission.opponent_recover_posture == 0:
		_expect(errs, fitted == base, "[① %s] 자세 칸이 0인데 fit_opponent가 다른 객체다" % label)
	else:
		var posture := commission.opponent_posture_max
		var recover := commission.opponent_recover_posture
		_expect(errs, recover >= 1 and recover <= posture and posture <= 9, "[① %s] 자세 칸 %d · %d (기대 1 ≤ 되찾는 ≤ 자세 ≤ 9)" % [label, posture, recover])


func t154_data_and_days() -> String:
	var errs: Array[String] = []
	var close := _commission(CLOSE_PATH)
	var rival := _commission(RIVAL_PATH)
	var dun := _commission(DUN_PATH)
	var spar := _commission(SPAR_PATH)
	if close == null or rival == null or dun == null or spar == null:
		return "세 의뢰나 대련이 Commission으로 로드되지 않는다"
	# ① 데이터.
	var rows := [
		[close, "제빵사 굴리엘모", BRUNO_PATH, "piazza.tres", "guglielmo.png", "브루노", 35, 25, 1, {"accept": 0, "success": 3, "fail": -1, "win": 1}],
		[rival, "모자 장인 클라라", BEATRICE_PATH, "alley.tres", "clara.png", "베아트리체", 40, 20, 4, {"accept": 0, "success": 3, "fail": -1, "win": 1}],
		[dun, "대금업자 비토리오", AGOSTINO_PATH, "court.tres", "vittorio.png", "사범", 70, 20, 5, {"accept": -3, "success": -2, "fail": -1}],
	]
	for row: Array in rows:
		var c := row[0] as Commission
		var label := String(row[1])
		_expect(errs, c.client_name == label, "[① %s] 의뢰인 이름 '%s'" % [label, c.client_name])
		_expect(errs, c.opponent != null and c.opponent.resource_path == String(row[2]), "[① %s] 상대 %s" % [label, c.opponent.resource_path if c.opponent != null else "없음"])
		_expect(errs, c.stage != null and c.stage.resource_path.get_file() == String(row[3]), "[① %s] 무대 %s (기대 %s)" % [label, c.stage.resource_path if c.stage != null else "없음", row[3]])
		_expect(errs, c.client_portrait != null and c.client_portrait.resource_path.get_file() == String(row[4]), "[① %s] 의뢰인 그림이 %s가 아님" % [label, row[4]])
		_expect(errs, not c.opponent_wears_hat, "[① %s] 모자를 쓴 판이다" % label)
		_expect(errs, c.base_reward == int(row[6]) and c.tip_max == int(row[7]) and c.haggle_min_stars == int(row[8]), "[① %s] 보수 %d · 팁 %d · 눈높이 %d" % [label, c.base_reward, c.tip_max, c.haggle_min_stars])
		_expect(errs, c.reputation_effect == row[9], "[① %s] reputation_effect %s" % [label, str(c.reputation_effect)])
		_expect(errs, c.conditions.size() == 1, "[① %s] 조건이 하나가 아님" % label)
		_expect(errs, c.dialogue.contains(String(row[5])) and c.dialogue.length() <= 280, "[① %s] 사연에 '%s'가 없거나 280자 넘음(%d)" % [label, row[5], c.dialogue.length()])
		_check_posture_cells(errs, label, c)
	var hold := close.conditions[0] as HoldCondition
	_expect(errs, hold != null and hold.blocks_needed >= 8 and hold.blocks_needed <= 16 and hold.early_touch_penalty == 35 and hold.early_hint == "아직입죠" and hold.ready_text == "이제 치십쇼",
		"[① 버티기] 조건의 칸이 표와 다름")
	var sleeve := rival.conditions[0] as TargetPartCondition
	_expect(errs, sleeve != null and sleeve.target_part == DT.Part.SWORD_ARM and sleeve.graze_penalty == 0 and sleeve.hit_penalty == 30, "[① 소매] 조건이 칼 든 팔 · 유효타만 · 30이 아님")
	var head := dun.conditions[0] as TargetPartCondition
	_expect(errs, head != null and head.target_part == DT.Part.HEAD and head.graze_penalty == 0 and head.hit_penalty == 30, "[① 머리] 조건이 머리 · 유효타만 · 30이 아님")
	for c: Commission in [close, rival]:
		_expect(errs, c.sets_flags.is_empty() and c.requires_flags.is_empty() and c.excluded_flags.is_empty(), "[① %s] 플래그 칸이 비어 있지 않다" % c.client_name)
	_expect(errs, dun.sets_flags == PackedStringArray(["dunned_master"]) and dun.requires_flags == PackedStringArray(["sparred_master"]) and dun.excluded_flags == PackedStringArray(["dunned_master"]),
		"[① 독촉] 플래그 칸이 표와 다름")
	# ② 대련이 남기는 플래그. 다른 칸은 그대로.
	_expect(errs, spar.sets_flags == PackedStringArray(["sparred_master"]) and spar.requires_flags.is_empty() and spar.excluded_flags.is_empty() and spar.partner == null,
		"[②] spar.tres의 플래그 칸 %s" % str(spar.sets_flags))
	_check_days(errs, close, rival, dun, spar)
	_check_tiers(errs, close, rival, dun)
	return _ok(errs)


func _check_days(errs: Array[String], close: Commission, rival: Commission, dun: Commission, spar: Commission) -> void:
	var schedule := load(Session.SCHEDULE_PATH) as DaySchedule
	_expect(errs, schedule.days.size() >= 7, "[③] 일정에 날이 일곱 미만이다")
	if schedule.days.size() < 7:
		return
	var fourth: DayData = schedule.days[3]
	var fifth: DayData = schedule.days[4]
	var sixth: DayData = schedule.days[5]
	_expect(errs, fourth.resource_path == DAY_DIR + "day_04.tres" and fifth.resource_path == DAY_DIR + "day_05.tres" and sixth.resource_path == DAY_DIR + "day_06.tres", "[③] 4 · 5 · 6번째 날이 day_04 · 05 · 06이 아님")
	_expect(errs, fourth.commissions.size() >= 3 and fourth.commissions[0] == spar and fourth.commissions[1].resource_path == FEATHER_PATH and fourth.commissions[2] == close,
		"[③] day_04의 첫째 · 둘째 · 셋째가 spar · feather_cut · close_baker가 아님")
	_expect(errs, fifth.commissions.size() >= 3 and fifth.commissions[2] == rival, "[③] day_05의 셋째가 rival_milliner가 아님")
	_expect(errs, sixth.commissions.size() >= 2 and sixth.commissions[1] == dun, "[③] day_06의 둘째가 dun_master가 아님")
	for c in fifth.commissions:
		_expect(errs, c.resource_path != FEATHER_PATH, "[③] day_05에 feather_cut이 남아 있다")
	for c in sixth.commissions:
		_expect(errs, c.resource_path != USURER_PATH, "[③] day_06에 first_blood_usurer가 남아 있다")
	var rules := _reputation()
	var economy := _economy()
	for day: DayData in [fourth, fifth, sixth]:
		for flags in [[], ["sparred_master"]]:
			var filtered := day.for_flags(PackedStringArray(flags))
			var names := {}
			for c in filtered.commissions:
				_expect(errs, not names.has(c.client_name), "[③] %s · 플래그 %s에 %s가 둘" % [day.resource_path.get_file(), str(flags), c.client_name])
				names[c.client_name] = true
			for star in range(1, rules.max_stars() + 1):
				var count := ReputationRules.guest_count(filtered.commissions.size(), filtered.base_guests, rules.guest_change(star), economy.duels_per_day)
				_expect(errs, count >= 3, "[③] %s · 플래그 %s · 별 %d의 손님 %d (기대 3 이상)" % [day.resource_path.get_file(), str(flags), star, count])
	for n in [1, 2, 3, 7]:
		var other := load(DAY_DIR + "day_0%d.tres" % n) as DayData
		for c in other.commissions:
			_expect(errs, c != close and c != rival and c != dun, "[③] day_0%d에 세 의뢰가 있다" % n)


func _check_tiers(errs: Array[String], close: Commission, rival: Commission, dun: Commission) -> void:
	_expect(errs, close.opponent.style_label(4) == "브루노 · 휩쓸기 2단", "[④ 4일차] 브루노 '%s'" % close.opponent.style_label(4))
	_expect(errs, rival.opponent.style_label(5) == "베아트리체 · 속임 베기", "[④ 5일차] 베아트리체 '%s'" % rival.opponent.style_label(5))
	_expect(errs, dun.opponent.style_label(6) == "아고스티노 · 엇박 찌르기 2단", "[④ 6일차] 아고스티노 '%s'" % dun.opponent.style_label(6))


# ================================================================ T155 대련 → 독촉

func _saved_morning(day_number: int, flags_value: Array) -> Dictionary:
	return {"version": 1, "day": day_number, "money": 50, "owned": [], "reputation": 20, "dice_seed": 7, "flags": flags_value}


## 진짜 일정과 평판 규칙을 실은 새 하루(GameSession과 같은 재료).
func _real_day() -> DayState:
	return DayState.new(_economy(), load(Session.DAY_PATH) as DayData, load(Session.CATALOG_PATH) as UpgradeCatalog,
		load(Session.SCHEDULE_PATH) as DaySchedule, _reputation())


func _end_record(reason: int) -> DuelRecord:
	var rec := DuelRecord.new()
	rec.ended = true
	rec.end_reason = reason
	rec.elapsed = 90.0
	return rec


func _to_closing(day: DayState) -> void:
	var guard := 0
	while day.phase != DayState.Phase.CLOSING and guard < 40:
		if day.phase == DayState.Phase.SETTLEMENT:
			day.proceed()
		elif day.phase == DayState.Phase.COUNTER:
			day.decline()
		else:
			break
		guard += 1


## 4일차 아침에서 첫 손님(대련)을 맡거나 돌려보내고 폐점까지 민 뒤, JSON을 지난 flags로 6일차 아침을 연다.
func _sixth_morning(take_spar: bool) -> DayState:
	var day := _real_day()
	day.restore(_saved_morning(4, []))
	if day.current_commission() == null or day.current_commission().resource_path != SPAR_PATH:
		return null
	if take_spar:
		day.accept()
		day.finish_duel(_end_record(DT.EndReason.TIME_UP))
	else:
		day.decline()
	_to_closing(day)
	var loaded: Variant = JSON.parse_string(JSON.stringify(day.saved_state()))
	var flags: Array = (loaded as Dictionary).get("flags", []) if loaded is Dictionary else []
	var sixth := _real_day()
	sixth.restore(_saved_morning(6, flags))
	return sixth


func t155_flag_chain() -> String:
	var errs: Array[String] = []
	# ①④ 대련을 맡아 정산(0점 — 시간 초과)하면 플래그가 남고 6일차 둘째가 독촉이다.
	var taken := _sixth_morning(true)
	if taken == null:
		return "4일차 아침의 첫 손님이 대련이 아니다"
	_expect(errs, taken.flags.has("sparred_master"), "[① · ④] 대련을 0점으로 맡아 정산했는데 flags %s" % str(taken.flags))
	_expect(errs, taken.data.commissions.size() >= 2 and taken.data.commissions[1].resource_path == DUN_PATH, "[①] 6일차 목록의 둘째가 dun_master가 아님")
	# ② 돌려보냈으면 플래그가 없고 독촉이 없다. 둘째는 throw_match.
	var declined := _sixth_morning(false)
	_expect(errs, declined != null and declined.flags.is_empty(), "[②] 대련을 돌려보냈는데 flags가 남음")
	if declined != null:
		for c in declined.data.commissions:
			_expect(errs, c.resource_path != DUN_PATH, "[②] 대련을 돌려보냈는데 6일차에 dun_master가 있다")
		_expect(errs, declined.data.commissions.size() >= 2 and declined.data.commissions[1].resource_path == THROW_MATCH_PATH, "[②] 6일차 목록의 둘째가 throw_match가 아님")
	# ③ 독촉을 맡아 정산하면 dunned_master, 일정이 돌아온 13일차(day_06)에 독촉이 없다.
	var day := _real_day()
	day.restore(_saved_morning(6, ["sparred_master"]))
	day.decline()
	_expect(errs, day.current_commission() != null and day.current_commission().resource_path == DUN_PATH, "[③] 첫 손님을 돌려보낸 뒤 현재 손님이 dun_master가 아님")
	day.accept()
	day.finish_duel(_end_record(DT.EndReason.TIME_UP))
	_expect(errs, day.flags.has("dunned_master") and day.flags.has("sparred_master"), "[③] 독촉을 맡아 정산한 뒤 flags %s" % str(day.flags))
	var again := _real_day()
	again.restore(_saved_morning(13, Array(day.flags)))
	for c in again.data.commissions:
		_expect(errs, c.resource_path != DUN_PATH, "[③] 13일차(day_06)에 dun_master가 다시 온다")
	_expect(errs, again.data.commissions.size() >= 1 and again.data.commissions[0].resource_path == PAIR_HATTER_PATH, "[③] 13일차 목록의 첫째가 pair_hatter가 아님(day_06이 돌아오지 않았다)")
	return _ok(errs)


# ================================================================ T156 세 판

## 의뢰의 조건 · 모자 · 상대(빈틈 1.0 + 의뢰의 자세 칸)로 판 하나를 끝까지 돌린다. ctx["core"]에 코어를 실어 봇의 함수가 기록을 읽게 한다.
func _duel(commission: Commission, opponent: OpponentData, cfg: Dictionary, seed_value: int, ctx: Dictionary) -> Dictionary:
	var fitted := commission.fit_opponent(opponent.with_opening(1.0))
	var core := _new_core(fitted, commission.conditions, seed_value, commission.opponent_wears_hat)
	ctx["core"] = core
	var bot := Bot.new(core, cfg)
	while not core.ended and core.time < HARD_STOP:
		core.tick(DELTA)
		bot.update()
	var hits: Array[int] = []
	var early := 0
	for ev in core.record.events:
		if ev["type"] == DuelRecord.ATTACK and ev["result"] == DT.AttackResult.HIT:
			hits.append(int(ev["part"]))
	if commission.conditions[0] is HoldCondition:
		early = (commission.conditions[0] as HoldCondition).early_touches(core.record)
	return {"reason": core.record.end_reason, "score": commission.evaluate(core.record), "time": core.time, "hits": hits, "early": early}


## 막고(쥐고), 빈틈에 가운데 중단으로 받아치고, 무너지면 finisher로 끝내는 봇. patient면 받아냄이 다 찰 때까지 받아치지 않는다.
func _cfg(finisher: Array, cond: HoldCondition, ctx: Dictionary) -> Dictionary:
	var hold := func(_atk: AttackData, _index: int) -> StringName:
		return &"hold"
	var aim := func(ev: Dictionary) -> Variant:
		if float(ev["recovery"]) <= 0.0:
			return null
		if cond != null and cond.counted_blocks((ctx["core"] as DuelCore).record) < cond.blocks_needed:
			return null
		return [DT.Direction.CENTER, DT.Height.MID]
	return {"guard_fn": hold, "step_fn": hold, "counter_fn": aim, "counter_delay": 0.25, "want_distance": DT.Distance.ENGAGE, "finisher": finisher}


func t156_duels() -> String:
	var errs: Array[String] = []
	_check_hold_duel(errs)
	_check_sleeve_duel(errs)
	_check_head_duel(errs)
	_check_settle_sections(errs)
	return _ok(errs)


func _check_hold_duel(errs: Array[String]) -> void:
	var close := _commission(CLOSE_PATH)
	var hold := close.conditions[0] as HoldCondition
	var bruno := close.opponent.for_day(4)
	var mid := [DT.Direction.CENTER, DT.Height.MID]
	var done := 0
	for seed_value in range(1, 6):
		var ctx := {}
		var r := _duel(close, bruno, _cfg(mid, hold, ctx), seed_value, ctx)
		print("  INFO 버티기 참는 봇 씨앗 %d: %.1f초 끝 %d 점수 %d 먼저 댄 칼 %d" % [seed_value, r["time"], r["reason"], r["score"], r["early"]])
		if int(r["reason"]) == DT.EndReason.CONDITION and int(r["score"]) == 100:
			done += 1
	_expect(errs, done >= 1, "[①] 참는 봇이 씨앗 1~5에서 100점으로 끝낸 판이 없다")
	for seed_value in range(1, 4):
		var ctx := {}
		var r := _duel(close, bruno, _cfg(mid, null, ctx), seed_value, ctx)
		print("  INFO 버티기 곧장 받아치는 봇 씨앗 %d: %.1f초 끝 %d 점수 %d 먼저 댄 칼 %d" % [seed_value, r["time"], r["reason"], r["score"], r["early"]])
		_expect(errs, int(r["score"]) != 100 and int(r["early"]) >= 1, "[① 씨앗 %d] 곧장 받아치는 봇이 100점이거나 먼저 댄 칼이 없다(점수 %d · 먼저 댄 칼 %d)" % [seed_value, r["score"], r["early"]])


func _check_sleeve_duel(errs: Array[String]) -> void:
	var rival := _commission(RIVAL_PATH)
	var bea := rival.opponent.for_day(5)
	var arm := [bea.sword_side, DT.Height.MID]
	var done := 0
	for seed_value in range(1, 6):
		var ctx := {}
		var r := _duel(rival, bea, _cfg(arm, null, ctx), seed_value, ctx)
		print("  INFO 소매 씨앗 %d: %.1f초 끝 %d 점수 %d" % [seed_value, r["time"], r["reason"], r["score"]])
		if int(r["reason"]) == DT.EndReason.CONDITION and int(r["score"]) == 100:
			done += 1
			_expect(errs, (r["hits"] as Array).size() == 1 and int((r["hits"] as Array)[0]) == DT.Part.SWORD_ARM, "[② 씨앗 %d] 유효타가 칼 든 팔 하나가 아님 %s" % [seed_value, str(r["hits"])])
	_expect(errs, done >= 1, "[②] 칼 쪽 가운데 봇이 씨앗 1~5에서 100점으로 끝낸 판이 없다")


func _check_head_duel(errs: Array[String]) -> void:
	var dun := _commission(DUN_PATH)
	var ago := dun.opponent.for_day(6)
	var top := [DT.Direction.CENTER, DT.Height.HIGH]
	var done := 0
	for seed_value in range(1, 6):
		var ctx := {}
		var r := _duel(dun, ago, _cfg(top, null, ctx), seed_value, ctx)
		print("  INFO 머리 씨앗 %d: %.1f초 끝 %d 점수 %d" % [seed_value, r["time"], r["reason"], r["score"]])
		if int(r["reason"]) == DT.EndReason.CONDITION and int(r["score"]) == 100:
			done += 1
			_expect(errs, (r["hits"] as Array).size() == 1 and int((r["hits"] as Array)[0]) == DT.Part.HEAD, "[③ 씨앗 %d] 유효타가 머리 하나가 아님 %s" % [seed_value, str(r["hits"])])
	_expect(errs, done >= 1, "[③] 가운데 위 봇이 씨앗 1~5에서 100점으로 끝낸 판이 없다")


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


## 끝난 기록: 받아냄 n개를 넣고, 먼저 댄 스침 g개를 앞에, 유효타 부위 목록을 뒤에.
func _hold_rec(blocks: int, grazes: int, hit: bool, end_reason: int) -> DuelRecord:
	var events: Array = []
	var t := 1.0
	for i in grazes:
		events.append(_atk(t, DT.AttackResult.GRAZE))
		t += 0.2
	for i in blocks:
		events.append(_blk(t))
		t += 1.0
	if hit:
		events.append(_atk(t, DT.AttackResult.HIT))
	return _record(events, end_reason)


func _part_rec(parts: Array, end_reason: int) -> DuelRecord:
	var events: Array = []
	var t := 5.0
	for part: int in parts:
		events.append(_atk(t, DT.AttackResult.HIT, part))
		t += 1.0
	return _record(events, end_reason)


func _check_settle_sections(errs: Array[String]) -> void:
	var rep := _reputation()
	_expect(errs, rep.scale_for_day(4) == SCALE_DAY and rep.scale_for_day(5) == SCALE_DAY and rep.scale_for_day(6) == SCALE_DAY, "[④] 4 · 5 · 6일차의 배율이 200이 아님")
	var n := _hold_of(CLOSE_PATH).blocks_needed
	var C := DT.EndReason.CONDITION
	var arm := DT.Part.SWORD_ARM
	var head := DT.Part.HEAD
	var torso := DT.Part.TORSO
	# 한 의뢰의 세 구간 기록(해냄 · 부분 · 못 해냄 하나 이상). 버티기의 0은 세 기록: 패배 · 시간 초과 · 먼저 댄 칼 셋.
	var rows: Array = [
		[CLOSE_PATH, 4, [_hold_rec(n, 0, true, C)], [_hold_rec(n, 1, true, C)],
			[_hold_rec(n, 0, false, DT.EndReason.PLAYER_DEFEATED), _hold_rec(n, 0, false, DT.EndReason.TIME_UP), _hold_rec(n, 3, true, C)]],
		[RIVAL_PATH, 5, [_part_rec([arm], C)], [_part_rec([arm, torso], C)], [_part_rec([], DT.EndReason.TIME_UP)]],
		[DUN_PATH, 6, [_part_rec([head], C)], [_part_rec([head, torso], C)], [_part_rec([], DT.EndReason.TIME_UP)]],
	]
	var section_names := ["해냄", "부분", "못 해냄"]
	for row: Array in rows:
		var commission := _commission(row[0])
		var label := commission.resource_path.get_file()
		var want_lines := [commission.success_line, commission.partial_line, commission.fail_line]
		for k in 3:
			for record: DuelRecord in row[2 + k]:
				var r := _settle(commission, record, int(row[1]))
				var score := int(r["score"])
				_expect(errs, r["reaction"] == want_lines[k], "[④ %s %s] 한마디 '%s' (기대 그 구간의 글)" % [label, section_names[k], r["reaction"]])
				if k == 0:
					_expect(errs, score > TIP_FLOOR, "[④ %s] 해냄 구간의 점수 %d가 팁 문턱 이하" % [label, score])
				elif k == 1:
					_expect(errs, score > 0 and score <= TIP_FLOOR, "[④ %s] 부분 구간의 점수 %d가 1~70이 아님" % [label, score])
				else:
					_expect(errs, score == 0, "[④ %s] 못 해냄 구간의 점수 %d가 0이 아님" % [label, score])
				var want_items := rep.settle_items(commission.reputation_effect, score, TIP_FLOOR, bool(r["won"]), SCALE_DAY)
				_expect(errs, r["items"] == want_items, "[④ %s %s] 평판 항목 %s (기대 reputation_effect × 2 → %s)" % [label, section_names[k], str(r["items"]), str(want_items)])
