extends RefCounted
## T28~T33: 하루 루프 — 경제 규칙, 보수 공식, 정산, 하루 상태와 장부, 결투의 하루 모드, 화면.
## 화면과 결투 씬에는 day를 직접 넣는다(GameSession 오토로드에 의존하지 않는다).

const Bot := preload("res://tests/duel_bots.gd")
const DT := preload("res://scripts/duel/duel_types.gd")

const ECONOMY_PATH := "res://data/economy_rules.tres"
const DAY_PATH := "res://data/days/day_01.tres"
const DUEL_RULES_PATH := "res://data/duel_rules.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const FIRST_BLOOD_PATH := "res://data/commissions/first_blood.tres"
const FEATHER_PATH := "res://data/commissions/feather_cut.tres"
const THROW_PATH := "res://data/commissions/throw_match.tres"

const DELTA := 1.0 / 60.0
## 한 판이 끝나기를 기다리는 프레임 상한(제한 시간 90초보다 넉넉하게).
const MAX_FRAMES := 7200
const AIM_MID_THRUST := [DT.Direction.CENTER, DT.Height.MID]

var _tree: SceneTree
var _mouse_pos := Vector2.ZERO


## 점수를 고정해 돌려주는 테스트용 조건.
class FixedScore extends CommissionCondition:
	var score := 0

	func describe() -> String:
		return "테스트용 고정 점수 %d" % score

	func evaluate(_record: DuelRecord) -> int:
		return score

	func explain(_record: DuelRecord) -> Array[String]:
		var lines: Array[String] = ["고정 점수 %d" % score]
		return lines


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T28", "name": "하루 데이터: 경제 규칙과 day_01 로드", "fn": t28_data},
		{"id": "T29", "name": "보수 공식: 표 열 줄과 단조성", "fn": t29_payout},
		{"id": "T30", "name": "정산 한 건: 충족도 → 돈, 부상", "fn": t30_settle},
		{"id": "T31", "name": "하루 상태와 장부: 45 → 103 → 152 → 72", "fn": t31_day_state},
		{"id": "T32", "name": "결투의 하루 모드: 다시 하기 없음, Space로 정산", "fn": t32_duel_day_mode},
		{"id": "T33", "name": "화면: 처음 화면, 카운터, 정산, 폐점", "fn": t33_screens},
	]


func cleanup() -> void:
	_tree = null


# ================================================================ 도우미

func _expect(errs: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		errs.append(msg)


func _result(errs: Array[String]) -> String:
	return "OK" if errs.is_empty() else " / ".join(errs)


## 테스트가 직접 만든 경제 규칙(.tres의 수치를 바꿔도 표와 장부 검사가 흔들리지 않게).
func _rules(tip_floor := 70, rent := 60, medical_fee := 20, starting_money := 0) -> EconomyRules:
	var rules := EconomyRules.new()
	rules.tip_floor = tip_floor
	rules.rent = rent
	rules.medical_fee = medical_fee
	rules.starting_money = starting_money
	return rules


## 고정 점수 조건 하나를 가진 테스트용 의뢰.
func _fixed_commission(client: String, base_reward: int, tip_max: int, score: int) -> Commission:
	var condition := FixedScore.new()
	condition.score = score
	var conditions: Array[CommissionCondition] = [condition]
	var commission := Commission.new()
	commission.client_name = client
	commission.dialogue = "테스트용 사연"
	commission.conditions = conditions
	commission.base_reward = base_reward
	commission.tip_max = tip_max
	return commission


## 손으로 만든 끝난 기록.
func _record(end_reason: int, elapsed := 40.0) -> DuelRecord:
	var record := DuelRecord.new()
	record.ended = true
	record.end_reason = end_reason
	record.elapsed = elapsed
	return record


## 실제 규칙·무기·상대로 의뢰의 결투를 끝까지 돌린 코어. cfg가 null이면 입력이 없다.
func _play(commission: Commission, cfg: Variant = null, seed_value := 1) -> DuelCore:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var core := DuelCore.new()
	core.setup(load(DUEL_RULES_PATH), load(WEAPON_PATH), commission.opponent, rng, commission.conditions)
	var bot: RefCounted = null
	if cfg != null:
		bot = Bot.new(core, cfg)
	var frames := 0
	while not core.ended and frames < MAX_FRAMES:
		core.tick(DELTA)
		if bot != null:
			bot.call("update")
		frames += 1
	return core


## T16·T22의 봇: 막고, 빈틈이 생기는 공격 뒤에 중단 찌르기, 무너지면 중단 찌르기.
func _cfg_first_blood_bot() -> Dictionary:
	var counter := func(ev: Dictionary) -> Variant:
		return AIM_MID_THRUST if float(ev["recovery"]) > 0.0 else null
	return {"counter_fn": counter, "finisher": AIM_MID_THRUST}


## 공식을 테스트 쪽에서 따로 계산한 값(0.5 올림). [기본 보수, 팁]
func _want_pay(score: int, base_reward: int, tip_max: int, tip_floor: int) -> Array[int]:
	var base := int(floor(base_reward * score / 100.0 + 0.5))
	var tip := 0
	if score > tip_floor:
		tip = int(floor(tip_max * (score - tip_floor) / float(100 - tip_floor) + 0.5))
	var out: Array[int] = [base, tip]
	return out


func _snapshot(day: DayState) -> Array:
	return [day.phase, day.index, day.results.size(), day.money, day.day_number]


# ================================================================ T28 데이터

func t28_data() -> String:
	var errs: Array[String] = []
	var rules := load(ECONOMY_PATH) as EconomyRules
	if rules == null:
		errs.append("%s 가 EconomyRules로 로드되지 않음" % ECONOMY_PATH)
	else:
		_expect(errs, rules.tip_floor >= 0 and rules.tip_floor < 100, "tip_floor %d (0 이상 100 미만이어야 함)" % rules.tip_floor)
		_expect(errs, rules.rent >= 0, "rent %d" % rules.rent)
		_expect(errs, rules.medical_fee >= 0, "medical_fee %d" % rules.medical_fee)
		_expect(errs, rules.starting_money >= 0, "starting_money %d" % rules.starting_money)

	var day := load(DAY_PATH) as DayData
	if day == null:
		errs.append("%s 가 DayData로 로드되지 않음" % DAY_PATH)
		return _result(errs)
	_expect(errs, day.commissions.size() == 3, "day_01의 의뢰 %d개 (기대 3)" % day.commissions.size())
	var expected := [FirstBloodCondition, TargetPartCondition, ThrowUndetectedCondition]
	for i in mini(day.commissions.size(), expected.size()):
		var commission := day.commissions[i]
		if commission == null:
			errs.append("의뢰 %d가 비어 있음" % i)
			continue
		_expect(errs, commission.conditions.size() == 1 and is_instance_of(commission.conditions[0], expected[i]),
			"의뢰 %d(%s)의 조건 타입이 순서와 다름" % [i, commission.client_name])
	return _result(errs)


# ================================================================ T29 보수 공식

func t29_payout() -> String:
	var errs: Array[String] = []
	var rules := _rules()
	# [충족도, 기본 보수, 팁 최대, 기대 기본 보수, 기대 팁] — 계획 004의 보수 표 그대로.
	var table := [
		[100, 30, 15, 30, 15],
		[40, 30, 15, 12, 0],
		[0, 30, 15, 0, 0],
		[100, 45, 25, 45, 25],
		[90, 45, 25, 41, 17],
		[80, 45, 25, 36, 8],
		[70, 45, 25, 32, 0],
		[100, 40, 30, 40, 30],
		[85, 40, 30, 34, 15],
		[71, 40, 30, 28, 1],
	]
	for row in table:
		var pay := DayState.payout(row[0], row[1], row[2], rules)
		_expect(errs, pay["base"] == row[3] and pay["tip"] == row[4],
			"충족도 %d (%d/%d) → 기본 %d 팁 %d (기대 %d, %d)" % [row[0], row[1], row[2], pay["base"], pay["tip"], row[3], row[4]])

	# 실제 의뢰와 로드한 규칙: 충족도가 오를 때 줄지 않고, 상한을 넘지 않고, 양 끝이 맞다.
	var loaded := load(ECONOMY_PATH) as EconomyRules
	for path in [FIRST_BLOOD_PATH, FEATHER_PATH, THROW_PATH]:
		var commission := load(path) as Commission
		var prev_base := -1
		var prev_tip := -1
		for score in 101:
			var pay := DayState.payout(score, commission.base_reward, commission.tip_max, loaded)
			var base: int = pay["base"]
			var tip: int = pay["tip"]
			if base < prev_base or tip < prev_tip:
				errs.append("[%s] 충족도 %d에서 돈이 줄어듦" % [commission.client_name, score])
				break
			if base > commission.base_reward or tip > commission.tip_max:
				errs.append("[%s] 충족도 %d에서 상한을 넘음" % [commission.client_name, score])
				break
			prev_base = base
			prev_tip = tip
		var top := DayState.payout(100, commission.base_reward, commission.tip_max, loaded)
		_expect(errs, top["base"] == commission.base_reward and top["tip"] == commission.tip_max,
			"[%s] 충족도 100인데 최대가 아님" % commission.client_name)
		var bottom := DayState.payout(0, commission.base_reward, commission.tip_max, loaded)
		_expect(errs, bottom["base"] == 0 and bottom["tip"] == 0, "[%s] 충족도 0인데 돈이 있음" % commission.client_name)
	return _result(errs)


# ================================================================ T30 정산 한 건

func t30_settle() -> String:
	var errs: Array[String] = []
	var rules := load(ECONOMY_PATH) as EconomyRules
	var first_blood := load(FIRST_BLOOD_PATH) as Commission
	var throw_match := load(THROW_PATH) as Commission

	# 첫 피 + 봇 → 100점, 돈 최대, 부상 아님
	var a_core := _play(first_blood, _cfg_first_blood_bot())
	var a := DayState.settle(first_blood, a_core.record, rules)
	_expect(errs, a_core.end_reason == DT.EndReason.CONDITION, "[30a] 조건으로 끝나지 않음")
	_expect(errs, a["score"] == 100, "[30a] 충족도 %d (기대 100)" % a["score"])
	_expect(errs, a["base"] == first_blood.base_reward and a["tip"] == first_blood.tip_max, "[30a] 돈이 최대가 아님")
	_expect(errs, a["total"] == first_blood.base_reward + first_blood.tip_max, "[30a] 합 %d" % a["total"])
	_expect(errs, not a["injured"] and a["medical_fee"] == 0, "[30a] 부상으로 셈")
	_expect(errs, a["client_name"] == first_blood.client_name, "[30a] 의뢰인 이름이 다름")
	_expect(errs, is_equal_approx(a["elapsed"], a_core.record.elapsed), "[30a] 결투 시간이 다름")
	_expect(errs, a["base_max"] == first_blood.base_reward and a["tip_max"] == first_blood.tip_max, "[30a] 최대값이 다름")

	# 첫 피 + 입력 없이 짐 → 0점, 돈 0, 부상
	var b_core := _play(first_blood)
	var b := DayState.settle(first_blood, b_core.record, rules)
	_expect(errs, b_core.end_reason == DT.EndReason.PLAYER_DEFEATED, "[30b] 패배로 끝나지 않음")
	_expect(errs, b["score"] == 0 and b["total"] == 0, "[30b] 충족도 %d, 합 %d (기대 0, 0)" % [b["score"], b["total"]])
	_expect(errs, b["injured"] and b["medical_fee"] == rules.medical_fee, "[30b] 부상·치료비가 아님")

	# 지기 + 입력 없이 짐 → 충족도는 evaluate와 같고 돈은 공식대로, 부상
	var c_core := _play(throw_match)
	var c := DayState.settle(throw_match, c_core.record, rules)
	var c_score := throw_match.evaluate(c_core.record)
	var c_want := _want_pay(c_score, throw_match.base_reward, throw_match.tip_max, rules.tip_floor)
	_expect(errs, c_core.end_reason == DT.EndReason.PLAYER_DEFEATED, "[30c] 패배로 끝나지 않음")
	_expect(errs, c["score"] == c_score, "[30c] 충족도 %d, evaluate %d" % [c["score"], c_score])
	_expect(errs, c["base"] == c_want[0] and c["tip"] == c_want[1], "[30c] 돈 %d+%d (기대 %d+%d)" % [c["base"], c["tip"], c_want[0], c_want[1]])
	_expect(errs, c["injured"], "[30c] 부상이 아님")
	_expect(errs, c["lines"] == throw_match.explain(c_core.record), "[30c] 내역 줄이 explain과 다름")

	# 지기 + 같은 봇으로 이겨 버림 → 0점, 돈 0, 부상 아님
	var d_core := _play(throw_match, _cfg_first_blood_bot())
	var d := DayState.settle(throw_match, d_core.record, rules)
	_expect(errs, d_core.end_reason == DT.EndReason.CONDITION, "[30d] 조건으로 끝나지 않음")
	_expect(errs, d["score"] == 0 and d["total"] == 0, "[30d] 충족도 %d, 합 %d (기대 0, 0)" % [d["score"], d["total"]])
	_expect(errs, not d["injured"] and d["medical_fee"] == 0, "[30d] 부상으로 셈")

	# 고정 80점 + 종료 사유 CONDITION → 공식대로, 부상 아님 / TIME_UP → 부상 아님
	var fixed := _fixed_commission("고정", 45, 25, 80)
	var e_want := _want_pay(80, 45, 25, rules.tip_floor)
	var e := DayState.settle(fixed, _record(DT.EndReason.CONDITION), rules)
	_expect(errs, e["base"] == e_want[0] and e["tip"] == e_want[1], "[30e] 돈 %d+%d (기대 %d+%d)" % [e["base"], e["tip"], e_want[0], e_want[1]])
	_expect(errs, not e["injured"], "[30e] 조건으로 끝났는데 부상")
	var f := DayState.settle(fixed, _record(DT.EndReason.TIME_UP), rules)
	_expect(errs, not f["injured"] and f["medical_fee"] == 0, "[30f] 시간 초과인데 부상")
	return _result(errs)


# ================================================================ T31 하루 상태와 장부

func _three_fixed() -> DayData:
	var commissions: Array[Commission] = [
		_fixed_commission("첫째", 30, 15, 100),
		_fixed_commission("둘째", 45, 25, 90),
		_fixed_commission("셋째", 40, 30, 85),
	]
	var data := DayData.new()
	data.commissions = commissions
	return data


## 요청이 거짓을 돌려주고 아무것도 바꾸지 않았는가.
func _expect_refused(errs: Array[String], day: DayState, ok: bool, label: String, before: Array) -> void:
	_expect(errs, not ok, "%s 가 참을 돌려줌" % label)
	_expect(errs, _snapshot(day) == before, "%s 가 상태를 바꿈" % label)


func t31_day_state() -> String:
	var errs: Array[String] = []
	var P := DayState.Phase
	var data := _three_fixed()
	var day := DayState.new(_rules(70, 60, 20, 0), data)
	var won := _record(DT.EndReason.CONDITION)
	var lost := _record(DT.EndReason.PLAYER_DEFEATED)

	# 새 하루
	_expect(errs, day.phase == P.COUNTER and day.index == 0, "새 하루의 단계 %d, 순번 %d" % [day.phase, day.index])
	_expect(errs, day.current_commission() == data.commissions[0], "새 하루의 지금 의뢰가 첫째가 아님")
	_expect(errs, day.money == 0 and day.day_number == 1, "새 하루의 소지금 %d, 날 %d" % [day.money, day.day_number])

	# 카운터에서 틀린 요청
	var snap := _snapshot(day)
	_expect_refused(errs, day, day.finish_duel(won), "카운터에서 결투 끝내기", snap)
	_expect_refused(errs, day, day.proceed(), "카운터에서 다음", snap)
	_expect_refused(errs, day, day.next_day(), "카운터에서 다음 날", snap)

	# 첫째: 100점
	_expect(errs, day.accept() and day.phase == P.DUEL, "맡기 뒤 단계가 결투가 아님")
	snap = _snapshot(day)
	_expect_refused(errs, day, day.accept(), "결투에서 맡기", snap)
	_expect_refused(errs, day, day.proceed(), "결투에서 다음", snap)
	_expect_refused(errs, day, day.finish_duel(null), "결투에서 기록 없이 끝내기", snap)
	_expect(errs, day.finish_duel(won) and day.phase == P.SETTLEMENT, "결투 끝 뒤 단계가 정산이 아님")
	_expect(errs, day.money == 45 and day.results.size() == 1, "첫째 정산 뒤 소지금 %d (기대 45)" % day.money)
	_expect(errs, day.last_result().get("total", -1) == 45, "첫째 결과의 합이 45가 아님")
	snap = _snapshot(day)
	_expect_refused(errs, day, day.accept(), "정산에서 맡기", snap)
	_expect_refused(errs, day, day.finish_duel(won), "정산에서 결투 끝내기", snap)
	_expect_refused(errs, day, day.next_day(), "정산에서 다음 날", snap)
	_expect(errs, day.proceed() and day.phase == P.COUNTER and day.index == 1, "첫째 뒤 둘째 의뢰인으로 가지 않음")

	# 둘째: 90점
	day.accept()
	day.finish_duel(won)
	_expect(errs, day.money == 103, "둘째 정산 뒤 소지금 %d (기대 103)" % day.money)
	_expect(errs, day.proceed() and day.phase == P.COUNTER and day.index == 2, "둘째 뒤 셋째 의뢰인으로 가지 않음")

	# 셋째: 85점, 유효타를 맞고 끝남
	day.accept()
	day.finish_duel(lost)
	_expect(errs, day.money == 152, "셋째 정산 뒤 소지금 %d (기대 152)" % day.money)
	_expect(errs, day.last_result().get("injured", false), "셋째 결과가 부상이 아님")
	_expect(errs, not day.has_next_commission(), "셋째 뒤에도 남은 의뢰가 있다고 함")
	_expect(errs, day.proceed() and day.phase == P.CLOSING, "셋째 뒤 폐점으로 가지 않음")
	_expect(errs, day.money == 72, "폐점에 들어선 뒤 소지금 %d (기대 72)" % day.money)
	var summary := day.closing_summary()
	_expect(errs, summary.get("income") == 152 and summary.get("rent") == 60 and summary.get("medical") == 20,
		"폐점 요약의 수입·임대료·치료비가 다름: %s" % str(summary))
	_expect(errs, summary.get("injuries") == 1 and summary.get("expenses") == 80 and summary.get("profit") == 72,
		"폐점 요약의 부상·지출·손익이 다름: %s" % str(summary))
	_expect(errs, summary.get("money_before") == 152 and summary.get("money_after") == 72, "폐점 요약의 소지금 전후가 다름")
	_expect(errs, day.current_commission() == null, "폐점인데 지금 의뢰가 있음")

	# 폐점에서 틀린 요청(다음을 다시 불러도 지출이 두 번 빠지지 않는다)
	snap = _snapshot(day)
	_expect_refused(errs, day, day.proceed(), "폐점에서 다음", snap)
	_expect_refused(errs, day, day.accept(), "폐점에서 맡기", snap)
	_expect_refused(errs, day, day.finish_duel(won), "폐점에서 결투 끝내기", snap)

	# 다음 날
	_expect(errs, day.next_day(), "폐점에서 다음 날이 거짓")
	_expect(errs, day.day_number == 2 and day.phase == P.COUNTER and day.index == 0, "다음 날의 날 번호·단계·순번이 다름")
	_expect(errs, day.results.is_empty() and day.money == 72, "다음 날의 결과 %d건, 소지금 %d (기대 0건, 72)" % [day.results.size(), day.money])

	# 의뢰가 0건인 하루
	var empty := DayState.new(_rules(70, 60, 20, 0), DayData.new())
	_expect(errs, empty.phase == P.CLOSING, "의뢰 0건인데 단계가 폐점이 아님")
	_expect(errs, empty.closing_summary().get("expenses") == 60 and empty.money == -60, "의뢰 0건의 지출이 임대료뿐이 아님")
	return _result(errs)


# ================================================================ T32 결투의 하루 모드

const DUEL_PATH := "res://scenes/duel/duel.tscn"


## 실제 InputEvent를 엔진의 입력 경로(Input → 창 → _unhandled_input)로 흘려 보낸다.
func _send(ev: InputEvent) -> void:
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _send_key(key: Key) -> void:
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = key
		ev.physical_keycode = key
		ev.pressed = pressed
		_send(ev)


func _send_click(button: MouseButton) -> void:
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = button
		ev.pressed = pressed
		ev.position = _mouse_pos
		ev.global_position = _mouse_pos
		_send(ev)


## 실제 데이터로 만든 하루. 첫 의뢰를 맡아 단계가 결투인 채로 돌려준다.
func _real_day_in_duel() -> DayState:
	var day := DayState.new(load(ECONOMY_PATH) as EconomyRules, load(DAY_PATH) as DayData)
	day.accept()
	return day


func t32_duel_day_mode() -> String:
	var errs: Array[String] = []
	var P := DayState.Phase
	var day := _real_day_in_duel()
	var start_money := day.money
	var duel: Node = (load(DUEL_PATH) as PackedScene).instantiate()
	duel.set("day", day)
	duel.set("mouse_aim_enabled", false)
	duel.set("rng_seed", 1)
	_tree.root.add_child(duel)
	var core: DuelCore = duel.get("core")
	var panel: ResultPanel = duel.get_node("ResultPanel")

	_expect(errs, duel.get("commission") == day.current_commission(), "하루 모드의 의뢰가 day의 지금 의뢰가 아님")
	var help: String = (duel.get_node("HUD").get("_help_label") as Label).text
	_expect(errs, not help.contains("다시 하기"), "하루 모드의 조작 안내에 다시 하기가 있음")
	_expect(errs, help.contains("좌클릭 공격"), "하루 모드의 조작 안내가 비어 있음")

	# R은 듣지 않는다.
	_send_key(KEY_R)
	_expect(errs, duel.get("core") == core, "하루 모드에서 R이 새 판을 시작함")

	# 결투가 끝나기 전의 Space는 아무것도 바꾸지 않는다.
	_send_key(KEY_SPACE)
	_expect(errs, day.phase == P.DUEL and day.results.is_empty(), "끝나기 전의 Space가 단계를 바꿈")

	# 첫 피 의뢰를 봇으로 끝낸다.
	var bot: RefCounted = Bot.new(core, _cfg_first_blood_bot())
	var frames := 0
	while not core.ended and frames < MAX_FRAMES:
		duel.call("advance", DELTA)
		bot.call("update")
		frames += 1
	_expect(errs, core.end_reason == DT.EndReason.CONDITION, "봇이 첫 피를 조건으로 끝내지 못함")
	_expect(errs, panel.is_showing(), "끝난 뒤 결과 패널이 보이지 않음")
	var footer: String = (panel.get("_footer") as Label).text
	_expect(errs, footer.contains("의뢰소로 돌아간다") and not footer.contains("다시 하기"), "결과 패널의 안내 글이 하루 모드의 것이 아님: %s" % footer)

	# 마우스 클릭으로는 넘어가지 않는다.
	_send_click(MOUSE_BUTTON_LEFT)
	_expect(errs, day.phase == P.DUEL and day.results.is_empty(), "좌클릭이 결과를 넘김")

	# Space → 정산
	_send_key(KEY_SPACE)
	_expect(errs, day.phase == P.SETTLEMENT, "Space 뒤 단계가 정산이 아님 (%d)" % day.phase)
	_expect(errs, day.results.size() == 1, "Space 뒤 결과 %d건 (기대 1)" % day.results.size())
	if day.results.size() == 1:
		var result := day.results[0]
		_expect(errs, result["score"] == panel.shown_score and result["score"] == 100, "결과의 충족도 %d, 패널 %d (기대 100)" % [result["score"], panel.shown_score])
		_expect(errs, day.money == start_money + int(result["total"]), "소지금 %d (기대 %d)" % [day.money, start_money + int(result["total"])])

	# 한 번 더 눌러도 한 번만 넘긴다. 넘긴 뒤에도 R은 듣지 않는다.
	_send_key(KEY_SPACE)
	_send_key(KEY_ENTER)
	_expect(errs, day.results.size() == 1 and day.phase == P.SETTLEMENT, "Space를 다시 눌러 결과가 또 넘어감")
	_send_key(KEY_R)
	_expect(errs, duel.get("core") == core, "정산으로 넘긴 뒤 R이 새 판을 시작함")

	duel.free()
	return _result(errs)


# ================================================================ T33 화면

const Session := preload("res://scripts/game_session.gd")
const Ui := preload("res://scripts/day_ui.gd")


## 화면 씬에 day를 넣어 붙인다. 호출한 쪽이 free()한다.
func _spawn_screen(path: String, day: DayState) -> Node:
	var screen: Node = (load(path) as PackedScene).instantiate()
	if day != null:
		screen.set("day", day)
	_tree.root.add_child(screen)
	return screen


## 화면의 Proceed 버튼을 누른다. 없으면 false.
func _press_proceed(screen: Node) -> bool:
	var button := screen.find_child("Proceed", true, false) as Button
	if button == null:
		return false
	button.pressed.emit()
	return true


func t33_screens() -> String:
	var errs: Array[String] = []
	var P := DayState.Phase

	# 단계 → 씬 경로
	for phase in [P.COUNTER, P.DUEL, P.SETTLEMENT, P.CLOSING]:
		var path: String = Session.scene_for_phase(phase)
		_expect(errs, ResourceLoader.exists(path) and load(path) is PackedScene, "단계 %d의 씬 %s 이 로드되지 않음" % [phase, path])
	_expect(errs, load(Session.TITLE_PATH) is PackedScene, "처음 화면이 로드되지 않음")

	# 처음 화면
	var title := _spawn_screen(Session.TITLE_PATH, null)
	_expect(errs, title.find_children("*", "Button", true, false).size() == 2, "처음 화면의 버튼이 2개가 아님")
	_expect(errs, title.find_child("Proceed", true, false) is Button, "처음 화면에 Proceed가 없음")
	title.free()

	var day := DayState.new(load(ECONOMY_PATH) as EconomyRules, load(DAY_PATH) as DayData)
	var commissions := day.data.commissions

	# 카운터
	var counter := _spawn_screen(Session.COUNTER_PATH, day)
	var text: String = Ui.all_text(counter)
	var first := day.current_commission()
	_expect(errs, text.contains(first.client_name), "카운터에 의뢰인 이름이 없음")
	_expect(errs, text.contains(first.dialogue), "카운터에 사연 대사가 없음")
	_expect(errs, text.contains(first.describe()[0]), "카운터에 조건 설명이 없음")
	_expect(errs, _press_proceed(counter) and day.phase == P.DUEL, "카운터의 Proceed 뒤 단계가 결투가 아님")
	counter.free()

	# 정산: 첫 피 100(부상 없음) → 깃털(입력 없이 짐) → 지기(입력 없이 짐, 부상)
	var records: Array[DuelRecord] = [
		_play(commissions[0], _cfg_first_blood_bot()).record,
		_play(commissions[1]).record,
		_play(commissions[2]).record,
	]
	for i in 3:
		if i > 0:
			day.accept()
		day.finish_duel(records[i])
		var result := day.last_result()
		var settlement := _spawn_screen(Session.SETTLEMENT_PATH, day)
		_expect(errs, settlement.get("shown_total") == result["total"], "[정산 %d] 화면의 합 %s, 결과 %d" % [i, str(settlement.get("shown_total")), result["total"]])
		var settle_text: String = Ui.all_text(settlement)
		_expect(errs, settle_text.contains(result["client_name"]), "[정산 %d] 의뢰인 이름이 없음" % i)
		_expect(errs, settle_text.contains("치료비") == bool(result["injured"]), "[정산 %d] 치료비 줄과 부상 여부가 어긋남" % i)
		_expect(errs, _press_proceed(settlement), "[정산 %d] Proceed가 없음" % i)
		if i < 2:
			_expect(errs, day.phase == P.COUNTER and day.index == i + 1, "[정산 %d] Proceed 뒤 다음 의뢰인이 아님" % i)
		else:
			_expect(errs, day.phase == P.CLOSING, "[정산 %d] Proceed 뒤 폐점이 아님" % i)
		settlement.free()
	_expect(errs, day.results.size() == 3 and day.results[0]["score"] == 100 and not day.results[0]["injured"], "첫 피 결과가 100점·부상 없음이 아님")
	_expect(errs, day.results.size() == 3 and day.results[2]["injured"], "지기 결과가 부상이 아님")

	# 폐점
	var closing := _spawn_screen(Session.CLOSING_PATH, day)
	_expect(errs, closing.get("shown") == true and closing.get("shown_profit") == day.closing_summary()["profit"],
		"폐점 화면의 손익 %s, 요약 %s" % [str(closing.get("shown_profit")), str(day.closing_summary().get("profit"))])
	_expect(errs, _press_proceed(closing) and day.day_number == 2 and day.phase == P.COUNTER, "폐점의 Proceed 뒤 2일차 카운터가 아님")
	closing.free()

	# 단계가 맞지 않는 day(카운터 단계)를 넣은 정산·폐점 화면은 아무것도 바꾸지 않는다.
	for path in [Session.SETTLEMENT_PATH, Session.CLOSING_PATH]:
		var before := _snapshot(day)
		var wrong := _spawn_screen(path, day)
		_press_proceed(wrong)
		_expect(errs, _snapshot(day) == before, "단계가 맞지 않는 화면(%s)이 day를 바꿈" % path)
		wrong.free()
	return _result(errs)
