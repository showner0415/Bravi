class_name DayState
extends RefCounted
## 하루의 상태와 장부. Node에 의존하지 않는다(화면은 이것을 읽고 전환만 부른다).
##
## 단계: COUNTER(의뢰인의 사연) → DUEL → SETTLEMENT → 다음 의뢰가 있으면 COUNTER, 없으면 CLOSING
##       → 다음 날이면 COUNTER.
## 단계에 맞지 않는 요청은 아무것도 바꾸지 않고 false를 돌려준다(오류를 찍지 않는다).
## 수입은 정산 때마다 소지금에 더하고, 지출(임대료 + 치료비)은 폐점에 들어설 때 한 번 뺀다.

enum Phase { COUNTER, DUEL, SETTLEMENT, CLOSING }

var rules: EconomyRules
var data: DayData

# --- 날을 넘는 것 (저장과 업그레이드가 들어오면 여기서 갈라낸다) ---
var day_number := 1
var money := 0

# --- 하루의 것 ---
var phase: int = Phase.COUNTER
## 지금 의뢰의 순번(0부터).
var index := 0
## 오늘 끝낸 결투의 정산 결과. settle()이 돌려준 Dictionary 그대로다(숫자와 글만 담는다).
var results: Array[Dictionary] = []
var _summary: Dictionary = {}


func _init(p_rules: EconomyRules, p_data: DayData) -> void:
	rules = p_rules
	data = p_data
	money = rules.starting_money
	_begin_day()


# ---------------------------------------------------------------- 순수 함수

## a x b / d를 0.5 올림으로 반올림한다. 정수 연산만 쓴다(부동소수를 지나지 않는다).
static func round_div(a: int, b: int, d: int) -> int:
	@warning_ignore("integer_division")
	return (a * b * 2 + d) / (2 * d)


## 충족도로 받는 돈. {"base": 기본 보수, "tip": 팁}
## 기본 보수는 충족도에 비례하고, 팁은 충족도가 tip_floor를 넘는 만큼에 비례한다.
static func payout(score: int, base_reward: int, tip_max: int, p_rules: EconomyRules) -> Dictionary:
	var s := clampi(score, 0, 100)
	var base := round_div(base_reward, s, 100)
	var tip := 0
	var tip_floor := clampi(p_rules.tip_floor, 0, 100)
	if s > tip_floor:
		tip = round_div(tip_max, s - tip_floor, 100 - tip_floor)
	return {"base": base, "tip": tip}


## 결투 한 건의 정산. record는 끝난 결투의 기록이다. 돌려주는 값은 숫자와 글뿐이다.
static func settle(commission: Commission, record: DuelRecord, p_rules: EconomyRules) -> Dictionary:
	var score := clampi(commission.evaluate(record), 0, 100)
	var pay := payout(score, commission.base_reward, commission.tip_max, p_rules)
	# 부상은 유효타를 맞고 끝난 결투다. 자세만 깎인 것은 부상이 아니다.
	var injured := record.end_reason == DuelTypes.EndReason.PLAYER_DEFEATED
	return {
		"client_name": commission.client_name,
		"score": score,
		"base": int(pay["base"]),
		"base_max": commission.base_reward,
		"tip": int(pay["tip"]),
		"tip_max": commission.tip_max,
		"total": int(pay["base"]) + int(pay["tip"]),
		"injured": injured,
		"medical_fee": p_rules.medical_fee if injured else 0,
		"lines": commission.explain(record),
		"elapsed": record.elapsed,
	}


# ---------------------------------------------------------------- 읽기

## 오늘 오는 의뢰의 수.
func commission_count() -> int:
	return data.commissions.size() if data != null else 0


## 지금 의뢰. 폐점이거나 의뢰가 없으면 null.
func current_commission() -> Commission:
	if phase == Phase.CLOSING or index < 0 or index >= commission_count():
		return null
	return data.commissions[index]


## 지금 의뢰 뒤에 남은 의뢰가 있는가.
func has_next_commission() -> bool:
	return index + 1 < commission_count()


## 가장 최근의 정산 결과. 없으면 빈 Dictionary.
func last_result() -> Dictionary:
	return results[results.size() - 1] if not results.is_empty() else {}


## 폐점 요약. 폐점 단계에서만 채워져 있다.
## income, rent, injuries, medical, expenses, profit, money_before, money_after
func closing_summary() -> Dictionary:
	return _summary


# ---------------------------------------------------------------- 전환

## 카운터에서 의뢰를 맡는다 → 결투.
func accept() -> bool:
	if phase != Phase.COUNTER or current_commission() == null:
		return false
	phase = Phase.DUEL
	return true


## 결투가 끝났다. 기록을 정산해 결과 목록에 넣고 수입을 소지금에 더한다 → 정산.
func finish_duel(record: DuelRecord) -> bool:
	if phase != Phase.DUEL or record == null:
		return false
	var result := settle(current_commission(), record, rules)
	results.append(result)
	money += int(result["total"])
	phase = Phase.SETTLEMENT
	return true


## 정산을 본 뒤 다음으로: 남은 의뢰가 있으면 다음 의뢰인, 없으면 폐점.
## 폐점에서는 아무것도 하지 않는다(지출이 두 번 빠지지 않는다).
func proceed() -> bool:
	if phase != Phase.SETTLEMENT:
		return false
	if has_next_commission():
		index += 1
		phase = Phase.COUNTER
	else:
		_enter_closing()
	return true


## 폐점 뒤 다음 날을 연다. 소지금은 이어진다.
func next_day() -> bool:
	if phase != Phase.CLOSING:
		return false
	day_number += 1
	_begin_day()
	return true


func _begin_day() -> void:
	index = 0
	results = []
	_summary = {}
	if commission_count() == 0:
		_enter_closing()
	else:
		phase = Phase.COUNTER


## 폐점에 들어선다. 지출을 한 번 빼고 요약을 만든다.
func _enter_closing() -> void:
	var income := 0
	var injuries := 0
	var medical := 0
	for result in results:
		income += int(result["total"])
		if result["injured"]:
			injuries += 1
			medical += int(result["medical_fee"])
	var expenses := rules.rent + medical
	var before := money
	money -= expenses
	_summary = {
		"income": income,
		"rent": rules.rent,
		"injuries": injuries,
		"medical": medical,
		"expenses": expenses,
		"profit": income - expenses,
		"money_before": before,
		"money_after": money,
	}
	phase = Phase.CLOSING
