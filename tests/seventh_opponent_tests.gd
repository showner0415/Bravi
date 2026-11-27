extends RefCounted
## T141~T144: 일곱째 상대 굴리엘모(계획 045, 결정 697~715 · T144는 계획 045b의 그림). 데이터의 틀·치고 빠지는 길의 표·가방, 치고 빠지기의 판, 표시와 연습 화면.
## 값(길의 칸·간격·빈틈·단·가방·가중치)은 결정 705·706·707의 표를 손으로 적은 기대다. 로드한 자원은 고치지 않는다(사본만).
## 결정 709의 고치는 차례가 옮길 수 있는 값(찌르기의 가중치·좌우 베기의 빈틈·치고 빠지기의 가중치·빠지는 길의 빈틈·서는 길)은 아래 상수와 표가 함께 옮기는 기대다.
## 도우미는 sixth_opponent_tests.gd의 것을 옮겨 썼다(그 파일은 고치지 않는다. fourth_opponent_tests.gd의 도우미는 sixth와 같이 빌린다).
## States.put으로 놓은 코어에는 advance · tick을 부르지 않는다. 판은 처음부터 tick으로 몰고(_play), 표시의 정적 함수는 tick 없이 부른다.

const Fourth := preload("res://tests/fourth_opponent_tests.gd")
const Bot := preload("res://tests/duel_bots.gd")
const DT := preload("res://scripts/duel/duel_types.gd")
const Controls := preload("res://scripts/controls.gd")
const SelectScript := preload("res://scripts/commission/commission_select.gd")
const Session := preload("res://scripts/game_session.gd")

const GUGLIELMO_PATH := "res://data/opponents/opponent_07.tres"
const BARTOLO_PATH := "res://data/opponents/opponent_01.tres"
const BRUNO_PATH := "res://data/opponents/opponent_02.tres"
const LORENZO_PATH := "res://data/opponents/opponent_03.tres"
const SERAFINA_PATH := "res://data/opponents/opponent_04.tres"
const AGOSTINO_PATH := "res://data/opponents/opponent_05.tres"
const BEATRICE_PATH := "res://data/opponents/opponent_06.tres"
const COMMISSION_DIR := "res://data/commissions"
const STYLE_NAME := "치고 빠지기"
## 고유 색(결정 704): 빵 껍질빛.
const SIG_COLOR := Color(0.6, 0.38, 0.12, 1.0)
const FROM_DAYS: Array[int] = [8, 10, 12, 14, 16]
## 뿌리의 값(결정 706 — 모든 길과 단에서 같다). 결정 709의 값 고침(치고 빠지기의 가중치 2 → 3)이 옮길 수 있다.
const ROOT_TELL := 0.9
const ROOT_WEIGHT := 2.0
## 두 틱 + 여유: 타격 사이의 간격은 판정 틱에 얹힌다.
const TIME_TOL := 0.04
## 기본 셋(결정 705). 결정 709의 값 고침(찌르기의 가중치 3 → 2, 좌우 베기의 빈틈 0.55 → 0.75)이 옮길 수 있다.
const THRUST_WEIGHT := 3.0
const CUT_RECOVERY := 0.55
## 가방(결정 707): 찌르기 + 좌우 베기 둘 + 치고 빠지기 + 3단의 겹찌르기 + 5단의 찌르고 베기. 위 가중치를 옮기면 함께 옮긴다.
const BAG_SIZES: Array[int] = [7, 7, 8, 8, 9, 9]
## 길 끝의 빈틈: 빠지는 길 1.3(결정 709 ②가 1.5로 옮길 수 있다 — 이 상수 하나), 서는 길 0.55.
const WITHDRAW_RECOVERY := 1.3
const STAND_RECOVERY := 0.55

## 기본 셋: 이름 -> [방향, 높이 묶음]. 예비는 바르톨로와 같다(결정 705).
const BASIC_DIRECTIONS := {"찌르기": 1, "왼쪽 베기": 0, "오른쪽 베기": 2}
const BASIC_HEIGHTS := {"찌르기": [1, 2], "왼쪽 베기": [1], "오른쪽 베기": [1]}
## 길의 표(결정 706). 이름 -> [빠지는가, 길 끝의 빈틈, [[방향 0 왼 · 1 가 · 2 오, 높이 묶음 0 상 · 1 중 · 2 하, 그 타격 앞의 간격], …]].
const ROUTE_SPECS := {
	"한 번 찍기": [true, WITHDRAW_RECOVERY, [[0, [0, 2], 0.9]]],
	"반대로 찍기": [true, WITHDRAW_RECOVERY, [[2, [0, 2], 0.9]]],
	"두 번 찍기": [true, WITHDRAW_RECOVERY, [[0, [0, 2], 0.9], [2, [0, 2], 0.55]]],
	"서서 받기": [false, STAND_RECOVERY, [[1, [0, 2], 0.9]]],
	"세 번 찍기": [true, WITHDRAW_RECOVERY, [[0, [0], 0.9], [2, [2], 0.55], [1, [1, 2], 0.6]]],
	"네 번 찍기": [true, WITHDRAW_RECOVERY, [[2, [0], 0.9], [0, [2], 0.55], [2, [2], 0.6], [1, [0, 2], 0.55]]],
}
## 단마다의 길(변주까지). 3단은 2단과, 5단은 4단과 같다.
const TIER_ROUTES := [
	["한 번 찍기", "반대로 찍기"],
	["한 번 찍기", "반대로 찍기", "두 번 찍기", "서서 받기"],
	["한 번 찍기", "반대로 찍기", "두 번 찍기", "서서 받기"],
	["한 번 찍기", "반대로 찍기", "두 번 찍기", "서서 받기", "세 번 찍기"],
	["한 번 찍기", "반대로 찍기", "두 번 찍기", "서서 받기", "세 번 찍기"],
	["한 번 찍기", "반대로 찍기", "두 번 찍기", "서서 받기", "세 번 찍기", "네 번 찍기"],
]
const TIER_NAMES := [
	["찌르기", "왼쪽 베기", "오른쪽 베기", "치고 빠지기"],
	["찌르기", "왼쪽 베기", "오른쪽 베기", "치고 빠지기"],
	["찌르기", "왼쪽 베기", "오른쪽 베기", "치고 빠지기", "겹찌르기"],
	["찌르기", "왼쪽 베기", "오른쪽 베기", "치고 빠지기", "겹찌르기"],
	["찌르기", "왼쪽 베기", "오른쪽 베기", "치고 빠지기", "겹찌르기", "찌르고 베기"],
	["찌르기", "왼쪽 베기", "오른쪽 베기", "치고 빠지기", "겹찌르기", "찌르고 베기"],
]

var _tree: SceneTree
var _f: Fourth = Fourth.new()
var _select: Node = null


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T141", "name": "일곱째 상대: 판정 값이 바르톨로와 같다, 기본 셋의 높이, 치고 빠지는 길의 표(방향·높이·간격·빠짐·빈틈)와 단·가방, 고유 색 하나, 하루에는 서지 않는다, 갈래 글", "fn": t141_seventh_opponent},
		{"id": "T142", "name": "치고 빠지기의 판: 빠지는 길은 한 번 물러나 따라붙어야 닿고 서는 길은 그 자리에서 닿는다, 타격의 시각, 꺾쇠의 열쇠, 같은 씨앗, 봇의 한 판, 실제 굴리엘모", "fn": t142_withdraw_duel},
		{"id": "T143", "name": "표시와 연습 화면: 단발·두 번·서는 길의 꺾쇠, 첫 줄·귀띔, 여섯 상대는 그대로, 결투 중 도움말, 연습의 둘째 쪽과 막는 법", "fn": t143_marks_and_practice},
		{"id": "T144", "name": "그림 데이터: 스물한 장과 팔 셋, 모자 없는 꼭대기·머리 가운데의 자·모자 쓴 꼭대기·발끝, 다리 관절·다리 폭·몸통 폭(달걀), 의뢰인 그림", "fn": t144_guglielmo_art},
	]


func cleanup() -> void:
	_free_select()
	_tree = null


# ================================================================ 도우미

func _ok(errs: Array[String]) -> String:
	return "OK" if errs.is_empty() else ", ".join(errs)


func _near(a: float, b: float) -> bool:
	return absf(a - b) <= 0.001


func _free_select() -> void:
	if _select != null and is_instance_valid(_select):
		if _select.get_parent() != null:
			_select.get_parent().remove_child(_select)
		_select.free()
	_select = null
	_f._reset_statics()


## 표의 길 하나의 열쇠: 타격마다 "방향/높이들@간격"을 ">"로 잇고 빠지는 길이면 앞에 "^"를 붙인다.
func _spec_key(spec: Array) -> String:
	var parts := PackedStringArray()
	for row: Array in (spec[2] as Array):
		var heights := ""
		for h: int in (row[1] as Array):
			heights += str(h)
		parts.append("%d/%s@%.2f" % [int(row[0]), heights, float(row[2])])
	return ("^" if bool(spec[0]) else "") + ">".join(parts)


## 데이터의 길의 열쇠(_spec_key와 같은 꼴).
func _data_key(route: AttackData) -> String:
	var parts := PackedStringArray()
	for strike in _f._strike_list(route):
		var heights := ""
		for h: int in strike.heights:
			heights += str(h)
		parts.append("%d/%s@%.2f" % [int(strike.direction), heights, strike.tell_time])
	return ("^" if route.withdraw else "") + ">".join(parts)


func _names_by_key() -> Dictionary:
	var out := {}
	for route_name: String in ROUTE_SPECS:
		out[_spec_key(ROUTE_SPECS[route_name])] = route_name
	return out


## 모든 단의 고유 공격에서 길(뿌리 + 변주)을 한 번씩만(같은 자원은 한 번) 모은다.
func _distinct_routes(lists: Array) -> Array[AttackData]:
	var out: Array[AttackData] = []
	var seen := {}
	for attacks: Array in lists:
		var roots: Array[AttackData] = _f._signature_roots(attacks)
		for root in roots:
			var routes: Array[AttackData] = _f._routes(root)
			for route in routes:
				if seen.has(route.get_instance_id()):
					continue
				seen[route.get_instance_id()] = true
				out.append(route)
	return out


func _route_named(routes: Array[AttackData], route_name: String) -> AttackData:
	var names := _names_by_key()
	for route in routes:
		var found: String = names.get(_data_key(route), "")
		if found == route_name:
			return route
	return null


func _all_blocked(count: int) -> Array:
	var out: Array = []
	for i in count:
		out.append(DT.StrikeResult.BLOCKED)
	return out


func _chain_events(core: DuelCore) -> Array[Dictionary]:
	return core.record.of_type(DuelRecord.STRIKE)


func _stop_at_step(step: int) -> Callable:
	return func(core: DuelCore) -> bool:
		return core.brain.state == DT.OpponentState.TELL and core.brain.pattern_root != null and core.brain.step_index == step


func _attacks_reached(count: int) -> Callable:
	return func(core: DuelCore) -> bool: return core.record.of_type(DuelRecord.ATTACK).size() >= count


## by가 같은 DISTANCE 이벤트.
func _hops(core: DuelCore, by: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for ev in core.record.of_type(DuelRecord.DISTANCE):
		if ev.get("by", "") == by:
			out.append(ev)
	return out


## t보다 늦게 시작한 걸음의 수.
func _steps_after(core: DuelCore, t: float) -> int:
	var count := 0
	for ev in core.record.of_type(DuelRecord.STEP_START):
		if float(ev["t"]) > t:
			count += 1
	return count


## 그 길 하나만 되풀이하는 상대의 예비 동작이 막 시작된 뇌(표시의 정적 함수가 읽는다).
func _tell_brain(opp: OpponentData, route: AttackData) -> OpponentBrain:
	var brain := OpponentBrain.new(_f._drill_opp(opp, route), _f._seeded())
	brain.start_idle(0.0)
	brain.start_tell(0.0, false)
	return brain


## 그 뇌의 번호 고리들(길 표시는 뺀다).
func _marks_of(brain: OpponentBrain, display_time: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if brain.state != DT.OpponentState.TELL:
		return out
	for mark in OpponentView.pattern_marks(brain, display_time):
		if mark["role"] != &"path":
			out.append(mark)
	return out


# ================================================================ T141 데이터

func t141_seventh_opponent() -> String:
	var errs: Array[String] = []
	var bartolo := load(BARTOLO_PATH) as OpponentData
	var gul := load(GUGLIELMO_PATH) as OpponentData
	# ① 로드, 이름, 갈래 이름, 칼 든 팔, 그림.
	if gul == null or bartolo == null:
		return "opponent_07.tres나 opponent_01.tres가 로드되지 않는다"
	if gul.display_name != "굴리엘모" or gul.style_name != STYLE_NAME:
		errs.append("이름 '%s' · 갈래 '%s'" % [gul.display_name, gul.style_name])
	if gul.sword_side != DT.Direction.LEFT:
		errs.append("칼 든 팔이 왼쪽이 아니다 (%d)" % gul.sword_side)
	if gul.art == null:
		errs.append("그림 데이터(art)가 비었다")
	# ② 바르톨로와 견준다: 이름·그림·포즈 아홉과 공격 목록·갈래 이름·단만 다르다(결정 699).
	_f._compare(bartolo, gul, "opponent", errs, Fourth.FREE_FIELDS + ["attacks"] + Fourth.SWORD_FIELDS)
	# ③ 1단의 기본 셋.
	_check_basics(errs, gul, bartolo)
	# ④ 단마다의 길과 단 · 고유 색.
	_check_tiers(errs, gul, bartolo)
	# ⑤ 가방의 장 수.
	for k in gul.tier_count():
		var brain := OpponentBrain.new(gul.at_tier(k), _f._seeded())
		brain.start_idle(0.0)
		brain.start_tell(0.0, false)
		var cards: int = brain.bag_remaining() + 1
		if k >= BAG_SIZES.size() or cards != BAG_SIZES[k]:
			errs.append("%d단의 가방 %d장 (기대 %s)" % [k + 1, cards, str(BAG_SIZES[k]) if k < BAG_SIZES.size() else "없음"])
	# ⑥ 어느 의뢰도 굴리엘모를 걸지 않는다(결정 712).
	var users: Array[String] = []
	for commission in CommissionLibrary.load_tree(COMMISSION_DIR):
		if commission.opponent != null and commission.opponent.resource_path == GUGLIELMO_PATH:
			users.append(commission.resource_path.get_file())
	if not users.is_empty():
		errs.append("굴리엘모를 거는 의뢰 %s (기대 없음)" % str(users))
	# ⑦ 갈래 글: 처음 서는 날 앞뒤와 단이 오르는 날, 마지막 단 뒤.
	if gul.style_label(7) != "굴리엘모 · 치고 빠지기":
		errs.append("style_label(7) '%s' (기대 '굴리엘모 · 치고 빠지기')" % gul.style_label(7))
	for i in FROM_DAYS.size():
		var want := "굴리엘모 · 치고 빠지기 %d단" % (i + 2)
		if gul.style_label(FROM_DAYS[i]) != want:
			errs.append("style_label(%d) '%s' (기대 '%s')" % [FROM_DAYS[i], gul.style_label(FROM_DAYS[i]), want])
	if gul.style_label(20) != "굴리엘모 · 치고 빠지기 6단":
		errs.append("style_label(20) '%s' (기대 마지막 단 6단에 머문다)" % gul.style_label(20))
	return _ok(errs)


## 1단: 공격 넷(찌르기 · 좌우 베기 · 치고 빠지기). 방향 · 예비는 바르톨로와 같고 높이는 가운데 줄이다(결정 705). 가중치와 베기의 빈틈은 위 상수다.
func _check_basics(errs: Array[String], gul: OpponentData, bartolo: OpponentData) -> void:
	if gul.attacks.size() != 4:
		errs.append("1단의 공격 %d개 (기대 4)" % gul.attacks.size())
		return
	for attack_name: String in BASIC_DIRECTIONS:
		var mine: AttackData = _f._find_named(gul.attacks, attack_name)
		var his: AttackData = _f._find_named(bartolo.attacks, attack_name)
		if mine == null or his == null:
			errs.append("1단에 %s가 없다 (굴리엘모 %s · 바르톨로 %s)" % [attack_name, mine != null, his != null])
			continue
		var want_recovery: float = his.recovery_time if attack_name == "찌르기" else CUT_RECOVERY
		var want_weight: float = THRUST_WEIGHT if attack_name == "찌르기" else 1.0
		if int(mine.direction) != int(BASIC_DIRECTIONS[attack_name]) or mine.direction != his.direction \
				or not _near(mine.tell_time, his.tell_time) or not _near(mine.recovery_time, want_recovery):
			errs.append("%s: 방향 %d · 예비 %.2f · 빈틈 %.2f (기대 %d · %.2f · %.2f)" % [
				attack_name, mine.direction, mine.tell_time, mine.recovery_time, int(BASIC_DIRECTIONS[attack_name]), his.tell_time, want_recovery])
		if not is_equal_approx(mine.weight, want_weight):
			errs.append("%s의 가중치 %.1f (기대 %.1f)" % [attack_name, mine.weight, want_weight])
		if str(mine.heights) != str(BASIC_HEIGHTS[attack_name]):
			errs.append("%s의 높이 묶음 %s (기대 %s)" % [attack_name, str(mine.heights), str(BASIC_HEIGHTS[attack_name])])
		if not mine.chain.is_empty() or mine.signature or mine.is_big or mine.sweep or mine.dive or mine.needs_raised_guard or mine.feint or mine.withdraw:
			errs.append("%s: 걸음 %d · 고유 %s · 큰 공격 %s · 휩쓸기 %s · 뛰어들기 %s · 올려 막기 %s · 헛손질 %s · 빠짐 %s (기대 모두 없음)" % [
				attack_name, mine.chain.size(), mine.signature, mine.is_big, mine.sweep, mine.dive, mine.needs_raised_guard, mine.feint, mine.withdraw])
	if gul.tiers.size() != FROM_DAYS.size():
		errs.append("단 %d개 (기대 %d)" % [gul.tiers.size(), FROM_DAYS.size()])
	else:
		for i in gul.tiers.size():
			if gul.tiers[i].from_day != FROM_DAYS[i]:
				errs.append("%d단의 from_day %d (기대 %d)" % [i + 2, gul.tiers[i].from_day, FROM_DAYS[i]])
	if gul.habits.size() != bartolo.habits.size():
		errs.append("버릇 %d개 (바르톨로 %d개)" % [gul.habits.size(), bartolo.habits.size()])


## 단마다: 공격 이름의 목록, 고유 공격 하나, 길의 열쇠(표와 같은 길 · 같은 간격 · 같은 빠짐), 3 · 5단의 뿌리 · 겹찌르기와 찌르고 베기, 고유 색 하나.
func _check_tiers(errs: Array[String], gul: OpponentData, bartolo: OpponentData) -> void:
	var lists: Array = _f._tier_lists(gul)
	if lists.size() != TIER_ROUTES.size():
		errs.append("단 %d개 (기대 %d)" % [lists.size(), TIER_ROUTES.size()])
		return
	var colors: Array[Color] = []
	var group_root: Array[AttackData] = []
	for k in lists.size():
		var attacks: Array = lists[k]
		var names: Array[String] = []
		for atk: AttackData in attacks:
			names.append(atk.attack_name)
		if str(names) != str(TIER_NAMES[k]):
			errs.append("%d단의 공격 %s (기대 %s)" % [k + 1, str(names), str(TIER_NAMES[k])])
		var roots: Array[AttackData] = _f._signature_roots(attacks)
		if roots.size() != 1:
			errs.append("%d단의 고유 공격 %d개 (기대 1)" % [k + 1, roots.size()])
			group_root.append(null)
			continue
		group_root.append(roots[0])
		var keys: Array[String] = []
		var routes: Array[AttackData] = _f._routes(roots[0])
		for route in routes:
			keys.append(_check_route(errs, k, route, colors))
		var want_keys: Array[String] = []
		for route_name: String in TIER_ROUTES[k]:
			want_keys.append(_spec_key(ROUTE_SPECS[route_name]))
		want_keys.sort()
		keys.sort()
		if str(keys) != str(want_keys):
			errs.append("%d단의 길 %s (기대 %s)" % [k + 1, str(keys), str(want_keys)])
	# 3단 · 5단은 앞 단의 뿌리를 같은 자원으로 쓴다(한쪽만 고치는 일이 없게).
	for pair: Array in [[2, 1], [4, 3]]:
		if group_root[pair[0]] == null or group_root[pair[0]] != group_root[pair[1]]:
			errs.append("%d단의 고유 공격이 %d단의 것과 같은 자원이 아니다" % [int(pair[0]) + 1, int(pair[1]) + 1])
	# 고유 색은 빵 껍질빛 하나다(모든 타격).
	var distinct := 0
	var seen: Array[Color] = []
	for color in colors:
		var known := false
		for other in seen:
			known = known or color.is_equal_approx(other)
		if not known:
			seen.append(color)
			distinct += 1
	if distinct != 1 or (not seen.is_empty() and not seen[0].is_equal_approx(SIG_COLOR)):
		errs.append("고유 공격의 색 %s (기대 빵 껍질빛 하나 %s)" % [str(seen), str(SIG_COLOR)])
	# 3단의 겹찌르기 · 5단의 찌르고 베기는 바르톨로의 같은 공격이다(예비 · 빈틈 · 가중치). 높이는 그의 기본을 따른다(결정 705).
	_check_composite(errs, lists[2], _f._tier_lists(bartolo)[2], "겹찌르기", [[1, 2], [1, 2]])
	_check_composite(errs, lists[4], _f._tier_lists(bartolo)[4], "찌르고 베기", [[1, 2], [1]])


## want_heights: 길의 타격마다의 높이 묶음(뿌리와 변주 모두).
func _check_composite(errs: Array[String], mine_list: Array, his_list: Array, atk_name: String, want_heights: Array) -> void:
	var mine: AttackData = _f._find_named(mine_list, atk_name)
	var his: AttackData = _f._find_named(his_list, atk_name)
	if mine == null or his == null:
		errs.append("%s가 없다 (굴리엘모 %s · 바르톨로 %s)" % [atk_name, mine != null, his != null])
		return
	if mine.direction != his.direction or not _near(mine.tell_time, his.tell_time) or not _near(mine.recovery_time, his.recovery_time) \
			or not is_equal_approx(mine.weight, his.weight) or mine.chain.size() != his.chain.size() or mine.signature or mine.feint or mine.withdraw:
		errs.append("%s: 방향 %d · 예비 %.2f · 빈틈 %.2f · 가중치 %.1f · 걸음 %d (바르톨로 %d · %.2f · %.2f · %.1f · %d)" % [
			atk_name, mine.direction, mine.tell_time, mine.recovery_time, mine.weight, mine.chain.size(),
			his.direction, his.tell_time, his.recovery_time, his.weight, his.chain.size()])
	var routes: Array[AttackData] = _f._routes(mine)
	for route in routes:
		var strikes: Array[AttackData] = _f._strike_list(route)
		if strikes.size() != want_heights.size():
			errs.append("%s의 타격 %d개 (기대 %d)" % [atk_name, strikes.size(), want_heights.size()])
			continue
		for j in strikes.size():
			if str(strikes[j].heights) != str(want_heights[j]):
				errs.append("%s의 %d번째 타격 높이 묶음 %s (기대 %s)" % [atk_name, j + 1, str(strikes[j].heights), str(want_heights[j])])


## 길 하나(뿌리 또는 변주)를 표와 견주고 열쇠를 돌려준다. 타격의 색은 colors에 모은다.
func _check_route(errs: Array[String], k: int, route: AttackData, colors: Array[Color]) -> String:
	var key := _data_key(route)
	var route_name: String = _names_by_key().get(key, "")
	var label := "%d단 길 %s" % [k + 1, route_name if route_name != "" else key]
	if route_name == "":
		errs.append("%s: 표에 없는 길이다" % label)
		return key
	var spec: Array = ROUTE_SPECS[route_name]
	var rows: Array = spec[2]
	if route.attack_name != STYLE_NAME or route.is_big or route.sweep or route.dive or route.needs_raised_guard or route.feint or route.mark_shape != &"":
		errs.append("%s: 이름 '%s' · 큰 공격 %s · 휩쓸기 %s · 뛰어들기 %s · 올려 막기 %s · 헛손질 %s · 꼴 '%s'" % [
			label, route.attack_name, route.is_big, route.sweep, route.dive, route.needs_raised_guard, route.feint, route.mark_shape])
	if route.withdraw != bool(spec[0]):
		errs.append("%s: 빠짐 %s (기대 %s)" % [label, route.withdraw, bool(spec[0])])
	if not _near(route.tell_time, ROOT_TELL) or not _near(route.recovery_time, float(spec[1])) or not is_equal_approx(route.weight, ROOT_WEIGHT):
		errs.append("%s: 뿌리의 예비 %.2f · 빈틈 %.2f · 가중치 %.1f (기대 %.2f · %.2f · %.1f)" % [label, route.tell_time, route.recovery_time, route.weight, ROOT_TELL, float(spec[1]), ROOT_WEIGHT])
	if route.tell_hint != "":
		errs.append("%s: 귀띔 '%s' (기대 빈 글)" % [label, route.tell_hint])
	var strikes: Array[AttackData] = _f._strike_list(route)
	if strikes.size() != rows.size():
		errs.append("%s: 타격 %d개 (기대 %d)" % [label, strikes.size(), rows.size()])
		return key
	for j in strikes.size():
		var row: Array = rows[j]
		var strike: AttackData = strikes[j]
		colors.append(strike.pose_color)
		if not _near(strike.tell_time, float(row[2])):
			errs.append("%s: %d번째 타격 앞의 간격 %.2f (기대 %.2f)" % [label, j + 1, strike.tell_time, float(row[2])])
		if strike.attack_name != STYLE_NAME or not strike.signature or strike.is_big or strike.sweep or strike.dive or strike.needs_raised_guard or strike.feint:
			errs.append("%s: %d번째 타격의 이름 '%s' · 고유 %s" % [label, j + 1, strike.attack_name, strike.signature])
		if j > 0 and (strike.withdraw or not _near(strike.recovery_time, 0.0)):
			errs.append("%s: %d번째 타격(걸음)의 빠짐 %s · 빈틈 %.2f (기대 거짓 · 0)" % [label, j + 1, strike.withdraw, strike.recovery_time])
	return key


# ================================================================ T142 치고 빠지기의 판

func t142_withdraw_duel() -> String:
	var errs: Array[String] = []
	var gul := load(GUGLIELMO_PATH) as OpponentData
	if gul == null or gul.tiers.size() < 5:
		return "opponent_07.tres가 없거나 단이 여섯이 아니다"
	var routes := _distinct_routes(_f._tier_lists(gul))
	print("  INFO T142 서로 다른 길의 자원 %d개 (표의 길 %d)" % [routes.size(), ROUTE_SPECS.size()])
	# (가)(나) 모든 단의 모든 길.
	for route in routes:
		_t142_route(errs, gul, route)
	# (다)(라)(마) 같은 씨앗, 봇의 한 판, 실제 굴리엘모.
	_t142_runs(errs, gul)
	return _ok(errs)


## 한 길: (가) 키 없는 봇이 모든 타격을 막고 — 빠지는 길이면 DISTANCE by "withdraw" 한 번 뒤 따라붙어 그 빈틈 안에 스침, 서는 길이면 DISTANCE 없이 그 자리에서 스침.
## (나) 타격 시각이 표의 간격, 마지막 고리에만 꺾쇠의 열쇠.
## 빠지는 길의 봇은 반응 0.25초(결정 709 ②의 셈), 서는 길은 반응 0이다(결정 706: 0.55의 빈틈은 반응 0.25초의 손에게 닿지 않는다).
func _t142_route(errs: Array[String], gul: OpponentData, route: AttackData) -> void:
	var key := _data_key(route)
	var route_name: String = _names_by_key().get(key, "")
	if route_name == "":
		errs.append("[%s] 표에 없는 길이다" % key)
		return
	var label := route_name
	var spec: Array = ROUTE_SPECS[route_name]
	var withdraw: bool = bool(spec[0])
	var rows: Array = spec[2]
	var count := rows.size()
	var cfg := Bot.first_blood_cfg()
	if withdraw:
		cfg["counter_delay"] = 0.25
	var opp: OpponentData = _f._drill_opp(gul, _f._solo(route))
	var core: DuelCore = _f._play(opp, cfg, _attacks_reached(1), 40.0)
	var strikes: Array[Dictionary] = core.record.of_type(DuelRecord.STRIKE)
	var attacks: Array[Dictionary] = core.record.of_type(DuelRecord.ATTACK)
	if not _f._is(strikes, _all_blocked(count)):
		errs.append("[가·%s] 결과 %s (기대 막힘 %d번)" % [label, _f._result_text(strikes), count])
		return
	if attacks.is_empty():
		errs.append("[가·%s] 봇이 받아치지 않았다 (시각 %.1f)" % [label, core.time])
		return
	var last: Dictionary = strikes[count - 1]
	var t := float(last["t"])
	var gap := float(last["recovery"])
	if absf(gap - float(spec[1])) > 0.01:
		errs.append("[가·%s] 끝의 빈틈 %.2f (기대 %.2f)" % [label, gap, float(spec[1])])
	var hops := _hops(core, "withdraw")
	if withdraw:
		if hops.size() != 1:
			errs.append("[가·%s] 물러남 %d번 (기대 1)" % [label, hops.size()])
		elif int(hops[0]["distance"]) != DT.Distance.FAR or absf(float(hops[0]["t"]) - t) > 0.000001:
			errs.append("[가·%s] 물러난 간격 %d · 시각 차 %.4f (기대 멀리 · 마지막 타격과 같은 시각)" % [label, int(hops[0]["distance"]), float(hops[0]["t"]) - t])
		if _steps_after(core, t) != 1:
			errs.append("[가·%s] 타격 뒤 걸음 %d번 (기대 1 — 막기를 떼고 따라붙는다)" % [label, _steps_after(core, t)])
	else:
		if not hops.is_empty():
			errs.append("[가·%s] 서는 길이 물러났다 (%d번)" % [label, hops.size()])
		if _steps_after(core, t) != 0 or core.distance == DT.Distance.FAR:
			errs.append("[가·%s] 서는 길 뒤 걸음 %d번 · 간격 %d (기대 0번 · 멀리 아님)" % [label, _steps_after(core, t), core.distance])
	var attack := attacks[0]
	if int(attack["result"]) != DT.AttackResult.GRAZE or float(attack["t"]) >= float(last["recovery_end"]):
		errs.append("[가·%s] 받아치기 결과 %d · 판정 %.2f (기대 스침 · 빈틈 %.2f 안)" % [label, int(attack["result"]), float(attack["t"]), float(last["recovery_end"])])
	for ev in core.record.of_type(DuelRecord.ATTACK_START):
		if bool(ev["rash"]):
			errs.append("[가·%s] 빈틈 안의 공격이 섣부르다" % label)
			break
	_check_times(errs, label, core, rows)
	_check_marks(errs, label, gul, route, withdraw, count)


## (나) 타격 이벤트가 길의 차례와 같고, 앞 타격으로부터 그 걸음의 간격(표) ± 두 틱 뒤에 온다.
func _check_times(errs: Array[String], label: String, core: DuelCore, rows: Array) -> void:
	var events := _chain_events(core)
	if events.size() != rows.size():
		errs.append("[나·%s] 타격 %d개 (기대 %d)" % [label, events.size(), rows.size()])
		return
	for i in range(1, events.size()):
		var want := float((rows[i] as Array)[2])
		var gap := float(events[i]["t"]) - float(events[i - 1]["t"])
		if absf(gap - want) > TIME_TOL:
			errs.append("[나·%s] %d번째와 %d번째 사이 %.3f초 (기대 %.2f ± %.2f)" % [label, i, i + 1, gap, want, TIME_TOL])


## (나) 단발이면 번호 고리가 없고 지금 고리에 꺾쇠(ring_withdraw_of), 이어지는 길이면 고리가 타격 수만큼 뜨고 마지막에만 withdraw 열쇠.
func _check_marks(errs: Array[String], label: String, gul: OpponentData, route: AttackData, withdraw: bool, count: int) -> void:
	var brain := _tell_brain(gul, _f._solo(route))
	if brain.state != DT.OpponentState.TELL:
		errs.append("[나·%s] 표시를 볼 예비 동작이 서지 않았다" % label)
		return
	var marks := _marks_of(brain, 0.0)
	if count == 1:
		if not marks.is_empty() or OpponentView.ring_withdraw_of(brain) != withdraw:
			errs.append("[나·%s] 단발: 고리 %d개 · 꺾쇠 %s (기대 0개 · %s)" % [label, marks.size(), str(OpponentView.ring_withdraw_of(brain)), str(withdraw)])
		return
	if marks.size() != count:
		errs.append("[나·%s] 고리 %d개 (기대 %d)" % [label, marks.size(), count])
		return
	for i in marks.size():
		var want := withdraw and i == count - 1
		if marks[i].has("withdraw") != want or (want and marks[i]["withdraw"] != true):
			errs.append("[나·%s] %d번째 고리의 withdraw 열쇠 %s (기대 %s)" % [label, i + 1, str(marks[i].get("withdraw", "없음")), "참" if want else "없음"])
	if OpponentView.ring_withdraw_of(brain):
		errs.append("[나·%s] 첫 타격의 예비 동작에 꺾쇠가 선다 (기대 거짓 — 마지막 타격에서만)" % label)


## (다) 같은 씨앗이면 마지막 단의 판이 같은 이벤트 줄 (라) 봇의 한 판 (마) 실제 굴리엘모(확률 켬)에서 물러남.
func _t142_runs(errs: Array[String], gul: OpponentData) -> void:
	var last_tier := gul.tier_count() - 1
	var cases: Array = [["키 없는 봇", {}], ["따라붙는 봇", Bot.first_blood_cfg()]]
	for item: Array in cases:
		var cfg: Dictionary = item[1]
		var first_run: DuelCore = _f._play(gul.at_tier(last_tier).with_opening(1.0), cfg, _f._never(), 40.0)
		var second_run: DuelCore = _f._play(gul.at_tier(last_tier).with_opening(1.0), cfg, _f._never(), 40.0)
		var first_lines: Array[String] = _f._lines(first_run)
		var second_lines: Array[String] = _f._lines(second_run)
		if first_lines.size() < 5 or first_lines != second_lines:
			errs.append("[다·%s] 마지막 단: 같은 씨앗의 이벤트 줄이 다르다 (%d줄 · %d줄)" % [str(item[0]), first_lines.size(), second_lines.size()])
	for tier in [0, last_tier]:
		var full: DuelCore = _f._play(gul.at_tier(tier).with_opening(1.0), Bot.first_blood_cfg(), _f._never(), 100.0)
		if not full.ended or full.record.of_type(DuelRecord.TELL_START).is_empty():
			errs.append("[라] %d단: 봇의 한 판이 끝나지 않았다 (시각 %.1f)" % [tier + 1, full.time])
	var day_rules: DuelRules = _f._rules()
	day_rules.stage_day = 1
	var long_run: DuelCore = _f._play(gul, {}, _f._never(), 60.0, day_rules)
	var withdraw_tells := 0
	for ev in long_run.record.of_type(DuelRecord.TELL_START):
		if (ev["attack"] as AttackData).attack_name == STYLE_NAME:
			withdraw_tells += 1
	var hop_count := _hops(long_run, "withdraw").size()
	if withdraw_tells < 1 or hop_count < 1:
		errs.append("[마] 실제 굴리엘모 60초 동안 치고 빠지기의 예비 동작 %d번 · 물러남 %d번 (둘 다 1 이상 기대)" % [withdraw_tells, hop_count])


# ================================================================ T143 표시와 연습 화면

func t143_marks_and_practice() -> String:
	var errs: Array[String] = []
	var gul := load(GUGLIELMO_PATH) as OpponentData
	if gul == null or gul.tiers.size() < 5:
		return "opponent_07.tres가 없거나 단이 여섯이 아니다"
	_marks_and_texts(errs, gul)
	_six_untouched(errs)
	_help_in_duel(errs, gul)
	_f._reset_statics()
	_practice_checks(errs)
	_free_select()
	return _ok(errs)


## ① 1단 단발: 고리 없음 · 꺾쇠 · 첫 줄 · 귀띔. 2단 "두 번 찍기": 둘째 고리에만 withdraw, 첫 타격 동안 꺾쇠 없음 · 둘째 동안 있음. 서는 길: 어디에도 없다.
func _marks_and_texts(errs: Array[String], gul: OpponentData) -> void:
	var roots: Array[AttackData] = _f._signature_roots(gul.attacks)
	if roots.size() != 1:
		errs.append("[①] 1단의 고유 공격 %d개 (기대 1)" % roots.size())
		return
	var single := _f._solo(roots[0])
	var brain := _tell_brain(gul, single)
	if not _marks_of(brain, 0.0).is_empty() or not OpponentView.ring_withdraw_of(brain):
		errs.append("[① 1단 단발] 고리 %d개 · 꺾쇠 %s (기대 0개 · 참)" % [_marks_of(brain, 0.0).size(), str(OpponentView.ring_withdraw_of(brain))])
	var tell: DuelCore = _f._play(_f._drill_opp(gul, single), {}, _f._stop_first_tell(), 30.0)
	var height: int = tell.brain.current_height()
	var parts := OpponentView.tell_texts(tell, false)
	if height < 0 or height >= DT.HEIGHT_NAMES.size():
		errs.append("[① 1단 단발] 타격의 높이 %d (기대 상 · 하 가운데 하나)" % height)
	else:
		var want_first := "%s · %s %s" % [STYLE_NAME, DT.GUARD_NAMES[tell.brain.current_attack.direction], DT.HEIGHT_NAMES[height]]
		if parts.size() != 2 or parts[0] != want_first or parts[1] != "":
			errs.append("[① 1단 단발] 상태 글 %s (기대 ['%s', ''])" % [str(parts), want_first])
	var routes := _distinct_routes(_f._tier_lists(gul))
	var two := _route_named(routes, "두 번 찍기")
	if two == null:
		errs.append("[① 2단] '두 번 찍기'가 없다")
	else:
		var two_brain := _tell_brain(gul, _f._solo(two))
		var marks := _marks_of(two_brain, 0.0)
		if marks.size() != 2 or marks[0].has("withdraw") or marks[1].get("withdraw", false) != true:
			errs.append("[① 두 번 찍기] 고리 %d개 · 첫째의 열쇠 %s · 둘째의 열쇠 %s (기대 2개 · 없음 · 참)" % [
				marks.size(), str(marks[0].has("withdraw")) if marks.size() > 0 else "-", str(marks[1].get("withdraw", "없음")) if marks.size() > 1 else "-"])
		if OpponentView.ring_withdraw_of(two_brain):
			errs.append("[① 두 번 찍기] 첫 타격 동안 꺾쇠가 선다")
		var two_first: DuelCore = _f._play(_f._drill_opp(gul, _f._solo(two)), {}, _f._stop_first_tell(), 30.0)
		var first_parts := OpponentView.tell_texts(two_first, false)
		if first_parts.size() != 2 or not first_parts[0].begins_with("%s (1/2) · " % STYLE_NAME) or first_parts[1] != "":
			errs.append("[① 두 번 찍기] 첫 타격의 상태 글 %s (기대 첫 줄 '%s (1/2) · …' · 귀띔 빈 글)" % [str(first_parts), STYLE_NAME])
		var second: DuelCore = _f._play(_f._drill_opp(gul, _f._solo(two)), {}, _stop_at_step(1), 30.0)
		var late := OpponentView.pattern_marks(second.brain, second.time)
		if second.brain.step_index != 1 or not OpponentView.ring_withdraw_of(second.brain) or late.size() != 1 or late[0].get("withdraw", false) != true:
			errs.append("[① 두 번 찍기] 둘째 타격 동안 꺾쇠 %s · 고리 %d개 (기대 참 · 1개 · withdraw)" % [str(OpponentView.ring_withdraw_of(second.brain)), late.size()])
		var second_parts := OpponentView.tell_texts(second, false)
		if second_parts.size() != 2 or not second_parts[0].begins_with("%s (2/2) · " % STYLE_NAME) or second_parts[1] != "":
			errs.append("[① 두 번 찍기] 둘째 타격의 상태 글 %s (기대 첫 줄 '%s (2/2) · …' · 귀띔 빈 글)" % [str(second_parts), STYLE_NAME])
	for stand_name: String in ["서서 받기"]:
		var stand := _route_named(routes, stand_name)
		if stand == null:
			errs.append("[① %s] 길이 없다" % stand_name)
			continue
		var stand_brain := _tell_brain(gul, _f._solo(stand))
		for mark in _marks_of(stand_brain, 0.0):
			if mark.has("withdraw"):
				errs.append("[① %s] 고리에 withdraw 열쇠가 있다" % stand_name)
		if OpponentView.ring_withdraw_of(stand_brain):
			errs.append("[① %s] 첫 타격에 꺾쇠가 선다" % stand_name)
		if stand.chain.size() > 0:
			var stand_late: DuelCore = _f._play(_f._drill_opp(gul, _f._solo(stand)), {}, _stop_at_step(1), 30.0)
			for mark in OpponentView.pattern_marks(stand_late.brain, stand_late.time):
				if mark.has("withdraw"):
					errs.append("[① %s] 둘째 타격의 고리에 withdraw 열쇠가 있다" % stand_name)
			if OpponentView.ring_withdraw_of(stand_late.brain):
				errs.append("[① %s] 마지막 타격에 꺾쇠가 선다" % stand_name)


## ② 여섯 상대의 모든 단 · 길: 고리에 withdraw 열쇠가 없고 ring_withdraw_of가 늘 거짓이다.
func _six_untouched(errs: Array[String]) -> void:
	for path: String in [BARTOLO_PATH, BRUNO_PATH, LORENZO_PATH, SERAFINA_PATH, AGOSTINO_PATH, BEATRICE_PATH]:
		var opp := load(path) as OpponentData
		if opp == null:
			errs.append("[②] %s가 로드되지 않는다" % path)
			continue
		var lists: Array = _f._tier_lists(opp)
		for k in lists.size():
			var attacks: Array = lists[k]
			for atk: AttackData in attacks:
				var atk_routes: Array[AttackData] = _f._routes(atk)
				for route in atk_routes:
					var brain := _tell_brain(opp, _f._solo(route))
					if OpponentView.ring_withdraw_of(brain):
						errs.append("[②] %s %d단 %s에 꺾쇠가 선다" % [opp.display_name, k + 1, atk.attack_name])
					for mark in _marks_of(brain, 0.0):
						if mark.has("withdraw"):
							errs.append("[②] %s %d단 %s의 고리에 withdraw 열쇠가 있다" % [opp.display_name, k + 1, atk.attack_name])


func _withdraw_help() -> String:
	return DuelHud.HELP_WITHDRAW % Controls.help_name(&"step_forward")


## 결투 중 도움말: 치고 빠지기의 줄은 굴리엘모에서만(1단과 마지막 단 모두).
func _help_in_duel(errs: Array[String], gul: OpponentData) -> void:
	for path: String in [BARTOLO_PATH, BRUNO_PATH, LORENZO_PATH, SERAFINA_PATH, AGOSTINO_PATH, BEATRICE_PATH]:
		var opp := load(path) as OpponentData
		if opp != null and DuelHud.help_text(opp).contains(_withdraw_help()):
			errs.append("[도움말] %s에게 치고 빠지기의 줄이 있다" % opp.display_name)
	for tier in [0, gul.tier_count() - 1]:
		if not DuelHud.help_text(gul.at_tier(tier)).contains(_withdraw_help()):
			errs.append("[도움말] 굴리엘모 %d단에 치고 빠지기의 줄이 없다" % (tier + 1))


## ③ 연습 화면: 상대 목록 둘째 쪽의 여섯째 · 일곱째 칸, 머리 줄, 단 고르기 여섯, 패턴 버튼 하나, 막는 법의 줄.
func _practice_checks(errs: Array[String]) -> void:
	var trials := SelectScript.load_trials()
	var index := -1
	var bea_index := -1
	for i in trials.size():
		if trials[i].resource_path == GUGLIELMO_PATH:
			index = i
		if trials[i].resource_path == BEATRICE_PATH:
			bea_index = i
	if index < 0:
		errs.append("[③] load_trials()에 굴리엘모가 없다")
		return
	if index != 6 or bea_index != 5 or index < SelectScript.LIST_ROWS or bea_index < SelectScript.LIST_ROWS:
		errs.append("[③] 굴리엘모 %d번째 · 베아트리체 %d번째 칸 (기대 일곱째 · 여섯째 — 둘 다 둘째 쪽)" % [index + 1, bea_index + 1])
	var entries := trials.size() + (1 if not SelectScript.load_spare_attacks().is_empty() else 0)
	_select = (load(Session.SELECT_PATH) as PackedScene).instantiate()
	_tree.root.add_child(_select)
	var page := _select.find_child("OpponentPage", true, false) as Label
	if page == null or page.text != "1/2":
		errs.append("[③] 처음의 쪽 글 '%s' (기대 1/2 — 상대 목록이 두 쪽)" % ("없음" if page == null else page.text))
	_select.call("pick_opponent", bea_index)
	page = _select.find_child("OpponentPage", true, false) as Label
	if page == null or page.text != "2/2":
		errs.append("[③] 여섯째를 고른 뒤의 쪽 글 '%s' (기대 2/2)" % ("없음" if page == null else page.text))
	_select.call("pick_opponent", index)
	page = _select.find_child("OpponentPage", true, false) as Label
	if page == null or page.text != "2/2":
		errs.append("[③] 일곱째를 고른 뒤의 쪽 글 '%s' (기대 2/2)" % ("없음" if page == null else page.text))
	var rows := _select.find_children("OpponentPick*", "Button", true, false).size()
	if rows != maxi(entries - SelectScript.LIST_ROWS, 0):
		errs.append("[③] 둘째 쪽의 상대 줄 %d개 (기대 %d)" % [rows, maxi(entries - SelectScript.LIST_ROWS, 0)])
	var head := _select.find_child("TrialHead", true, false)
	var head_texts: Array[String] = []
	if head != null:
		for label in head.find_children("*", "Label", true, false):
			head_texts.append((label as Label).text)
	if not head_texts.has("굴리엘모") or not head_texts.has(STYLE_NAME):
		errs.append("[③] TrialHead의 글 %s에 '굴리엘모'와 '치고 빠지기'가 없다" % str(head_texts))
	var pick := _select.find_child("StyleTierPick", true, false) as OptionButton
	if pick == null or pick.item_count != 6:
		errs.append("[③] StyleTierPick의 항목 %s (기대 6)" % ("없음" if pick == null else str(pick.item_count)))
	_check_drill_and_help(errs, "1단", false)
	if pick != null:
		pick.item_selected.emit(5)
		_check_drill_and_help(errs, "6단", true)


func _check_drill_and_help(errs: Array[String], label: String, want_chain: bool) -> void:
	var drills := _select.find_children("PatternDrill*", "Button", true, false)
	if drills.size() != 1:
		errs.append("[③ %s] PatternDrill %d개 (기대 1)" % [label, drills.size()])
	elif (drills[0] as Button).text != STYLE_NAME:
		errs.append("[③ %s] PatternDrill의 글 '%s' (기대 '%s')" % [label, (drills[0] as Button).text, STYLE_NAME])
	if _select.find_child("SlashDrill", true, false) != null:
		errs.append("[③ %s] 굴리엘모에게 SlashDrill이 있다" % label)
	var help_node := _select.find_child("PatternHelp", true, false) as Label
	if help_node == null:
		errs.append("[③ %s] PatternHelp가 없다" % label)
		return
	var text := help_node.text
	var has_withdraw := text.contains(_withdraw_help().trim_prefix(" · "))
	var has_height: bool = _f._help_has(text, DuelHud.HELP_HEIGHT)
	if not has_withdraw or not has_height:
		errs.append("[③ %s] 막는 법에 치고 빠지기(%s) · 높이(%s)의 줄이 다 있지 않다" % [label, has_withdraw, has_height])
	var has_sweep: bool = _f._help_has(text, DuelHud.HELP_SWEEP)
	var has_dive: bool = _f._help_has(text, DuelHud.HELP_DIVE)
	var has_beat: bool = _f._help_has(text, DuelHud.HELP_BEAT)
	var has_feint: bool = _f._help_has(text, DuelHud.HELP_FEINT)
	if has_sweep or has_dive or has_beat or has_feint:
		errs.append("[③ %s] 막는 법에 휩쓸기(%s) · 뛰어들기(%s) · 엇박(%s) · 헛손질(%s) 줄이 있다" % [label, has_sweep, has_dive, has_beat, has_feint])
	if want_chain and not _f._help_has(text, DuelHud.HELP_CHAIN):
		errs.append("[③ %s] 막는 법에 이어 치기 줄이 없다 (이어지는 길이 있는 단)" % label)


# ================================================================ T144 그림 데이터(계획 045b, 결정 728)

const GUL_ART_PATH := "res://data/opponents/guglielmo_art.tres"
const GUL_ART_DIR := "res://assets/art/opponents/guglielmo/"
## 작업 6이 자른 스물한 장의 크기.
const GUL_ART_SIZES := {
	"head": Vector2i(236, 214), "head_oops": Vector2i(238, 214), "head_dizzy": Vector2i(239, 214), "hat": Vector2i(272, 145),
	"feather": Vector2i(249, 78), "torso": Vector2i(413, 492), "legs": Vector2i(161, 393), "arm": Vector2i(87, 258),
	"hand": Vector2i(94, 86), "sword": Vector2i(134, 410), "arm_up_sword": Vector2i(154, 553), "arm_up": Vector2i(105, 299),
	"arm_up_fist": Vector2i(140, 107), "arm_thrust": Vector2i(156, 111), "arm_thrust_fist": Vector2i(156, 232),
	"arm_thrust_sword": Vector2i(283, 295), "arm_thrust_blade": Vector2i(61, 48), "arm_aim": Vector2i(137, 184),
	"arm_aim_fist": Vector2i(137, 177), "arm_aim_sword": Vector2i(187, 195), "arm_aim_blade": Vector2i(140, 113),
}
## 몸의 값의 한계(계획 045b "몸의 값" 표).
const GUL_MIN_NECK_Y := -206.0
const GUL_MAX_NECK_Y := -196.0
const GUL_MIN_BARE_TOP := 315.0
const GUL_MAX_BARE_TOP := 335.0
const GUL_MIN_HEAD_MID := 252.0
const GUL_MAX_HAT_TOP := 355.0
const GUL_MIN_FOOT := 195.0
const GUL_MAX_FOOT := 215.0
## 다리 윗선이 앞치마 뒤에 숨는다.
const GUL_MIN_LEGS_JOINT_Y := 12.0
## 붙은 두 다리(아고스티노의 약 175와 갈린다).
const GUL_MAX_LEGS_WIDTH := 120.0
## 달걀이 데이터에서도 보인다: 몸통 그림의 폭이 다리 그림의 폭의 1.6배 이상.
const GUL_MIN_TORSO_PER_LEGS := 1.6


func t144_guglielmo_art() -> String:
	var errs: Array[String] = []
	var bartolo := load(BARTOLO_PATH) as OpponentData
	var gul := load(GUGLIELMO_PATH) as OpponentData
	if gul == null or gul.art == null or bartolo == null or bartolo.art == null:
		return "opponent_07.tres나 그 그림이 없음"
	var art: OpponentArt = gul.art
	if art.resource_path != GUL_ART_PATH:
		errs.append("그림 데이터 %s (기대 %s)" % [art.resource_path, GUL_ART_PATH])
	if art == bartolo.art:
		errs.append("바르톨로의 그림을 빌려 쓴다")
	_gul_check_files(errs, art, bartolo.art)
	_gul_check_body(errs, art, bartolo.art)
	var client := "res://assets/art/clients/guglielmo.png"
	if ResourceLoader.exists(client):
		var tex := load(client) as Texture2D
		if tex == null or Vector2i(tex.get_size()) != Vector2i(450, 675):
			errs.append("의뢰인 그림의 크기 %s (기대 450x675)" % (str(Vector2i(tex.get_size())) if tex != null else "읽을 수 없음"))
	else:
		print("INFO T144: assets/art/clients/guglielmo.png가 아직 없다(위험 R7)")
	return _ok(errs)


func _gul_check_files(errs: Array[String], art: OpponentArt, bartolo_art: OpponentArt) -> void:
	for part_name: String in Fourth.ART_PARTS:
		var part := art.get(part_name) as PartArt
		if part == null or part.texture == null or not part.texture.resource_path.begins_with(GUL_ART_DIR):
			errs.append("그림 %s: 없거나 굴리엘모의 폴더가 아님" % part_name)
		elif part.units_per_px.x <= 0.0 or part.units_per_px.y <= 0.0:
			errs.append("그림 %s: units_per_px %s" % [part_name, part.units_per_px])
	if art.hand != null and art.hand.outline.size() < 6:
		errs.append("손의 윤곽선이 없음")
	if art.arm_arts.size() != bartolo_art.arm_arts.size():
		errs.append("따로 그린 팔 %d개 (바르톨로 %d개)" % [art.arm_arts.size(), bartolo_art.arm_arts.size()])
	else:
		for i in art.arm_arts.size():
			var mine: ArmArt = art.arm_arts[i]
			var his: ArmArt = bartolo_art.arm_arts[i]
			if mine.key != his.key or not is_equal_approx(mine.rotation_deg, his.rotation_deg) or mine.layers.size() != his.layers.size():
				errs.append("팔 %s: 키·회전·층 수가 바르톨로(%s)와 다름" % [mine.key, his.key])
				continue
			for k in mine.layers.size():
				var layer: ArmLayer = mine.layers[k]
				if layer.part != his.layers[k].part or layer.texture == null or not layer.texture.resource_path.begins_with(GUL_ART_DIR):
					errs.append("팔 %s 층 %d: part·그림이 어긋남" % [mine.key, k])
				elif (layer.part == 4) != (layer.outline.size() >= 6):
					errs.append("팔 %s 층 %d: 주먹의 윤곽선이 없거나 주먹이 아닌데 있음" % [mine.key, k])
	for file: String in GUL_ART_SIZES:
		var tex := load(GUL_ART_DIR + file + ".png") as Texture2D
		if tex == null or Vector2i(tex.get_size()) != GUL_ART_SIZES[file]:
			errs.append("%s.png의 크기 %s (기대 %s)" % [file, Vector2i(tex.get_size()) if tex != null else Vector2i.ZERO, GUL_ART_SIZES[file]])


## 달걀 · 다리 · 밀대 · 모자의 덮음은 그림을 봐야 아는 값이라 판 S2 · S4의 몫이다.
func _gul_check_body(errs: Array[String], art: OpponentArt, bartolo_art: OpponentArt) -> void:
	if art.neck.y < GUL_MIN_NECK_Y or art.neck.y > GUL_MAX_NECK_Y:
		errs.append("neck.y %.1f (기대 %.0f~%.0f)" % [art.neck.y, GUL_MIN_NECK_Y, GUL_MAX_NECK_Y])
	if art.legs == null or art.legs.texture == null or art.torso == null or art.torso.texture == null or art.hat == null:
		return
	var hat_limit: float = minf(_f._hat_top(bartolo_art), GUL_MAX_HAT_TOP)
	var hat_top: float = _f._hat_top(art)
	var foot: float = _f._foot_tip(art)
	var joint_y: float = art.legs.joint.y * art.legs.units_per_px.y
	var legs_w: float = float(art.legs.texture.get_width()) * art.legs.units_per_px.x
	var torso_w: float = _f._torso_width(art)
	print("INFO T144: 모자 쓴 꼭대기 %.1f (바르톨로 %.1f) · 발끝 %.1f · 다리 관절 %.1f · 다리 폭 %.1f · 몸통 폭 %.1f" % [hat_top, _f._hat_top(bartolo_art), foot, joint_y, legs_w, torso_w])
	if hat_top > hat_limit + 0.01:
		errs.append("모자 쓴 꼭대기 %.2f (바르톨로의 값 %.2f와 %.0f 이하여야 한다)" % [hat_top, _f._hat_top(bartolo_art), GUL_MAX_HAT_TOP])
	for head_part: PartArt in [art.head, art.head_oops, art.head_dizzy]:
		if head_part == null:
			errs.append("머리 셋 가운데 빈 것이 있다")
			continue
		var top: float = _f._bare_top(art, head_part)
		var mid: float = top - head_part.joint.y * head_part.units_per_px.y / 2.0
		if top < GUL_MIN_BARE_TOP - 0.01 or top > GUL_MAX_BARE_TOP + 0.01:
			errs.append("모자 없는 꼭대기 %.2f (기대 %.0f~%.0f)" % [top, GUL_MIN_BARE_TOP, GUL_MAX_BARE_TOP])
		if mid < GUL_MIN_HEAD_MID - 0.01:
			errs.append("머리 가운데의 자 %.2f (%.0f 이상이어야 한다)" % [mid, GUL_MIN_HEAD_MID])
	if foot < GUL_MIN_FOOT - 0.01 or foot > GUL_MAX_FOOT + 0.01:
		errs.append("발끝 %.2f (기대 %.0f~%.0f)" % [foot, GUL_MIN_FOOT, GUL_MAX_FOOT])
	if joint_y < GUL_MIN_LEGS_JOINT_Y:
		errs.append("다리 관절의 높이 %.2f (%.0f 이상이어야 윗선이 앞치마 뒤에 숨는다)" % [joint_y, GUL_MIN_LEGS_JOINT_Y])
	if legs_w > GUL_MAX_LEGS_WIDTH + 0.01:
		errs.append("다리 그림의 폭 %.2f (%.0f 이하 — 붙은 두 다리)" % [legs_w, GUL_MAX_LEGS_WIDTH])
	if torso_w < legs_w * GUL_MIN_TORSO_PER_LEGS - 0.01:
		errs.append("몸통 그림의 폭 %.2f (다리 %.2f의 %.1f배 이상 — 달걀)" % [torso_w, legs_w, GUL_MIN_TORSO_PER_LEGS])
