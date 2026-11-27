extends RefCounted
## T52~T54: 평판과 대가 — 평판의 규칙, 하루 상태의 평판과 손님 수, 화면.
## 하루의 도우미(고정 점수 의뢰, 손으로 만든 기록, 화면 붙이기)는 day_tests.gd의 것을 쓴다.
## 통과 조건은 테스트가 직접 만든 평판 규칙·경제 규칙·고정 점수 의뢰·하루 데이터로 본다.
## 로드한 .tres는 구조만 통과 조건이고, 값으로 잰 것은 INFO 줄이다.

const Day := preload("res://tests/day_tests.gd")
const DT := preload("res://scripts/duel/duel_types.gd")
const Session := preload("res://scripts/game_session.gd")
const Ui := preload("res://scripts/day_ui.gd")

const RULES_PATH := "res://data/reputation_rules.tres"
const ECONOMY_PATH := "res://data/economy_rules.tres"
const SCHEDULE_PATH := "res://data/day_schedule.tres"
const COMMISSION_PATHS: Array[String] = [
	"res://data/commissions/first_blood.tres",
	"res://data/commissions/feather_cut.tres",
	"res://data/commissions/throw_match.tres",
	"res://data/commissions/variants/legs_only.tres",
	"res://data/commissions/variants/first_blood_poor.tres",
	"res://data/commissions/variants/first_blood_usurer.tres",
	"res://data/commissions/variants/throw_bet.tres",
	"res://data/commissions/spar.tres",
	"res://data/commissions/variants/court_beehive.tres",
	"res://data/commissions/variants/noble_baker.tres",
	"res://data/commissions/variants/pair_hatter.tres",
	"res://data/commissions/variants/pair_baker.tres",
	"res://data/commissions/variants/after_hatter.tres",
	"res://data/commissions/variants/after_baker.tres",
	"res://data/commissions/variants/close_baker.tres",
	"res://data/commissions/variants/rival_milliner.tres",
	"res://data/commissions/variants/dun_master.tres",
]

## 테스트가 적는 팁 문턱.
const TIP_FLOOR := 70

var _tree: SceneTree
var _d := Day.new()


func list(tree: SceneTree) -> Array:
	_tree = tree
	_d.set("_tree", tree)
	return [
		{"id": "T52", "name": "평판의 규칙: 별, 정산의 항목, 손님 수", "fn": t52_rules},
		{"id": "T53", "name": "하루 상태의 평판: 9 → 10 → 12 → 16 → 13, 손님 3 → 5 → 3 → 7", "fn": t53_day_state},
		{"id": "T54", "name": "평판의 화면: 카운터의 평판·소문·손님 줄, 정산의 평판 줄, 폐점의 두 줄", "fn": t54_screens},
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


## 테스트가 직접 만든 평판 규칙("규칙"의 값 그대로).
func _rep_rules(start := 9) -> ReputationRules:
	var rules := ReputationRules.new()
	rules.enabled = true
	rules.start = start
	rules.min_value = 0
	rules.max_value = 20
	rules.star_thresholds = PackedInt32Array([4, 8, 12, 16])
	rules.guest_delta = PackedInt32Array([-2, -1, 0, 1, 2])
	rules.perfect_bonus = 1
	return rules


func _effect(accept: int, success: int, fail: int) -> Dictionary:
	return {"accept": accept, "success": success, "fail": fail}


## 고정 점수와 평판의 값을 가진 테스트용 의뢰.
func _commission(client: String, score: int, effect: Dictionary) -> Commission:
	var commission: Commission = _d._fixed_commission(client, 30, 15, score)
	commission.reputation_effect = effect
	return commission


func _honest() -> Commission:
	return _commission("정직", 100, _effect(0, 1, -1))


func _poor() -> Commission:
	return _commission("가난", 90, _effect(1, 1, -1))


func _dirty() -> Commission:
	return _commission("궂은일", 100, _effect(-3, 0, -2))


func _failed() -> Commission:
	return _commission("실패", 0, _effect(0, 1, -1))


func _halfway() -> Commission:
	return _commission("어중간", 60, _effect(1, 1, -1))


func _caught() -> Commission:
	return _commission("들킨 궂은일", 0, _effect(-3, 0, -2))


func _bonus() -> Commission:
	return _commission("덤", 100, _effect(0, 1, -1))


func _day_data(commissions: Array[Commission], base_guests := 0) -> DayData:
	var data := DayData.new()
	data.commissions = commissions
	data.base_guests = base_guests
	return data


## 하루 X(기준 0): 정직, 가난, 궂은일.
func _day_x() -> DayData:
	var commissions: Array[Commission] = [_honest(), _poor(), _dirty()]
	return _day_data(commissions)


## 하루 Y(기준 5): 정직, 가난, 궂은일, 실패, 어중간 + 덤 자리(들킨 궂은일, 덤).
func _day_y() -> DayData:
	var commissions: Array[Commission] = [_honest(), _poor(), _dirty(), _failed(), _halfway(), _caught(), _bonus()]
	return _day_data(commissions, 5)


func _schedule(days: Array[DayData]) -> DaySchedule:
	var schedule := DaySchedule.new()
	schedule.days = days
	return schedule


## 일정 [X, Y]의 하루 상태. rep가 null이면 평판 규칙 없이 만든다.
func _xy_day(rep: ReputationRules, duels := 3) -> DayState:
	var days: Array[DayData] = [_day_x(), _day_y()]
	return DayState.new(_d._duel_rules(duels), null, null, _schedule(days), rep)


## 지금 손님을 맡아 끝내고(정산까지) 평판을 돌려준다.
func _take(day: DayState) -> int:
	day.accept()
	day.finish_duel(_d._record(DT.EndReason.CONDITION))
	return day.reputation


## 하루의 순서를 따라간다. 글자마다: "A" 맡아 끝내고 다음으로, "D" 돌려보낸다.
## 걸음마다 [단계, 소지금, 마지막 결과의 합]을 trace에 적는다.
func _play_day(day: DayState, steps: String, trace: Array) -> void:
	for step in steps:
		if step == "A":
			day.accept()
			day.finish_duel(_d._record(DT.EndReason.CONDITION))
			trace.append([day.phase, day.money, day.last_result().get("total", -1)])
			day.proceed()
		else:
			day.decline()
		trace.append([day.phase, day.money, day.last_result().get("total", -1)])


func _total(rules: ReputationRules, effect: Dictionary, score: int, tip_floor := TIP_FLOOR) -> int:
	return ReputationRules.items_total(rules.settle_items(effect, score, tip_floor))


func _count(rules: ReputationRules, effect: Dictionary, score: int) -> int:
	return rules.settle_items(effect, score, TIP_FLOOR).size()


# ================================================================ T52 평판의 규칙

func t52_rules() -> String:
	var errs: Array[String] = []
	var rules := _rep_rules()

	# ---- 별: 문턱 [4, 8, 12, 16]
	for row in [[0, 1], [3, 1], [4, 2], [7, 2], [8, 3], [9, 3], [11, 3], [12, 4], [15, 4], [16, 5], [20, 5]]:
		_expect(errs, rules.stars(row[0]) == row[1], "[별] 평판 %d → 별 %d (기대 %d)" % [row[0], rules.stars(row[0]), row[1]])
	_expect(errs, rules.max_stars() == 5, "[별] 별의 최대 %d (기대 5)" % rules.max_stars())
	_expect(errs, rules.to_next_star(9) == 3 and rules.to_next_star(16) == 0 and rules.to_next_star(0) == 4,
		"[별] 다음 별까지: 9 → %d, 16 → %d (기대 3, 0)" % [rules.to_next_star(9), rules.to_next_star(16)])
	_expect(errs, rules.clamp_value(-3) == 0 and rules.clamp_value(25) == 20 and rules.clamp_value(9) == 9, "[별] 범위로 자르지 않음")

	# ---- 정산의 항목: [효과, 충족도, 기대 합, 기대 항목 수]
	var plain := _effect(0, 1, -1)
	var kind := _effect(1, 1, -1)
	var dirty := _effect(-3, 0, -2)
	var table := [
		[plain, 100, 2, 2], [plain, 99, 1, 1], [plain, 71, 1, 1], [plain, 70, 0, 0], [plain, 1, 0, 0], [plain, 0, -1, 1],
		[kind, 100, 3, 3], [kind, 90, 2, 2], [kind, 60, 1, 1], [kind, 0, 0, 2],
		[dirty, 100, -3, 1], [dirty, 60, -3, 1], [dirty, 0, -5, 2],
	]
	for row in table:
		_expect(errs, _total(rules, row[0], row[1]) == row[2] and _count(rules, row[0], row[1]) == row[3],
			"[항목] 효과 %s, 충족도 %d → 합 %d, 항목 %d개 (기대 %d, %d개)" % [
				str(row[0]), row[1], _total(rules, row[0], row[1]), _count(rules, row[0], row[1]), row[2], row[3]])
	# 궂은일은 100점이어도 "흠 없이"가 붙지 않는다.
	var dirty_names: Array = []
	for item: Array in rules.settle_items(dirty, 100, TIP_FLOOR):
		dirty_names.append(item[0])
	_expect(errs, dirty_names == [ReputationRules.ITEM_ACCEPT_BAD], "[항목] 궂은일 100점의 항목 %s (기대 '궂은일을 맡았다'뿐)" % str(dirty_names))
	# 빈 Dictionary, 키가 빠진 Dictionary, 실수 값, 덤 0, 다른 팁 문턱
	_expect(errs, _total(rules, {}, 100) == 0 and _total(rules, {}, 0) == 0, "[항목] 빈 효과의 합이 0이 아님")
	_expect(errs, _total(rules, {"success": 1}, 100) == 2 and _total(rules, {"success": 1}, 0) == 0, "[항목] 키가 빠진 효과를 0으로 읽지 않음")
	_expect(errs, _total(rules, {"accept": 1.0, "success": 0.0, "fail": 0.0}, 50) == 1, "[항목] 실수 값(1.0)을 +1로 읽지 않음")
	var no_bonus := _rep_rules()
	no_bonus.perfect_bonus = 0
	_expect(errs, _total(no_bonus, plain, 100) == 1, "[항목] 덤이 0인 규칙에서 100점이 +1이 아님")
	_expect(errs, _total(rules, plain, 60, 50) == 1 and _total(rules, plain, 50, 50) == 0, "[항목] 팁 문턱 50에서 60점이 '해냈다'가 아님")

	# ---- 손님 수: [목록 길이, 기준, 결투 수, 별 1~5의 기대]
	var guests := [
		[7, 5, 3, [3, 4, 5, 6, 7]],
		[6, 5, 3, [3, 4, 5, 6, 6]],
		[5, 5, 3, [3, 4, 5, 5, 5]],
		[7, 5, 4, [4, 4, 5, 6, 7]],
		# 아래 한계는 기준과 결투 수 가운데 작은 쪽이다.
		[7, 2, 3, [2, 2, 2, 3, 4]],
		# 목록이 결투 수보다 짧으면 목록 길이가 이긴다.
		[2, 5, 3, [2, 2, 2, 2, 2]],
		# 기준을 목록 길이로 먼저 자르지 않는다.
		[7, 9, 3, [7, 7, 7, 7, 7]],
		# 기준 0이면 목록 전부가 온다.
		[7, 0, 3, [7, 7, 7, 7, 7]],
	]
	for row in guests:
		var got: Array[int] = []
		for star in range(1, 6):
			got.append(ReputationRules.guest_count(row[0], row[1], rules.guest_change(star), row[2]))
		_expect(errs, got == row[3], "[손님 수] 목록 %d, 기준 %d, 결투 %d → %s (기대 %s)" % [row[0], row[1], row[2], str(got), str(row[3])])
	var flat := _rep_rules()
	flat.guest_delta = PackedInt32Array()
	for star in range(1, 6):
		_expect(errs, ReputationRules.guest_count(7, 5, flat.guest_change(star), 3) == 5, "[손님 수] 증감이 빈 규칙인데 별 %d의 손님이 5가 아님" % star)
	_expect(errs, ReputationRules.guest_count(7, 5, 0, -2) == 5 and ReputationRules.guest_count(0, 5, 2, 3) == 0, "[손님 수] 음수인 결투 수나 빈 목록을 다루지 못함")

	# ---- 로드한 값: 구조만 통과 조건이다
	var loaded := load(RULES_PATH) as ReputationRules
	if loaded == null:
		errs.append("%s 가 ReputationRules로 로드되지 않음" % RULES_PATH)
		return _result(errs)
	var ascending := true
	for i in range(1, loaded.star_thresholds.size()):
		if loaded.star_thresholds[i] <= loaded.star_thresholds[i - 1]:
			ascending = false
	_expect(errs, ascending, "로드한 별의 문턱이 오름차순이 아님: %s" % str(loaded.star_thresholds))
	_expect(errs, loaded.min_value <= loaded.start and loaded.start <= loaded.max_value, "로드한 시작 평판 %d가 범위 %d~%d 밖" % [loaded.start, loaded.min_value, loaded.max_value])
	print("  INFO 로드한 평판 규칙: 켜짐 %s, 시작 %d (별 %d), 범위 %d~%d, 별의 문턱 %s, 손님 증감 %s, 흠 없이 +%d" % [
		str(loaded.enabled), loaded.start, loaded.stars(loaded.start), loaded.min_value, loaded.max_value,
		str(loaded.star_thresholds), str(loaded.guest_delta), loaded.perfect_bonus])

	var schedule := load(SCHEDULE_PATH) as DaySchedule
	var economy := load(ECONOMY_PATH) as EconomyRules
	if schedule == null or economy == null:
		errs.append("일정이나 경제 규칙이 로드되지 않음")
		return _result(errs)
	for i in schedule.days.size():
		var day_data := schedule.days[i]
		if day_data == null:
			continue
		_expect(errs, day_data.base_guests >= 0 and day_data.base_guests <= day_data.commissions.size(),
			"일정의 %d번째 날: 기준 손님 수 %d가 0 미만이거나 목록 길이 %d보다 큼" % [i + 1, day_data.base_guests, day_data.commissions.size()])
		var by_star: Array[int] = []
		for star in range(1, loaded.max_stars() + 1):
			by_star.append(ReputationRules.guest_count(day_data.commissions.size(), day_data.base_guests, loaded.guest_change(star), economy.duels_per_day))
		print("  INFO %d일차: 목록 %d, 기준 %d, 별 1~%d의 손님 %s" % [i + 1, day_data.commissions.size(), day_data.base_guests, loaded.max_stars(), str(by_star)])
	for path in COMMISSION_PATHS:
		var commission := load(path) as Commission
		if commission == null:
			errs.append("%s 가 Commission으로 로드되지 않음" % path)
			continue
		var effect := commission.reputation_effect
		var values := [int(effect.get("accept", 0)), int(effect.get("success", 0)), int(effect.get("fail", 0))]
		print("  INFO %s (%d+%d): 맡으면 %+d, 해내면 %+d, 못 해내면 %+d, 흠 없이 해냈을 때의 합 %+d" % [
			commission.client_name, commission.base_reward, commission.tip_max, values[0], values[1], values[2],
			ReputationRules.items_total(loaded.settle_items(effect, 100, economy.tip_floor))])

	# ---- INFO (통과 조건 아님): 나흘의 장부 어림. 결투는 돌리지 않고 점수를 고정해 평판과 수입을 따라간다.
	print("  INFO 나흘의 어림 (날마다: 그날의 손님 수 · 수입 → 정산 뒤 평판과 별)")
	for style in ["정직한 손님 셋을 전부 100점", "보수가 큰 셋을 전부 100점", "보수가 큰 셋을 전부 85점", "앞에서부터 셋을 전부 0점"]:
		print("  INFO %s: %s" % [style, _ledger(style, loaded, economy, schedule)])
	return _result(errs)


## 한 가지 플레이로 나흘을 따라간 어림. 날마다 "손님 n명 · 수입 m → 평판 r(별 s)".
func _ledger(style: String, rules: ReputationRules, economy: EconomyRules, schedule: DaySchedule) -> String:
	var reputation := rules.clamp_value(rules.start)
	var parts: Array[String] = []
	var score := 100
	if style.contains("전부 85점"):
		score = 85
	elif style.contains("전부 0점"):
		score = 0
	for day_number in range(1, 5):
		var day_data := schedule.day_for(day_number)
		var delta := rules.guest_change(rules.stars(reputation)) if rules.enabled else 0
		var count := ReputationRules.guest_count(day_data.commissions.size(), day_data.base_guests, delta, economy.duels_per_day)
		var came: Array[Commission] = []
		for i in count:
			came.append(day_data.commissions[i])
		var taken: Array[Commission] = []
		if style.begins_with("정직"):
			# 앞에서부터 보며 맡는 값이 0 이상인 손님을 맡는다.
			for commission in came:
				if taken.size() < economy.duels_per_day and int(commission.reputation_effect.get("accept", 0)) >= 0:
					taken.append(commission)
		elif style.begins_with("보수"):
			# 기본 보수와 팁 최대의 합이 큰 순서로(같으면 앞의 손님).
			var rest := came.duplicate()
			while taken.size() < economy.duels_per_day and not rest.is_empty():
				var best: Commission = rest[0]
				for commission: Commission in rest:
					if commission.base_reward + commission.tip_max > best.base_reward + best.tip_max:
						best = commission
				taken.append(best)
				rest.erase(best)
		else:
			for commission in came:
				if taken.size() < economy.duels_per_day:
					taken.append(commission)
		var income := 0
		for commission in taken:
			var pay := DayState.payout(score, commission.base_reward, commission.tip_max, economy)
			income += int(pay["base"]) + int(pay["tip"])
			if rules.enabled:
				reputation = rules.clamp_value(reputation + ReputationRules.items_total(
					rules.settle_items(commission.reputation_effect, score, economy.tip_floor)))
		parts.append("%d일차 손님 %d명 · 수입 %d → 평판 %d(별 %d)" % [day_number, count, income, reputation, rules.stars(reputation)])
	return " / ".join(PackedStringArray(parts))


# ================================================================ T53 하루 상태의 평판

func t53_day_state() -> String:
	var errs: Array[String] = []
	var P := DayState.Phase

	# ---- ㄱ. 1일차(X, 손님 3): 9 → 정직 11 → 가난 13 → 궂은일 10
	var day := _xy_day(_rep_rules())
	_expect(errs, day.has_reputation() and day.reputation == 9 and day.reputation_stars() == 3 and day.commission_count() == 3,
		"[ㄱ·1일차] 시작 평판 %d, 별 %d, 손님 %d (기대 9, 3, 3)" % [day.reputation, day.reputation_stars(), day.commission_count()])
	_expect(errs, _take(day) == 11, "[ㄱ·1일차] 정직 뒤 평판 %d (기대 11)" % day.reputation)
	var first := day.last_result()
	_expect(errs, first.get("reputation_before") == 9 and first.get("reputation_after") == 11 and (first.get("reputation_items", []) as Array).size() == 2,
		"[ㄱ·1일차] 정직의 결과에 9 → 11과 항목 둘이 없음: %s" % str(first))
	day.proceed()
	_expect(errs, _take(day) == 13, "[ㄱ·1일차] 가난 뒤 평판 %d (기대 13)" % day.reputation)
	day.proceed()
	_expect(errs, _take(day) == 10, "[ㄱ·1일차] 궂은일 뒤 평판 %d (기대 10)" % day.reputation)
	day.proceed()
	var summary := day.closing_summary()
	_expect(errs, day.phase == P.CLOSING and summary.get("reputation_start") == 9 and summary.get("reputation") == 10,
		"[ㄱ·1일차] 폐점 요약의 평판이 9 → 10이 아님: %s" % str(summary))
	_expect(errs, day.tomorrow_guests() == 5 and day.tomorrow_base_guests() == 5, "[ㄱ·1일차] 내일의 손님 %d (기준 %d) (기대 5, 5)" % [day.tomorrow_guests(), day.tomorrow_base_guests()])

	# 2일차(Y, 손님 5): 정직을 돌려보낸다(그대로 10) → 가난 12 → 궂은일을 돌려보낸다 → 실패 11 → 어중간 12
	day.next_day()
	_expect(errs, day.commission_count() == 5 and day.day_start_reputation == 10, "[ㄱ·2일차] 손님 %d (기대 5)" % day.commission_count())
	day.decline()
	_expect(errs, day.reputation == 10, "[ㄱ·2일차] 돌려보내기가 평판을 움직임 (%d)" % day.reputation)
	_expect(errs, _take(day) == 12, "[ㄱ·2일차] 가난 뒤 평판 %d (기대 12)" % day.reputation)
	day.proceed()
	day.decline()
	_expect(errs, _take(day) == 11, "[ㄱ·2일차] 실패 뒤 평판 %d (기대 11)" % day.reputation)
	day.proceed()
	_expect(errs, _take(day) == 12, "[ㄱ·2일차] 어중간 뒤 평판 %d (기대 12: 맡은 값만)" % day.reputation)
	day.proceed()
	_expect(errs, day.phase == P.CLOSING and day.reputation_stars() == 4 and day.tomorrow_guests() == 3 and day.tomorrow_base_guests() == 0,
		"[ㄱ·2일차] 폐점의 별 %d, 내일의 손님 %d (기대 4, 3)" % [day.reputation_stars(), day.tomorrow_guests()])

	# 3일차(X): 정직 14 → 가난 16 → 궂은일을 돌려보낸다
	day.next_day()
	_expect(errs, _take(day) == 14, "[ㄱ·3일차] 정직 뒤 평판 %d (기대 14)" % day.reputation)
	day.proceed()
	_expect(errs, _take(day) == 16, "[ㄱ·3일차] 가난 뒤 평판 %d (기대 16)" % day.reputation)
	day.proceed()
	day.decline()
	_expect(errs, day.phase == P.CLOSING and day.reputation_stars() == 5 and day.tomorrow_guests() == 7,
		"[ㄱ·3일차] 폐점의 별 %d, 내일의 손님 %d (기대 5, 7)" % [day.reputation_stars(), day.tomorrow_guests()])

	# 4일차(Y, 손님 7): 앞의 다섯을 돌려보내고 들킨 궂은일 → 11. 그날의 손님 수는 여전히 7이고 덤이 온다 → 13
	day.next_day()
	_expect(errs, day.commission_count() == 7 and day.data.commissions[6].client_name == "덤", "[ㄱ·4일차] 손님 %d (기대 7, 일곱째가 덤)" % day.commission_count())
	for i in 5:
		day.decline()
	_expect(errs, day.phase == P.COUNTER and day.current_commission().client_name == "들킨 궂은일", "[ㄱ·4일차] 여섯째 손님이 들킨 궂은일이 아님")
	_expect(errs, _take(day) == 11 and day.reputation_stars() == 3, "[ㄱ·4일차] 들킨 궂은일 뒤 평판 %d (기대 11)" % day.reputation)
	_expect(errs, day.commission_count() == 7 and day.has_next_commission(), "[ㄱ·4일차] 평판이 내려가자 그날의 손님 수가 바뀜 (%d)" % day.commission_count())
	day.proceed()
	_expect(errs, day.phase == P.COUNTER and day.current_commission().client_name == "덤", "[ㄱ·4일차] 다음 손님이 덤이 아님")
	_expect(errs, _take(day) == 13, "[ㄱ·4일차] 덤 뒤 평판 %d (기대 13)" % day.reputation)
	day.proceed()
	summary = day.closing_summary()
	_expect(errs, day.phase == P.CLOSING and summary.get("duels") == 2 and (summary.get("declined") as Array).size() == 5 and summary.get("missed") == 0,
		"[ㄱ·4일차] 폐점 요약이 결투 2, 돌려보낸 손님 5, 만나지 못한 손님 0이 아님: %s" % str(summary))

	# ---- ㄴ. 낮은 쪽: [실패, 실패, 들킨 궂은일] → 9 → 8 → 7 → 2, 별 1, 내일의 손님 3
	for duels: int in [3, 4]:
		var bad_commissions: Array[Commission] = [_failed(), _failed(), _caught()]
		var days: Array[DayData] = [_day_data(bad_commissions), _day_y()]
		var low := DayState.new(_d._duel_rules(duels), null, null, _schedule(days), _rep_rules())
		var seen: Array[int] = []
		for i in 3:
			seen.append(_take(low))
			low.proceed()
		_expect(errs, seen == [8, 7, 2] and low.reputation_stars() == 1, "[ㄴ·결투 %d] 1일차의 평판 %s, 별 %d (기대 [8, 7, 2], 1)" % [duels, str(seen), low.reputation_stars()])
		var want_guests := 3 if duels == 3 else 4
		_expect(errs, low.tomorrow_guests() == want_guests, "[ㄴ·결투 %d] 내일의 손님 %d (기대 %d)" % [duels, low.tomorrow_guests(), want_guests])
		low.next_day()
		_expect(errs, low.commission_count() == want_guests, "[ㄴ·결투 %d] 2일차의 손님 %d (기대 %d)" % [duels, low.commission_count(), want_guests])
		if duels == 3:
			# 정직과 가난을 돌려보내고 궂은일(100점) → 0(아래로 잘린다). 오지 않은 넷은 만나지 못한 손님으로 세지 않는다.
			low.decline()
			low.decline()
			_expect(errs, _take(low) == 0 and low.last_result().get("reputation_after") == 0, "[ㄴ] 궂은일 뒤 평판 %d (기대 0: 아래로 잘림)" % low.reputation)
			low.proceed()
			_expect(errs, low.phase == P.CLOSING and low.closing_summary().get("missed") == 0, "[ㄴ] 오지 않은 손님을 만나지 못한 손님으로 셈: %s" % str(low.closing_summary()))

	# 위로 잘림: 평판 19에서 정직 → 20
	var high := _xy_day(_rep_rules(19))
	_expect(errs, _take(high) == 20, "[위로 잘림] 19에서 정직 뒤 평판 %d (기대 20)" % high.reputation)

	# ---- 돈은 같다: ㄱ의 1~3일차(양쪽의 손님 수가 3, 5, 3으로 같다)를 평판 규칙 없이 돌려도 걸음마다 단계·소지금·합이 같다
	var with_rules := _xy_day(_rep_rules())
	var without := _xy_day(null)
	var trace_with: Array = []
	var trace_without: Array = []
	var guests_without: Array[int] = []
	for steps: String in ["AAA", "DADAA", "AAD"]:
		guests_without.append(without.commission_count())
		_play_day(with_rules, steps, trace_with)
		_play_day(without, steps, trace_without)
		_expect(errs, with_rules.phase == P.CLOSING and without.phase == P.CLOSING, "[돈은 같다] 순서 %s 뒤 폐점이 아님" % steps)
		with_rules.next_day()
		without.next_day()
	guests_without.append(without.commission_count())
	_expect(errs, trace_with == trace_without and not trace_with.is_empty(), "[돈은 같다] 평판 유무에 따라 단계·소지금·합이 갈림")
	_expect(errs, with_rules.money == without.money, "[돈은 같다] 사흘 뒤의 소지금 %d, %d" % [with_rules.money, without.money])
	# 평판 규칙이 없는 쪽: Y의 손님은 기준만(5), 평판은 0에서 움직이지 않고, 결과에 평판 키가 없다.
	_expect(errs, guests_without == [3, 5, 3, 5], "[규칙 없음] 날마다의 손님 %s (기대 [3, 5, 3, 5])" % str(guests_without))
	_expect(errs, not without.has_reputation() and without.reputation == 0 and without.reputation_stars() == 0, "[규칙 없음] 평판이 0에서 움직임")
	var bare := _xy_day(null)
	_take(bare)
	_expect(errs, not bare.last_result().has("reputation_before") and not bare.last_result().has("reputation_items"), "[규칙 없음] 결과에 평판 키가 있음")
	bare.proceed()
	_take(bare)
	bare.proceed()
	_take(bare)
	bare.proceed()
	_expect(errs, not bare.closing_summary().has("reputation"), "[규칙 없음] 폐점 요약에 평판 키가 있음")
	_expect(errs, with_rules.commission_count() == 7, "[돈은 같다] 평판이 있는 쪽의 4일차 손님 %d (기대 7)" % with_rules.commission_count())

	# ---- enabled가 거짓인 규칙은 규칙 없이 만든 것과 같다
	var disabled_rules := _rep_rules()
	disabled_rules.enabled = false
	var off := _xy_day(disabled_rules)
	var trace_off: Array = []
	var trace_none: Array = []
	var none := _xy_day(null)
	for steps: String in ["AAA", "DADAA"]:
		_play_day(off, steps, trace_off)
		_play_day(none, steps, trace_none)
		off.next_day()
		none.next_day()
	_expect(errs, trace_off == trace_none and not off.has_reputation() and off.reputation == 0 and off.commission_count() == none.commission_count(),
		"[꺼짐] enabled가 거짓인 규칙의 하루가 규칙 없는 하루와 다름")
	return _result(errs)


# ================================================================ T54 평판의 화면

const REPUTATION_NODES: Array[String] = ["ReputationLabel", "ReputationHint", "GuestNote", "ReputationLine", "ReputationLedger"]


## 하루 하나짜리 일정의 하루 상태.
func _single_day(data: DayData, rep: ReputationRules) -> DayState:
	var days: Array[DayData] = [data]
	return DayState.new(_d._duel_rules(3), null, null, _schedule(days), rep)


## 화면을 붙였다 떼며 그 이름의 Label의 글자를 읽는다. 없으면 빈 문자열.
func _screen_label(path: String, day: DayState, node_name: String) -> String:
	var screen: Node = _d._spawn_screen(path, day)
	var text: String = _d._label_text(screen, node_name)
	screen.free()
	return text


## 화면에 평판의 노드가 하나라도 있는가.
func _has_reputation_nodes(path: String, day: DayState) -> bool:
	var screen: Node = _d._spawn_screen(path, day)
	var found := false
	for node_name in REPUTATION_NODES:
		if _d._has_node(screen, node_name):
			found = true
	screen.free()
	return found


func t54_screens() -> String:
	var errs: Array[String] = []
	var P := DayState.Phase

	# ---- 카운터: 평판, 소문 한 줄(맡는 값의 방향만)
	var day := _xy_day(_rep_rules())
	var counter: Node = _d._spawn_screen(Session.COUNTER_PATH, day)
	var label: String = _d._label_text(counter, "ReputationLabel")
	_expect(errs, label.contains("9") and label.contains("별 3") and counter.get("shown_reputation") == day.reputation,
		"[카운터] ReputationLabel '%s', 내보인 평판 %s (기대 9, 별 3)" % [label, str(counter.get("shown_reputation"))])
	_expect(errs, not _d._has_node(counter, "ReputationHint"), "[카운터] 맡는 값이 0인 손님(정직)에게 소문 줄이 있음")
	_expect(errs, not _d._has_node(counter, "GuestNote"), "[카운터] 기준 손님 수가 없는 날인데 GuestNote가 있음")
	counter.free()
	day.decline()
	_expect(errs, _screen_label(Session.COUNTER_PATH, day, "ReputationHint").contains("오를"), "[카운터] 가난한 손님의 소문 줄에 '오를'이 없음")
	day.decline()
	_expect(errs, _screen_label(Session.COUNTER_PATH, day, "ReputationHint").contains("깎일"), "[카운터] 궂은일의 소문 줄에 '깎일'이 없음")

	# ---- GuestNote: 평판 때문에 손님 줄이 보통과 다른 날의 첫 카운터에만 있다
	var crowded := _single_day(_day_y(), _rep_rules(16))
	_expect(errs, crowded.commission_count() == 7, "[GuestNote] 평판 16으로 연 Y의 손님 %d (기대 7)" % crowded.commission_count())
	var note := _screen_label(Session.COUNTER_PATH, crowded, "GuestNote")
	_expect(errs, note.contains("7") and note.contains("5"), "[GuestNote] 첫 카운터의 글 '%s'에 7과 5가 없음" % note)
	crowded.decline()
	_expect(errs, _screen_label(Session.COUNTER_PATH, crowded, "GuestNote") == "", "[GuestNote] 첫 손님을 돌려보낸 다음 카운터에도 있음")
	_expect(errs, _screen_label(Session.COUNTER_PATH, _single_day(_day_y(), _rep_rules()), "GuestNote") == "", "[GuestNote] 별 3(보통)으로 연 Y의 첫 카운터에 있음")

	# ---- 정산: 평판 줄과 까닭
	var settled := _xy_day(_rep_rules())
	_take(settled)
	var settlement: Node = _d._spawn_screen(Session.SETTLEMENT_PATH, settled)
	var line: String = _d._label_text(settlement, "ReputationLine")
	_expect(errs, line.contains("9") and line.contains("11") and line.contains("해냈다") and line.contains("흠 없이"), "[정산] 정직(100점)의 평판 줄 '%s'" % line)
	_expect(errs, not Ui.all_text(settlement).contains("치료비"), "[정산] 다치지 않았는데 화면에 '치료비'가 있음")
	settlement.free()

	var half_commissions: Array[Commission] = [_halfway()]
	var half := _single_day(_day_data(half_commissions), _rep_rules())
	_take(half)
	var half_line := _screen_label(Session.SETTLEMENT_PATH, half, "ReputationLine")
	_expect(errs, half_line.contains("맡았다") and not half_line.contains("해냈다") and half_line.contains("10"), "[정산] 어중간(60점)의 평판 줄 '%s' (기대 맡은 값만)" % half_line)

	var none_commissions: Array[Commission] = [_commission("무", 100, _effect(0, 0, 0))]
	var nothing := _single_day(_day_data(none_commissions), _rep_rules())
	_take(nothing)
	_expect(errs, _screen_label(Session.SETTLEMENT_PATH, nothing, "ReputationLine").contains("그대로"), "[정산] 항목이 없는 결과의 평판 줄에 '그대로'가 없음")

	var up_commissions: Array[Commission] = [_honest()]
	var star_up := _single_day(_day_data(up_commissions), _rep_rules(11))
	_take(star_up)
	var star_line := _screen_label(Session.SETTLEMENT_PATH, star_up, "ReputationLine")
	_expect(errs, star_line.contains("별 3 → 4"), "[정산] 별이 바뀐 결과의 평판 줄 '%s'에 '별 3 → 4'가 없음" % star_line)

	# ---- 폐점: 그날 시작과 지금의 평판, 내일의 손님
	var closed := _xy_day(_rep_rules())
	for i in 3:
		_take(closed)
		closed.proceed()
	var ledger := _screen_label(Session.CLOSING_PATH, closed, "ReputationLedger")
	_expect(errs, closed.phase == P.CLOSING and ledger.contains("9") and ledger.contains("10") and ledger.contains("내일의 손님 5"),
		"[폐점] ReputationLedger '%s' (기대 9 → 10, 내일의 손님 5)" % ledger)

	# 폐점에서 결투 수를 올리는 것을 사면 내일의 손님 줄이 다시 채워진다(별 1: 아래 한계가 결투 수다).
	var more: UpgradeData = _d._upgrade(&"t_more_duels", 10, UpgradeData.Target.ECONOMY, &"duels_per_day", 1.0)
	var more_list: Array[UpgradeData] = [more]
	var rich: EconomyRules = _d._duel_rules(3)
	rich.starting_money = 500
	var shop_days: Array[DayData] = [_day_x(), _day_y()]
	var shopper := DayState.new(rich, null, _d._catalog(more_list), _schedule(shop_days), _rep_rules(2))
	for i in 3:
		shopper.decline()
	var closing: Node = _d._spawn_screen(Session.CLOSING_PATH, shopper)
	_expect(errs, shopper.phase == P.CLOSING and shopper.tomorrow_guests() == 3 and _d._label_text(closing, "ReputationLedger").contains("내일의 손님 3"),
		"[폐점·구매] 사기 전의 내일의 손님이 3이 아님: '%s'" % _d._label_text(closing, "ReputationLedger"))
	_expect(errs, _d._press(closing, "Buy_t_more_duels") and shopper.owns(more), "[폐점·구매] 결투 수 업그레이드를 사지 못함")
	_expect(errs, shopper.tomorrow_guests() == 4 and _d._label_text(closing, "ReputationLedger").contains("내일의 손님 4"),
		"[폐점·구매] 산 뒤의 내일의 손님 %d, 화면 '%s' (기대 4)" % [shopper.tomorrow_guests(), _d._label_text(closing, "ReputationLedger")])
	closing.free()

	# ---- 평판 규칙 없이 만든 day, enabled가 거짓인 규칙의 day: 세 화면에 평판의 노드가 하나도 없다
	var disabled := _rep_rules(16)
	disabled.enabled = false
	for rep: ReputationRules in [null, disabled]:
		var tag := "규칙 없음" if rep == null else "꺼짐"
		var plain_days: Array[DayData] = [_day_y(), _day_x()]
		var plain := DayState.new(_d._duel_rules(3), null, null, _schedule(plain_days), rep)
		# 소문 줄이 붙었을 손님(가난)의 카운터까지 본다.
		_expect(errs, not _has_reputation_nodes(Session.COUNTER_PATH, plain), "[%s] 첫 카운터에 평판의 노드가 있음" % tag)
		plain.decline()
		_expect(errs, not _has_reputation_nodes(Session.COUNTER_PATH, plain), "[%s] 가난한 손님의 카운터에 평판의 노드가 있음" % tag)
		_take(plain)
		_expect(errs, not _has_reputation_nodes(Session.SETTLEMENT_PATH, plain), "[%s] 정산에 평판의 노드가 있음" % tag)
		plain.proceed()
		while plain.phase == P.COUNTER:
			plain.decline()
		_expect(errs, plain.phase == P.CLOSING and not _has_reputation_nodes(Session.CLOSING_PATH, plain), "[%s] 폐점에 평판의 노드가 있음" % tag)
	return _result(errs)
