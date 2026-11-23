extends RefCounted
## T28~T33: 하루 루프 — 경제 규칙, 보수 공식, 정산, 하루 상태와 장부, 결투의 하루 모드, 화면.
## T34~T36: 폐점의 가게 — 업그레이드 데이터, 구매와 적용, 가게 화면과 결투 적용.
## T37~T39: 접수의 선택 — 일정과 의뢰의 데이터, 돌려보내기와 결투 수, 접수의 화면.
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
		{"id": "T34", "name": "업그레이드 데이터: 목록과 효과의 대상", "fn": t34_upgrade_data},
		{"id": "T35", "name": "구매와 적용: 팁 덧붙임, 322 → 72 → 169", "fn": t35_buy_and_apply},
		{"id": "T36", "name": "가게 화면과 결투 적용: 포커스, 구매, 내 자세 +1", "fn": t36_shop_screen},
		{"id": "T37", "name": "일정과 의뢰의 데이터: 구조, 변형 넷, 해낼 수 있는가", "fn": t37_schedule_data},
		{"id": "T38", "name": "돌려보내기와 결투 수: 58 → 107 → 137 → 57", "fn": t38_decline_and_duels},
		{"id": "T39", "name": "접수의 화면: 돌려보내기, 한마디, 결투 수가 찬 정산", "fn": t39_counter_screens},
		{"id": "T45", "name": "보수의 기준치: 80 이상이면 전액, 그 아래부터 깎임", "fn": t45_full_pay},
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
## 모자 없는 판만 만든다(의뢰의 opponent_wears_hat을 넘기지 않는다). 깃털을 봇으로 해내는 검사를
## 여기에 더하려면 모자 여부를 넘겨야 한다. 지금은 깃털을 입력 없이 지는 데만 쓴다.
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
	return Bot.first_blood_cfg()


## 공식을 테스트 쪽에서 따로 계산한 값(0.5 올림). [기본 보수, 팁]
## 전액 기준치까지 따로 계산한다: 보수에 쓰는 충족도 = min(100, 충족도 x 100 / 기준치).
func _want_pay(score: int, base_reward: int, tip_max: int, rules: EconomyRules) -> Array[int]:
	var threshold := clampi(rules.full_pay_score, 1, 100)
	var paid := mini(100, int(floor(score * 100.0 / threshold + 0.5)))
	var base := int(floor(base_reward * paid / 100.0 + 0.5))
	var tip_score := paid if rules.full_pay_covers_tip else score
	var tip := 0
	if tip_score > rules.tip_floor:
		tip = int(floor(tip_max * (tip_score - rules.tip_floor) / float(100 - rules.tip_floor) + 0.5))
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
	var c_want := _want_pay(c_score, throw_match.base_reward, throw_match.tip_max, rules)
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
	var e_want := _want_pay(80, 45, 25, rules)
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
	var help: String = DuelHud.help_text(core.opponent_data, true, core.opponent_has_hat, core.weapon)
	_expect(errs, duel.get_node("HUD").get("_help_label") == null, "결투 HUD에 조작 안내가 남아 있음(결정 323)")
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
	_expect(errs, title.find_children("*", "Button", true, false).size() == 3, "처음 화면의 버튼이 3개가 아님")
	_expect(errs, title.find_child("Help", true, false) is Button, "처음 화면에 Help가 없음")
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


# ================================================================ T34 업그레이드 데이터

const CATALOG_PATH := "res://data/upgrade_catalog.tres"


## 효과의 대상 규칙을 로드해 돌려준다.
func _loaded_target(target: int) -> Resource:
	return load(ECONOMY_PATH) if target == UpgradeData.Target.ECONOMY else load(DUEL_RULES_PATH)


func t34_upgrade_data() -> String:
	var errs: Array[String] = []
	var catalog := load(CATALOG_PATH) as UpgradeCatalog
	if catalog == null:
		errs.append("%s 가 UpgradeCatalog로 로드되지 않음" % CATALOG_PATH)
		return _result(errs)
	_expect(errs, catalog.upgrades.size() == 3, "목록의 업그레이드 %d개 (기대 3)" % catalog.upgrades.size())

	var ids: Array[StringName] = []
	for upgrade in catalog.upgrades:
		if upgrade == null:
			errs.append("목록에 빈 칸이 있음")
			continue
		var label := String(upgrade.id)
		_expect(errs, upgrade.id != &"" and not ids.has(upgrade.id), "[%s] id가 비었거나 겹침" % label)
		ids.append(upgrade.id)
		_expect(errs, upgrade.resource_path.begins_with("res://data/upgrades/"), "[%s] data/upgrades/의 파일이 아님" % label)
		_expect(errs, upgrade.price > 0, "[%s] 값 %d (0보다 커야 함)" % [label, upgrade.price])
		_expect(errs, upgrade.display_name != "" and upgrade.description != "", "[%s] 이름이나 설명이 비어 있음" % label)
		var current: Variant = _loaded_target(upgrade.target).get(upgrade.property)
		var kind := typeof(current)
		_expect(errs, kind == TYPE_INT or kind == TYPE_FLOAT, "[%s] 대상 규칙에 숫자 속성 %s 이(가) 없음" % [label, upgrade.property])
		if kind == TYPE_INT:
			_expect(errs, is_equal_approx(upgrade.amount, roundf(upgrade.amount)), "[%s] 정수 속성에 소수부가 있는 양 %s" % [label, str(upgrade.amount)])

	# 목록의 효과를 전부 적용한 규칙(더할 양 자체는 음수일 수 있다).
	var economy := UpgradeData.applied(load(ECONOMY_PATH), UpgradeData.Target.ECONOMY, catalog.upgrades) as EconomyRules
	var duel := UpgradeData.applied(load(DUEL_RULES_PATH), UpgradeData.Target.DUEL, catalog.upgrades) as DuelRules
	for upgrade in catalog.upgrades:
		if upgrade == null:
			continue
		var applied: Resource = economy if upgrade.target == UpgradeData.Target.ECONOMY else duel
		var value: Variant = applied.get(upgrade.property)
		if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
			_expect(errs, float(value) >= 0.0, "[%s] 전부 적용한 %s 이(가) 음수 (%s)" % [upgrade.id, upgrade.property, str(value)])
	_expect(errs, duel.player_posture_max >= 1, "전부 적용한 내 자세 %d (1 이상이어야 함)" % duel.player_posture_max)
	_expect(errs, economy.tip_floor < 100, "전부 적용한 tip_floor %d (100 미만이어야 함)" % economy.tip_floor)
	_expect(errs, (load(ECONOMY_PATH) as EconomyRules).tip_bonus_percent == 0, "로드한 경제 규칙의 팁 덧붙임이 0이 아님")
	return _result(errs)


# ================================================================ T35 구매와 적용

func _upgrade(id: StringName, price: int, target: UpgradeData.Target, property: StringName, amount: float) -> UpgradeData:
	var upgrade := UpgradeData.new()
	upgrade.id = id
	upgrade.display_name = "테스트 %s" % id
	upgrade.description = "테스트용"
	upgrade.price = price
	upgrade.target = target
	upgrade.property = property
	upgrade.amount = amount
	return upgrade


func _catalog(upgrades: Array[UpgradeData]) -> UpgradeCatalog:
	var catalog := UpgradeCatalog.new()
	catalog.upgrades = upgrades
	return catalog


## 테스트가 직접 만든 셋(값 40 / 90 / 120). .tres의 값과 일부러 다르다.
func _test_upgrades() -> Array[UpgradeData]:
	var out: Array[UpgradeData] = [
		_upgrade(&"t_medicine", 40, UpgradeData.Target.ECONOMY, &"medical_fee", -10.0),
		_upgrade(&"t_chair", 90, UpgradeData.Target.ECONOMY, &"tip_bonus_percent", 30.0),
		_upgrade(&"t_vest", 120, UpgradeData.Target.DUEL, &"player_posture_max", 1.0),
	]
	return out


## 고정 점수 하루(100 / 90 / 85, 셋째만 유효타를 맞고 끝남)를 폐점까지 민다.
func _run_fixed_day(day: DayState) -> void:
	var ends := [DT.EndReason.CONDITION, DT.EndReason.CONDITION, DT.EndReason.PLAYER_DEFEATED]
	for end_reason in ends:
		day.accept()
		day.finish_duel(_record(end_reason))
		day.proceed()


func _shop_snapshot(day: DayState) -> Array:
	return [day.phase, day.money, day.owned.duplicate()]


func t35_buy_and_apply() -> String:
	var errs: Array[String] = []
	var P := DayState.Phase

	# 팁 표: [충족도, 팁 최대, 덧붙임 0, 덧붙임 30]
	var plain := _rules()
	var boosted := _rules()
	boosted.tip_bonus_percent = 30
	var table := [
		[100, 15, 15, 20],
		[100, 25, 25, 33],
		[100, 30, 30, 39],
		[90, 25, 17, 22],
		[80, 25, 8, 11],
		[85, 30, 15, 20],
		[71, 30, 1, 1],
		[70, 30, 0, 0],
	]
	for row in table:
		var tip0: int = DayState.payout(row[0], 40, row[1], plain)["tip"]
		var tip30: int = DayState.payout(row[0], 40, row[1], boosted)["tip"]
		_expect(errs, tip0 == row[2] and tip30 == row[3],
			"충족도 %d 팁 최대 %d → 덧붙임 0: %d, 30: %d (기대 %d, %d)" % [row[0], row[1], tip0, tip30, row[2], row[3]])
	for tip_max in [15, 25, 30]:
		var shown_max: int = DayState.settle(_fixed_commission("팁", 40, tip_max, 100), _record(DT.EndReason.CONDITION), boosted)["tip_max"]
		var prev := -1
		for score in 101:
			var tip: int = DayState.payout(score, 40, tip_max, boosted)["tip"]
			if tip < prev or tip > shown_max:
				errs.append("덧붙임 30, 팁 최대 %d: 충족도 %d에서 팁 %d (앞 %d, 화면의 최대 %d)" % [tip_max, score, tip, prev, shown_max])
				break
			prev = tip

	# 폐점이 아닌 단계에서는 살 수 없다.
	var upgrades := _test_upgrades()
	var medicine := upgrades[0]
	var chair := upgrades[1]
	var vest := upgrades[2]
	var rich := DayState.new(_rules(70, 60, 20, 1000), _three_fixed(), _catalog(upgrades))
	var snap := _shop_snapshot(rich)
	_expect(errs, not rich.buy(medicine) and _shop_snapshot(rich) == snap, "카운터에서 사짐")
	rich.accept()
	snap = _shop_snapshot(rich)
	_expect(errs, not rich.buy(medicine) and _shop_snapshot(rich) == snap, "결투에서 사짐")
	rich.finish_duel(_record(DT.EndReason.CONDITION))
	snap = _shop_snapshot(rich)
	_expect(errs, not rich.buy(medicine) and _shop_snapshot(rich) == snap, "정산에서 사짐")
	_expect(errs, not rich.has_buyable(), "폐점이 아닌데 살 수 있는 것이 있다고 함")

	# 폐점에서: 소지금 72
	var day := DayState.new(_rules(70, 60, 20, 0), _three_fixed(), _catalog(upgrades))
	_expect(errs, day.effective_rules().medical_fee == 20 and day.effective_rules().tip_bonus_percent == 0,
		"가진 것이 없는데 적용된 경제 규칙이 기본과 다름")
	_run_fixed_day(day)
	_expect(errs, day.phase == P.CLOSING and day.money == 72, "고정 하루의 폐점 소지금 %d (기대 72)" % day.money)
	_expect(errs, day.has_buyable(), "소지금 72인데 살 수 있는 것이 없다고 함")
	snap = _shop_snapshot(day)
	_expect(errs, not day.buy(vest) and _shop_snapshot(day) == snap, "소지금 72로 값 120짜리가 사짐")
	_expect(errs, day.buy(medicine) and day.money == 32 and day.owns(medicine), "값 40짜리를 산 뒤 소지금 %d (기대 32)" % day.money)
	snap = _shop_snapshot(day)
	_expect(errs, not day.buy(medicine) and _shop_snapshot(day) == snap, "같은 것이 다시 사짐")
	_expect(errs, not day.buy(chair) and _shop_snapshot(day) == snap, "소지금 32로 값 90짜리가 사짐")
	_expect(errs, not day.buy(null) and _shop_snapshot(day) == snap, "null이 사짐")
	var stranger := _upgrade(&"t_stranger", 1, UpgradeData.Target.ECONOMY, &"rent", -1.0)
	_expect(errs, not day.buy(stranger) and _shop_snapshot(day) == snap, "목록에 없는 것이 사짐")
	_expect(errs, not day.has_buyable(), "소지금 32인데 살 수 있는 것이 있다고 함")

	# 목록 없이 만든 하루
	var bare := DayState.new(_rules(70, 60, 20, 1000), _three_fixed())
	_run_fixed_day(bare)
	snap = _shop_snapshot(bare)
	_expect(errs, not bare.buy(medicine) and not bare.has_buyable() and _shop_snapshot(bare) == snap, "목록 없는 하루에서 사짐")

	# 소지금이 음수인 폐점
	var cheap := _upgrade(&"t_cheap", 1, UpgradeData.Target.ECONOMY, &"rent", -1.0)
	var cheap_list: Array[UpgradeData] = [cheap]
	var broke := DayState.new(_rules(70, 60, 20, 0), DayData.new(), _catalog(cheap_list))
	_expect(errs, broke.phase == P.CLOSING and broke.money == -60, "의뢰 0건의 폐점 소지금 %d (기대 -60)" % broke.money)
	_expect(errs, not broke.buy(cheap) and broke.money == -60 and broke.owned.is_empty(), "소지금이 음수인데 사짐")

	# 이틀의 장부: 250 → 322 → 셋을 사서 72 → 169
	var rules := _rules(70, 60, 20, 250)
	var base_duel := DuelRules.new()
	var base_posture := base_duel.player_posture_max
	var ledger := DayState.new(rules, _three_fixed(), _catalog(upgrades))
	_expect(errs, ledger.effective_duel_rules(base_duel).player_posture_max == base_posture, "가진 것이 없는데 적용된 결투 규칙이 기본과 다름")
	_run_fixed_day(ledger)
	_expect(errs, ledger.money == 322, "1일차 폐점 소지금 %d (기대 322)" % ledger.money)
	for upgrade in upgrades:
		_expect(errs, ledger.buy(upgrade), "[%s] 사지지 않음" % upgrade.id)
	_expect(errs, ledger.money == 72 and ledger.owned.size() == 3, "셋을 산 뒤 소지금 %d, 가진 것 %d (기대 72, 3)" % [ledger.money, ledger.owned.size()])

	var economy := ledger.effective_rules()
	var duel := ledger.effective_duel_rules(base_duel)
	_expect(errs, economy != rules and duel != base_duel, "적용된 규칙이 기본 규칙과 같은 객체임")
	_expect(errs, economy.medical_fee == 10 and economy.tip_bonus_percent == 30, "적용된 경제 규칙: 치료비 %d, 덧붙임 %d (기대 10, 30)" % [economy.medical_fee, economy.tip_bonus_percent])
	_expect(errs, duel.player_posture_max == base_posture + 1 and typeof(duel.get("player_posture_max")) == TYPE_INT, "적용된 내 자세 %s (기대 %d, 정수)" % [str(duel.get("player_posture_max")), base_posture + 1])
	_expect(errs, rules.medical_fee == 20 and rules.tip_bonus_percent == 0 and base_duel.player_posture_max == base_posture, "사는 것이 기본 규칙을 고침")

	_expect(errs, ledger.next_day() and ledger.day_number == 2 and ledger.owned.size() == 3 and ledger.money == 72, "다음 날로 넘어가며 가진 것이나 소지금이 달라짐")
	_run_fixed_day(ledger)
	if ledger.results.size() == 3:
		var tips := [ledger.results[0]["tip"], ledger.results[1]["tip"], ledger.results[2]["tip"]]
		_expect(errs, tips == [20, 22, 20], "2일차의 팁 %s (기대 [20, 22, 20])" % str(tips))
		_expect(errs, ledger.results[2]["medical_fee"] == 10, "2일차 셋째의 치료비 %d (기대 10)" % ledger.results[2]["medical_fee"])
	else:
		errs.append("2일차의 결과 %d건 (기대 3)" % ledger.results.size())
	_expect(errs, ledger.money == 169 and ledger.closing_summary().get("profit") == 97, "2일차 폐점 소지금 %d, 손익 %s (기대 169, 97)" % [ledger.money, str(ledger.closing_summary().get("profit"))])

	# 실수 속성: 빈틈 인정 유예 + 0.05
	var grace := _upgrade(&"t_grace", 10, UpgradeData.Target.DUEL, &"opening_grace", 0.05)
	var grace_list: Array[UpgradeData] = [grace]
	var grace_day := DayState.new(_rules(70, 60, 20, 500), _three_fixed(), _catalog(grace_list))
	_run_fixed_day(grace_day)
	var base_grace := base_duel.opening_grace
	_expect(errs, grace_day.buy(grace), "실수 효과의 업그레이드가 사지지 않음")
	_expect(errs, is_equal_approx(grace_day.effective_duel_rules(base_duel).opening_grace, base_grace + 0.05), "적용된 빈틈 인정 유예가 기본 + 0.05가 아님")
	_expect(errs, is_equal_approx(base_duel.opening_grace, base_grace), "실수 효과가 기본 규칙을 고침")
	return _result(errs)


# ================================================================ T36 가게 화면과 결투 적용

func _buy_buttons(screen: Node) -> Array[Button]:
	var out: Array[Button] = []
	for node in screen.find_children("Buy_*", "Button", true, false):
		out.append(node as Button)
	return out


## 화면의 Proceed에 포커스가 있는가.
func _proceed_focused(screen: Node) -> bool:
	var proceed := screen.find_child("Proceed", true, false) as Button
	return proceed != null and _tree.root.gui_get_focus_owner() == proceed


func t36_shop_screen() -> String:
	var errs: Array[String] = []
	var P := DayState.Phase
	var upgrades := _test_upgrades()

	# 소지금이 넉넉한 폐점
	var day := DayState.new(_rules(70, 60, 20, 1000), _three_fixed(), _catalog(upgrades))
	_run_fixed_day(day)
	var closing := _spawn_screen(Session.CLOSING_PATH, day)
	var buttons := _buy_buttons(closing)
	_expect(errs, buttons.size() == upgrades.size(), "Buy_ 버튼 %d개 (기대 %d)" % [buttons.size(), upgrades.size()])
	for button in buttons:
		_expect(errs, not button.disabled, "[%s] 소지금이 넉넉한데 눌리지 않음" % button.name)
	_expect(errs, _tree.root.gui_get_focus_owner() == null, "살 것이 있는데 포커스를 가진 버튼이 있음")
	_expect(errs, closing.get("shown_money") == day.money, "화면의 소지금 %s, day %d" % [str(closing.get("shown_money")), day.money])
	if buttons.size() == upgrades.size():
		# 마우스로 누른 버튼은 포커스를 갖는다. 살 것이 남아 있으면 산 뒤에 그 포커스가 풀려야 한다.
		var first := closing.find_child("Buy_%s" % upgrades[0].id, true, false) as Button
		var money_before := day.money
		first.grab_focus()
		_expect(errs, _tree.root.gui_get_focus_owner() == first, "헤드리스에서 버튼이 포커스를 잡지 못함(포커스 검사가 서지 않는다)")
		first.pressed.emit()
		_expect(errs, day.money == money_before - upgrades[0].price and day.owns(upgrades[0]), "버튼을 눌렀는데 사지지 않음")
		_expect(errs, closing.get("shown_money") == day.money, "산 뒤 화면의 소지금 %s, day %d" % [str(closing.get("shown_money")), day.money])
		_expect(errs, is_instance_valid(first) and first.is_inside_tree() and first.disabled and first.text.contains("샀다"),
			"누른 그 버튼이 눌리지 않는 '샀다'가 되지 않음")
		_expect(errs, closing.find_child("Buy_%s" % upgrades[0].id, true, false) == first, "가게를 다시 그리며 버튼 노드가 바뀜")
		_expect(errs, _tree.root.gui_get_focus_owner() == null, "살 것이 남았는데 산 뒤에도 포커스가 남음")
		for i in range(1, upgrades.size()):
			(closing.find_child("Buy_%s" % upgrades[i].id, true, false) as Button).pressed.emit()
		_expect(errs, day.owned.size() == upgrades.size(), "전부 눌렀는데 가진 것 %d개" % day.owned.size())
		_expect(errs, _proceed_focused(closing), "전부 산 뒤 Proceed에 포커스가 없음")
	_expect(errs, _press_proceed(closing) and day.day_number == 2 and day.phase == P.COUNTER, "폐점의 Proceed 뒤 2일차 카운터가 아님")
	closing.free()

	# 소지금이 음수인 폐점
	var broke := DayState.new(_rules(70, 60, 20, 0), DayData.new(), _catalog(upgrades))
	var broke_screen := _spawn_screen(Session.CLOSING_PATH, broke)
	var broke_buttons := _buy_buttons(broke_screen)
	_expect(errs, broke_buttons.size() == upgrades.size(), "[음수] Buy_ 버튼 %d개" % broke_buttons.size())
	_expect(errs, _proceed_focused(broke_screen), "[음수] 살 것이 없는데 Proceed에 포커스가 없음")
	var snap := _shop_snapshot(broke)
	for button in broke_buttons:
		_expect(errs, button.disabled, "[음수] %s 이(가) 눌림" % button.name)
		button.pressed.emit()
	_expect(errs, _shop_snapshot(broke) == snap, "[음수] 눌리지 않는 버튼의 신호가 day를 바꿈")
	broke_screen.free()

	# 목록 없이 만든 하루의 폐점
	var bare := DayState.new(_rules(70, 60, 20, 1000), _three_fixed())
	_run_fixed_day(bare)
	var bare_screen := _spawn_screen(Session.CLOSING_PATH, bare)
	_expect(errs, _buy_buttons(bare_screen).is_empty(), "[목록 없음] Buy_ 버튼이 있음")
	_expect(errs, _proceed_focused(bare_screen), "[목록 없음] Proceed에 포커스가 없음")
	_expect(errs, Ui.all_text(bare_screen).contains("살 것이 없다"), "[목록 없음] 안내 글이 없음")
	bare_screen.free()

	# 결투 씬: 내 자세를 1 올리는 업그레이드를 가진 하루.
	# 사기는 폐점에서만 되므로, 의뢰 1건짜리 하루를 끝까지 밀어 사고 다음 날로 넘어가 맡는다.
	var base_posture := (load(DUEL_RULES_PATH) as DuelRules).player_posture_max
	var vest := _upgrade(&"t_vest", 10, UpgradeData.Target.DUEL, &"player_posture_max", 1.0)
	var vest_list: Array[UpgradeData] = [vest]
	var one: Array[Commission] = [load(FIRST_BLOOD_PATH) as Commission]
	var one_day := DayData.new()
	one_day.commissions = one
	var duel_day := DayState.new(_rules(70, 60, 20, 1000), one_day, _catalog(vest_list))
	duel_day.accept()
	duel_day.finish_duel(_record(DT.EndReason.CONDITION))
	duel_day.proceed()
	_expect(errs, duel_day.buy(vest) and duel_day.next_day() and duel_day.accept() and duel_day.phase == P.DUEL,
		"업그레이드를 가진 결투 단계의 하루를 만들지 못함")
	var duel: Node = (load(DUEL_PATH) as PackedScene).instantiate()
	duel.set("day", duel_day)
	duel.set("mouse_aim_enabled", false)
	duel.set("rng_seed", 1)
	_tree.root.add_child(duel)
	var core: DuelCore = duel.get("core")
	_expect(errs, core.rules.player_posture_max == base_posture + 1 and core.player_posture == base_posture + 1,
		"하루 모드의 내 자세 %d/%d (기대 %d)" % [core.player_posture, core.rules.player_posture_max, base_posture + 1])
	_expect(errs, (load(DUEL_RULES_PATH) as DuelRules).player_posture_max == base_posture, "결투 씬이 로드한 결투 규칙을 고침")
	duel.free()

	# day 없이 붙인 결투 씬(연습)은 기본 규칙이다.
	var practice: Node = (load(DUEL_PATH) as PackedScene).instantiate()
	practice.set("mouse_aim_enabled", false)
	practice.set("rng_seed", 1)
	_tree.root.add_child(practice)
	var practice_core: DuelCore = practice.get("core")
	_expect(errs, practice_core.rules.player_posture_max == base_posture and practice_core.player_posture == base_posture,
		"연습의 내 자세 %d/%d (기대 %d)" % [practice_core.player_posture, practice_core.rules.player_posture_max, base_posture])
	practice.free()
	return _result(errs)


# ================================================================ T37 일정과 의뢰의 데이터

const SCHEDULE_PATH := "res://data/day_schedule.tres"
const VARIANT_DIR := "res://data/commissions/variants/"
const POOR_PATH := VARIANT_DIR + "first_blood_poor.tres"
const BET_PATH := VARIANT_DIR + "throw_bet.tres"
const USURER_PATH := VARIANT_DIR + "first_blood_usurer.tres"
const LEGS_PATH := VARIANT_DIR + "legs_only.tres"


## 막고, 빈틈이 생기는 공격 뒤에 가운데 하단, 무너지면 가운데 하단으로 치는 봇.
func _cfg_legs_bot() -> Dictionary:
	var aim := [DT.Direction.CENTER, DT.Height.LOW]
	var counter := func(ev: Dictionary) -> Variant:
		return aim if float(ev["recovery"]) > 0.0 else null
	return {"counter_fn": counter, "finisher": aim}


## 통과 조건은 구조만 본다. 조율하는 값(날 수, 손님 수, 한마디를 채웠는지)은 INFO 줄이다.
func t37_schedule_data() -> String:
	var errs: Array[String] = []
	var schedule := load(SCHEDULE_PATH) as DaySchedule
	if schedule == null:
		errs.append("%s 가 DaySchedule로 로드되지 않음" % SCHEDULE_PATH)
		return _result(errs)
	_expect(errs, schedule.days.size() >= 1, "일정에 날이 없음")
	var guest_counts: Array[int] = []
	for i in schedule.days.size():
		var day_data := schedule.days[i]
		if day_data == null:
			errs.append("일정의 %d번째 날이 비어 있음" % (i + 1))
			continue
		guest_counts.append(day_data.commissions.size())
		_expect(errs, day_data.commissions.size() >= 1, "일정의 %d번째 날에 손님이 없음" % (i + 1))
		for commission in day_data.commissions:
			if commission == null:
				errs.append("일정의 %d번째 날에 빈 손님이 있음" % (i + 1))
				continue
			var label := commission.client_name
			_expect(errs, commission.client_name != "" and commission.dialogue != "", "[%s] 이름이나 대사가 비어 있음" % label)
			_expect(errs, commission.opponent != null, "[%s] 상대가 없음" % label)
			_expect(errs, commission.conditions.size() >= 1 and not commission.describe().is_empty(), "[%s] 조건이나 조건 설명이 없음" % label)
			_expect(errs, commission.base_reward > 0, "[%s] 기본 보수 %d" % [label, commission.base_reward])

	# 변형 넷의 조건 타입
	var variant_types := {
		POOR_PATH: FirstBloodCondition,
		BET_PATH: ThrowUndetectedCondition,
		USURER_PATH: FirstBloodCondition,
		LEGS_PATH: TargetPartCondition,
	}
	for path: String in variant_types:
		var variant := load(path) as Commission
		if variant == null:
			errs.append("%s 가 Commission으로 로드되지 않음" % path)
			continue
		_expect(errs, variant.conditions.size() == 1 and is_instance_of(variant.conditions[0], variant_types[path]),
			"[%s] 조건 타입이 표와 다름" % variant.client_name)
	if not errs.is_empty():
		return _result(errs)
	var legs := load(LEGS_PATH) as Commission
	_expect(errs, (legs.conditions[0] as TargetPartCondition).target_part == DT.Part.LEGS, "legs_only의 지정 부위가 다리가 아님")

	# 일곱 의뢰의 한마디는 "치료비"를 담지 않는다(T33이 정산 화면의 그 낱말로 부상 줄을 본다).
	var empty_lines := 0
	for path in [FIRST_BLOOD_PATH, FEATHER_PATH, THROW_PATH, POOR_PATH, BET_PATH, USURER_PATH, LEGS_PATH]:
		var commission := load(path) as Commission
		_expect(errs, not commission.success_line.contains("치료비") and not commission.decline_line.contains("치료비"),
			"[%s] 한마디에 '치료비'가 있음" % commission.client_name)
		if commission.success_line == "" or commission.decline_line == "":
			empty_lines += 1

	var rules := load(ECONOMY_PATH) as EconomyRules
	_expect(errs, rules.duels_per_day >= 1, "duels_per_day %d (1 이상이어야 함)" % rules.duels_per_day)

	# 해낼 수 있는 의뢰인가(실제 결투 규칙·무기·상대, 시드 1)
	var legs_core := _play(legs, _cfg_legs_bot())
	_expect(errs, legs_core.end_reason == DT.EndReason.CONDITION and legs.evaluate(legs_core.record) == 100,
		"다리 의뢰 + 하단 봇: 종료 사유 %d, %d점 (기대 조건으로 끝나고 100)" % [legs_core.end_reason, legs.evaluate(legs_core.record)])
	var legs_mid := _play(legs, _cfg_first_blood_bot())
	_expect(errs, legs.evaluate(legs_mid.record) != 100, "다리 의뢰가 중단 찌르기로도 100점임")
	for path in [POOR_PATH, USURER_PATH]:
		var first_blood := load(path) as Commission
		var core := _play(first_blood, _cfg_first_blood_bot())
		_expect(errs, first_blood.evaluate(core.record) == 100, "[%s] 첫 피 봇이 %d점 (기대 100)" % [first_blood.client_name, first_blood.evaluate(core.record)])
	var bet := load(BET_PATH) as Commission
	var bet_core := _play(bet)
	var bet_result := DayState.settle(bet, bet_core.record, rules)
	_expect(errs, bet_result["injured"] and bet_result["score"] == bet.evaluate(bet_core.record),
		"[%s] 입력 없이 진 기록이 부상이 아니거나 점수가 evaluate와 다름" % bet.client_name)

	var crowded := 0
	for count in guest_counts:
		if count > rules.duels_per_day:
			crowded += 1
	print("  INFO 일정 %d일, 날마다 손님 %s, 결투 수 %d, 손님이 결투 수보다 많은 날 %d, 한마디가 빈 의뢰 %d/7" % [
		guest_counts.size(), str(guest_counts), rules.duels_per_day, crowded, empty_lines])
	return _result(errs)


# ================================================================ T38 돌려보내기와 결투 수

## 고정 점수 손님 다섯. 첫째와 둘째에만 한마디가 있다.
func _five_fixed() -> DayData:
	var commissions: Array[Commission] = [
		_fixed_commission("첫째", 30, 15, 100),
		_fixed_commission("둘째", 45, 25, 90),
		_fixed_commission("셋째", 40, 30, 85),
		_fixed_commission("넷째", 20, 10, 100),
		_fixed_commission("다섯째", 50, 20, 100),
	]
	commissions[0].success_line = "첫째가 고마워한다"
	commissions[0].decline_line = "첫째가 서운해한다"
	commissions[1].success_line = "둘째가 고마워한다"
	commissions[1].decline_line = "둘째가 서운해한다"
	var data := DayData.new()
	data.commissions = commissions
	return data


func _duel_rules(duels_per_day: int) -> EconomyRules:
	var rules := _rules(70, 60, 20, 0)
	rules.duels_per_day = duels_per_day
	return rules


func _decline_snapshot(day: DayState) -> Array:
	return [day.phase, day.index, day.results.size(), day.money, day.declined.duplicate(), day.last_declined.duplicate()]


## 지금 손님을 맡아 그 종료 사유로 끝내고 정산까지 간다(다음으로 넘기지는 않는다).
func _fight(day: DayState, end_reason: int) -> void:
	day.accept()
	day.finish_duel(_record(end_reason))


func t38_decline_and_duels() -> String:
	var errs: Array[String] = []
	var P := DayState.Phase
	var won := DT.EndReason.CONDITION
	var lost := DT.EndReason.PLAYER_DEFEATED

	# 새 하루
	var data := _five_fixed()
	var day := DayState.new(_duel_rules(3), data)
	_expect(errs, day.duels_left() == 3 and day.waiting_count() == 4, "새 하루의 남은 결투 %d, 기다리는 손님 %d (기대 3, 4)" % [day.duels_left(), day.waiting_count()])

	# 카운터가 아닌 단계에서는 돌려보낼 수 없다.
	var wrong := DayState.new(_duel_rules(3), _five_fixed())
	wrong.accept()
	var snap := _decline_snapshot(wrong)
	_expect(errs, not wrong.decline() and _decline_snapshot(wrong) == snap, "결투에서 돌려보내짐")
	wrong.finish_duel(_record(won))
	snap = _decline_snapshot(wrong)
	_expect(errs, not wrong.decline() and _decline_snapshot(wrong) == snap, "정산에서 돌려보내짐")

	# (가) 첫째를 돌려보내고 둘째·셋째·넷째를 맡는다.
	_expect(errs, day.decline(), "(가) 카운터에서 돌려보내기가 거짓")
	_expect(errs, day.phase == P.COUNTER and day.index == 1 and day.results.is_empty() and day.money == 0 and day.waiting_count() == 3,
		"(가) 돌려보낸 뒤 단계 %d, 순번 %d, 결과 %d건, 소지금 %d, 기다리는 손님 %d" % [day.phase, day.index, day.results.size(), day.money, day.waiting_count()])
	_expect(errs, day.last_declined.get("client_name") == "첫째" and day.last_declined.get("line") == "첫째가 서운해한다",
		"(가) 방금 돌려보낸 손님이 첫째가 아님: %s" % str(day.last_declined))
	_fight(day, won)
	_expect(errs, day.last_declined.is_empty(), "(가) 손님을 맡았는데 방금 돌려보낸 손님이 남아 있음")
	_expect(errs, day.money == 58, "(가) 둘째 정산 뒤 소지금 %d (기대 58)" % day.money)
	_expect(errs, day.last_result().get("success_line") == "둘째가 고마워한다", "(가) 둘째의 정산 결과에 한마디가 없음")
	day.proceed()
	_fight(day, lost)
	_expect(errs, day.money == 107, "(가) 셋째 정산 뒤 소지금 %d (기대 107)" % day.money)
	_expect(errs, day.last_result().get("success_line") == "", "(가) 셋째의 정산 결과에 한마디가 있음")
	day.proceed()
	_fight(day, won)
	_expect(errs, day.money == 137, "(가) 넷째 정산 뒤 소지금 %d (기대 137)" % day.money)
	_expect(errs, day.waiting_count() == 1 and day.duels_left() == 0 and not day.has_next_commission(),
		"(가) 결투 수가 찼는데 다음 손님을 만난다고 함")
	_expect(errs, day.proceed() and day.phase == P.CLOSING, "(가) 결투 수가 찬 뒤 폐점으로 가지 않음")
	_expect(errs, day.money == 57, "(가) 폐점 소지금 %d (기대 57)" % day.money)
	var summary := day.closing_summary()
	_expect(errs, summary.get("duels") == 3 and summary.get("declined") == ["첫째"] and summary.get("missed") == 1,
		"(가) 요약의 결투·돌려보낸 손님·만나지 못한 손님이 다름: %s" % str(summary))
	snap = _decline_snapshot(day)
	_expect(errs, not day.decline() and _decline_snapshot(day) == snap, "폐점에서 돌려보내짐")

	# 다음 날로 넘어가면 돌려보낸 기록이 비어 있다.
	day.next_day()
	_expect(errs, day.declined.is_empty() and day.last_declined.is_empty() and day.duels_left() == 3, "다음 날에 돌려보낸 기록이 남아 있음")

	# (나) 다섯을 전부 돌려보낸다.
	var all_declined := DayState.new(_duel_rules(3), _five_fixed())
	for i in 5:
		_expect(errs, all_declined.phase == P.COUNTER and all_declined.decline(), "(나) %d번째 손님을 돌려보내지 못함" % (i + 1))
	summary = all_declined.closing_summary()
	_expect(errs, all_declined.phase == P.CLOSING and all_declined.results.is_empty() and all_declined.money == -60,
		"(나) 전부 돌려보낸 뒤 단계 %d, 소지금 %d (기대 폐점, -60)" % [all_declined.phase, all_declined.money])
	_expect(errs, summary.get("duels") == 0 and (summary.get("declined") as Array).size() == 5 and summary.get("missed") == 0,
		"(나) 요약이 다름: %s" % str(summary))
	_expect(errs, all_declined.last_declined.get("client_name") == "다섯째" and all_declined.last_declined.get("line") == "",
		"(나) 폐점에서 방금 돌려보낸 손님이 다섯째가 아님")

	# (다) 첫째·둘째를 맡고 나머지 셋을 돌려보낸다.
	var two := DayState.new(_duel_rules(3), _five_fixed())
	for i in 2:
		_fight(two, won)
		two.proceed()
	for i in 3:
		two.decline()
	summary = two.closing_summary()
	_expect(errs, two.phase == P.CLOSING and summary.get("duels") == 2 and summary.get("missed") == 0,
		"(다) 요약이 다름: %s" % str(summary))

	# (라) 결투 수 1
	var one := DayState.new(_duel_rules(1), _five_fixed())
	_fight(one, won)
	_expect(errs, not one.has_next_commission() and one.proceed() and one.phase == P.CLOSING, "(라) 결투 수 1인데 한 판 뒤 폐점이 아님")
	_expect(errs, one.closing_summary().get("missed") == 4, "(라) 만나지 못한 손님 %s (기대 4)" % str(one.closing_summary().get("missed")))

	# (마) 결투 수 0
	var none := DayState.new(_duel_rules(0), _five_fixed())
	_expect(errs, none.phase == P.CLOSING and none.closing_summary().get("missed") == 5,
		"(마) 결투 수 0인데 곧바로 폐점이 아니거나 만나지 못한 손님이 전체가 아님")

	# (바) 결투 수를 1 올리는 업그레이드
	var more := _upgrade(&"t_more_duels", 10, UpgradeData.Target.ECONOMY, &"duels_per_day", 1.0)
	var more_list: Array[UpgradeData] = [more]
	var rich_rules := _duel_rules(3)
	rich_rules.starting_money = 500
	var upgraded := DayState.new(rich_rules, _five_fixed(), _catalog(more_list))
	for i in 5:
		upgraded.decline()
	_expect(errs, upgraded.buy(more) and upgraded.next_day() and upgraded.duels_left() == 4,
		"(바) 결투 수 업그레이드를 산 다음 날의 남은 결투 %d (기대 4)" % upgraded.duels_left())

	# 일정
	var three := _three_fixed()
	var five := _five_fixed()
	var schedule := DaySchedule.new()
	var two_days: Array[DayData] = [three, five]
	schedule.days = two_days
	var scheduled := DayState.new(_duel_rules(3), null, null, schedule)
	var counts: Array[int] = []
	for i in 3:
		counts.append(scheduled.commission_count())
		while scheduled.phase == P.COUNTER:
			scheduled.decline()
		scheduled.next_day()
	_expect(errs, counts == [3, 5, 3], "일정의 날마다 손님 수 %s (기대 [3, 5, 3])" % str(counts))

	var single := DaySchedule.new()
	var one_day: Array[DayData] = [five]
	single.days = one_day
	var repeated := DayState.new(_duel_rules(3), three, null, single)
	_expect(errs, repeated.data == five, "하루뿐인 일정의 1일차가 그 하루가 아님")
	while repeated.phase == P.COUNTER:
		repeated.decline()
	repeated.next_day()
	_expect(errs, repeated.data == five, "하루뿐인 일정의 2일차가 그 하루가 아님")

	var plain := DayState.new(_duel_rules(3), three)
	while plain.phase == P.COUNTER:
		plain.decline()
	plain.next_day()
	_expect(errs, plain.data == three and plain.phase == P.COUNTER, "일정 없는 하루의 2일차가 처음 받은 DayData가 아님")

	var with_fallback := DayState.new(_duel_rules(3), three, null, DaySchedule.new())
	_expect(errs, with_fallback.data == three and with_fallback.phase == P.COUNTER, "빈 일정인데 함께 받은 DayData를 쓰지 않음")
	var nothing := DayState.new(_duel_rules(3), null, null, DaySchedule.new())
	_expect(errs, nothing.phase == P.CLOSING, "빈 일정에 DayData도 없는데 곧바로 폐점이 아님")
	return _result(errs)


# ================================================================ T39 접수의 화면

const Settlement := preload("res://scripts/economy/settlement.gd")


func _press(screen: Node, button_name: String) -> bool:
	var button := screen.find_child(button_name, true, false) as Button
	if button == null:
		return false
	button.pressed.emit()
	return true


## 그 이름의 Label의 글자. 없으면 빈 문자열.
func _label_text(screen: Node, node_name: String) -> String:
	var label := screen.find_child(node_name, true, false) as Label
	return label.text if label != null else ""


func _has_node(screen: Node, node_name: String) -> bool:
	return screen.find_child(node_name, true, false) != null


func t39_counter_screens() -> String:
	var errs: Array[String] = []
	var P := DayState.Phase
	var won := DT.EndReason.CONDITION

	# 카운터: 손님 다섯, 결투 셋
	var day := DayState.new(_duel_rules(3), _five_fixed())
	var counter := _spawn_screen(Session.COUNTER_PATH, day)
	_expect(errs, counter.find_child("Proceed", true, false) is Button and counter.find_child("Decline", true, false) is Button,
		"카운터에 Proceed나 Decline이 없음")
	var focused := _tree.root.gui_get_focus_owner()
	_expect(errs, focused == null or not counter.is_ancestor_of(focused), "카운터가 열릴 때 포커스를 가진 버튼이 있음")
	_expect(errs, counter.get("shown_waiting") == day.waiting_count() and counter.get("shown_duels_left") == day.duels_left(),
		"카운터가 내보인 기다리는 손님 %s·남은 결투 %s가 day(%d, %d)와 다름" % [
			str(counter.get("shown_waiting")), str(counter.get("shown_duels_left")), day.waiting_count(), day.duels_left()])
	_expect(errs, not _has_node(counter, "DeclineNote"), "손님 다섯·결투 셋인데 DeclineNote가 있음")
	_expect(errs, not _has_node(counter, "DeclinedLine"), "아무도 돌려보내지 않았는데 DeclinedLine이 있음")

	# 돌려보낸다 → 둘째 손님의 카운터에 첫째의 한마디
	_expect(errs, _press(counter, "Decline") and day.index == 1 and day.phase == P.COUNTER, "Decline 뒤 순번 %d, 단계 %d" % [day.index, day.phase])
	counter.free()
	counter = _spawn_screen(Session.COUNTER_PATH, day)
	_expect(errs, Ui.all_text(counter).contains("둘째"), "돌려보낸 뒤의 카운터에 둘째 손님의 이름이 없음")
	var declined_text := _label_text(counter, "DeclinedLine")
	_expect(errs, declined_text.contains("첫째") and declined_text.contains("첫째가 서운해한다"), "DeclinedLine에 첫째의 이름과 한마디가 없음: '%s'" % declined_text)
	_expect(errs, _press_proceed(counter) and day.phase == P.DUEL and day.last_declined.is_empty(), "맡은 뒤에도 방금 돌려보낸 손님이 남아 있음")
	counter.free()

	# 정산: 한마디가 있는 의뢰(둘째, 90점)를 문턱 넘는 점수로 끝냄
	day.finish_duel(_record(won))
	var settlement := _spawn_screen(Session.SETTLEMENT_PATH, day)
	var reaction := _label_text(settlement, "Reaction")
	_expect(errs, reaction == "둘째가 고마워한다", "문턱을 넘겼는데 한마디가 아님: '%s'" % reaction)
	_expect(errs, not _has_node(settlement, "MissedNote"), "결투 수가 남았는데 MissedNote가 있음")
	settlement.free()
	day.proceed()

	# 한마디가 빈 손님(셋째)을 돌려보낸 뒤의 카운터에는 DeclinedLine이 없다.
	day.decline()
	counter = _spawn_screen(Session.COUNTER_PATH, day)
	_expect(errs, Ui.all_text(counter).contains("넷째") and not _has_node(counter, "DeclinedLine"), "한마디가 빈 손님을 돌려보냈는데 DeclinedLine이 있음")
	counter.free()

	# 한마디가 빈 의뢰(넷째, 100점)의 정산은 공통 문구다.
	_fight(day, won)
	settlement = _spawn_screen(Session.SETTLEMENT_PATH, day)
	_expect(errs, _label_text(settlement, "Reaction") == Settlement.REACTION_PERFECT, "한마디가 빈 의뢰의 정산이 공통 문구가 아님")
	settlement.free()
	day.proceed()

	# 마지막 손님의 카운터에서 Decline → 폐점. 폐점에 돌려보낸 손님의 이름이 있다.
	counter = _spawn_screen(Session.COUNTER_PATH, day)
	_expect(errs, _press(counter, "Decline") and day.phase == P.CLOSING, "마지막 손님을 돌려보냈는데 폐점이 아님")
	counter.free()
	var closing := _spawn_screen(Session.CLOSING_PATH, day)
	var names := _label_text(closing, "DeclinedNames")
	_expect(errs, names.contains("첫째") and names.contains("셋째") and names.contains("다섯째"), "폐점에 돌려보낸 손님의 이름이 없음: '%s'" % names)
	_expect(errs, not _has_node(closing, "MissedLine"), "만나지 못한 손님이 없는데 MissedLine이 있음")
	closing.free()

	# 문턱 이하의 점수로 끝낸 같은 의뢰 → 공통 문구
	var low_data := _five_fixed()
	(low_data.commissions[0].conditions[0] as FixedScore).score = 60
	var low := DayState.new(_duel_rules(3), low_data)
	_fight(low, won)
	settlement = _spawn_screen(Session.SETTLEMENT_PATH, low)
	_expect(errs, _label_text(settlement, "Reaction") == Settlement.REACTION_PARTIAL, "문턱 이하인데 공통 문구가 아님: '%s'" % _label_text(settlement, "Reaction"))
	settlement.free()

	# 결투 수가 찬 정산: 손님이 남아 있으면 MissedNote, 버튼은 "가게를 닫는다"
	var full := DayState.new(_duel_rules(3), _five_fixed())
	for i in 3:
		_fight(full, won)
		if i < 2:
			full.proceed()
	settlement = _spawn_screen(Session.SETTLEMENT_PATH, full)
	_expect(errs, _has_node(settlement, "MissedNote"), "결투 수가 찼고 손님이 남았는데 MissedNote가 없음")
	_expect(errs, (settlement.find_child("Proceed", true, false) as Button).text == "가게를 닫는다", "결투 수가 찬 정산의 버튼 글이 다름")
	_expect(errs, _press_proceed(settlement) and full.phase == P.CLOSING, "결투 수가 찬 정산의 Proceed 뒤 폐점이 아님")
	settlement.free()
	closing = _spawn_screen(Session.CLOSING_PATH, full)
	_expect(errs, _label_text(closing, "MissedLine").contains("만나지 못한 손님 2"), "폐점에 만나지 못한 손님 줄이 없음")
	_expect(errs, not _has_node(closing, "DeclinedNames") and not _has_node(closing, "DeclinedLine"), "아무도 돌려보내지 않았는데 돌려보낸 손님 줄이 있음")
	closing.free()

	# 손님 셋·결투 셋: 첫 카운터에 DeclineNote가 있고, 다 맡은 폐점에는 두 줄이 다 없다.
	var even := DayState.new(_duel_rules(3), _three_fixed())
	counter = _spawn_screen(Session.COUNTER_PATH, even)
	_expect(errs, _has_node(counter, "DeclineNote"), "손님 셋·결투 셋인데 DeclineNote가 없음")
	counter.free()
	_run_fixed_day(even)
	closing = _spawn_screen(Session.CLOSING_PATH, even)
	_expect(errs, not _has_node(closing, "DeclinedNames") and not _has_node(closing, "MissedLine"), "다 맡은 하루의 폐점에 돌려보낸·만나지 못한 손님 줄이 있음")
	closing.free()

	# 마지막 손님을 돌려보내 온 폐점에는 그 손님의 한마디가 있다.
	var last_data := DayData.new()
	var one: Array[Commission] = [_five_fixed().commissions[0]]
	last_data.commissions = one
	var last := DayState.new(_duel_rules(3), last_data)
	last.decline()
	closing = _spawn_screen(Session.CLOSING_PATH, last)
	_expect(errs, _label_text(closing, "DeclinedLine").contains("첫째가 서운해한다"), "마지막 손님을 돌려보낸 폐점에 한마디가 없음")
	closing.free()

	# 단계가 맞지 않는 day(결투 단계)를 넣은 카운터는 아무것도 바꾸지 않는다.
	var wrong := DayState.new(_duel_rules(3), _five_fixed())
	wrong.accept()
	var snap := _decline_snapshot(wrong)
	counter = _spawn_screen(Session.COUNTER_PATH, wrong)
	_press(counter, "Decline")
	_expect(errs, _decline_snapshot(wrong) == snap, "단계가 맞지 않는 카운터의 Decline이 day를 바꿈")
	counter.free()
	return _result(errs)


# ================================================================ T45 보수의 기준치

## 테스트가 직접 만든 규칙: 팁 문턱 70에 전액 기준치와 "팁에도 거는가"를 적는다.
func _full_pay_rules(full_pay_score: int, covers_tip := true) -> EconomyRules:
	var rules := _rules()
	rules.full_pay_score = full_pay_score
	rules.full_pay_covers_tip = covers_tip
	return rules


## 고정 점수 의뢰 하나를 끝낸 정산 단계의 하루.
func _settled_day(rules: EconomyRules, score: int) -> DayState:
	var data := DayData.new()
	var one: Array[Commission] = [_fixed_commission("기준치", 45, 25, score)]
	data.commissions = one
	var day := DayState.new(rules, data)
	_fight(day, DT.EndReason.CONDITION)
	return day


func t45_full_pay() -> String:
	var errs: Array[String] = []
	var with_tip := _full_pay_rules(80)
	var base_only := _full_pay_rules(80, false)
	var off := _full_pay_rules(100)
	_expect(errs, EconomyRules.new().full_pay_score == 100 and EconomyRules.new().full_pay_covers_tip,
		"스크립트 기본값이 '기준치 없음, 팁에도 건다'가 아님")

	# ---- 기준치 80, 팁에도 건다: 계획 008의 표 그대로. [충족도, 기본 보수, 팁 최대, 기대 기본 보수, 기대 팁]
	var table := [
		[100, 45, 25, 45, 25],
		[90, 45, 25, 45, 25],
		[80, 45, 25, 45, 25],
		[70, 45, 25, 40, 15],
		[60, 45, 25, 34, 4],
		[40, 45, 25, 23, 0],
		[0, 45, 25, 0, 0],
		[100, 30, 15, 30, 15],
		[40, 30, 15, 15, 0],
		[0, 30, 15, 0, 0],
	]
	for row in table:
		var pay := DayState.payout(row[0], row[1], row[2], with_tip)
		_expect(errs, pay["base"] == row[3] and pay["tip"] == row[4],
			"[팁에도] 충족도 %d (%d/%d) → 기본 %d 팁 %d (기대 %d, %d)" % [row[0], row[1], row[2], pay["base"], pay["tip"], row[3], row[4]])

	# ---- 대안(기준치 80, 기본 보수에만): 계획 008의 대안 표. 기본 보수는 "팁에도 건다"일 때와 같다.
	var alt_table := [
		[100, 45, 25],
		[90, 45, 17],
		[80, 45, 8],
		[70, 40, 0],
		[60, 34, 0],
	]
	for row in alt_table:
		var pay := DayState.payout(row[0], 45, 25, base_only)
		_expect(errs, pay["base"] == row[1] and pay["tip"] == row[2],
			"[기본 보수에만] 충족도 %d → 기본 %d 팁 %d (기대 %d, %d)" % [row[0], pay["base"], pay["tip"], row[1], row[2]])
		_expect(errs, pay["base"] == DayState.payout(row[0], 45, 25, with_tip)["base"], "[기본 보수에만] 충족도 %d의 기본 보수가 '팁에도 건다'일 때와 다름" % row[0])

	# ---- 충족도 0~100 전부: 줄지 않고, 상한을 넘지 않고, 기준치 이상이면 최대다
	for rules: EconomyRules in [with_tip, base_only]:
		var label := "팁에도" if rules.full_pay_covers_tip else "기본 보수에만"
		var prev_base := -1
		var prev_tip := -1
		for score in 101:
			var pay := DayState.payout(score, 45, 25, rules)
			var base: int = pay["base"]
			var tip: int = pay["tip"]
			if base < prev_base or tip < prev_tip or base > 45 or tip > 25:
				errs.append("[%s] 충족도 %d에서 돈이 줄거나 상한을 넘음 (기본 %d, 팁 %d)" % [label, score, base, tip])
				break
			if score >= 80 and (base != 45 or (rules.full_pay_covers_tip and tip != 25)):
				errs.append("[%s] 충족도 %d가 기준치 이상인데 최대가 아님 (기본 %d, 팁 %d)" % [label, score, base, tip])
				break
			prev_base = base
			prev_tip = tip
		_expect(errs, DayState.payout(100, 45, 25, rules)["tip"] == 25, "[%s] 충족도 100인데 팁이 최대가 아님" % label)

	# ---- 기준치 100이면 지금의 식이다(끄는 법): T29의 표와 같고, 기본 규칙과 전 구간이 같다
	var plain := _rules()
	for row in [[90, 45, 25, 41, 17], [80, 45, 25, 36, 8], [70, 45, 25, 32, 0], [85, 40, 30, 34, 15], [71, 40, 30, 28, 1], [40, 30, 15, 12, 0]]:
		var pay := DayState.payout(row[0], row[1], row[2], off)
		_expect(errs, pay["base"] == row[3] and pay["tip"] == row[4], "[기준치 100] 충족도 %d (%d/%d) → 기본 %d 팁 %d (기대 %d, %d)" % [
			row[0], row[1], row[2], pay["base"], pay["tip"], row[3], row[4]])
	for score in 101:
		if DayState.payout(score, 45, 25, off) != DayState.payout(score, 45, 25, plain):
			errs.append("[기준치 100] 충족도 %d의 돈이 기본 규칙과 다름" % score)
			break

	# ---- 0이나 음수, 100 초과로 적은 기준치는 오류 없이 1~100으로 잘린다
	for raw: int in [0, -5]:
		var low := DayState.payout(1, 45, 25, _full_pay_rules(raw))
		_expect(errs, DayState.full_pay_score(_full_pay_rules(raw)) == 1 and low["base"] == 45 and low["tip"] == 25,
			"[기준치 %d] 1로 잘리지 않음 (충족도 1 → 기본 %d, 팁 %d)" % [raw, low["base"], low["tip"]])
		_expect(errs, DayState.payout(0, 45, 25, _full_pay_rules(raw))["base"] == 0, "[기준치 %d] 충족도 0인데 돈이 있음" % raw)
	_expect(errs, DayState.full_pay_score(_full_pay_rules(250)) == 100 \
		and DayState.payout(80, 45, 25, _full_pay_rules(250)) == DayState.payout(80, 45, 25, plain), "[기준치 250] 100으로 잘리지 않음")

	# ---- 팁 덧붙임(30%)과 함께: 기준치 80, 충족도 80 → 팁이 덧붙임이 든 최대다
	var boosted := _full_pay_rules(80)
	boosted.tip_bonus_percent = 30
	var boosted_tip: int = DayState.payout(80, 45, 25, boosted)["tip"]
	_expect(errs, boosted_tip == DayState.boosted_tip_max(25, boosted) and boosted_tip == 33, "[덧붙임 30] 충족도 80의 팁 %d (기대 33)" % boosted_tip)

	# ---- 정산 결과와 화면의 한 줄(FullPayNote)
	var met := _settled_day(with_tip, 90)
	_expect(errs, met.last_result().get("full_pay") == true and met.last_result().get("full_pay_score") == 80 \
		and met.last_result().get("total") == 70 and met.last_result().get("score") == 90,
		"기준치 80에 90점인 정산 결과가 다름: %s" % str(met.last_result()))
	var met_screen := _spawn_screen(Session.SETTLEMENT_PATH, met)
	_expect(errs, _label_text(met_screen, "FullPayNote").contains("전부"), "기준치 이상인데 FullPayNote에 '전부'가 없음: '%s'" % _label_text(met_screen, "FullPayNote"))
	_expect(errs, Ui.all_text(met_screen).contains("충족도 90"), "정산 화면의 충족도가 깎이지 않은 숫자(90)가 아님")
	met_screen.free()

	var missed := _settled_day(with_tip, 60)
	_expect(errs, missed.last_result().get("full_pay") == false and missed.last_result().get("total") == 38, "기준치 80에 60점인 정산 결과가 다름: %s" % str(missed.last_result()))
	var missed_screen := _spawn_screen(Session.SETTLEMENT_PATH, missed)
	_expect(errs, _label_text(missed_screen, "FullPayNote").contains("못 미쳐"), "기준치 아래인데 FullPayNote에 '못 미쳐'가 없음: '%s'" % _label_text(missed_screen, "FullPayNote"))
	missed_screen.free()

	var alt_screen := _spawn_screen(Session.SETTLEMENT_PATH, _settled_day(base_only, 90))
	_expect(errs, _label_text(alt_screen, "FullPayNote").contains("기본 보수를 전부"), "기본 보수에만 거는 규칙의 FullPayNote가 다름: '%s'" % _label_text(alt_screen, "FullPayNote"))
	alt_screen.free()

	var off_screen := _spawn_screen(Session.SETTLEMENT_PATH, _settled_day(off, 90))
	_expect(errs, not _has_node(off_screen, "FullPayNote"), "기준치 100인데 FullPayNote가 있음")
	off_screen.free()

	# ---- 로드한 규칙: 범위만 통과 조건이다
	var loaded := load(ECONOMY_PATH) as EconomyRules
	_expect(errs, loaded.full_pay_score >= 1 and loaded.full_pay_score <= 100, "로드한 전액 기준치 %d (1 이상 100 이하여야 함)" % loaded.full_pay_score)
	print("  INFO 로드한 경제 규칙: 전액 기준치 %d, 팁에도 건다 %s, 팁 문턱 %d" % [loaded.full_pay_score, str(loaded.full_pay_covers_tip), loaded.tip_floor])

	# ---- INFO (통과 조건 아님): 의뢰 일곱의 받는 돈을 세 가지로 — 기준치 없음 / 팁에도 건다 / 기본 보수에만
	var none_rules := loaded.duplicate() as EconomyRules
	none_rules.full_pay_score = 100
	var both_rules := loaded.duplicate() as EconomyRules
	both_rules.full_pay_covers_tip = true
	var base_rules := loaded.duplicate() as EconomyRules
	base_rules.full_pay_covers_tip = false
	var scores := [100, 90, 80, 70, 60, 40]
	print("  INFO 받는 돈 (기준치 없음 / 팁에도 건다 / 기본 보수에만), 충족도 %s" % str(scores))
	for path in [FIRST_BLOOD_PATH, FEATHER_PATH, THROW_PATH, POOR_PATH, BET_PATH, USURER_PATH, LEGS_PATH]:
		var commission := load(path) as Commission
		var cells: Array[String] = []
		for score: int in scores:
			var triple: Array[String] = []
			for rules: EconomyRules in [none_rules, both_rules, base_rules]:
				var pay := DayState.payout(score, commission.base_reward, commission.tip_max, rules)
				triple.append(str(int(pay["base"]) + int(pay["tip"])))
			cells.append("%d점 %s" % [score, " / ".join(PackedStringArray(triple))])
		print("  INFO %s (%d+%d): %s" % [commission.client_name, commission.base_reward, commission.tip_max, " · ".join(PackedStringArray(cells))])
	return _result(errs)
