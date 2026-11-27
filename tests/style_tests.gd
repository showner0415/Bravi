extends RefCounted
## T112~T116: 검술의 단(계획 040). 단의 틀, 원칙 4의 한계, 갈래와 색, 하루·연습·저장, 새 길이 도는 모습.

const Bot := preload("res://tests/duel_bots.gd")
const DT := preload("res://scripts/duel/duel_types.gd")
const Session := preload("res://scripts/game_session.gd")
const Ui := preload("res://scripts/day_ui.gd")
const SelectScript := preload("res://scripts/commission/commission_select.gd")

const BARTOLO_PATH := "res://data/opponents/opponent_01.tres"
const BRUNO_PATH := "res://data/opponents/opponent_02.tres"
const LORENZO_PATH := "res://data/opponents/opponent_03.tres"
const SERAFINA_PATH := "res://data/opponents/opponent_04.tres"
const AGOSTINO_PATH := "res://data/opponents/opponent_05.tres"
const BEATRICE_PATH := "res://data/opponents/opponent_06.tres"
const FIRST_BLOOD_PATH := "res://data/commissions/first_blood.tres"
const LEGS_ONLY_PATH := "res://data/commissions/variants/legs_only.tres"
const USURER_PATH := "res://data/commissions/variants/first_blood_usurer.tres"
const RULES_PATH := "res://data/duel_rules.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const DUEL_PATH := "res://scenes/duel/duel.tscn"
const OPPONENT_PATHS: Array[String] = [BARTOLO_PATH, BRUNO_PATH, LORENZO_PATH, SERAFINA_PATH, AGOSTINO_PATH, BEATRICE_PATH]
const DELTA := 1.0 / 60.0
const EPS := 1e-6
## 결정 375의 하한과 계획 040의 한 패턴 길이 상한.
const MIN_GAP := 0.55
const MAX_STRIKES := 4
const MAX_LENGTH := 3.5
## 단마다 정한 날(결정 583). 코드의 tier_for_day와 따로 손으로 적어 견준다.
const FROM_DAYS := {
	BARTOLO_PATH: [4, 5, 6, 7, 9, 11],
	BRUNO_PATH: [4, 5, 6, 7, 9, 11],
	LORENZO_PATH: [7, 9, 11, 13, 15],
	SERAFINA_PATH: [7, 9, 11, 13, 15],
	AGOSTINO_PATH: [6, 8, 10, 12, 14],
	BEATRICE_PATH: [7, 9, 11, 13, 15],
}
## 1단의 공격 수(하루의 상대의 목록은 그대로다).
const FIRST_TIER_SIZES := {BARTOLO_PATH: 5, BRUNO_PATH: 5, LORENZO_PATH: 4, SERAFINA_PATH: 2, AGOSTINO_PATH: 4, BEATRICE_PATH: 4}

var _tree: SceneTree


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T112", "name": "단의 틀: 날이 단을 고르고, 사본이 원본을 건드리지 않고, 단의 수에 상한이 없다", "fn": t112_tier_frame},
		{"id": "T113", "name": "단의 한계(원칙 4): 간격·타수·길이·빈틈·읽을 양·한쪽만 오른다", "fn": t113_limits},
		{"id": "T114", "name": "갈래와 색: 고유 색이 상태 색·초록·기본 색에서 떨어지고 1단의 패턴 값이 그대로다", "fn": t114_style_colors},
		{"id": "T115", "name": "하루·연습·저장: 날이 단을 고르고 연습 화면이 단을 제자리에서 바꾼다", "fn": t115_day_practice_save},
		{"id": "T116", "name": "새 길이 돈다: 네 번 베기·4점과 세로 휩쓸기·뛰어들어 한 번 더·겹찌르기·찌르고 베기·마지막 단의 판", "fn": t116_new_routes},
	]


func cleanup() -> void:
	_tree = null


# ================================================================ 도우미

func _same_list(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if a[i] != b[i]:
			return false
	return true


## 뿌리와 변주(가방에서 나오면 이 가운데 하나를 고르게 뽑는다).
func _routes(atk: AttackData) -> Array[AttackData]:
	var out: Array[AttackData] = [atk]
	for v in atk.variants:
		out.append(v as AttackData)
	return out


## 한 길의 타격들: 뿌리와 걸음.
func _strike_list(route: AttackData) -> Array[AttackData]:
	var out: Array[AttackData] = [route]
	for s in route.chain:
		out.append(s as AttackData)
	return out


## 상대의 단마다의 공격 목록. 0번이 1단이다.
func _tier_lists(opp: OpponentData) -> Array:
	var out: Array = [opp.attacks]
	for tier in opp.tiers:
		out.append(tier.attacks)
	return out


func _last_attacks(opp: OpponentData) -> Array[AttackData]:
	return opp.tiers[opp.tiers.size() - 1].attacks


func _find(list: Array, attack_name: String) -> AttackData:
	for atk in list:
		if (atk as AttackData).attack_name == attack_name:
			return atk
	return null


## 변주를 뗀 사본: 길을 하나로 고정한다. 로드한 자원은 고치지 않는다.
func _solo(atk: AttackData) -> AttackData:
	var copy := atk.duplicate() as AttackData
	var none: Array[Resource] = []
	copy.variants = none
	return copy


## 공격 하나만 되풀이하는 상대(대기 1.0초 고정, 빈틈의 확률 끔).
func _drill_opp(opp: OpponentData, atk: AttackData) -> OpponentData:
	var copy := opp.drill(atk)
	copy.opening_chance = 1.0
	copy.idle_time_min = 1.0
	copy.idle_time_max = 1.0
	return copy


func _play(opp: OpponentData, cfg: Dictionary, stop: Callable, until: float, on_tick := Callable()) -> DuelCore:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var weapon := (load(WEAPON_PATH) as WeaponData).duplicate() as WeaponData
	# 엉킴을 끈 무기: 밀착에서 밀려나는 일이 판을 흔들지 않는다.
	weapon.close_bind_time = 0.0
	var rules := load(RULES_PATH) as DuelRules
	var core := DuelCore.new()
	var none: Array[CommissionCondition] = []
	core.setup(rules, weapon, opp, rng, none, false)
	var bot := Bot.new(core, cfg)
	core.step(1)
	while not core.ended and core.time < until:
		core.tick(DELTA)
		if on_tick.is_valid():
			on_tick.call(core)
		bot.update()
		if stop.call(core):
			break
	return core


func _stop_strikes(count: int) -> Callable:
	return func(core: DuelCore) -> bool: return core.record.of_type(DuelRecord.STRIKE).size() >= count


func _never() -> Callable:
	return func(_core: DuelCore) -> bool: return false


func _results(strikes: Array) -> Array[int]:
	var out: Array[int] = []
	for ev: Dictionary in strikes:
		out.append(int(ev["result"]))
	return out


func _result_text(strikes: Array) -> String:
	return str(_results(strikes))


func _is(strikes: Array, want: Array) -> bool:
	return _result_text(strikes) == str(want)


func _mode(mode: StringName) -> Callable:
	return func(_a: AttackData, _i: int) -> StringName: return mode


func _dives(core: DuelCore) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for ev in core.record.of_type(DuelRecord.DISTANCE):
		if ev["by"] == "dive":
			out.append(ev)
	return out


func _ok(errs: Array[String]) -> String:
	return "OK" if errs.is_empty() else ", ".join(errs)


# ================================================================ T112 단의 틀

func _count_le(days: Array, day: int) -> int:
	var n := 0
	for d: int in days:
		if d <= day:
			n += 1
	return n


func _test_attack(index: int) -> AttackData:
	var atk := AttackData.new()
	atk.attack_name = "시험%d" % index
	atk.direction = DT.Direction.CENTER
	atk.tell_time = 0.7
	atk.recovery_time = 0.0
	return atk


func t112_tier_frame() -> String:
	var errs: Array[String] = []
	for path in OPPONENT_PATHS:
		var opp := load(path) as OpponentData
		var label := opp.display_name
		var from_days: Array = FROM_DAYS[path]
		if opp.tiers.size() < 2 or opp.tier_count() != 1 + opp.tiers.size():
			errs.append("%s: 단 %d개 · tier_count %d" % [label, opp.tiers.size(), opp.tier_count()])
			continue
		var last_from := 0
		for i in opp.tiers.size():
			var tier := opp.tiers[i]
			if tier.attacks.is_empty():
				errs.append("%s %d단: 공격이 없다" % [label, i + 2])
			if tier.from_day <= last_from:
				errs.append("%s %d단: from_day %d가 앞 단(%d)보다 크지 않다" % [label, i + 2, tier.from_day, last_from])
			last_from = tier.from_day
			if from_days.size() != opp.tiers.size() or tier.from_day != from_days[i]:
				errs.append("%s %d단: from_day %d (기대 %s)" % [label, i + 2, tier.from_day, str(from_days)])
		# 날과 단: 첫 단 전은 원본 그 객체, 그 뒤는 그 단의 목록, 아주 큰 날은 마지막 단, 0 이하는 원본.
		for d in range(-3, 40):
			var want := _count_le(from_days, d) if d > 0 else 0
			if opp.tier_for_day(d) != want:
				errs.append("%s: tier_for_day(%d) = %d (기대 %d)" % [label, d, opp.tier_for_day(d), want])
				continue
			var got := opp.for_day(d)
			if want == 0:
				if got != opp:
					errs.append("%s: for_day(%d)가 원본 그 객체가 아니다" % [label, d])
			elif got == opp or not _same_list(got.attacks, opp.tiers[want - 1].attacks):
				errs.append("%s: for_day(%d)가 %d단의 목록이 아니다" % [label, d, want + 1])
		var huge := opp.for_day(100000)
		if not _same_list(huge.attacks, _last_attacks(opp)) or opp.tier_for_day(100000) != opp.tiers.size():
			errs.append("%s: 아주 큰 날이 마지막 단이 아니다" % label)
		if opp.at_tier(0) != opp or opp.at_tier(-2) != opp or not _same_list(opp.at_tier(999).attacks, _last_attacks(opp)):
			errs.append("%s: at_tier의 0·음수·넘침이 어긋남" % label)
		# 사본의 목록을 고쳐도 원본과 단 데이터의 목록은 그대로다. 목록 밖의 값은 그대로 나눠 쓴다.
		for k in range(1, opp.tier_count()):
			var copy := opp.at_tier(k)
			var base_size := opp.attacks.size()
			var tier_size := opp.tiers[k - 1].attacks.size()
			copy.attacks.append(AttackData.new())
			if opp.attacks.size() != base_size or opp.tiers[k - 1].attacks.size() != tier_size:
				errs.append("%s %d단: 사본에 더한 공격이 원본이나 단 데이터에 번졌다" % [label, k + 1])
			copy.attacks.clear()
			if opp.attacks.size() != base_size or opp.tiers[k - 1].attacks.size() != tier_size:
				errs.append("%s %d단: 사본의 목록을 비웠더니 원본이나 단 데이터가 바뀌었다" % [label, k + 1])
			var same_tier := opp.at_tier(k)
			for prop in opp.get_property_list():
				if not (int(prop["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE):
					continue
				var field: String = prop["name"]
				if field == "attacks":
					continue
				var a: Variant = same_tier.get(field)
				var b: Variant = opp.get(field)
				if a != b:
					errs.append("%s %d단: %s가 원본과 다르다" % [label, k + 1, field])
	# tiers가 빈 상대는 어느 날에도 원본이다.
	var bare := (load(BARTOLO_PATH) as OpponentData).duplicate() as OpponentData
	var no_tiers: Array[StyleTier] = []
	bare.tiers = no_tiers
	for d in [-1, 0, 1, 5, 50]:
		if bare.for_day(d) != bare or bare.tier_for_day(d) != 0:
			errs.append("단 없는 상대의 %d일차가 원본이 아니다" % d)
	if bare.at_tier(3) != bare or bare.tier_count() != 1:
		errs.append("단 없는 상대의 at_tier·tier_count")
	# 단 여덟 개짜리 시험 데이터(상한 없음).
	var eight := (load(BARTOLO_PATH) as OpponentData).duplicate() as OpponentData
	var made: Array[StyleTier] = []
	var firsts: Array[AttackData] = []
	for k in 8:
		var tier := StyleTier.new()
		tier.from_day = 2 + k * 2
		var one := _test_attack(k)
		firsts.append(one)
		var list: Array[AttackData] = [one]
		tier.attacks = list
		made.append(tier)
	eight.tiers = made
	if eight.tier_count() != 9 or eight.tier_for_day(1) != 0 or eight.tier_for_day(2) != 1 or eight.tier_for_day(3) != 1 \
			or eight.tier_for_day(4) != 2 or eight.tier_for_day(16) != 8 or eight.tier_for_day(99) != 8:
		errs.append("여덟 단: tier_count %d · 날 1·2·3·4·16·99 → %d %d %d %d %d %d" % [eight.tier_count(), eight.tier_for_day(1),
			eight.tier_for_day(2), eight.tier_for_day(3), eight.tier_for_day(4), eight.tier_for_day(16), eight.tier_for_day(99)])
	if eight.at_tier(8).attacks[0] != firsts[7] or eight.at_tier(50).attacks[0] != firsts[7] or eight.for_day(5).attacks[0] != firsts[1]:
		errs.append("여덟 단: 단이 목록을 잘못 고른다")
	var eighth := eight.for_day(99).with_opening(1.0)
	var run := _play(eighth, {}, _never(), 6.0)
	if run.record.of_type(DuelRecord.TELL_START).is_empty():
		errs.append("여덟 단의 마지막 단이 6초 동안 예비 동작을 내지 않았다")
	# 카운터의 갈래 글(결정 590).
	for path in OPPONENT_PATHS:
		var opp := load(path) as OpponentData
		var from_days: Array = FROM_DAYS[path]
		for d in [1, 3, 4, 5, 7, 9, 11, 15, 40]:
			var tier_index := _count_le(from_days, d)
			var want := "%s · %s" % [opp.display_name, opp.style_name]
			if tier_index > 0:
				want += " %d단" % (tier_index + 1)
			if opp.style_label(d) != want:
				errs.append("style_label(%d) '%s' (기대 '%s')" % [d, opp.style_label(d), want])
	var nameless := OpponentData.new()
	nameless.display_name = "무명"
	if nameless.style_label(9) != "무명":
		errs.append("갈래 이름이 없는 상대의 글 '%s'" % nameless.style_label(9))
	return _ok(errs)


# ================================================================ T113 한계

func _where(opp: OpponentData, tier_index: int, route: AttackData) -> String:
	return "%s %d단 %s" % [opp.display_name, tier_index + 1, route.attack_name]


func _check_route(errs: Array[String], where: String, route: AttackData, gap: float) -> void:
	var strikes := _strike_list(route)
	if strikes.size() > MAX_STRIKES:
		errs.append("%s: 타격 %d개 (상한 %d)" % [where, strikes.size(), MAX_STRIKES])
	var length := route.tell_time
	for i in range(1, strikes.size()):
		if strikes[i].tell_time < gap - EPS:
			errs.append("%s: 걸음 간격 %.2f (하한 %.2f)" % [where, strikes[i].tell_time, gap])
		length += strikes[i].tell_time
	if length > MAX_LENGTH + EPS:
		errs.append("%s: 패턴 길이 %.2f초 (상한 %.1f)" % [where, length, MAX_LENGTH])
	for s in strikes:
		if s.recovery_time > EPS and s.recovery_time < MIN_GAP - EPS:
			errs.append("%s: 빈틈 %.2f초 (0이거나 %.2f 이상)" % [where, s.recovery_time, MIN_GAP])
	if not route.chain.is_empty() and route.needs_raised_guard:
		errs.append("%s: 패턴의 뿌리가 올려 막기 공격이다" % where)
	_check_feints(errs, where, route, strikes)
	if route.sweep:
		var points: Array[Vector2i] = []
		for s in strikes:
			if s.heights.size() != 1:
				errs.append("%s: 휩쓸기의 점이 높이 하나가 아니다" % where)
				points.clear()
				break
			points.append(Vector2i(int(s.direction), int(s.heights[0])))
		for i in range(1, points.size()):
			var dd := absi(points[i].x - points[i - 1].x)
			var dh := absi(points[i].y - points[i - 1].y)
			if dd > 1 or dh > 1 or (dd == 0 and dh == 0):
				errs.append("%s: 휩쓸기의 %d번째 점이 이웃한 한 칸 차가 아니다 (가로 %d · 세로 %d)" % [where, i + 1, dd, dh])


## 헛손질의 한계(결정 672 ㄱ~ㄷ). 헛손질이 없는 길에는 아무것도 걸지 않는다.
func _check_feints(errs: Array[String], where: String, route: AttackData, strikes: Array[AttackData]) -> void:
	var feints := 0
	for s in strikes:
		if s.feint:
			feints += 1
	if feints == 0:
		return
	if route.sweep or route.dive or route.needs_raised_guard:
		errs.append("%s: 휩쓸기 · 뛰어들기 · 올려 막기 길에 헛손질이 있다" % where)
	if strikes.size() < 2:
		errs.append("%s: 걸음이 없는 길에 헛손질이 있다" % where)
	if strikes[strikes.size() - 1].feint:
		errs.append("%s: 길의 마지막 타격이 헛손질이다" % where)
	if feints >= strikes.size():
		errs.append("%s: 진짜 타격이 없다" % where)
	if feints > 2:
		errs.append("%s: 헛손질 %d개 (상한 2)" % [where, feints])
	for i in strikes.size():
		if not strikes[i].feint:
			continue
		var real: AttackData = null
		for j in range(i + 1, strikes.size()):
			if not strikes[j].feint:
				real = strikes[j]
				break
		if real == null:
			continue
		if real.direction != strikes[i].direction:
			continue
		var overlap := strikes[i].heights.is_empty() or real.heights.is_empty()
		for h in strikes[i].heights:
			if real.heights.has(h):
				overlap = true
		if overlap:
			errs.append("%s: %d번째 헛손질과 그다음 진짜 타격의 칸이 겹친다" % [where, i + 1])


## 공격의 모든 값(걸음과 변주까지). 한 단이 기본과 고유 가운데 어느 쪽을 바꿨는지 가를 때 쓴다.
func _sig_text(atk: AttackData) -> String:
	var text := "%s|%d|%.3f|%.3f|%.3f|%s|%s|%s|%s|%s|%s|%s|%s" % [atk.attack_name, atk.direction, atk.tell_time, atk.recovery_time,
		atk.weight, atk.is_big, atk.needs_raised_guard, atk.sweep, atk.dive, atk.signature, str(atk.heights), str(atk.pose_color), atk.feint]
	for c in atk.chain:
		text += "/" + _sig_text(c as AttackData)
	text += "~"
	for v in atk.variants:
		text += "/" + _sig_text(v as AttackData)
	return text


## [고유의 값들, 기본의 값들]. 순서와 상관없게 정렬한다.
func _split_texts(attacks: Array) -> Array:
	var sigs: Array[String] = []
	var bases: Array[String] = []
	for atk: AttackData in attacks:
		if atk.signature:
			sigs.append(_sig_text(atk))
		else:
			bases.append(_sig_text(atk))
	sigs.sort()
	bases.sort()
	return [sigs, bases]


## 읽을 양 = 타수의 합 + 길의 수 + 칸의 가짓수(빈 heights는 1). 길 = 뿌리와 변주.
func _reading_amount(attacks: Array) -> int:
	var total := 0
	for atk: AttackData in attacks:
		for route in _routes(atk):
			total += 1
			for s in _strike_list(route):
				total += 1 + maxi(s.heights.size(), 1)
	return total


## 이름마다 뿌리·변주의 가장 짧은 예비.
func _min_tells(attacks: Array) -> Dictionary:
	var out := {}
	for atk: AttackData in attacks:
		for route in _routes(atk):
			var key: String = route.attack_name
			if not out.has(key) or route.tell_time < float(out[key]):
				out[key] = route.tell_time
	return out


func t113_limits() -> String:
	var errs: Array[String] = []
	var weapon := load(WEAPON_PATH) as WeaponData
	var gap := maxf(MIN_GAP, weapon.guard_cooldown + weapon.parry_window)
	for path in OPPONENT_PATHS:
		var opp := load(path) as OpponentData
		var lists := _tier_lists(opp)
		for i in lists.size():
			var attacks: Array = lists[i]
			for atk: AttackData in attacks:
				for route in _routes(atk):
					_check_route(errs, _where(opp, i, route), route, gap)
		for habit in opp.habits:
			if habit.response.recovery_time > EPS and habit.response.recovery_time < MIN_GAP - EPS:
				errs.append("%s: 버릇의 빈틈 %.2f" % [opp.display_name, habit.response.recovery_time])
		# 단을 따라: 예비가 짧아지지 않고, 읽을 양이 늘고, 기본과 고유 가운데 한쪽만 바뀐다.
		for i in range(1, lists.size()):
			var prev: Array = lists[i - 1]
			var now: Array = lists[i]
			var before_tells := _min_tells(prev)
			var after_tells := _min_tells(now)
			for key in before_tells:
				if after_tells.has(key) and float(after_tells[key]) < float(before_tells[key]) - EPS:
					errs.append("%s %d단: '%s'의 예비 %.2f가 앞 단(%.2f)보다 짧다" % [opp.display_name, i + 1, key, after_tells[key], before_tells[key]])
			var was := _reading_amount(prev)
			var is_now := _reading_amount(now)
			if is_now <= was:
				errs.append("%s %d단: 읽을 양 %d가 앞 단(%d)보다 늘지 않았다" % [opp.display_name, i + 1, is_now, was])
			var old_split := _split_texts(prev)
			var new_split := _split_texts(now)
			var sig_changed: bool = old_split[0] != new_split[0]
			var base_changed: bool = old_split[1] != new_split[1]
			if sig_changed == base_changed:
				errs.append("%s %d단: 기본 %s · 고유 %s (한쪽만 바뀌어야 한다)" % [opp.display_name, i + 1, base_changed, sig_changed])
	return _ok(errs)


# ================================================================ T114 갈래와 색

func _rgb_dist(a: Color, b: Color) -> float:
	return sqrt(pow(a.r - b.r, 2.0) + pow(a.g - b.g, 2.0) + pow(a.b - b.b, 2.0))


func _hue_gap(a: Color, b: Color) -> float:
	var d := absf(a.h - b.h)
	return minf(d, 1.0 - d)


## 몸의 상태 색(뷰의 상수), 초록 셋(결정 582), 기본 색 셋.
func _state_colors() -> Array:
	return [["타격 빨강", OpponentView.COLOR_STRIKE], ["빈틈 파랑", OpponentView.COLOR_RECOVERY], ["무너짐 보라", OpponentView.COLOR_STAGGER],
		["닿음 흰색", OpponentView.COLOR_TOUCHED], ["팔 둔함 잿빛", OpponentView.COLOR_ARM_SLOW]]


func _green_colors() -> Array:
	return [["초록(칸)", Color(0.3, 1.0, 0.5)], ["초록(꼬리표)", Color(0.45, 1.0, 0.6)], ["초록(막기)", Color(0.3, 0.85, 0.45)]]


func _base_colors() -> Array[Color]:
	return [Color(1, 0.9, 0.25), Color(1, 0.75, 0.2), Color(1, 0.5, 0.1)]


func _near_any(c: Color, colors: Array[Color]) -> bool:
	for other in colors:
		if _rgb_dist(c, other) < 0.01:
			return true
	return false


## 1단의 고유 패턴 길들(뿌리, 변주 차례)의 모습. 값은 git의 지금 값이다.
func _row(route: AttackData) -> String:
	var text := "%s d%d t%.2f r%.2f b%d h%s" % [route.attack_name, route.direction, route.tell_time, route.recovery_time,
		1 if route.is_big else 0, str(route.heights)]
	if route.feint:
		text += " f"
	for s: AttackData in route.chain:
		text += " > d%d t%.2f h%s" % [s.direction, s.tell_time, str(s.heights)]
		if s.feint:
			text += " f"
	return text


func _first_tier_rows(opp: OpponentData) -> Array[String]:
	var rows: Array[String] = []
	for atk in opp.attacks:
		if atk.signature:
			for route in _routes(atk):
				rows.append(_row(route))
	return rows


func _expected_rows(path: String) -> Array[String]:
	match path:
		BARTOLO_PATH:
			return [
				"이어 베기 d2 t0.90 r1.20 b0 h[0, 1] > d0 t0.75 h[0, 1]",
				"이어 베기 d0 t0.90 r1.20 b0 h[0, 1] > d2 t0.75 h[0, 1]",
				"세 번 베기 d2 t0.90 r1.60 b1 h[0, 1] > d0 t0.75 h[0, 1] > d1 t0.65 h[1, 2]",
				"세 번 베기 d0 t0.90 r1.60 b1 h[0, 1] > d2 t0.75 h[0, 1] > d1 t0.65 h[1, 2]",
			]
		BRUNO_PATH:
			return [
				"휩쓸기 d0 t1.00 r1.60 b1 h[1] > d1 t0.60 h[1] > d2 t0.60 h[1]",
				"휩쓸기 d0 t1.00 r1.60 b1 h[0] > d1 t0.60 h[1] > d2 t0.60 h[2]",
				"휩쓸기 d0 t1.00 r1.60 b1 h[2] > d1 t0.60 h[2] > d2 t0.60 h[2]",
				"되돌려 휩쓸기 d2 t1.00 r1.60 b1 h[1] > d1 t0.60 h[1] > d0 t0.60 h[1]",
				"되돌려 휩쓸기 d2 t1.00 r1.60 b1 h[2] > d1 t0.60 h[1] > d0 t0.60 h[0]",
				"되돌려 휩쓸기 d2 t1.00 r1.60 b1 h[2] > d1 t0.60 h[2] > d0 t0.60 h[2]",
			]
		LORENZO_PATH:
			return ["뛰어드는 찌르기 d1 t1.20 r1.60 b0 h[1, 2]"]
		SERAFINA_PATH:
			return [
				"층층 찌르기 d1 t0.90 r1.60 b1 h[0] > d1 t0.60 h[1] > d1 t0.60 h[2]",
				"층층 찌르기 d1 t0.90 r1.60 b1 h[2] > d1 t0.60 h[1] > d1 t0.60 h[0]",
				"층층 찌르기 d1 t0.90 r1.60 b1 h[1] > d1 t0.60 h[2] > d1 t0.60 h[0]",
			]
		AGOSTINO_PATH:
			return [
				"엇박 찌르기 d1 t0.90 r0.55 b0 h[1] > d1 t0.60 h[1] > d1 t1.30 h[1]",
				"엇박 찌르기 d1 t0.90 r0.55 b0 h[1] > d1 t1.30 h[1] > d1 t0.60 h[1]",
			]
		BEATRICE_PATH:
			return [
				"속임 베기 d0 t0.90 r1.20 b0 h[0] f > d2 t0.65 h[1, 2]",
				"속임 베기 d0 t0.90 r1.20 b0 h[0] f > d0 t0.65 h[2]",
			]
	return []


func t114_style_colors() -> String:
	var errs: Array[String] = []
	var styles: Array[String] = []
	var own_colors: Array[Color] = []
	var own_names: Array[String] = []
	var base_set := _base_colors()
	for path in OPPONENT_PATHS:
		var opp := load(path) as OpponentData
		var label := opp.display_name
		if opp.style_name.is_empty() or styles.has(opp.style_name):
			errs.append("%s: style_name '%s'이 비었거나 다른 상대와 같다" % [label, opp.style_name])
		styles.append(opp.style_name)
		var sig_colors: Array[Color] = []
		var base_colors: Array[Color] = []
		for list: Array in _tier_lists(opp):
			for atk: AttackData in list:
				for v in atk.variants:
					if (v as AttackData).signature != atk.signature:
						errs.append("%s: '%s'의 변주 signature가 뿌리와 다르다" % [label, atk.attack_name])
				for route in _routes(atk):
					for s in _strike_list(route):
						if route.signature:
							sig_colors.append(s.pose_color)
						else:
							base_colors.append(s.pose_color)
		for habit in opp.habits:
			base_colors.append(habit.response.pose_color)
		if sig_colors.is_empty():
			errs.append("%s: 고유 공격이 없다" % label)
			continue
		var mine := sig_colors[0]
		for c in sig_colors:
			if _rgb_dist(c, mine) > 0.01:
				errs.append("%s: 고유 검술의 색이 하나가 아니다 (%s와 %s)" % [label, str(mine), str(c)])
				break
		for c in base_colors:
			if not _near_any(c, base_set):
				errs.append("%s: 기본 공격의 색 %s가 기본 색 셋이 아니다" % [label, str(c)])
				break
		for pair: Array in _state_colors() + _green_colors():
			var other: Color = pair[1]
			var dist := _rgb_dist(mine, other)
			if dist < 0.35:
				errs.append("%s: 고유 색이 %s와 %.3f (0.35 이상)" % [label, pair[0], dist])
		for other in base_set:
			if _rgb_dist(mine, other) < 0.35:
				errs.append("%s: 고유 색이 기본 색 %s와 %.3f (0.35 이상)" % [label, str(other), _rgb_dist(mine, other)])
		# 색상의 차: 빈틈의 파랑·초록 셋·타격의 빨강과 이어져 읽히지 않게(임시 문턱 0.06).
		var hue_pairs: Array = [["빈틈 파랑", OpponentView.COLOR_RECOVERY], ["타격 빨강", OpponentView.COLOR_STRIKE]] + _green_colors()
		var gaps: Array[String] = []
		for pair: Array in hue_pairs:
			var gap_value := _hue_gap(mine, pair[1])
			gaps.append("%s %.3f" % [pair[0], gap_value])
			if gap_value < 0.06:
				errs.append("%s: 고유 색의 색상이 %s와 %.3f (0.06 이상)" % [label, pair[0], gap_value])
		print("  INFO 색상 차 %s(%s): %s" % [label, opp.style_name, " · ".join(PackedStringArray(gaps))])
		for i in own_colors.size():
			if _rgb_dist(mine, own_colors[i]) < 0.25:
				errs.append("%s의 고유 색이 %s의 것과 %.3f (0.25 이상)" % [label, own_names[i], _rgb_dist(mine, own_colors[i])])
		own_colors.append(mine)
		own_names.append(label)
		# 1단: 색을 바꾼 패턴의 값은 그대로다.
		var rows := _first_tier_rows(opp)
		var want := _expected_rows(path)
		if str(rows) != str(want):
			errs.append("%s 1단의 고유 패턴 값이 달라졌다: %s (기대 %s)" % [label, str(rows), str(want)])
		if opp.attacks.size() != FIRST_TIER_SIZES[path]:
			errs.append("%s 1단의 공격이 %d개 (기대 %d)" % [label, opp.attacks.size(), FIRST_TIER_SIZES[path]])
	return _ok(errs)


# ================================================================ T115 하루·연습·저장

## 하루의 판을 열어 코어가 받은 상대를 돌려준다. style_tier가 0 이상이면 그 단으로 고정한다.
func _scene_opponent(day: DayState, style_tier := -1) -> OpponentData:
	day.accept()
	var duel: Node = (load(DUEL_PATH) as PackedScene).instantiate()
	duel.set("day", day)
	duel.set("mouse_aim_enabled", false)
	duel.set("rng_seed", 1)
	if style_tier >= 0:
		duel.set("style_tier", style_tier)
	_tree.root.add_child(duel)
	var used: OpponentData = (duel.get("core") as DuelCore).opponent_data
	duel.free()
	return used


func _one_day(commission_path: String, day_number: int) -> DayState:
	var data := DayData.new()
	var one: Array[Commission] = [load(commission_path) as Commission]
	data.commissions = one
	var day := DayState.new(load(Session.ECONOMY_PATH) as EconomyRules, data)
	day.day_number = day_number
	return day


func _bound_opponent(button: Button) -> OpponentData:
	for connection in button.pressed.get_connections():
		var args: Array = (connection["callable"] as Callable).get_bound_arguments()
		if not args.is_empty() and args[0] is OpponentData:
			return args[0]
	return null


func _count(select: Node, pattern: String) -> int:
	return select.find_children(pattern, "Button", true, false).size()


func t115_day_practice_save() -> String:
	var errs: Array[String] = []
	var bartolo := load(BARTOLO_PATH) as OpponentData
	var bruno := load(BRUNO_PATH) as OpponentData
	var lorenzo := load(LORENZO_PATH) as OpponentData
	var cases := [
		[FIRST_BLOOD_PATH, bartolo, FROM_DAYS[BARTOLO_PATH], [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 20]],
		[LEGS_ONLY_PATH, bruno, FROM_DAYS[BRUNO_PATH], [1, 3, 4, 6, 7, 9, 11, 30]],
		[USURER_PATH, lorenzo, FROM_DAYS[LORENZO_PATH], [3, 6, 7, 8, 9, 13, 15, 30]],
	]
	# 하루의 판: 날이 단을 고른다. 1단인 날은 원본 그 객체다.
	for item: Array in cases:
		var opp: OpponentData = item[1]
		var from_days: Array = item[2]
		for d: int in item[3]:
			var used := _scene_opponent(_one_day(item[0], d))
			var tier_index := _count_le(from_days, d)
			if tier_index == 0:
				if used != opp:
					errs.append("%s %d일차: 코어의 상대가 원본 그 객체가 아니다" % [opp.display_name, d])
			elif used == opp or not _same_list(used.attacks, opp.tiers[tier_index - 1].attacks):
				errs.append("%s %d일차: 코어의 상대가 %d단의 목록이 아니다" % [opp.display_name, d, tier_index + 1])
	# style_tier 훅: 0이면 6일차도 원본, 2면 1일차도 3단.
	if _scene_opponent(_one_day(FIRST_BLOOD_PATH, 6), 0) != bartolo:
		errs.append("style_tier = 0인데 6일차가 원본이 아니다")
	if not _same_list(_scene_opponent(_one_day(FIRST_BLOOD_PATH, 1), 2).attacks, bartolo.tiers[1].attacks):
		errs.append("style_tier = 2인데 1일차가 3단이 아니다")
	# 저장: 열쇠가 지금과 같고, 6일차의 아침을 되돌린 판도 4단이다.
	var economy := load(Session.ECONOMY_PATH) as EconomyRules
	var saver := _one_day(FIRST_BLOOD_PATH, 6)
	var saved := saver.saved_state()
	var keys := saved.keys()
	keys.sort()
	if str(keys) != str(["day", "dice_seed", "money", "owned", "reputation", "version"]):
		errs.append("저장 Dictionary의 열쇠 %s" % str(keys))
	var data := DayData.new()
	var one: Array[Commission] = [load(FIRST_BLOOD_PATH) as Commission]
	data.commissions = one
	var restored := DayState.new(economy, data)
	if not restored.restore(saved) or restored.day_number != 6:
		errs.append("6일차의 아침을 되돌리지 못했다")
	elif not _same_list(_scene_opponent(restored).attacks, bartolo.tiers[2].attacks):
		errs.append("되돌린 6일차의 판이 4단이 아니다")
	# 카운터의 "상대:" 줄.
	for pair: Array in [[1, "상대: 바르톨로 · 이어 베기", "이어 베기 3단"], [5, "상대: 바르톨로 · 이어 베기 3단", ""]]:
		var counter: Node = (load(Session.COUNTER_PATH) as PackedScene).instantiate()
		counter.set("day", _one_day(FIRST_BLOOD_PATH, pair[0]))
		_tree.root.add_child(counter)
		var text: String = Ui.all_text(counter)
		counter.free()
		if not text.contains(pair[1]):
			errs.append("%d일차 카운터에 '%s'가 없다" % [pair[0], pair[1]])
		if pair[2] != "" and text.contains(pair[2]):
			errs.append("%d일차 카운터에 '%s'가 있다" % [pair[0], pair[2]])
	errs.append_array(_practice_checks(bartolo, bruno, lorenzo))
	return _ok(errs)


## 연습 화면(root에 붙인 화면에서): 단 고르기가 시험 칸을 제자리에서 새로 짓는다.
func _practice_checks(bartolo: OpponentData, bruno: OpponentData, lorenzo: OpponentData) -> Array[String]:
	var errs: Array[String] = []
	var opponents: Array[OpponentData] = [bartolo, bruno, lorenzo]
	SelectScript._style_tier = 0
	SelectScript._picked_opponent = 0
	var select: Node = (load(Session.SELECT_PATH) as PackedScene).instantiate()
	_tree.root.add_child(select)
	for n in opponents.size():
		var opp := opponents[n]
		SelectScript._style_tier = 0
		select.call("pick_opponent", n)
		var pick := select.find_child("StyleTierPick", true, false) as OptionButton
		if pick == null:
			select.free()
			SelectScript._style_tier = 0
			SelectScript._picked_opponent = 0
			errs.append("상대 %d: 연습 화면에 StyleTierPick이 없다" % n)
			return errs
		if pick.item_count != opp.tier_count():
			errs.append("상대 %d: StyleTierPick의 항목 %d개 (기대 %d)" % [n, pick.item_count, opp.tier_count()])
		var first := select.find_child("TrialDuel0", true, false) as Button
		if first == null or _bound_opponent(first) != opp:
			errs.append("상대 %d: 처음의 TrialDuel0이 원본 상대를 묶고 있지 않다" % n)
		for index in [2, 0, 6, 1, 99]:
			var old_grid := select.find_child("TrialGrid", true, false)
			var old_help := select.find_child("PatternHelp", true, false)
			pick.item_selected.emit(index)
			var grids := select.find_children("TrialGrid", "", true, false)
			var helps := select.find_children("PatternHelp", "", true, false)
			if grids.size() != 1 or is_instance_valid(old_grid):
				errs.append("상대 %d 단 %d: TrialGrid가 새 노드 하나가 아니다 (%d개)" % [n, index + 1, grids.size()])
			if helps.size() != 1 or is_instance_valid(old_help):
				errs.append("상대 %d 단 %d: PatternHelp가 새 노드 하나가 아니다 (%d개)" % [n, index + 1, helps.size()])
			if not is_instance_valid(pick) or select.find_child("StyleTierPick", true, false) != pick:
				errs.append("상대 %d 단 %d: StyleTierPick이 같은 노드로 살아 있지 않다" % [n, index + 1])
			var button := select.find_child("TrialDuel0", true, false) as Button
			var bound: OpponentData = null
			if button != null:
				bound = _bound_opponent(button)
			if bound == null:
				errs.append("상대 %d 단 %d: TrialDuel0에 상대가 묶여 있지 않다" % [n, index + 1])
			elif index == 0:
				if bound != opp:
					errs.append("상대 %d 단 1: TrialDuel0이 원본이 아니다" % n)
			elif not _same_list(bound.attacks, opp.tiers[mini(index, opp.tiers.size()) - 1].attacks):
				errs.append("상대 %d 단 %d: TrialDuel0의 상대가 그 단(넘치면 마지막)의 목록이 아니다" % [n, index + 1])
			var want_drills := 0
			if bound != null:
				for atk: AttackData in bound.attacks:
					if atk.signature:
						want_drills += 1
			want_drills = mini(want_drills, SelectScript.DRILL_MAX)
			var drills := _count(select, "PatternDrill*")
			if drills != want_drills:
				errs.append("상대 %d 단 %d: 패턴만 버튼 %d개 (기대 %d)" % [n, index + 1, drills, want_drills])
			var slashes := _count(select, "SlashDrill")
			if _count(select, "TrialDuel*") != 1 or _count(select, "OpeningDay*") != 4 or _count(select, "PartCounterToggle") != 1 \
					or slashes != (1 if n == 0 else 0):
				errs.append("상대 %d 단 %d: 자유 결투 %d · 빈틈 날 %d · 반격 실험 %d · 베기만 %d (기대 1 · 4 · 1 · %d)" % [n, index + 1,
					_count(select, "TrialDuel*"), _count(select, "OpeningDay*"), _count(select, "PartCounterToggle"), slashes,
					1 if n == 0 else 0])
			var grid: Control = null
			if not grids.is_empty():
				grid = grids[0] as Control
			var first_free := select.find_child("TrialDuel0", true, false) as Control
			if grid != null and first_free != null:
				var grid_size := grid.get_combined_minimum_size()
				if grid_size.x > 1216.0 or grid_size.y > first_free.get_combined_minimum_size().y * 2.0 + 20.0:
					errs.append("상대 %d 단 %d: 시험 칸 폭 %d (한도 1216) 높이 %d" % [n, index + 1, int(grid_size.x), int(grid_size.y)])
			var head := select.get("_head") as Control
			if head != null and head.get_combined_minimum_size().x > 1216.0:
				errs.append("상대 %d 단 %d: 제목 줄 폭 %d (한도 1216)" % [n, index + 1, int(head.get_combined_minimum_size().x)])
	# 가장 높은 단을 고른 채 단이 적은 상대로 가면 그 상대의 마지막 단이 보이고 고른 값은 남는다.
	var most := 0
	for opp in opponents:
		most = maxi(most, opp.tier_count())
	SelectScript._style_tier = most - 1
	for n in opponents.size():
		if opponents[n].tier_count() < most:
			select.call("pick_opponent", n)
			var short_pick := select.find_child("StyleTierPick", true, false) as OptionButton
			if short_pick == null or short_pick.selected != opponents[n].tier_count() - 1 or SelectScript._style_tier != most - 1:
				errs.append("상대 %d: %d단을 고른 채 가면 마지막 단이 보이고 값이 남아야 한다" % [n, most])
	# 의뢰 카드의 판은 1단이다.
	for commission in CommissionLibrary.load_tree("res://data/commissions"):
		if commission.opponent != null and FIRST_TIER_SIZES.has(commission.opponent.resource_path) \
				and commission.opponent.attacks.size() != FIRST_TIER_SIZES[commission.opponent.resource_path]:
			errs.append("%s의 상대 공격이 1단이 아니다" % commission.client_name)
	select.free()
	SelectScript._style_tier = 0
	SelectScript._picked_opponent = 0
	return errs


# ================================================================ T116 새 길이 돈다

func _find_or_note(errs: Array[String], attacks: Array, attack_name: String, label: String) -> AttackData:
	var atk := _find(attacks, attack_name)
	if atk == null:
		errs.append("%s: '%s'가 마지막 단에 없다" % [label, attack_name])
	return atk


## 이름이 같은 길 가운데 조건에 맞는 첫 길(없으면 null). 변주를 뗀 사본이 아니라 원본 길이다.
func _route_where(attacks: Array, attack_name: String, want_chain: int, vertical: bool) -> AttackData:
	for atk: AttackData in attacks:
		if atk.attack_name != attack_name:
			continue
		for route in _routes(atk):
			if route.chain.size() != want_chain:
				continue
			var all_same := true
			for s in _strike_list(route):
				all_same = all_same and s.direction == route.direction
			if all_same == vertical:
				return route
	return null


func _lines(core: DuelCore) -> Array[String]:
	var out: Array[String] = []
	for ev: Dictionary in core.record.events:
		var line := "%s %.4f" % [str(ev["type"]), float(ev.get("t", -1.0))]
		if ev.has("result"):
			line += " r%s" % str(ev["result"])
		if ev.get("attack") is AttackData:
			line += " " + (ev["attack"] as AttackData).attack_name
		out.append(line)
	return out


func t116_new_routes() -> String:
	var errs: Array[String] = []
	var SR := DT.StrikeResult
	var bartolo := load(BARTOLO_PATH) as OpponentData
	var bruno := load(BRUNO_PATH) as OpponentData
	var lorenzo := load(LORENZO_PATH) as OpponentData
	var all_parry := _mode(&"parry")

	# (가) 네 번 베기: 넷을 다 막으면 빈틈이 열리고(패리면 덤), 셋째에서 틀리면 그 한 번만 맞고 끝난다.
	var four_source := _find_or_note(errs, _last_attacks(bartolo), "네 번 베기", "바르톨로")
	if four_source != null:
		var four := _solo(four_source)
		var blocked := _play(_drill_opp(bartolo, four), {}, _stop_strikes(4), 30.0)
		var strikes := blocked.record.of_type(DuelRecord.STRIKE)
		if not _is(strikes, [SR.BLOCKED, SR.BLOCKED, SR.BLOCKED, SR.BLOCKED]):
			errs.append("[네 번 베기·막기] 결과 %s" % _result_text(strikes))
		elif absf(float(strikes[3]["recovery"]) - four.recovery_time) > 0.01 or not blocked.brain.wide_open:
			errs.append("[네 번 베기·막기] 마지막 빈틈 %.2f (기대 %.2f) · 크게 열림 %s" % [strikes[3]["recovery"], four.recovery_time, blocked.brain.wide_open])
		var parried := _play(_drill_opp(bartolo, four), {"guard_fn": all_parry}, _stop_strikes(4), 30.0)
		strikes = parried.record.of_type(DuelRecord.STRIKE)
		var want_parry := four.recovery_time + bartolo.parried_recovery_bonus
		if not _is(strikes, [SR.PARRIED, SR.PARRIED, SR.PARRIED, SR.PARRIED]):
			errs.append("[네 번 베기·패리] 결과 %s" % _result_text(strikes))
		elif absf(float(strikes[3]["recovery"]) - want_parry) > 0.01:
			errs.append("[네 번 베기·패리] 마지막 빈틈 %.2f (기대 %.2f)" % [strikes[3]["recovery"], want_parry])
		var wrong_third := func(_a: AttackData, index: int) -> StringName: return &"wrong" if index == 2 else &"hold"
		# 셋째의 판정 뒤 0.9초까지 더 본다: 넷째가 올 자리(0.65초)가 지나도 안 오면 패턴이 끝난 것이다.
		var after_third := func(core: DuelCore) -> bool:
			var seen := core.record.of_type(DuelRecord.STRIKE)
			return seen.size() >= 3 and core.time >= float(seen[2]["t"]) + 0.9
		var missed := _play(_drill_opp(bartolo, four), {"step_fn": wrong_third}, after_third, 30.0)
		strikes = missed.record.of_type(DuelRecord.STRIKE)
		if not _is(strikes, [SR.BLOCKED, SR.BLOCKED, SR.GRAZE]):
			errs.append("[네 번 베기·셋째를 놓침] 결과 %s (기대 막힘 막힘 스침에서 끝)" % _result_text(strikes))

	# (나) 4점과 세로 휩쓸기: 쥐고 끌면 막히고, 높이를 안 옮기면 뚫리고, 떼었다 누르면 그 점에서 뚫린다.
	var sweep_list := _last_attacks(bruno)
	var four_points := _route_where(sweep_list, "휩쓸기", 3, false)
	var vertical := _route_where(sweep_list, "휩쓸기", 2, true)
	if four_points == null or vertical == null:
		errs.append("브루노의 마지막 단에 4점 휩쓸기(%s)나 세로 휩쓸기(%s)가 없다" % [four_points != null, vertical != null])
	else:
		var held := _play(_drill_opp(bruno, _solo(four_points)), {}, _stop_strikes(4), 30.0)
		var strikes := held.record.of_type(DuelRecord.STRIKE)
		if not _is(strikes, [SR.BLOCKED, SR.BLOCKED, SR.BLOCKED, SR.BLOCKED]) or not held.brain.wide_open \
				or absf(float(strikes[strikes.size() - 1]["recovery"]) - four_points.recovery_time) > 0.01:
			errs.append("[4점·쥐고 끌기] 결과 %s · 크게 열림 %s" % [_result_text(strikes), held.brain.wide_open])
		var lifted := _play(_drill_opp(bruno, _solo(four_points)), {"guard_fn": all_parry}, _stop_strikes(2), 30.0)
		strikes = lifted.record.of_type(DuelRecord.STRIKE)
		if not _is(strikes, [SR.BLOCKED, SR.GRAZE]):
			errs.append("[4점·떼었다 누름] 결과 %s (기대 막힘 뒤 스침)" % _result_text(strikes))
		var down := _play(_drill_opp(bruno, _solo(vertical)), {}, _stop_strikes(3), 30.0)
		strikes = down.record.of_type(DuelRecord.STRIKE)
		if not _is(strikes, [SR.BLOCKED, SR.BLOCKED, SR.BLOCKED]) or not down.brain.wide_open:
			errs.append("[세로·쥐고 끌기] 결과 %s · 크게 열림 %s" % [_result_text(strikes), down.brain.wide_open])
		# 걸음에서 막기를 옮기지 않는다(&"stay"는 알 수 없는 모드라 봇이 아무것도 하지 않는다): 방향이 같아도 높이가 틀려 뚫린다.
		var stayed := _play(_drill_opp(bruno, _solo(vertical)), {"step_fn": _mode(&"stay")}, _stop_strikes(2), 30.0)
		strikes = stayed.record.of_type(DuelRecord.STRIKE)
		if not _is(strikes, [SR.BLOCKED, SR.GRAZE]):
			errs.append("[세로·높이를 안 옮김] 결과 %s (기대 막힘 뒤 스침)" % _result_text(strikes))
		var vertical_lifted := _play(_drill_opp(bruno, _solo(vertical)), {"guard_fn": all_parry}, _stop_strikes(2), 30.0)
		strikes = vertical_lifted.record.of_type(DuelRecord.STRIKE)
		if not _is(strikes, [SR.BLOCKED, SR.GRAZE]):
			errs.append("[세로·떼었다 누름] 결과 %s (기대 막힘 뒤 스침)" % _result_text(strikes))

	# (다) 뛰어들어 한 번 더: 한 걸음이면 다시 밀착, 두 걸음이면 멀리에서 헛침, 처음부터 물러서면 둘째가 없다.
	_dive_again_checks(errs, lorenzo)

	# (라) 겹찌르기와 찌르고 베기: 끝이 찌르기면 빈틈 0(패리면 덤), 끝이 베기면 0.55.
	for opp in [bartolo, bruno, lorenzo]:
		var name_text: String = opp.display_name
		var double_source := _find_or_note(errs, _last_attacks(opp), "겹찌르기", name_text)
		if double_source != null:
			var double := _solo(double_source)
			var strikes := _play(_drill_opp(opp, double), {}, _stop_strikes(2), 30.0).record.of_type(DuelRecord.STRIKE)
			if not _is(strikes, [SR.BLOCKED, SR.BLOCKED]) or absf(float(strikes[1]["recovery"])) > 0.01:
				errs.append("[%s 겹찌르기·막기] 결과 %s · 마지막 빈틈 %s (기대 막힘 둘 · 0)" % [name_text, _result_text(strikes), str(strikes[1]["recovery"]) if strikes.size() > 1 else "-"])
			strikes = _play(_drill_opp(opp, double), {"guard_fn": all_parry}, _stop_strikes(2), 30.0).record.of_type(DuelRecord.STRIKE)
			if not _is(strikes, [SR.PARRIED, SR.PARRIED]) or absf(float(strikes[1]["recovery"]) - opp.parried_recovery_bonus) > 0.01:
				errs.append("[%s 겹찌르기·패리] 결과 %s · 마지막 빈틈 %s (기대 패리 둘 · %.2f)" % [name_text, _result_text(strikes),
					str(strikes[1]["recovery"]) if strikes.size() > 1 else "-", opp.parried_recovery_bonus])
		var slash_source := _find_or_note(errs, _last_attacks(opp), "찌르고 베기", name_text)
		if slash_source != null:
			var slash := _solo(slash_source)
			var strikes := _play(_drill_opp(opp, slash), {}, _stop_strikes(2), 30.0).record.of_type(DuelRecord.STRIKE)
			if not _is(strikes, [SR.BLOCKED, SR.BLOCKED]) or absf(float(strikes[1]["recovery"]) - 0.55) > 0.01:
				errs.append("[%s 찌르고 베기·막기] 결과 %s · 마지막 빈틈 %s (기대 막힘 둘 · 0.55)" % [name_text, _result_text(strikes), str(strikes[1]["recovery"]) if strikes.size() > 1 else "-"])

	# (마)(바) 마지막 단: 같은 씨앗이면 같은 이벤트 줄, 봇이 한 판을 끝낸다. 빈틈의 확률은 끈 사본이다.
	for opp in [bartolo, bruno, lorenzo]:
		var name_text: String = opp.display_name
		var first_run := _play(opp.at_tier(opp.tiers.size()).with_opening(1.0), {}, _never(), 40.0)
		var second_run := _play(opp.at_tier(opp.tiers.size()).with_opening(1.0), {}, _never(), 40.0)
		var first_lines := _lines(first_run)
		if first_lines.size() < 5 or first_lines != _lines(second_run):
			errs.append("%s 마지막 단: 같은 씨앗의 이벤트 줄이 다르다 (%d줄 · %d줄)" % [name_text, first_lines.size(), _lines(second_run).size()])
		var full := _play(opp.at_tier(opp.tiers.size()).with_opening(1.0), Bot.first_blood_cfg(), _never(), 100.0)
		if not full.ended or full.record.of_type(DuelRecord.TELL_START).is_empty():
			errs.append("%s 마지막 단: 봇의 한 판이 끝나지 않았다 (시각 %.1f)" % [name_text, full.time])
	return _ok(errs)


## 로렌초 마지막 단의 "뛰어들어 한 번 더"(찌르기가 이어진다). 걸음은 첫 타격 이벤트를 받은 그 틱에 낸다.
func _dive_again_checks(errs: Array[String], lorenzo: OpponentData) -> void:
	var SR := DT.StrikeResult
	var dive_source := _find_or_note(errs, _last_attacks(lorenzo), "뛰어드는 찌르기", "로렌초")
	if dive_source == null:
		return
	var again: AttackData = null
	for route in _routes(dive_source):
		if route.dive and route.chain.size() == 1 and route.recovery_time > 1.9:
			again = route
			break
	if again == null:
		errs.append("로렌초의 마지막 단에 '뛰어들어 한 번 더'(뛰어들기 + 걸음 하나, 회수 2.0)가 없다")
		return
	var step_tell: float = (again.chain[0] as AttackData).tell_time
	var whiff_recovery := again.recovery_time * lorenzo.whiff_recovery_multiplier
	var drill := _drill_opp(lorenzo, _solo(again))
	# 막기만: 첫 타격이 밀착으로 밀고 들어오고 step_tell 뒤 둘째가 막힌다. 빈틈 2.0, 밀착 그대로.
	var blocked := _play(drill, {}, _stop_strikes(2), 30.0)
	var strikes := blocked.record.of_type(DuelRecord.STRIKE)
	if not _is(strikes, [SR.BLOCKED, SR.BLOCKED]):
		errs.append("[한 번 더·막기] 결과 %s" % _result_text(strikes))
	else:
		if absf(float(strikes[1]["t"]) - float(strikes[0]["t"]) - step_tell) > 0.01:
			errs.append("[한 번 더·막기] 둘째까지 %.3f초 (기대 %.2f)" % [float(strikes[1]["t"]) - float(strikes[0]["t"]), step_tell])
		if absf(float(strikes[1]["recovery"]) - again.recovery_time) > 0.01 or blocked.distance != DT.Distance.CLOSE or _dives(blocked).size() != 1:
			errs.append("[한 번 더·막기] 빈틈 %.2f (기대 %.2f) · 간격 %d (기대 밀착) · 뛰어들기 이동 %d번 (기대 1)" % [
				strikes[1]["recovery"], again.recovery_time, blocked.distance, _dives(blocked).size()])
	# 한 걸음·두 걸음: 첫 타격을 막은 틱에 막기를 풀고 물러선다. 걸음이 끝난 틱에 다음 걸음(두 걸음)이나 막기(한 걸음)를 낸다.
	for steps_back in [1, 2]:
		var state := [0, steps_back]
		var move := func(core: DuelCore) -> void:
			if state[0] == 0 and not core.record.of_type(DuelRecord.STRIKE).is_empty():
				core.set_guard(false)
				core.step(-1)
				state[0] = 1
				state[1] -= 1
			elif state[0] == 1 and core.player_state == DT.PlayerState.READY:
				if state[1] > 0:
					core.step(-1)
					state[1] -= 1
				else:
					core.set_guard(true)
					state[0] = 2
		var moved := _play(drill, {}, _stop_strikes(2), 30.0, move)
		strikes = moved.record.of_type(DuelRecord.STRIKE)
		var dives := _dives(moved)
		if strikes.size() != 2:
			errs.append("[한 번 더·%d걸음] 타격 %d개 (기대 2)" % [steps_back, strikes.size()])
			continue
		if steps_back == 1:
			# 교전에서 둘째를 받는다: 닿지 않은 헛침이 아니고, 다시 밀착으로 밀고 든다.
			if int(strikes[1]["result"]) == SR.WHIFF or dives.size() != 2 or moved.distance != DT.Distance.CLOSE:
				errs.append("[한 번 더·한 걸음] 둘째 %s · 뛰어들기 이동 %d번 · 간격 %d (기대 헛침 아님 · 2번 · 밀착)" % [
					str(strikes[1]["result"]), dives.size(), moved.distance])
		else:
			# 멀리에서 헛침: 빈틈 굴림(확률을 끈 사본이라 열린다)이고 교전으로 떨어진다.
			if int(strikes[1]["result"]) != SR.WHIFF or absf(float(strikes[1]["recovery"]) - whiff_recovery) > 0.01 \
					or dives.size() != 2 or dives[1]["distance"] != DT.Distance.ENGAGE:
				errs.append("[한 번 더·두 걸음] 둘째 %s · 빈틈 %.2f (기대 헛침 · %.2f) · 뛰어들기 이동 %d번 (기대 2번 · 마지막 교전)" % [
					str(strikes[1]["result"]), float(strikes[1]["recovery"]), whiff_recovery, dives.size()])
	# 처음부터 물러서면 헛침으로 끝나고 둘째는 없다.
	var away := _play(drill, {"guard_fn": _mode(&"retreat")}, _never(), 4.2)
	strikes = away.record.of_type(DuelRecord.STRIKE)
	if not _is(strikes, [SR.WHIFF]) or not away.record.of_type(DuelRecord.PATTERN_STEP).is_empty():
		errs.append("[한 번 더·처음부터 물러섬] 결과 %s · 걸음 %d개 (기대 헛침 하나 · 걸음 없음)" % [_result_text(strikes), away.record.of_type(DuelRecord.PATTERN_STEP).size()])
