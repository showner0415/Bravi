extends RefCounted
## T130~T133: 대련(계획 043, 결정 653~665). 조건의 셈, 의뢰의 상대 맞춤, 대련의 판과 표시, 의뢰의 데이터와 하루.
## 값(횟수·부분 점수·자세)은 spar.tres에서 읽는다: 결정 662의 값 고침이 옮겨도 이 파일은 그대로다.
## 놓은 코어(States.put)는 걸리지 않는다: 그 뒤의 tick은 끝나지 않는다(위험 R9). 씬을 보는 곳은 _update_views(0.0)만 부른다.

const Fourth := preload("res://tests/fourth_opponent_tests.gd")
const Bot := preload("res://tests/duel_bots.gd")
const Plain := preload("res://tests/plain_opponent.gd")
const States := preload("res://tests/opponent_states.gd")
const DT := preload("res://scripts/duel/duel_types.gd")
const Session := preload("res://scripts/game_session.gd")
const Ui := preload("res://scripts/day_ui.gd")

const SPAR_PATH := "res://data/commissions/spar.tres"
const FIRST_BLOOD_PATH := "res://data/commissions/first_blood.tres"
const AGOSTINO_PATH := "res://data/opponents/opponent_05.tres"
const COMMISSION_DIR := "res://data/commissions"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const REPUTATION_PATH := "res://data/reputation_rules.tres"
const DAY_DIR := "res://data/days/"
const DELTA := 1.0 / 60.0
const RUN_LIMIT := 100.0
const SEEDS := 10

var _tree: SceneTree
var _f: Fourth = Fourth.new()


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T130", "name": "대련 조건의 셈: 무너뜨린 수와 상처, 부분 점수, 판에서 세 번째 무너짐의 순간에 끝남, 무너진 상대를 치면 그 자리에서 0점, 상태 없음", "fn": t130_spar_condition},
		{"id": "T131", "name": "의뢰의 상대 맞춤: with_posture, 칸이 빈 의뢰는 같은 객체, 결투 씬의 날과 단, 연습 판", "fn": t131_fit_opponent},
		{"id": "T132", "name": "대련의 판과 표시: 치지 않는 봇과 치는 봇, 게이지의 글, 귀띔, 첫 피에는 귀띔 없음", "fn": t132_spar_duel},
		{"id": "T133", "name": "대련 의뢰의 데이터와 하루: spar.tres, 4일차의 첫 자리, 카운터의 상대 줄, 정산의 한마디와 평판", "fn": t133_spar_data},
	]


func cleanup() -> void:
	_tree = null


# ================================================================ 도우미

func _ok(errs: Array[String]) -> String:
	return "OK" if errs.is_empty() else ", ".join(errs)


func _expect(errs: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		errs.append(msg)


func _spar() -> Commission:
	return load(SPAR_PATH) as Commission


func _cond() -> SparCondition:
	return _spar().conditions[0] as SparCondition


## 손으로 만든 기록: 무너뜨린 수, 유효타 수, 채점하지 않는 이벤트(머리 스침 · 막힌 공격 · 내가 맞은 스침 · 무너짐 끝)를 섞을지.
func _rec(starts: int, hits := 0, noise := false) -> DuelRecord:
	var rec := DuelRecord.new()
	for i in starts:
		rec.add({"type": DuelRecord.STAGGER_START, "t": 1.0 + i})
	if noise:
		rec.add({"type": DuelRecord.ATTACK, "t": 0.5, "result": DT.AttackResult.GRAZE, "part": DT.Part.HEAD})
		rec.add({"type": DuelRecord.ATTACK, "t": 0.6, "result": DT.AttackResult.BLOCKED, "part": DT.Part.TORSO})
		rec.add({"type": DuelRecord.STRIKE, "t": 0.7, "result": DT.StrikeResult.GRAZE})
		rec.add({"type": DuelRecord.STAGGER_END, "t": 2.5})
	for i in hits:
		rec.add({"type": DuelRecord.ATTACK, "t": 3.0 + i, "result": DT.AttackResult.HIT, "part": DT.Part.TORSO})
	return rec


func _hits(record: DuelRecord) -> int:
	return record.count_where(DuelRecord.ATTACK, "result", DT.AttackResult.HIT)


func _count(core: DuelCore, type: StringName) -> int:
	return core.record.of_type(type).size()


## 치지 않는 봇(막고, 빈틈에 가운데 중단, 끝내기 없음)의 설정. finisher가 참이면 무너진 상대도 친다.
func _bot_cfg(finisher: bool) -> Dictionary:
	var cfg := Bot.first_blood_cfg()
	if not finisher:
		cfg.erase("finisher")
	return cfg


## 조건을 건 코어를 봇으로 끝까지(또는 RUN_LIMIT까지) 돌린다. 엉킴을 끈 무기라 밀려나는 일이 판을 흔들지 않는다.
func _run(opp: OpponentData, cond: SparCondition, cfg: Dictionary, seed_value: int, rules: DuelRules) -> DuelCore:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var weapon := (load(WEAPON_PATH) as WeaponData).duplicate() as WeaponData
	weapon.close_bind_time = 0.0
	var core := DuelCore.new()
	var conds: Array[CommissionCondition] = [cond]
	core.setup(rules, weapon, opp, rng, conds, false)
	var bot := Bot.new(core, cfg)
	core.step(1)
	while not core.ended and core.time < RUN_LIMIT:
		core.tick(DELTA)
		bot.update()
	return core


## 한 칸 자세로 줄인 옛 규칙의 아고스티노: 빈틈마다 가운데 중단 한 번이 무너뜨린다.
func _tiny_opponent() -> OpponentData:
	var ago := load(AGOSTINO_PATH) as OpponentData
	return Plain.of(ago).with_posture(1, 1)


func _one_day(commission_path: String, day_number: int) -> DayState:
	var data := DayData.new()
	var one: Array[Commission] = [load(commission_path) as Commission]
	data.commissions = one
	var day := DayState.new(load(Session.ECONOMY_PATH) as EconomyRules, data)
	day.day_number = day_number
	return day


## 하루의 결투 씬. 호출한 쪽이 free()한다. 걸리지 않게 처리를 끈다(위험 R9).
func _open_day_duel(commission_path: String, day_number: int) -> Node:
	var day := _one_day(commission_path, day_number)
	day.accept()
	var duel: Node = (load(Session.DUEL_PATH) as PackedScene).instantiate()
	duel.set("day", day)
	duel.set("mouse_aim_enabled", false)
	duel.set("rng_seed", 1)
	_tree.root.add_child(duel)
	duel.set_process(false)
	duel.set_physics_process(false)
	return duel


## 의뢰를 넣은 연습 꼴의 결투 씬(날 없음). 호출한 쪽이 free()한다.
func _open_commission_duel(commission_path: String) -> Node:
	var duel: Node = (load(Session.DUEL_PATH) as PackedScene).instantiate()
	duel.set("commission", load(commission_path))
	duel.set("mouse_aim_enabled", false)
	duel.set("rng_seed", 1)
	_tree.root.add_child(duel)
	duel.set_process(false)
	duel.set_physics_process(false)
	return duel


## 상대를 놓고 화면만 한 번 그린다. tick을 부르지 않는다(위험 R9).
func _show_state(duel: Node, state: int) -> void:
	var core := duel.get("core") as DuelCore
	var now := States.put(core, state, null, 0.0, DT.Distance.ENGAGE)
	duel.set("_display_time", now)
	duel.call("_update_views", 0.0)


# ================================================================ T130 조건의 셈

func t130_spar_condition() -> String:
	var errs: Array[String] = []
	_check_counting(errs)
	_check_hint_and_meter(errs)
	_check_duel_ends(errs)
	_check_stateless(errs)
	return _ok(errs)


func _check_counting(errs: Array[String]) -> void:
	var cond := _cond()
	var need := cond.topples_needed
	# ① 무너뜨린 수별 점수와 끝.
	for k in need + 2:
		var rec := _rec(k)
		var want := 100 if k >= need else cond.partial_scores[mini(k, cond.partial_scores.size() - 1)]
		_expect(errs, cond.evaluate(rec) == want, "[①] 무너뜨림 %d: 점수 %d (기대 %d)" % [k, cond.evaluate(rec), want])
		_expect(errs, (cond.check_end(rec) != "") == (k >= need), "[①] 무너뜨림 %d: check_end '%s' (기대 %s)" % [k, cond.check_end(rec), "사유" if k >= need else "빈 글"])
	# ② 유효타가 하나라도 있으면 무너뜨린 수와 상관없이 wound_score, 판은 그 자리에서 끝난다.
	for k in need + 1:
		var rec := _rec(k, 1)
		_expect(errs, cond.evaluate(rec) == cond.wound_score, "[②] 무너뜨림 %d + 상처: 점수 %d (기대 %d)" % [k, cond.evaluate(rec), cond.wound_score])
		_expect(errs, cond.check_end(rec) != "", "[②] 무너뜨림 %d + 상처: check_end가 빈 글" % k)
	# ③ 스침(머리 포함) · 막힌 공격 · 내가 맞은 스침 · 무너짐의 끝은 점수도 끝도 바꾸지 않는다.
	for k in need:
		var plain := _rec(k)
		var noisy := _rec(k, 0, true)
		_expect(errs, cond.evaluate(plain) == cond.evaluate(noisy), "[③] 무너뜨림 %d: 채점하지 않는 이벤트가 점수를 바꿈 (%d → %d)" % [k, cond.evaluate(plain), cond.evaluate(noisy)])
		_expect(errs, cond.check_end(plain) == cond.check_end(noisy), "[③] 무너뜨림 %d: 채점하지 않는 이벤트가 끝을 바꿈" % k)
	# ⑦ 수치는 데이터다: 두 번에 끝나고 다치게 하면 30.
	var two := cond.duplicate() as SparCondition
	two.topples_needed = 2
	two.wound_score = 30
	_expect(errs, two.check_end(_rec(1)) == "" and two.check_end(_rec(2)) != "", "[⑦] 두 번 조건: 한 번은 계속, 두 번은 끝이 아님")
	_expect(errs, two.evaluate(_rec(2)) == 100 and two.evaluate(_rec(2, 1)) == 30, "[⑦] 두 번 조건: 점수 %d · 상처 %d (기대 100 · 30)" % [two.evaluate(_rec(2)), two.evaluate(_rec(2, 1))])
	_expect(errs, two.live_meter(_rec(1))["text"] == "무너뜨림 1/2", "[⑦] 두 번 조건의 게이지 글 '%s'" % two.live_meter(_rec(1))["text"])


func _check_hint_and_meter(errs: Array[String]) -> void:
	var cond := _cond()
	var need := cond.topples_needed
	# ⑧ 게이지의 글과 값, 귀띔, 설명.
	for k in need + 1:
		var meter := cond.live_meter(_rec(k))
		_expect(errs, String(meter.get("text", "")) == "무너뜨림 %d/%d" % [k, need], "[⑧] 무너뜨림 %d: 게이지 글 '%s'" % [k, meter.get("text", "")])
		_expect(errs, int(meter.get("value", -1)) == int(100.0 * k / need), "[⑧] 무너뜨림 %d: 게이지 값 %s (기대 %d)" % [k, str(meter.get("value", -1)), int(100.0 * k / need)])
		_expect(errs, int(meter.get("pending", -1)) == 0, "[⑧] 게이지의 pending이 0이 아님")
	var live := _rec(1)
	_expect(errs, cond.stagger_hint(live) == cond.hold_hint and cond.hold_hint != "", "[⑧] 진행 중 귀띔 '%s' (기대 '%s')" % [cond.stagger_hint(live), cond.hold_hint])
	var done := _rec(need)
	done.ended = true
	_expect(errs, cond.stagger_hint(done) == "", "[⑧] 끝난 판의 귀띔 '%s' (기대 빈 글)" % cond.stagger_hint(done))
	_expect(errs, cond.describe().contains(str(need)), "[⑧] describe에 횟수 %d가 없다: '%s'" % [need, cond.describe()])
	_expect(errs, not cond.describe().contains("무장 해제"), "[⑧] describe에 '무장 해제'가 있다")
	var base := CommissionCondition.new()
	_expect(errs, base.stagger_hint(live) == "", "[⑧] 기반 클래스의 stagger_hint가 빈 글이 아님")


## ④~⑤: 한 칸 자세의 상대로 치지 않는 봇은 세 번째 무너짐의 시각에 끝내고, 치는 봇은 첫 무너짐 뒤의 유효타에서 0점으로 끝난다.
func _check_duel_ends(errs: Array[String]) -> void:
	var cond := _cond()
	var need := cond.topples_needed
	var opp := _tiny_opponent()
	var rules: DuelRules = _f._rules()
	var calm := _run(opp, cond, _bot_cfg(false), 1, rules)
	var starts := calm.record.of_type(DuelRecord.STAGGER_START)
	_expect(errs, calm.end_reason == DT.EndReason.CONDITION, "[④] 끝난 까닭 %d (기대 조건) 시각 %.1f" % [calm.end_reason, calm.time])
	_expect(errs, starts.size() == need, "[④] STAGGER_START %d (기대 %d)" % [starts.size(), need])
	_expect(errs, _count(calm, DuelRecord.STAGGER_END) == need - 1, "[④] STAGGER_END %d (기대 %d)" % [_count(calm, DuelRecord.STAGGER_END), need - 1])
	if starts.size() == need:
		var last_t := float(starts[need - 1]["t"])
		_expect(errs, absf(calm.record.elapsed - last_t) < 0.0001, "[④] 끝난 시각 %.4f · 마지막 무너짐 %.4f (같아야 한다)" % [calm.record.elapsed, last_t])
	_expect(errs, cond.evaluate(calm.record) == 100, "[④] 점수 %d (기대 100)" % cond.evaluate(calm.record))
	_expect(errs, _hits(calm.record) == 0, "[④] 치지 않는 봇인데 유효타 %d" % _hits(calm.record))

	var rough := _run(opp, cond, _bot_cfg(true), 1, rules)
	var rough_hits := rough.record.of_type(DuelRecord.ATTACK).filter(func(ev: Dictionary) -> bool: return ev["result"] == DT.AttackResult.HIT)
	_expect(errs, rough.end_reason == DT.EndReason.CONDITION and rough_hits.size() >= 1, "[⑤] 끝난 까닭 %d · 유효타 %d (기대 조건 · 1 이상)" % [rough.end_reason, rough_hits.size()])
	_expect(errs, _count(rough, DuelRecord.STAGGER_START) == 1, "[⑤] STAGGER_START %d (기대 1)" % _count(rough, DuelRecord.STAGGER_START))
	_expect(errs, cond.evaluate(rough.record) == cond.wound_score, "[⑤] 점수 %d (기대 %d)" % [cond.evaluate(rough.record), cond.wound_score])
	if not rough_hits.is_empty():
		var hit_t := float((rough_hits[0] as Dictionary)["t"])
		_expect(errs, absf(rough.record.elapsed - hit_t) < 0.0001, "[⑤] 끝난 시각 %.4f · 유효타 %.4f (같아야 한다)" % [rough.record.elapsed, hit_t])

	# ⑦ 판에서도 수치가 데이터다.
	var two := cond.duplicate() as SparCondition
	two.topples_needed = 2
	two.wound_score = 30
	var two_calm := _run(opp, two, _bot_cfg(false), 1, rules)
	_expect(errs, two_calm.end_reason == DT.EndReason.CONDITION and _count(two_calm, DuelRecord.STAGGER_START) == 2 and two.evaluate(two_calm.record) == 100,
		"[⑦] 두 번 조건의 판: 까닭 %d · 무너뜨림 %d · 점수 %d (기대 조건 · 2 · 100)" % [two_calm.end_reason, _count(two_calm, DuelRecord.STAGGER_START), two.evaluate(two_calm.record)])
	var two_rough := _run(opp, two, _bot_cfg(true), 1, rules)
	_expect(errs, two.evaluate(two_rough.record) == 30, "[⑦] 두 번 조건의 치는 봇: 점수 %d (기대 30)" % two.evaluate(two_rough.record))


## ⑥ 같은 조건 자원으로 두 판을 이어 돌려도 둘째 판이 0에서 센다(상태 없음).
func _check_stateless(errs: Array[String]) -> void:
	var cond := _cond()
	var opp := _tiny_opponent()
	var rules: DuelRules = _f._rules()
	var first := _run(opp, cond, _bot_cfg(false), 1, rules)
	_expect(errs, cond.check_end(DuelRecord.new()) == "", "[⑥] 첫 판 뒤 빈 기록에서 check_end가 사유를 냄")
	var second := _run(opp, cond, _bot_cfg(false), 1, rules)
	_expect(errs, _count(second, DuelRecord.STAGGER_START) == cond.topples_needed and cond.evaluate(second.record) == 100,
		"[⑥] 둘째 판: 무너뜨림 %d · 점수 %d (기대 %d · 100)" % [_count(second, DuelRecord.STAGGER_START), cond.evaluate(second.record), cond.topples_needed])
	_expect(errs, absf(first.record.elapsed - second.record.elapsed) < 0.0001, "[⑥] 같은 씨앗의 두 판 길이가 다름 (%.3f · %.3f)" % [first.record.elapsed, second.record.elapsed])


# ================================================================ T131 의뢰의 상대 맞춤

func t131_fit_opponent() -> String:
	var errs: Array[String] = []
	var ago := load(AGOSTINO_PATH) as OpponentData
	_check_with_posture(errs, ago)
	_check_blank_commissions(errs)
	_check_scene_opponent(errs, ago)
	_check_spar_values(errs, ago)
	return _ok(errs)


## 칸 둘과 저장 아닌 값(경로·이름)을 뺀 나머지가 같은가.
func _compare_rest(errs: Array[String], label: String, a: OpponentData, b: OpponentData, skip: Array) -> void:
	for p: Dictionary in a.get_property_list():
		if (int(p["usage"]) & PROPERTY_USAGE_STORAGE) == 0:
			continue
		var prop_name := String(p["name"])
		if prop_name in skip or prop_name.begins_with("resource_") or prop_name.begins_with("metadata/"):
			continue
		if a.get(prop_name) != b.get(prop_name):
			errs.append("%s: '%s'이 다르다" % [label, prop_name])


func _check_with_posture(errs: Array[String], ago: OpponentData) -> void:
	var base_max := ago.posture_max
	var base_recover := ago.stagger_recover_posture
	_expect(errs, ago.with_posture(0, 0) == ago, "[①] with_posture(0, 0)이 자기 자신이 아님")
	_expect(errs, ago.with_posture(-1, 0) == ago, "[①] with_posture(-1, 0)이 자기 자신이 아님")
	var skip := ["posture_max", "stagger_recover_posture"]
	var cases := [
		{"label": "(3, 0)", "args": [3, 0], "max": 3, "recover": clampi(base_recover, 1, 3)},
		{"label": "(0, 2)", "args": [0, 2], "max": base_max, "recover": clampi(2, 1, base_max)},
		{"label": "(3, 9)", "args": [3, 9], "max": 3, "recover": 3},
	]
	for c: Dictionary in cases:
		var args: Array = c["args"]
		var copy := ago.with_posture(int(args[0]), int(args[1]))
		_expect(errs, copy != ago, "[①] with_posture%s가 사본이 아니다" % c["label"])
		_expect(errs, copy.posture_max == int(c["max"]), "[①] with_posture%s: 자세 %d (기대 %d)" % [c["label"], copy.posture_max, int(c["max"])])
		_expect(errs, copy.stagger_recover_posture == int(c["recover"]), "[①] with_posture%s: 되찾는 자세 %d (기대 %d)" % [c["label"], copy.stagger_recover_posture, int(c["recover"])])
		_compare_rest(errs, "[①] with_posture%s" % c["label"], ago, copy, skip)
	_expect(errs, ago.posture_max == base_max and ago.stagger_recover_posture == base_recover, "[①] 원본의 두 값이 바뀜")


## ② 두 칸이 0인 의뢰는 받은 상대 그 객체를 돌려준다.
func _check_blank_commissions(errs: Array[String]) -> void:
	var blank := 0
	for c in CommissionLibrary.load_tree(COMMISSION_DIR):
		if c.opponent == null:
			continue
		if c.opponent_posture_max <= 0 and c.opponent_recover_posture <= 0:
			blank += 1
			_expect(errs, c.fit_opponent(c.opponent) == c.opponent, "[②] %s: 칸이 빈데 fit_opponent가 사본을 돌려줌" % c.resource_path.get_file())
		else:
			_expect(errs, c.fit_opponent(c.opponent) != c.opponent, "[②] %s: 칸이 있는데 fit_opponent가 원본을 돌려줌" % c.resource_path.get_file())
	_expect(errs, blank >= 1, "[②] 칸이 빈 의뢰가 하나도 없다")


## ③ ④ 결투 씬이 고른 상대. 걸지 않고 읽기만 한다.
func _check_scene_opponent(errs: Array[String], ago: OpponentData) -> void:
	var spar := _spar()
	_expect(errs, ago.tier_for_day(4) == 0 and ago.tier_for_day(6) > 0, "[③] 전제: 4일차는 1단 · 6일차는 2단 이상이어야 한다 (%d · %d)" % [ago.tier_for_day(4), ago.tier_for_day(6)])
	for day_number in [4, 6]:
		var duel := _open_day_duel(SPAR_PATH, day_number)
		var core := duel.get("core") as DuelCore
		var used := core.opponent_data
		var tag := "[③ %d일차]" % day_number
		_expect(errs, used != ago, "%s 코어의 상대가 원본 그 객체다" % tag)
		_expect(errs, used.posture_max == spar.opponent_posture_max and used.stagger_recover_posture == spar.opponent_recover_posture,
			"%s 자세 %d · 되찾는 자세 %d (기대 %d · %d)" % [tag, used.posture_max, used.stagger_recover_posture, spar.opponent_posture_max, spar.opponent_recover_posture])
		_expect(errs, core.brain.posture == spar.opponent_posture_max, "%s 뇌의 자세 %d (기대 %d)" % [tag, core.brain.posture, spar.opponent_posture_max])
		_expect(errs, used.attacks == ago.for_day(day_number).attacks, "%s 공격 목록이 %d단의 것이 아니다" % [tag, ago.tier_for_day(day_number) + 1])
		duel.free()
	# 칸이 빈 의뢰(첫 피)의 1일차 판은 원본 그 객체다(4일차는 바르톨로의 2단이라 사본이다).
	var bartolo := (load(FIRST_BLOOD_PATH) as Commission).opponent
	var first := _open_day_duel(FIRST_BLOOD_PATH, 1)
	_expect(errs, (first.get("core") as DuelCore).opponent_data == bartolo, "[③] 첫 피 1일차 판의 상대가 원본 그 객체가 아니다")
	first.free()
	var first_four := _open_day_duel(FIRST_BLOOD_PATH, 4)
	var four_core := first_four.get("core") as DuelCore
	_expect(errs, four_core.opponent_data.posture_max == bartolo.posture_max and four_core.opponent_data.stagger_recover_posture == bartolo.stagger_recover_posture,
		"[③] 첫 피 4일차 판의 자세가 원본과 다르다")
	first_four.free()
	# ④ 의뢰 없는 연습 판은 원본의 자세다.
	var practice: Node = (load(Session.DUEL_PATH) as PackedScene).instantiate()
	practice.set("practice_opponent", ago)
	practice.set("mouse_aim_enabled", false)
	practice.set("rng_seed", 1)
	_tree.root.add_child(practice)
	practice.set_process(false)
	practice.set_physics_process(false)
	var practice_core := practice.get("core") as DuelCore
	_expect(errs, practice_core.opponent_data.posture_max == ago.posture_max and practice_core.opponent_data.stagger_recover_posture == ago.stagger_recover_posture,
		"[④] 연습 판의 자세 %d · %d (기대 원본 %d · %d)" % [practice_core.opponent_data.posture_max, practice_core.opponent_data.stagger_recover_posture, ago.posture_max, ago.stagger_recover_posture])
	_expect(errs, practice_core.brain.posture == ago.posture_max, "[④] 연습 판의 뇌의 자세 %d (기대 %d)" % [practice_core.brain.posture, ago.posture_max])
	practice.free()


## ⑤ 대련의 두 칸은 값을 적지 않고 관계만 본다.
func _check_spar_values(errs: Array[String], ago: OpponentData) -> void:
	var spar := _spar()
	var mx := spar.opponent_posture_max
	var rc := spar.opponent_recover_posture
	_expect(errs, rc >= 1 and rc <= mx and mx <= ago.posture_max, "[⑤] 대련의 칸 자세 %d · 되찾는 자세 %d · 원본 자세 %d (기대 1 ≤ 되찾는 ≤ 자세 ≤ 원본)" % [mx, rc, ago.posture_max])


# ================================================================ T132 대련의 판과 표시

func t132_spar_duel() -> String:
	var errs: Array[String] = []
	_check_real_runs(errs)
	_check_screen(errs)
	_check_other_commissions(errs)
	_check_meter_text(errs)
	return _ok(errs)


## ① ② 실제 데이터(spar.tres의 조건 · fit_opponent · 날 4의 규칙 사본)로 씬 없이 코어와 봇만 건다.
func _check_real_runs(errs: Array[String]) -> void:
	var spar := _spar()
	var cond := _cond()
	var ago := load(AGOSTINO_PATH) as OpponentData
	var opp := spar.fit_opponent(ago.for_day(4))
	var calm_done := 0
	var calm_hits := 0
	var rough_staggered := 0
	for seed_value in range(1, SEEDS + 1):
		var rules: DuelRules = _f._rules()
		rules.stage_day = 4
		var calm := _run(opp, cond, _bot_cfg(false), seed_value, rules)
		var calm_score := cond.evaluate(calm.record)
		calm_hits += _hits(calm.record)
		if calm.end_reason == DT.EndReason.CONDITION and calm_score == 100:
			calm_done += 1
		print("  INFO [T132 ①] 씨앗 %d: %.1f초 · 끝 %d · 무너뜨림 %d · 점수 %d" % [seed_value, calm.record.elapsed, calm.end_reason, _count(calm, DuelRecord.STAGGER_START), calm_score])
		var rough := _run(opp, cond, _bot_cfg(true), seed_value, rules)
		var staggers := _count(rough, DuelRecord.STAGGER_START)
		if staggers > 0:
			rough_staggered += 1
			_expect(errs, cond.evaluate(rough.record) == cond.wound_score and _hits(rough.record) >= 1,
				"[②] 씨앗 %d: 무너뜨림 %d인데 점수 %d · 유효타 %d (기대 %d점 · 1 이상)" % [seed_value, staggers, cond.evaluate(rough.record), _hits(rough.record), cond.wound_score])
	_expect(errs, calm_done >= 1, "[①] 치지 않는 봇이 %d판 가운데 하나도 조건으로 100점에 끝내지 못했다" % SEEDS)
	_expect(errs, calm_hits == 0, "[①] 치지 않는 봇의 유효타 %d (기대 0)" % calm_hits)
	_expect(errs, rough_staggered >= 1, "[②] 치는 봇이 어느 판에서도 무너뜨리지 못해 확인할 판이 없다")


## ③ 대련 의뢰의 화면. 처음의 "무너뜨림 0/n"은 start_duel이 이미 그린 것이다. 이후는 놓고 그리기만 한다(tick 없음).
func _check_screen(errs: Array[String]) -> void:
	var cond := _cond()
	var duel := _open_commission_duel(SPAR_PATH)
	var core := duel.get("core") as DuelCore
	var hud := duel.get_node("HUD") as DuelHud
	var meter := hud.get("_meter") as DuelHud.Meter
	var view := duel.get_node("OpponentView") as OpponentView
	var label := view.get_node("StateLabel") as Label
	var hint := view.get_node("StateHint") as Label
	_expect(errs, meter.visible and meter.shown_text() == "무너뜨림 0/%d" % cond.topples_needed, "[③] 처음 게이지 '%s'(보임 %s) (기대 '무너뜨림 0/%d')" % [meter.shown_text(), meter.visible, cond.topples_needed])
	core.record.add({"type": DuelRecord.STAGGER_START, "t": 1.0})
	_show_state(duel, DT.OpponentState.STAGGER)
	_expect(errs, hint.visible and hint.text == cond.hold_hint, "[③] 무너짐의 귀띔 '%s'(보임 %s) (기대 '%s')" % [hint.text, hint.visible, cond.hold_hint])
	_expect(errs, label.text == "무너짐!", "[③] 상태 글자 '%s' (기대 '무너짐!')" % label.text)
	_expect(errs, meter.shown_text() == "무너뜨림 1/%d" % cond.topples_needed, "[③] 무너뜨림 하나 뒤 게이지 '%s'" % meter.shown_text())
	_show_state(duel, DT.OpponentState.IDLE)
	_expect(errs, not hint.visible, "[③] 대기로 돌아왔는데 귀띔이 남아 있다: '%s'" % hint.text)
	duel.free()


## ④ 조건이 귀띔을 주지 않는 의뢰의 무너짐에는 귀띔이 없다.
func _check_other_commissions(errs: Array[String]) -> void:
	var duel := _open_commission_duel(FIRST_BLOOD_PATH)
	var view := duel.get_node("OpponentView") as OpponentView
	var label := view.get_node("StateLabel") as Label
	var hint := view.get_node("StateHint") as Label
	_show_state(duel, DT.OpponentState.STAGGER)
	_expect(errs, label.text == "무너짐!", "[④] 첫 피 의뢰의 상태 글자 '%s' (기대 '무너짐!')" % label.text)
	_expect(errs, not hint.visible, "[④] 첫 피 의뢰의 무너짐에 귀띔이 있다: '%s'" % hint.text)
	duel.free()


## ④ 게이지의 글: text가 비면 지금의 "이름 값"(+ 덧말), 있으면 그 글. text만 바뀐 set_values도 글을 바꾼다.
func _check_meter_text(errs: Array[String]) -> void:
	var meter := DuelHud.Meter.new()
	meter.set_values("의심", 40, 0)
	_expect(errs, meter.shown_text() == "의심 40", "[④ 게이지] 글 '%s' (기대 '의심 40')" % meter.shown_text())
	meter.set_values("의심", 40, 5)
	_expect(errs, meter.shown_text() == "의심 40 (지금 끝나면 +5)", "[④ 게이지] 덧말 '%s'" % meter.shown_text())
	meter.set_values("무너뜨림", 33, 0, "무너뜨림 1/3")
	_expect(errs, meter.shown_text() == "무너뜨림 1/3", "[④ 게이지] text '%s'" % meter.shown_text())
	meter.set_values("무너뜨림", 33, 0, "무너뜨림 둘")
	_expect(errs, meter.shown_text() == "무너뜨림 둘", "[④ 게이지] text만 바꾼 set_values가 글을 바꾸지 않음 '%s'" % meter.shown_text())
	meter.set_values("무너뜨림", 33, 0)
	_expect(errs, meter.shown_text() == "무너뜨림 33", "[④ 게이지] text를 비우면 이름 값이 아님 '%s'" % meter.shown_text())
	meter.free()


# ================================================================ T133 의뢰의 데이터와 하루

func t133_spar_data() -> String:
	var errs: Array[String] = []
	_check_data(errs)
	_check_day_slot(errs)
	_check_counter(errs)
	_check_day_flow(errs)
	return _ok(errs)


func _check_data(errs: Array[String]) -> void:
	var spar := _spar()
	if spar == null:
		errs.append("[①] spar.tres가 Commission으로 로드되지 않는다")
		return
	var ago := load(AGOSTINO_PATH) as OpponentData
	_expect(errs, spar.opponent != null and spar.opponent.resource_path == AGOSTINO_PATH, "[①] 상대가 opponent_05.tres가 아니다")
	_expect(errs, spar.client_name.contains(ago.display_name), "[①] 의뢰인 이름 '%s'에 상대 이름 '%s'이 없다" % [spar.client_name, ago.display_name])
	_expect(errs, spar.conditions.size() == 1 and spar.conditions[0] is SparCondition, "[①] 조건이 SparCondition 하나가 아니다")
	_expect(errs, not spar.opponent_wears_hat, "[①] 모자를 씌운다")
	_expect(errs, spar.stage != null and spar.stage.resource_path.get_file() == "court.tres", "[①] 무대가 안뜰이 아니다")
	_expect(errs, int(spar.reputation_effect.get("win", 0)) == 0, "[①] reputation_effect에 win이 있다")
	_expect(errs, int(spar.reputation_effect.get("success", 0)) > 0 and int(spar.reputation_effect.get("fail", 0)) < 0, "[①] 해냄 값이 0 이하이거나 못 해냄 값이 0 이상이다")
	_expect(errs, spar.base_reward > 0, "[①] 기본 보수 %d" % spar.base_reward)


func _check_day_slot(errs: Array[String]) -> void:
	var day := load(DAY_DIR + "day_04.tres") as DayData
	_expect(errs, day != null and not day.commissions.is_empty() and day.commissions[0].resource_path == SPAR_PATH, "[②] day_04의 첫 자리가 spar.tres가 아니다")
	if day != null:
		_expect(errs, day.base_guests <= day.commissions.size(), "[②] day_04의 기준 손님 수 %d가 목록 %d보다 크다" % [day.base_guests, day.commissions.size()])
	for n in [1, 2, 3]:
		var early := load(DAY_DIR + "day_0%d.tres" % n) as DayData
		for c in early.commissions:
			_expect(errs, c.resource_path != SPAR_PATH, "[②] day_0%d에 spar.tres가 있다" % n)


## ③ 카운터의 이름과 "상대:" 줄이 한 화면에 선다.
func _check_counter(errs: Array[String]) -> void:
	var spar := _spar()
	for row: Array in [[4, "상대: 아고스티노 · 엇박 찌르기"], [6, "상대: 아고스티노 · 엇박 찌르기 2단"]]:
		var counter: Node = (load(Session.COUNTER_PATH) as PackedScene).instantiate()
		counter.set("day", _one_day(SPAR_PATH, int(row[0])))
		_tree.root.add_child(counter)
		var text := Ui.all_text(counter)
		_expect(errs, text.contains(spar.client_name), "[③ %d일차] 카운터에 의뢰인 이름이 없다" % int(row[0]))
		_expect(errs, text.contains(String(row[1])), "[③ %d일차] 카운터에 '%s'가 없다" % [int(row[0]), row[1]])
		counter.free()


## 한 손님의 하루(평판 규칙 실음)를 그 기록으로 정산한다. 정산 화면의 한마디와 결과를 돌려준다.
func _settle(record: DuelRecord) -> Dictionary:
	var data := DayData.new()
	var one: Array[Commission] = [_spar()]
	data.commissions = one
	var day := DayState.new(load(Session.ECONOMY_PATH) as EconomyRules, data, null, null, load(REPUTATION_PATH) as ReputationRules)
	day.accept()
	day.finish_duel(record)
	var result := day.last_result()
	var settlement: Node = (load(Session.SETTLEMENT_PATH) as PackedScene).instantiate()
	settlement.set("day", day)
	_tree.root.add_child(settlement)
	var reaction := settlement.find_child("Reaction", true, false) as Label
	var names: Array[String] = []
	var items: Array = result.get("reputation_items", [])
	for item: Array in items:
		names.append(String(item[0]))
	var out := {"result": result, "reaction": reaction.text if reaction != null else "", "items": names}
	settlement.free()
	return out


func _check_day_flow(errs: Array[String]) -> void:
	var spar := _spar()
	var cond := _cond()
	# 세 번 무너뜨린 판: 100점, 이기지 않음, "해냈다"만, 해낸 말.
	var full := _rec(cond.topples_needed)
	full.ended = true
	full.end_reason = DT.EndReason.CONDITION
	full.elapsed = 30.0
	var a := _settle(full)
	var a_result: Dictionary = a["result"]
	var a_items: Array = a["items"]
	_expect(errs, int(a_result["score"]) == 100, "[④ 세 번] 충족도 %d (기대 100)" % int(a_result["score"]))
	_expect(errs, not bool(a_result["won"]), "[④ 세 번] won이 참이다")
	_expect(errs, "해냈다" in a_items and not ("이겼다" in a_items), "[④ 세 번] 평판 항목 %s (기대 해냈다 있음 · 이겼다 없음)" % str(a_items))
	_expect(errs, a["reaction"] == spar.success_line, "[④ 세 번] 한마디 '%s' (기대 success_line)" % a["reaction"])
	# 다치게 한 판: 0점, "해내지 못했다", 못 한 말.
	var wound := _rec(1, 1)
	wound.ended = true
	wound.end_reason = DT.EndReason.CONDITION
	wound.elapsed = 12.0
	var b := _settle(wound)
	var b_result: Dictionary = b["result"]
	var b_items: Array = b["items"]
	_expect(errs, int(b_result["score"]) == cond.wound_score, "[④ 상처] 충족도 %d (기대 %d)" % [int(b_result["score"]), cond.wound_score])
	_expect(errs, "해내지 못했다" in b_items and not ("해냈다" in b_items) and not ("이겼다" in b_items), "[④ 상처] 평판 항목 %s (기대 해내지 못했다만)" % str(b_items))
	_expect(errs, b["reaction"] == spar.fail_line, "[④ 상처] 한마디 '%s' (기대 fail_line)" % b["reaction"])
	# 둘 무너뜨리고 시간 초과: 부분 점수, 부분의 말, 팁 없음(결정 656).
	var half := _rec(cond.topples_needed - 1)
	half.ended = true
	half.end_reason = DT.EndReason.TIME_UP
	half.elapsed = 90.0
	var c := _settle(half)
	var c_result: Dictionary = c["result"]
	var c_items: Array = c["items"]
	var want := cond.partial_scores[mini(cond.topples_needed - 1, cond.partial_scores.size() - 1)]
	_expect(errs, int(c_result["score"]) == want, "[④ 부분] 충족도 %d (기대 %d)" % [int(c_result["score"]), want])
	_expect(errs, c["reaction"] == spar.partial_line, "[④ 부분] 한마디 '%s' (기대 partial_line)" % c["reaction"])
	_expect(errs, int(c_result["tip"]) == 0, "[④ 부분] 팁 %d (기대 0)" % int(c_result["tip"]))
	_expect(errs, not ("해냈다" in c_items), "[④ 부분] 부분 점수에 '해냈다'가 붙었다: %s" % str(c_items))
