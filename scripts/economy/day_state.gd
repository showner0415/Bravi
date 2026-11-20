class_name DayState
extends RefCounted
## 하루의 상태와 장부. Node에 의존하지 않는다(화면은 이것을 읽고 전환만 부른다).
##
## 단계: COUNTER(손님의 사연) → 맡으면 DUEL → SETTLEMENT → 다음 손님을 만나게 되면 COUNTER, 아니면 CLOSING
##       → 다음 날이면 COUNTER.
##       COUNTER에서 돌려보내면 다음 손님의 COUNTER, 기다리는 손님이 없으면 CLOSING.
## 손님은 차례로 한 명씩 온다. 하루에 맡는 결투는 duels_per_day까지이고, 차면 남은 손님은 돌아간다.
## 단계에 맞지 않는 요청은 아무것도 바꾸지 않고 false를 돌려준다(오류를 찍지 않는다).
## 수입은 정산 때마다 소지금에 더하고, 지출(임대료 + 치료비)은 폐점에 들어설 때 한 번 뺀다.
## 업그레이드는 폐점에서 사고, 그 효과는 다음 날부터 난다(사는 때가 그날의 정산과 지출이 끝난 뒤다).

enum Phase { COUNTER, DUEL, SETTLEMENT, CLOSING }
## 지금 손님과의 흥정("값을 올려 부른다"). 한 손님에게 한 번뿐이고 되돌릴 수 없다.
enum Haggle { NONE, AGREED, REFUSED }

## 저장의 형식 버전. 다른 버전의 저장은 읽지 않는다(옮기지 않는다).
const SAVE_VERSION := 1
## 흥정 주사위의 씨앗이 가질 수 있는 가장 큰 값(randi의 범위).
const DICE_SEED_MAX := 4294967295

## 기본 경제 규칙. 업그레이드가 적용된 것은 effective_rules()다.
var rules: EconomyRules
## 오늘의 손님. 일정이 있으면 하루를 시작할 때마다 일정에서 가져온 것이다.
var data: DayData
## 가게에 나오는 업그레이드의 목록. null이면 살 것이 없다.
var catalog: UpgradeCatalog
## 날의 순서. null이면 날마다 처음 받은 DayData다.
var schedule: DaySchedule
## 처음 받은 DayData. 일정이 그날의 하루를 주지 못할 때 쓴다.
var _fallback_data: DayData
## 평판의 규칙. null이거나 enabled가 거짓이면 평판이 없다.
var reputation_rules: ReputationRules

# --- 날을 넘는 것 (저장에 드는 것. saved_state / restore) ---
var day_number := 1
var money := 0
## 가진 업그레이드의 id. 효과를 낼 때 목록에서 찾는다.
var owned: Array[StringName] = []
## 평판. 맡은 의뢰의 정산 때 움직인다. 평판이 없으면 0에서 움직이지 않는다.
var reputation := 0
## 흥정 주사위의 씨앗. 새로 시작할 때 한 번 뽑고 저장에 든다.
## 같은 가게의 같은 날 같은 순번의 손님은 같은 주사위다(haggle_roll).
var dice_seed := 0

# --- 하루의 것 ---
var phase: int = Phase.COUNTER
## 지금 의뢰의 순번(0부터).
var index := 0
## 오늘 끝낸 결투의 정산 결과. settle()이 돌려준 Dictionary 그대로다(숫자와 글만 담는다).
var results: Array[Dictionary] = []
## 오늘 돌려보낸 손님의 이름. 돌려보낸 순서다.
var declined: Array[String] = []
## 방금 돌려보낸 손님. {"client_name", "line"}. 손님을 맡거나 날이 바뀌면 비운다.
var last_declined: Dictionary = {}
var _summary: Dictionary = {}
## 오늘 오는 손님 수. 하루를 시작할 때 그때의 평판으로 정하고 그날 안에는 바뀌지 않는다.
var _guest_count := 0
## 오늘을 시작할 때의 평판.
var day_start_reputation := 0
## 흥정의 결과와, 그 흥정을 한 손님의 순번. 순번이 지금 손님과 다르면 흥정은 없는 것이다(haggle_state).
var _haggle: int = Haggle.NONE
var _haggle_index := -1
## 흥정 주사위의 씨앗을 뽑는다(새로 시작할 때 한 번).
var _rng := RandomNumberGenerator.new()


## 일정(p_schedule)이 있으면 p_data는 대체값이다: 일정이 그날의 하루를 주지 못할 때만 쓴다.
func _init(p_rules: EconomyRules, p_data: DayData, p_catalog: UpgradeCatalog = null,
		p_schedule: DaySchedule = null, p_reputation: ReputationRules = null) -> void:
	_rng.randomize()
	dice_seed = _rng.randi()
	rules = p_rules
	data = p_data
	_fallback_data = p_data
	catalog = p_catalog
	schedule = p_schedule
	reputation_rules = p_reputation
	money = rules.starting_money
	# 첫날의 손님 수가 평판에 달렸으므로 하루를 시작하기 전에 정한다.
	reputation = reputation_rules.clamp_value(reputation_rules.start) if has_reputation() else 0
	_begin_day()


# ---------------------------------------------------------------- 순수 함수

## a x b / d를 0.5 올림으로 반올림한다. 정수 연산만 쓴다(부동소수를 지나지 않는다).
static func round_div(a: int, b: int, d: int) -> int:
	@warning_ignore("integer_division")
	return (a * b * 2 + d) / (2 * d)


## 전액 기준치(1~100으로 자른 값). 100이면 기준치가 없는 것이다.
static func full_pay_score(p_rules: EconomyRules) -> int:
	return clampi(p_rules.full_pay_score, 1, 100)


## 보수에 쓰는 충족도: 충족도를 전액 기준치에 견준 비율(0~100). 기준치 이상이면 100이다.
## 기준치가 100이면 충족도 그대로다.
static func pay_score(score: int, p_rules: EconomyRules) -> int:
	return mini(100, round_div(clampi(score, 0, 100), 100, full_pay_score(p_rules)))


## 충족도로 받는 돈. {"base": 기본 보수, "tip": 팁}
## 기본 보수는 보수에 쓰는 충족도에 비례하고, 팁은 그것이 tip_floor를 넘는 만큼에 비례한다.
## full_pay_covers_tip이 거짓이면 팁만 원래 충족도로 계산한다.
## 팁에는 tip_bonus_percent가 덧붙는다(0이면 덧붙임이 없을 때와 같은 값이다).
## 기본 보수에는 base_bonus_percent가 덧붙는다. 충족도 비례와 한 식에서 곱하고 한 번 반올림한다
## (0이면 덧붙임이 없을 때와 같은 정수다. 100 + 덧붙임은 0 아래로 내려가지 않는다).
static func payout(score: int, base_reward: int, tip_max: int, p_rules: EconomyRules) -> Dictionary:
	var paid := pay_score(score, p_rules)
	var base := round_div(base_reward * maxi(100 + p_rules.base_bonus_percent, 0), paid, 10000)
	var tip := 0
	var tip_score := paid if p_rules.full_pay_covers_tip else clampi(score, 0, 100)
	var tip_floor := clampi(p_rules.tip_floor, 0, 100)
	if tip_score > tip_floor:
		tip = round_div(tip_max * (100 + p_rules.tip_bonus_percent), tip_score - tip_floor, 100 * (100 - tip_floor))
	return {"base": base, "tip": tip}


## 덧붙임이 든 팁의 최대.
static func boosted_tip_max(tip_max: int, p_rules: EconomyRules) -> int:
	return round_div(tip_max, 100 + p_rules.tip_bonus_percent, 100)


## 덧붙임이 든 기본 보수의 최대. 충족도 100에서 payout이 주는 기본 보수와 같은 값이다.
static func boosted_base_max(base_reward: int, p_rules: EconomyRules) -> int:
	return round_div(base_reward, maxi(100 + p_rules.base_bonus_percent, 0), 100)


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
		"base_max": boosted_base_max(commission.base_reward, p_rules),
		"tip": int(pay["tip"]),
		"tip_max": boosted_tip_max(commission.tip_max, p_rules),
		"total": int(pay["base"]) + int(pay["tip"]),
		# 전액 기준치와, 충족도가 그 이상이었는가(정산 화면이 읽는다).
		"full_pay_score": full_pay_score(p_rules),
		"full_pay": score >= full_pay_score(p_rules),
		"injured": injured,
		"medical_fee": p_rules.medical_fee if injured else 0,
		"lines": commission.explain(record),
		"elapsed": record.elapsed,
		"success_line": commission.success_line,
		"fail_line": commission.fail_line,
		"partial_line": commission.partial_line,
	}


## 이긴 결투인가: 내가 상대에게 넣은 유효타가 하나 이상 있고, 유효타를 맞고 지지 않았다.
## 기록의 ATTACK은 내 공격이다(상대의 공격은 STRIKE).
static func is_win(record: DuelRecord) -> bool:
	if record == null or record.end_reason == DuelTypes.EndReason.PLAYER_DEFEATED:
		return false
	return record.count_where(DuelRecord.ATTACK, "result", DuelTypes.AttackResult.HIT) > 0


# ---------------------------------------------------------------- 읽기

## 오늘 오는 의뢰의 수. 하루를 시작할 때 정해진다(기준 손님 수가 있는 날은 평판의 별에 따라 다르다).
func commission_count() -> int:
	return _guest_count


## 평판이 있는가: 규칙이 있고 켜져 있다.
func has_reputation() -> bool:
	return reputation_rules != null and reputation_rules.enabled


## 지금 평판의 별 수. 평판이 없으면 0.
func reputation_stars() -> int:
	return reputation_rules.stars(reputation) if has_reputation() else 0


## 오늘의 기본 보수 덧붙임(%). 오늘을 시작할 때의 평판의 별로 정하고 그날 안에는 바뀌지 않는다. 평판이 없으면 0.
func reputation_pay_percent() -> int:
	if not has_reputation():
		return 0
	return reputation_rules.pay_change(reputation_rules.stars(day_start_reputation))


## 내일의 하루. 일정이 주는 날이고, 없으면 처음 받은 DayData다.
func tomorrow_data() -> DayData:
	var next: DayData = null
	if schedule != null:
		next = schedule.day_for(day_number + 1)
	return next if next != null else _fallback_data


## 내일 오는 손님 수. 지금의 평판과 지금 가진 업그레이드가 적용된 결투 수로 계산한다.
func tomorrow_guests() -> int:
	return _guests_for(tomorrow_data())


## 내일의 기준 손님 수. 0이면 평판과 상관없이 목록 전부가 오는 날이다.
func tomorrow_base_guests() -> int:
	var next := tomorrow_data()
	return next.base_guests if next != null else 0


## 그 하루에 지금의 평판으로 오는 손님 수.
func _guests_for(day_data: DayData) -> int:
	if day_data == null:
		return 0
	var delta := reputation_rules.guest_change(reputation_rules.stars(reputation)) if has_reputation() else 0
	return ReputationRules.guest_count(day_data.commissions.size(), day_data.base_guests, delta,
		effective_rules().duels_per_day)


## 지금 의뢰. 폐점이거나 의뢰가 없으면 null.
func current_commission() -> Commission:
	if phase == Phase.CLOSING or index < 0 or index >= commission_count():
		return null
	return data.commissions[index]


## 오늘 남은 결투 수.
func duels_left() -> int:
	return maxi(effective_rules().duels_per_day - results.size(), 0)


## 문밖에 기다리는 손님의 수(지금 손님 뒤에 오는 손님).
func waiting_count() -> int:
	return maxi(commission_count() - index - 1, 0)


## 다음 손님을 만나게 되는가: 기다리는 손님이 있고 남은 결투 수가 있다.
func has_next_commission() -> bool:
	return waiting_count() > 0 and duels_left() > 0


## 가장 최근의 정산 결과. 없으면 빈 Dictionary.
func last_result() -> Dictionary:
	return results[results.size() - 1] if not results.is_empty() else {}


## 폐점 요약. 폐점 단계에서만 채워져 있다.
## income, rent, injuries, medical, expenses, profit, money_before, money_after,
## duels(오늘의 결투 수), declined(돌려보낸 손님의 이름들), missed(만나지 못한 손님 수)
func closing_summary() -> Dictionary:
	return _summary


## 그 업그레이드를 가졌는가.
func owns(upgrade: UpgradeData) -> bool:
	return upgrade != null and owned.has(upgrade.id)


## 지금 살 수 있는가: 폐점이고, 목록에 있고, 아직 없고, 소지금이 값 이상이다.
func can_buy(upgrade: UpgradeData) -> bool:
	if phase != Phase.CLOSING or upgrade == null or catalog == null:
		return false
	if not catalog.upgrades.has(upgrade) or owns(upgrade):
		return false
	return money >= upgrade.price


## 지금 살 수 있는 것이 하나라도 있는가.
func has_buyable() -> bool:
	if catalog == null:
		return false
	for upgrade in catalog.upgrades:
		if can_buy(upgrade):
			return true
	return false


## 가진 업그레이드. 목록의 순서다.
func owned_upgrades() -> Array[UpgradeData]:
	var out: Array[UpgradeData] = []
	if catalog == null:
		return out
	for upgrade in catalog.upgrades:
		if owns(upgrade):
			out.append(upgrade)
	return out


## 가진 업그레이드가 적용된 경제 규칙. 기본 규칙(rules)의 사본이고, 기본 규칙은 고치지 않는다.
func effective_rules() -> EconomyRules:
	return UpgradeData.applied(rules, UpgradeData.Target.ECONOMY, owned_upgrades()) as EconomyRules


## 정산에 쓰는 경제 규칙: 가진 업그레이드에 오늘의 평판(별)의 기본 보수 덧붙임을 더한 것. 사본이다.
## 정산과 카운터가 같은 것을 쓴다. 평판이 없거나 덧붙임이 0이면 effective_rules()와 같은 값이다.
## 팁은 별과 상관없다. 지금 손님이 흥정을 받아 줬으면 기본 보수에 흥정의 덧붙임을 더하고 전액 기준치를
## 흥정의 값으로 바꾼다. 거절당한 손님이면 팁의 덧붙임에서 감점을 뺀다(−100 아래로는 내려가지 않는다).
func settle_rules() -> EconomyRules:
	return _rules_with_haggle(haggle_state())


## 지금 손님이 흥정을 받아 줬다고 쳤을 때의 경제 규칙. 사본이고 읽기만 한다(상태를 바꾸지 않는다).
## 카운터가 흥정 전의 보수 줄("받아 주면 기본 보수 N")에 쓴다. 이미 받아 준 뒤면 settle_rules()와 같은 값이다.
func haggle_preview_rules() -> EconomyRules:
	return _rules_with_haggle(Haggle.AGREED)


## 지금 손님이 흥정을 거절했다고 쳤을 때의 경제 규칙. 사본이고 읽기만 한다(상태를 바꾸지 않는다).
## 카운터가 흥정 전의 "거절당하면 팁 최대 N"에 쓴다.
func haggle_refused_rules() -> EconomyRules:
	return _rules_with_haggle(Haggle.REFUSED)


## 흥정의 상태(Haggle)가 그렇다고 쳤을 때 지금 손님의 판에 쓰는 경제 규칙. 사본이고 상태를 바꾸지 않는다.
func _rules_with_haggle(p_haggle: int) -> EconomyRules:
	var economy := effective_rules()
	economy.base_bonus_percent += reputation_pay_percent()
	if p_haggle == Haggle.AGREED:
		economy.base_bonus_percent += economy.haggle_bonus_percent
		economy.full_pay_score = economy.haggle_full_pay_score
	elif p_haggle == Haggle.REFUSED and economy.haggle_refuse_tip_cut_percent > 0:
		economy.tip_bonus_percent = maxi(economy.tip_bonus_percent - economy.haggle_refuse_tip_cut_percent, -100)
	return economy


## 지금 손님과의 흥정의 결과(Haggle). 흥정한 손님의 순번이 지금 손님과 다르면 NONE이다.
func haggle_state() -> int:
	return _haggle if _haggle_index == index else Haggle.NONE


## 지금 값을 올려 부를 수 있는가: 카운터이고, 흥정이 켜져 있고(덧붙임이 0보다 큼),
## 흥정할 수 있는 손님이고(haggle_min_stars가 0보다 큼), 이 손님에게 아직 흥정하지 않았다.
func can_haggle() -> bool:
	var commission := current_commission()
	if phase != Phase.COUNTER or commission == null:
		return false
	if effective_rules().haggle_bonus_percent <= 0 or commission.haggle_min_stars <= 0:
		return false
	return haggle_state() == Haggle.NONE


## 지금 흥정하면 받아 줄 확률(%, 0~100). 흥정할 수 없는 손님이면 0, 평판이 없으면 100이다.
## 평판이 있으면 지금 평판의 별과 손님의 값의 차로 경제 규칙의 표에서 읽는다.
## 화면은 이 값을 보여 주지 않는다(사용자 결정 2026-11-20). 판정(haggle)과 테스트가 쓴다.
func haggle_chance() -> int:
	var commission := current_commission()
	if commission == null or commission.haggle_min_stars <= 0:
		return 0
	if not has_reputation():
		return 100
	return effective_rules().haggle_chance_for(reputation_stars() - commission.haggle_min_stars)


## 지금 손님의 흥정 주사위(0~99). 씨앗·날 번호·손님의 순번이 같으면 늘 같은 값이다
## (하루를 다시 해도 다시 뽑히지 않는다). 상태를 바꾸지 않는다.
func haggle_roll() -> int:
	var dice := RandomNumberGenerator.new()
	dice.seed = dice_seed * 1000003 + day_number * 1009 + index
	return dice.randi_range(0, 99)


## 기본 결투 규칙을 받아, 가진 업그레이드가 적용된 사본을 돌려준다.
func effective_duel_rules(base: DuelRules) -> DuelRules:
	return UpgradeData.applied(base, UpgradeData.Target.DUEL, owned_upgrades()) as DuelRules


# ---------------------------------------------------------------- 저장

static func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


## 읽을 수 있는 저장인가: 버전이 같고 날과 소지금이 숫자다.
static func is_readable_save(saved: Dictionary) -> bool:
	var version: Variant = saved.get("version")
	if not _is_number(version) or int(version) != SAVE_VERSION:
		return false
	return _is_number(saved.get("day")) and _is_number(saved.get("money"))


## 저장할 것: 다음에 열 날의 아침. 폐점이면 내일이고, 아직 아무도 맡거나 돌려보내지 않은 아침이면 오늘이다.
## 하루 중(그 뒤부터 폐점 전까지)에는 빈 Dictionary다(적을 아침이 없다). 상태를 바꾸지 않는다.
func saved_state() -> Dictionary:
	var day_to_open := 0
	if phase == Phase.CLOSING:
		day_to_open = day_number + 1
	elif phase == Phase.COUNTER and index == 0 and results.is_empty() and declined.is_empty():
		day_to_open = day_number
	if day_to_open <= 0:
		return {}
	var ids: Array[String] = []
	for owned_id in owned:
		ids.append(String(owned_id))
	return {"version": SAVE_VERSION, "day": day_to_open, "money": money, "owned": ids,
		"reputation": reputation, "dice_seed": dice_seed}


## 저장된 아침으로 되돌리고 그날을 시작한다. 읽을 수 없는 저장이면 아무것도 바꾸지 않고 false다.
## 값은 믿지 않는다: 날은 1 이상, 가진 것은 목록에 있는 것만, 평판은 범위로 자른다.
func restore(saved: Dictionary) -> bool:
	if not is_readable_save(saved):
		return false
	day_number = maxi(int(saved["day"]), 1)
	money = int(saved["money"])
	owned = _known_ids(saved.get("owned"))
	var saved_reputation: Variant = saved.get("reputation")
	if has_reputation() and _is_number(saved_reputation):
		reputation = reputation_rules.clamp_value(int(saved_reputation))
	var saved_seed: Variant = saved.get("dice_seed")
	if _is_number(saved_seed):
		dice_seed = clampi(int(saved_seed), 0, DICE_SEED_MAX)
	_begin_day()
	return true


## 저장된 id 가운데 목록에 있는 것. 목록의 순서이고 겹치지 않는다.
func _known_ids(value: Variant) -> Array[StringName]:
	var kept: Array[StringName] = []
	if catalog == null or not (value is Array):
		return kept
	var wanted: Array = value
	for upgrade in catalog.upgrades:
		if upgrade != null and wanted.has(String(upgrade.id)) and not kept.has(upgrade.id):
			kept.append(upgrade.id)
	return kept


# ---------------------------------------------------------------- 전환

## 카운터에서 의뢰를 맡는다 → 결투.
func accept() -> bool:
	if phase != Phase.COUNTER or current_commission() == null:
		return false
	last_declined = {}
	phase = Phase.DUEL
	return true


## 카운터에서 손님을 돌려보낸다 → 기다리는 손님이 있으면 다음 손님, 없으면 폐점.
## 돌려보낸 손님은 그날 다시 오지 않는다.
func decline() -> bool:
	var commission := current_commission()
	if phase != Phase.COUNTER or commission == null:
		return false
	declined.append(commission.client_name)
	last_declined = {"client_name": commission.client_name, "line": commission.decline_line}
	if waiting_count() > 0:
		index += 1
	else:
		_enter_closing()
	return true


## 카운터에서 값을 올려 부른다. 손님이 받아 주거나 거절한다(확률에 따른 무작위). 한 손님에게 한 번뿐이고
## 되돌릴 수 없다. 올려 부를 수 없으면 아무것도 바꾸지 않고 false를 돌려준다. 그 뒤에도 맡거나 돌려보낼 수 있다.
## roll은 0~99의 주사위다. 음수면 지금 손님의 정해진 주사위(haggle_roll)를 쓴다. 확률(haggle_chance)보다 작으면
## 받아 준다. 테스트는 roll로 결과를 고정한다.
func haggle(roll := -1) -> bool:
	if not can_haggle():
		return false
	if roll < 0:
		roll = haggle_roll()
	_haggle = Haggle.AGREED if roll < haggle_chance() else Haggle.REFUSED
	_haggle_index = index
	return true


## 결투가 끝났다. 기록을 정산해 결과 목록에 넣고 수입을 소지금에 더한다 → 정산.
func finish_duel(record: DuelRecord) -> bool:
	if phase != Phase.DUEL or record == null:
		return false
	var commission := current_commission()
	# 오늘의 평판(별)이 기본 보수의 비율을 바꾼다. 그날을 시작할 때의 별로 정해져 있다.
	var economy := settle_rules()
	var result := settle(commission, record, economy)
	var won := is_win(record)
	result["won"] = won
	result["reputation_pay_percent"] = reputation_pay_percent()
	# 흥정을 받아 준 판이면 그 덧붙임(%)을 싣는다. 아니면 0이다.
	result["haggle_percent"] = economy.haggle_bonus_percent if haggle_state() == Haggle.AGREED else 0
	# 흥정을 거절당한 판이면 팁의 감점(%)을 싣는다. 아니면 0이다.
	result["haggle_tip_cut_percent"] = economy.haggle_refuse_tip_cut_percent if haggle_state() == Haggle.REFUSED else 0
	if has_reputation():
		# 평판은 맡은 의뢰의 정산 때 한 번 움직인다. 이 판의 돈은 이 평판과 상관없다(기본 보수의 비율은 오늘을 시작할 때의 별이다).
		var items := reputation_rules.settle_items(commission.reputation_effect, int(result["score"]), economy.tip_floor,
			won, reputation_rules.scale_for_day(day_number))
		result["reputation_before"] = reputation
		reputation = reputation_rules.clamp_value(reputation + ReputationRules.items_total(items))
		result["reputation_after"] = reputation
		result["reputation_items"] = items
	results.append(result)
	money += int(result["total"])
	phase = Phase.SETTLEMENT
	return true


## 정산을 본 뒤 다음으로: 다음 손님을 만나게 되면 그 손님, 아니면 폐점.
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


## 폐점에서 업그레이드를 산다. 소지금에서 값을 빼고 가진 것에 더한다. 효과는 다음 날부터 난다.
func buy(upgrade: UpgradeData) -> bool:
	if not can_buy(upgrade):
		return false
	money -= upgrade.price
	owned.append(upgrade.id)
	return true


## 폐점 뒤 다음 날을 연다. 소지금과 가진 업그레이드는 이어진다.
func next_day() -> bool:
	if phase != Phase.CLOSING:
		return false
	day_number += 1
	_begin_day()
	return true


func _begin_day() -> void:
	if schedule != null:
		var scheduled := schedule.day_for(day_number)
		data = scheduled if scheduled != null else _fallback_data
	index = 0
	results = []
	declined = []
	last_declined = {}
	_summary = {}
	_haggle = Haggle.NONE
	_haggle_index = -1
	day_start_reputation = reputation
	_guest_count = _guests_for(data)
	# 손님이 없거나 맡을 수 있는 결투가 없으면 곧바로 폐점이다.
	if commission_count() == 0 or duels_left() <= 0:
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
	var rent := effective_rules().rent
	var expenses := rent + medical
	var before := money
	money -= expenses
	_summary = {
		"income": income,
		"rent": rent,
		"injuries": injuries,
		"medical": medical,
		"expenses": expenses,
		"profit": income - expenses,
		"money_before": before,
		"money_after": money,
		"duels": results.size(),
		"declined": declined.duplicate(),
		"missed": maxi(commission_count() - results.size() - declined.size(), 0),
	}
	if has_reputation():
		_summary["reputation_start"] = day_start_reputation
		_summary["reputation"] = reputation
	phase = Phase.CLOSING
