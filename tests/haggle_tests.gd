extends RefCounted
## T55: 흥정의 확률과 거절의 대가 — 확률표, 주사위, 받아 준 판과 거절당한 판의 돈, 다음 손님에서 사라짐, 화면.
## 하루의 도우미(고정 점수 의뢰, 손으로 만든 기록, 화면 붙이기)는 day_tests.gd의 것을 쓴다.
## 통과 조건은 테스트가 직접 만든 경제 규칙·평판 규칙·고정 점수 의뢰로 본다(.tres의 값과 상관없다).
## 주사위는 haggle(roll)로 고정한다. roll이 확률보다 작으면 받아 준다.

const Day := preload("res://tests/day_tests.gd")
const DT := preload("res://scripts/duel/duel_types.gd")
const Session := preload("res://scripts/game_session.gd")
const Ui := preload("res://scripts/day_ui.gd")

var _tree: SceneTree
var _d := Day.new()


func list(tree: SceneTree) -> Array:
	_tree = tree
	_d.set("_tree", tree)
	return [
		{"id": "T55", "name": "흥정의 확률과 거절의 대가: 표, 주사위, 팁 감점, 다음 손님에서 사라짐", "fn": t55_haggle},
	]


func cleanup() -> void:
	_d.cleanup()
	_d = null
	_tree = null


# ================================================================ 도우미

func _expect(errs: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		errs.append(msg)


func _result(errs: Array[String]) -> String:
	return "OK" if errs.is_empty() else " / ".join(errs)


## 테스트가 직접 만든 경제 규칙: 기준치 80, 흥정 +30(100점이어야 다 받는다), 확률표 70·85·95 / 40·15·5.
## tip_cut은 거절의 팁 감점, tip_bonus는 팁의 덧붙임(응접실 의자의 자리)이다.
func _haggle_rules(tip_cut := 50, tip_bonus := 0) -> EconomyRules:
	var economy: EconomyRules = _d._duel_rules(3)
	economy.full_pay_score = 80
	economy.tip_bonus_percent = tip_bonus
	economy.haggle_bonus_percent = 30
	economy.haggle_full_pay_score = 100
	economy.haggle_refuse_tip_cut_percent = tip_cut
	economy.haggle_chance_met = PackedInt32Array([70, 85, 95])
	economy.haggle_chance_short = PackedInt32Array([40, 15, 5])
	return economy


## 테스트가 직접 만든 평판 규칙: 시작 9(별 3). 기본 보수의 덧붙임과 날의 배율은 없다.
func _rep_rules() -> ReputationRules:
	var rep := ReputationRules.new()
	rep.enabled = true
	rep.start = 9
	rep.min_value = 0
	rep.max_value = 20
	rep.star_thresholds = PackedInt32Array([4, 8, 12, 16])
	rep.guest_delta = PackedInt32Array([0, 0, 0, 0, 0])
	rep.perfect_bonus = 1
	return rep


## 고정 점수 100의 의뢰. min_stars는 흥정의 눈높이다. 평판의 값은 기본(전부 0)이라 평판이 움직이지 않는다.
func _client(client: String, base_reward: int, tip_max: int, min_stars: int) -> Commission:
	var commission: Commission = _d._fixed_commission(client, base_reward, tip_max, 100)
	commission.haggle_min_stars = min_stars
	return commission


## 손님 넷: 갑(눈높이 3), 을(4), 병(0 = 흥정할 수 없다), 정(5).
func _four() -> DayData:
	var commissions: Array[Commission] = [
		_client("갑", 45, 25, 3), _client("을", 45, 25, 4), _client("병", 30, 15, 0), _client("정", 45, 25, 5)]
	var data := DayData.new()
	data.commissions = commissions
	return data


## 손님 넷의 새 하루. with_reputation이 거짓이면 평판 규칙 없이 만든다.
func _new_day(economy: EconomyRules, with_reputation := true) -> DayState:
	if with_reputation:
		return DayState.new(economy, _four(), null, null, _rep_rules())
	return DayState.new(economy, _four())


## 지금 손님을 맡아 끝낸다(정산까지). 그 판의 결과를 돌려준다.
func _take(day: DayState) -> Dictionary:
	day.accept()
	day.finish_duel(_d._record(DT.EndReason.CONDITION))
	return day.last_result()


# ================================================================ T55 흥정의 확률과 거절의 대가

func t55_haggle() -> String:
	var errs: Array[String] = []
	_check_table(errs)
	_check_chances(errs)
	_check_agreed(errs)
	_check_refused(errs)
	_check_cleared(errs)
	_check_read_only(errs)
	_check_no_reputation(errs)
	_check_sum_and_floor(errs)
	_check_screens(errs)
	return _result(errs)


## 가. 확률표: 차마다의 값, 표가 끝나면 마지막 값, 빈 표.
func _check_table(errs: Array[String]) -> void:
	var economy := _haggle_rules()
	var rows := [[0, 70], [1, 85], [2, 95], [7, 95], [-1, 40], [-2, 15], [-3, 5], [-7, 5]]
	for row: Array in rows:
		var got := economy.haggle_chance_for(int(row[0]))
		_expect(errs, got == int(row[1]), "[가] 차 %d의 확률 %d (기대 %d)" % [int(row[0]), got, int(row[1])])
	var empty := EconomyRules.new()
	_expect(errs, empty.haggle_chance_for(0) == 100 and empty.haggle_chance_for(3) == 100 and empty.haggle_chance_for(-1) == 0,
		"[가] 빈 표의 확률 %d, %d, %d (기대 100, 100, 0)" % [
			empty.haggle_chance_for(0), empty.haggle_chance_for(3), empty.haggle_chance_for(-1)])


## 나. 별 3에서 손님마다의 확률. 흥정할 수 없는 손님은 0이고 눌리지 않는다.
func _check_chances(errs: Array[String]) -> void:
	var day := _new_day(_haggle_rules())
	_expect(errs, day.reputation_stars() == 3, "[나] 시작 별 %d (기대 3)" % day.reputation_stars())
	_expect(errs, day.haggle_chance() == 70, "[나] 갑(눈높이 3)의 확률 %d (기대 70)" % day.haggle_chance())
	day.decline()
	_expect(errs, day.haggle_chance() == 40, "[나] 을(눈높이 4)의 확률 %d (기대 40)" % day.haggle_chance())
	day.decline()
	_expect(errs, day.haggle_chance() == 0 and not day.can_haggle(), "[나] 병(눈높이 0)의 확률 %d, 흥정할 수 있음 %s (기대 0, false)" % [
		day.haggle_chance(), str(day.can_haggle())])
	_expect(errs, not day.haggle(0) and day.haggle_state() == DayState.Haggle.NONE, "[나] 흥정할 수 없는 손님에게 흥정이 됨")
	day.decline()
	_expect(errs, day.haggle_chance() == 15, "[나] 정(눈높이 5)의 확률 %d (기대 15)" % day.haggle_chance())


## 다·라. 주사위 69는 받아 준다(확률 70). 받아 준 판의 규칙과 돈.
func _check_agreed(errs: Array[String]) -> void:
	var day := _new_day(_haggle_rules())
	_expect(errs, day.haggle(69) and day.haggle_state() == DayState.Haggle.AGREED, "[다] 확률 70에서 주사위 69가 받아 주지 않음")
	var economy := day.settle_rules()
	_expect(errs, economy.base_bonus_percent == 30 and economy.full_pay_score == 100 and economy.tip_bonus_percent == 0,
		"[라] 받아 준 판의 규칙: 기본 보수 덧붙임 %d, 기준치 %d, 팁 덧붙임 %d (기대 30, 100, 0)" % [
			economy.base_bonus_percent, economy.full_pay_score, economy.tip_bonus_percent])
	var result := _take(day)
	_expect(errs, int(result["base"]) == 59 and int(result["tip"]) == 25,
		"[라] 받아 준 판의 돈: 기본 보수 %d, 팁 %d (기대 59, 25)" % [int(result["base"]), int(result["tip"])])
	_expect(errs, int(result.get("haggle_percent", -1)) == 30 and int(result.get("haggle_tip_cut_percent", -1)) == 0,
		"[라] 받아 준 판의 결과: 흥정 %d, 팁 감점 %d (기대 30, 0)" % [
			int(result.get("haggle_percent", -1)), int(result.get("haggle_tip_cut_percent", -1))])


## 다·마. 주사위 70은 거절이다(확률 70). 거절당한 판의 규칙과 돈. 다시 흥정할 수 없다.
func _check_refused(errs: Array[String]) -> void:
	var day := _new_day(_haggle_rules())
	_expect(errs, day.haggle(70) and day.haggle_state() == DayState.Haggle.REFUSED, "[다] 확률 70에서 주사위 70이 거절이 아님")
	_expect(errs, not day.can_haggle() and not day.haggle(0) and day.haggle_state() == DayState.Haggle.REFUSED,
		"[마] 거절당한 뒤에 다시 흥정이 됨")
	var economy := day.settle_rules()
	_expect(errs, economy.tip_bonus_percent == -50 and economy.base_bonus_percent == 0 and economy.full_pay_score == 80,
		"[마] 거절당한 판의 규칙: 팁 덧붙임 %d, 기본 보수 덧붙임 %d, 기준치 %d (기대 -50, 0, 80)" % [
			economy.tip_bonus_percent, economy.base_bonus_percent, economy.full_pay_score])
	var result := _take(day)
	_expect(errs, int(result["base"]) == 45 and int(result["tip"]) == 13 and int(result["tip_max"]) == 13 and int(result["total"]) == 58,
		"[마] 거절당한 판의 돈: 기본 보수 %d, 팁 %d / %d, 합 %d (기대 45, 13 / 13, 58)" % [
			int(result["base"]), int(result["tip"]), int(result["tip_max"]), int(result["total"])])
	_expect(errs, int(result.get("haggle_percent", -1)) == 0 and int(result.get("haggle_tip_cut_percent", -1)) == 50,
		"[마] 거절당한 판의 결과: 흥정 %d, 팁 감점 %d (기대 0, 50)" % [
			int(result.get("haggle_percent", -1)), int(result.get("haggle_tip_cut_percent", -1))])


## 바. 거절의 감점은 그 손님에게만 걸린다: 돌려보내거나 맡아 끝낸 뒤의 다음 손님에게는 없다.
func _check_cleared(errs: Array[String]) -> void:
	var sent := _new_day(_haggle_rules())
	sent.haggle(99)
	sent.decline()
	_expect(errs, sent.haggle_state() == DayState.Haggle.NONE and sent.settle_rules().tip_bonus_percent == 0 and sent.can_haggle(),
		"[바] 거절당한 손님을 돌려보낸 뒤: 흥정 %d, 팁 덧붙임 %d (기대 0, 0)" % [
			sent.haggle_state(), sent.settle_rules().tip_bonus_percent])
	var done := _new_day(_haggle_rules())
	done.haggle(99)
	_take(done)
	done.proceed()
	_expect(errs, done.phase == DayState.Phase.COUNTER and done.index == 1, "[바] 맡아 끝낸 뒤 다음 손님의 카운터가 아님")
	_expect(errs, done.haggle_state() == DayState.Haggle.NONE and done.settle_rules().tip_bonus_percent == 0 and done.can_haggle(),
		"[바] 거절당한 손님을 맡아 끝낸 뒤: 흥정 %d, 팁 덧붙임 %d (기대 0, 0)" % [
			done.haggle_state(), done.settle_rules().tip_bonus_percent])


## 사. 미리 보는 두 함수는 읽기만 한다.
func _check_read_only(errs: Array[String]) -> void:
	var day := _new_day(_haggle_rules())
	var refused := day.haggle_refused_rules()
	var agreed := day.haggle_preview_rules()
	_expect(errs, refused.tip_bonus_percent == -50 and refused.base_bonus_percent == 0,
		"[사] 거절을 친 규칙: 팁 덧붙임 %d, 기본 보수 덧붙임 %d (기대 -50, 0)" % [refused.tip_bonus_percent, refused.base_bonus_percent])
	_expect(errs, agreed.base_bonus_percent == 30 and agreed.full_pay_score == 100 and agreed.tip_bonus_percent == 0,
		"[사] 받아 줌을 친 규칙: 기본 보수 덧붙임 %d, 기준치 %d (기대 30, 100)" % [agreed.base_bonus_percent, agreed.full_pay_score])
	_expect(errs, day.haggle_state() == DayState.Haggle.NONE and day.can_haggle(), "[사] 미리 보는 함수가 흥정의 상태를 바꿈")
	_expect(errs, day.settle_rules().tip_bonus_percent == 0 and day.settle_rules().base_bonus_percent == 0,
		"[사] 미리 본 뒤의 규칙이 흥정 전과 다름")


## 아. 평판이 없는 하루는 늘 받아 준다(주사위를 뽑아도 같다).
func _check_no_reputation(errs: Array[String]) -> void:
	var day := _new_day(_haggle_rules(), false)
	_expect(errs, not day.has_reputation() and day.haggle_chance() == 100, "[아] 평판이 없는 하루의 확률 %d (기대 100)" % day.haggle_chance())
	_expect(errs, day.haggle() and day.haggle_state() == DayState.Haggle.AGREED, "[아] 평판이 없는 하루에 흥정을 받아 주지 않음")


## 자. 팁의 덧붙임(의자)과는 더하고, 팁은 0 아래로 내려가지 않는다.
func _check_sum_and_floor(errs: Array[String]) -> void:
	var chair := _new_day(_haggle_rules(50, 30))
	chair.haggle(99)
	var chair_rules := chair.settle_rules()
	_expect(errs, chair_rules.tip_bonus_percent == -20 and DayState.boosted_tip_max(25, chair_rules) == 20,
		"[자] 덧붙임 30에서 거절: 팁 덧붙임 %d, 팁 최대 %d (기대 -20, 20)" % [
			chair_rules.tip_bonus_percent, DayState.boosted_tip_max(25, chair_rules)])
	var deep := _new_day(_haggle_rules(150))
	deep.haggle(99)
	_expect(errs, deep.settle_rules().tip_bonus_percent == -100, "[자] 감점 150에서 팁 덧붙임 %d (기대 -100)" % deep.settle_rules().tip_bonus_percent)
	var result := _take(deep)
	_expect(errs, int(result["tip"]) == 0 and int(result["tip_max"]) == 0 and int(result["base"]) == 45,
		"[자] 감점 150의 돈: 기본 보수 %d, 팁 %d / %d (기대 45, 0 / 0)" % [int(result["base"]), int(result["tip"]), int(result["tip_max"])])


## 차. 화면: 흥정 전의 대가, 거절 뒤의 보수 줄과 버튼, 정산의 팁 줄. 확률은 화면에 나오지 않는다.
func _check_screens(errs: Array[String]) -> void:
	var day := _new_day(_haggle_rules())
	var before: Node = _d._spawn_screen(Session.COUNTER_PATH, day)
	var hint: String = _d._label_text(before, "HaggleLine")
	_expect(errs, hint.contains("팁 최대 13") and not hint.contains("%") and not hint.contains("70"),
		"[차] 흥정 전의 HaggleLine '%s' (기대: '팁 최대 13'이 있고 확률이 없다)" % hint)
	_expect(errs, _d._has_node(before, "Haggle"), "[차] 흥정 전의 카운터에 Haggle 버튼이 없음")
	before.free()

	day.haggle(99)
	var after: Node = _d._spawn_screen(Session.COUNTER_PATH, day)
	var pay: String = _d._label_text(after, "PayLine")
	_expect(errs, pay.contains("팁 최대 13") and pay.contains("깎였다"), "[차] 거절 뒤의 PayLine '%s' (기대: '팁 최대 13', '깎였다')" % pay)
	var button := after.find_child("Haggle", true, false) as Button
	_expect(errs, button != null and button.disabled, "[차] 거절 뒤의 Haggle 버튼이 없거나 눌림")
	after.free()

	_take(day)
	var settlement: Node = _d._spawn_screen(Session.SETTLEMENT_PATH, day)
	var text: String = Ui.all_text(settlement)
	_expect(errs, text.contains("흥정 거절"), "[차] 거절당한 판의 정산에 '흥정 거절'이 없음")
	settlement.free()
