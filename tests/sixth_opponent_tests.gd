extends RefCounted
## T136~T138: 여섯째 상대 베아트리체(계획 044, 결정 666~683). 데이터의 틀·속임 길의 표·가방, 속임 베기의 판, 표시와 연습 화면.
## 값(길의 칸·간격·단·가방·가중치)은 결정 674·675·676의 표를 손으로 적은 기대다. 로드한 자원은 고치지 않는다(사본만).
## 결정 678의 고치는 차례가 옮길 수 있는 값(찌르기의 가중치·기본 베기의 빈틈·속임 베기의 가중치·끝의 빈틈·가방)은 아래 상수가 함께 옮기는 기대다.
## 도우미는 fourth_opponent_tests.gd에서 빌린다(그 파일은 고치지 않는다. 빌린 도우미는 _tree를 쓰지 않는다).

const Fourth := preload("res://tests/fourth_opponent_tests.gd")
const Bot := preload("res://tests/duel_bots.gd")
const DT := preload("res://scripts/duel/duel_types.gd")
const SelectScript := preload("res://scripts/commission/commission_select.gd")
const Session := preload("res://scripts/game_session.gd")

const BEATRICE_PATH := "res://data/opponents/opponent_06.tres"
const BARTOLO_PATH := "res://data/opponents/opponent_01.tres"
const BRUNO_PATH := "res://data/opponents/opponent_02.tres"
const LORENZO_PATH := "res://data/opponents/opponent_03.tres"
const SERAFINA_PATH := "res://data/opponents/opponent_04.tres"
const AGOSTINO_PATH := "res://data/opponents/opponent_05.tres"
const COMMISSION_DIR := "res://data/commissions"
const STYLE_NAME := "속임 베기"
## 그녀의 귀띔은 비어 있다(첫 줄의 " · 헛손질"이 같은 말을 한다). "속았다"는 받아넘김 자리 글·소리·기록이 알린다.
const HINT := ""
## 고유 색(결정 673): 라임빛.
const SIG_COLOR := Color(0.6, 1.0, 0.1, 1.0)
const FROM_DAYS: Array[int] = [7, 9, 11, 13, 15]
## 뿌리와 변주의 값(결정 675 — 모든 단에서 같다). 결정 678의 값 고침(② 가중치 2 → 3, 끝의 빈틈 1.2 → 1.4)이 옮길 수 있다.
const ROOT_TELL := 0.9
const ROOT_RECOVERY := 1.2
const ROOT_WEIGHT := 2.0
## 기본 셋(결정 674). 결정 678의 값 고침(찌르기의 가중치 3 → 2, 좌우 베기의 빈틈 0.55 → 0.75)이 옮길 수 있다.
const THRUST_WEIGHT := 3.0
const CUT_RECOVERY := 0.55
## 가방(결정 676): 찌르기 + 좌우 베기 둘 + 속임 + 3단의 겹찌르기 + 5단의 찌르고 베기. 위 가중치를 옮기면 함께 옮긴다.
const BAG_SIZES: Array[int] = [7, 7, 8, 8, 9, 9]
## 두 틱 + 여유: 타격 사이의 간격은 판정 틱에 얹힌다.
const TIME_TOL := 0.04

## 기본 셋: 이름 -> [방향, 높이 묶음, 가중치를 정하는 값은 코드가, 예비, 빈틈]. 예비와 방향은 바르톨로와 같고 높이 묶음만 뒤집혔다(결정 674).
const BASIC_DIRECTIONS := {"찌르기": 1, "왼쪽 베기": 0, "오른쪽 베기": 2}
const BASIC_HEIGHTS := {"찌르기": [0, 1], "왼쪽 베기": [1, 2], "오른쪽 베기": [1, 2]}
## 길의 표(결정 675). 줄 하나 = [방향 0 왼 · 1 가 · 2 오, 높이 묶음 0 상 · 1 중 · 2 하, 헛손질, 그 타격 앞의 간격].
const ROUTE_SPECS := {
	"오른쪽으로": [[0, [0], true, 0.9], [2, [1, 2], false, 0.65]],
	"같은 쪽 낮게": [[0, [0], true, 0.9], [0, [2], false, 0.65]],
	"막고 흘리고": [[0, [1], false, 0.9], [1, [0], true, 0.6], [2, [2], false, 0.65]],
	"두 번 속임": [[0, [0], true, 0.9], [2, [0], true, 0.6], [1, [1, 2], false, 0.65]],
	"왼쪽으로": [[2, [0], true, 0.9], [0, [1, 2], false, 0.65]],
	"두 겹 속임": [[2, [1], true, 0.9], [0, [1], false, 0.65], [0, [0], true, 0.6], [2, [1], false, 0.65]],
}
## 단마다의 길(변주까지). 3단은 2단과, 5단은 4단과 같다.
const TIER_ROUTES := [
	["오른쪽으로", "같은 쪽 낮게"],
	["오른쪽으로", "같은 쪽 낮게", "막고 흘리고"],
	["오른쪽으로", "같은 쪽 낮게", "막고 흘리고"],
	["오른쪽으로", "같은 쪽 낮게", "막고 흘리고", "두 번 속임", "왼쪽으로"],
	["오른쪽으로", "같은 쪽 낮게", "막고 흘리고", "두 번 속임", "왼쪽으로"],
	["오른쪽으로", "같은 쪽 낮게", "막고 흘리고", "두 번 속임", "왼쪽으로", "두 겹 속임"],
]
const TIER_NAMES := [
	["찌르기", "왼쪽 베기", "오른쪽 베기", "속임 베기"],
	["찌르기", "왼쪽 베기", "오른쪽 베기", "속임 베기"],
	["찌르기", "왼쪽 베기", "오른쪽 베기", "속임 베기", "겹찌르기"],
	["찌르기", "왼쪽 베기", "오른쪽 베기", "속임 베기", "겹찌르기"],
	["찌르기", "왼쪽 베기", "오른쪽 베기", "속임 베기", "겹찌르기", "찌르고 베기"],
	["찌르기", "왼쪽 베기", "오른쪽 베기", "속임 베기", "겹찌르기", "찌르고 베기"],
]

var _tree: SceneTree
var _f: Fourth = Fourth.new()
var _select: Node = null


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T136", "name": "여섯째 상대: 판정 값이 바르톨로와 같다, 기본 셋의 높이, 속임 길의 표(방향·높이·간격·헛손질)와 단·가방, 고유 색 하나, 하루에는 서지 않는다", "fn": t136_sixth_opponent},
		{"id": "T137", "name": "속임 베기의 판: 속지 않는 손과 속는 손의 빈틈, 타격의 시각, 넷째 고리의 비킴, 같은 씨앗, 봇의 한 판, 실제 베아트리체", "fn": t137_feint_duel},
		{"id": "T138", "name": "표시와 연습 화면: 빈 고리의 feint 열쇠, 첫 줄·귀띔, 화면 칸의 테두리, 다섯 상대는 그대로, 연습의 둘째 쪽과 막는 법", "fn": t138_marks_and_practice},
		{"id": "T139", "name": "그림 데이터: 스물한 장과 팔 셋, 모자 없는 꼭대기·머리 가운데의 자·모자 쓴 꼭대기·발끝, 치마 관절과 치마 폭(다섯 가운데 가장 넓다)", "fn": t139_beatrice_art},
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


## 표의 길 하나의 열쇠: 타격마다 "(~)방향/높이들"을 ">"로 잇는다. ~는 헛손질.
func _spec_key(spec: Array) -> String:
	var parts := PackedStringArray()
	for row: Array in spec:
		var heights := ""
		for h: int in (row[1] as Array):
			heights += str(h)
		parts.append("%s%d/%s" % ["~" if bool(row[2]) else "", int(row[0]), heights])
	return ">".join(parts)


## 데이터의 길의 열쇠(_spec_key와 같은 꼴).
func _data_key(route: AttackData) -> String:
	var parts := PackedStringArray()
	for strike in _f._strike_list(route):
		var heights := ""
		for h: int in strike.heights:
			heights += str(h)
		parts.append("%s%d/%s" % ["~" if strike.feint else "", int(strike.direction), heights])
	return ">".join(parts)


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


func _want_results(blocked: int, last: int) -> Array:
	var out: Array = []
	for i in blocked:
		out.append(DT.StrikeResult.BLOCKED)
	out.append(last)
	return out


## 헛손질 · 타격 이벤트만 차례대로.
func _chain_events(core: DuelCore) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for ev: Dictionary in core.record.events:
		if ev["type"] == DuelRecord.FEINT or ev["type"] == DuelRecord.STRIKE:
			out.append(ev)
	return out


func _bite_cfg() -> Dictionary:
	return {"bite_fn": func(_a: AttackData) -> bool: return true}


func _stop_at_step(step: int) -> Callable:
	return func(core: DuelCore) -> bool:
		return core.brain.state == DT.OpponentState.TELL and core.brain.pattern_root != null and core.brain.step_index == step


func _stop_feints(count: int) -> Callable:
	return func(core: DuelCore) -> bool: return core.record.of_type(DuelRecord.FEINT).size() >= count


# ================================================================ T136 데이터

func t136_sixth_opponent() -> String:
	var errs: Array[String] = []
	var bartolo := load(BARTOLO_PATH) as OpponentData
	var bea := load(BEATRICE_PATH) as OpponentData
	# ① 로드, 이름, 갈래 이름, 칼 든 팔, 그림.
	if bea == null or bartolo == null:
		return "opponent_06.tres나 opponent_01.tres가 로드되지 않는다"
	if bea.display_name != "베아트리체" or bea.style_name != STYLE_NAME:
		errs.append("이름 '%s' · 갈래 '%s'" % [bea.display_name, bea.style_name])
	if bea.sword_side != DT.Direction.LEFT:
		errs.append("칼 든 팔이 왼쪽이 아니다 (%d)" % bea.sword_side)
	if bea.art == null:
		errs.append("그림 데이터(art)가 비었다")
	# ② 바르톨로와 견준다: 이름·그림·포즈 아홉과 공격 목록·갈래 이름·단만 다르다(결정 668).
	_f._compare(bartolo, bea, "opponent", errs, Fourth.FREE_FIELDS + ["attacks"] + Fourth.SWORD_FIELDS)
	# ③ 1단의 기본 셋.
	_check_basics(errs, bea, bartolo)
	# ④ 단마다의 길과 단 · 고유 색.
	_check_tiers(errs, bea, bartolo)
	# ⑤ 가방의 장 수.
	for k in bea.tier_count():
		var brain := OpponentBrain.new(bea.at_tier(k), _f._seeded())
		brain.start_idle(0.0)
		brain.start_tell(0.0, false)
		var cards: int = brain.bag_remaining() + 1
		if k >= BAG_SIZES.size() or cards != BAG_SIZES[k]:
			errs.append("%d단의 가방 %d장 (기대 %s)" % [k + 1, cards, str(BAG_SIZES[k]) if k < BAG_SIZES.size() else "없음"])
	# ⑥ 베아트리체를 거는 의뢰는 굴리엘모 편의 대련과 그의 편을 든 뒤의 지기, 클라라의 맞수뿐이다(계획 047. 결정 681은 047이 넘는다).
	var users: Array[String] = []
	for commission in CommissionLibrary.load_tree(COMMISSION_DIR):
		if commission.opponent != null and commission.opponent.resource_path == BEATRICE_PATH:
			users.append(commission.resource_path.get_file())
	if users != ["after_baker.tres", "pair_baker.tres", "rival_milliner.tres"]:
		errs.append("베아트리체를 거는 의뢰 %s (기대 after_baker.tres · pair_baker.tres · rival_milliner.tres, 계획 048)" % str(users))
	return _ok(errs)


## 1단: 공격 넷(찌르기 · 좌우 베기 · 속임 베기). 방향 · 예비는 바르톨로와 같고 높이 묶음은 뒤집혔다. 가중치와 베기의 빈틈은 위 상수다.
func _check_basics(errs: Array[String], bea: OpponentData, bartolo: OpponentData) -> void:
	if bea.attacks.size() != 4:
		errs.append("1단의 공격 %d개 (기대 4)" % bea.attacks.size())
		return
	for attack_name: String in BASIC_DIRECTIONS:
		var mine: AttackData = _f._find_named(bea.attacks, attack_name)
		var his: AttackData = _f._find_named(bartolo.attacks, attack_name)
		if mine == null or his == null:
			errs.append("1단에 %s가 없다 (베아트리체 %s · 바르톨로 %s)" % [attack_name, mine != null, his != null])
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
		if not mine.chain.is_empty() or mine.signature or mine.is_big or mine.sweep or mine.dive or mine.needs_raised_guard or mine.feint:
			errs.append("%s: 걸음 %d · 고유 %s · 큰 공격 %s · 휩쓸기 %s · 뛰어들기 %s · 올려 막기 %s · 헛손질 %s (기대 모두 없음)" % [
				attack_name, mine.chain.size(), mine.signature, mine.is_big, mine.sweep, mine.dive, mine.needs_raised_guard, mine.feint])
	if bea.tiers.size() != FROM_DAYS.size():
		errs.append("단 %d개 (기대 %d)" % [bea.tiers.size(), FROM_DAYS.size()])
	else:
		for i in bea.tiers.size():
			if bea.tiers[i].from_day != FROM_DAYS[i]:
				errs.append("%d단의 from_day %d (기대 %d)" % [i + 2, bea.tiers[i].from_day, FROM_DAYS[i]])
	if bea.habits.size() != bartolo.habits.size():
		errs.append("버릇 %d개 (바르톨로 %d개)" % [bea.habits.size(), bartolo.habits.size()])


## 단마다: 공격 이름의 목록, 고유 공격 하나, 길의 열쇠(표와 같은 길 · 같은 간격), 3 · 5단의 뿌리 · 겹찌르기와 찌르고 베기, 고유 색 하나.
func _check_tiers(errs: Array[String], bea: OpponentData, bartolo: OpponentData) -> void:
	var lists: Array = _f._tier_lists(bea)
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
	# 고유 색은 라임빛 하나다(모든 타격).
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
		errs.append("고유 공격의 색 %s (기대 라임빛 하나 %s)" % [str(seen), str(SIG_COLOR)])
	# 3단의 겹찌르기 · 5단의 찌르고 베기는 바르톨로의 같은 공격이다(예비 · 빈틈 · 가중치. 높이 묶음은 그녀의 찌르기를 따른다).
	_check_composite(errs, lists[2], _f._tier_lists(bartolo)[2], "겹찌르기")
	_check_composite(errs, lists[4], _f._tier_lists(bartolo)[4], "찌르고 베기")


func _check_composite(errs: Array[String], mine_list: Array, his_list: Array, atk_name: String) -> void:
	var mine: AttackData = _f._find_named(mine_list, atk_name)
	var his: AttackData = _f._find_named(his_list, atk_name)
	if mine == null or his == null:
		errs.append("%s가 없다 (베아트리체 %s · 바르톨로 %s)" % [atk_name, mine != null, his != null])
		return
	if mine.direction != his.direction or not _near(mine.tell_time, his.tell_time) or not _near(mine.recovery_time, his.recovery_time) \
			or not is_equal_approx(mine.weight, his.weight) or mine.chain.size() != his.chain.size() or mine.signature or mine.feint:
		errs.append("%s: 방향 %d · 예비 %.2f · 빈틈 %.2f · 가중치 %.1f · 걸음 %d (바르톨로 %d · %.2f · %.2f · %.1f · %d)" % [
			atk_name, mine.direction, mine.tell_time, mine.recovery_time, mine.weight, mine.chain.size(),
			his.direction, his.tell_time, his.recovery_time, his.weight, his.chain.size()])
	if str(mine.heights) != str([0, 1]):
		errs.append("%s의 높이 묶음 %s (기대 그녀의 찌르기와 같은 [0, 1])" % [atk_name, str(mine.heights)])


## 길 하나(뿌리 또는 변주)를 표와 견주고 열쇠를 돌려준다. 타격의 색은 colors에 모은다.
func _check_route(errs: Array[String], k: int, route: AttackData, colors: Array[Color]) -> String:
	var key := _data_key(route)
	var route_name: String = _names_by_key().get(key, "")
	var label := "%d단 길 %s" % [k + 1, route_name if route_name != "" else key]
	if route_name == "":
		errs.append("%s: 표에 없는 길이다" % label)
		return key
	if route.attack_name != STYLE_NAME or route.is_big or route.sweep or route.dive or route.needs_raised_guard:
		errs.append("%s: 이름 '%s' · 큰 공격 %s · 휩쓸기 %s · 뛰어들기 %s · 올려 막기 %s" % [label, route.attack_name, route.is_big, route.sweep, route.dive, route.needs_raised_guard])
	if not _near(route.tell_time, ROOT_TELL) or not _near(route.recovery_time, ROOT_RECOVERY) or not is_equal_approx(route.weight, ROOT_WEIGHT):
		errs.append("%s: 뿌리의 예비 %.2f · 빈틈 %.2f · 가중치 %.1f (기대 %.2f · %.2f · %.1f)" % [label, route.tell_time, route.recovery_time, route.weight, ROOT_TELL, ROOT_RECOVERY, ROOT_WEIGHT])
	if route.tell_hint != HINT:
		errs.append("%s: 귀띔 '%s' (기대 '%s')" % [label, route.tell_hint, HINT])
	var spec: Array = ROUTE_SPECS[route_name]
	var strikes: Array[AttackData] = _f._strike_list(route)
	if strikes.size() != spec.size():
		errs.append("%s: 타격 %d개 (기대 %d)" % [label, strikes.size(), spec.size()])
		return key
	for j in strikes.size():
		var row: Array = spec[j]
		var strike: AttackData = strikes[j]
		colors.append(strike.pose_color)
		if not _near(strike.tell_time, float(row[3])):
			errs.append("%s: %d번째 타격 앞의 간격 %.2f (기대 %.2f)" % [label, j + 1, strike.tell_time, float(row[3])])
		if strike.attack_name != STYLE_NAME or not strike.signature or strike.is_big or strike.sweep or strike.dive or strike.needs_raised_guard:
			errs.append("%s: %d번째 타격의 이름 '%s' · 고유 %s" % [label, j + 1, strike.attack_name, strike.signature])
		if j > 0 and not _near(strike.recovery_time, 0.0):
			errs.append("%s: %d번째 타격(걸음)의 빈틈 %.2f (기대 0)" % [label, j + 1, strike.recovery_time])
	return key


# ================================================================ T137 속임 베기의 판

func t137_feint_duel() -> String:
	var errs: Array[String] = []
	var bea := load(BEATRICE_PATH) as OpponentData
	if bea == null or bea.tiers.size() < 5:
		return "opponent_06.tres가 없거나 단이 여섯이 아니다"
	var lists: Array = _f._tier_lists(bea)
	var routes := _distinct_routes(lists)
	print("  INFO T137 서로 다른 길의 자원 %d개 (표의 길 %d)" % [routes.size(), ROUTE_SPECS.size()])
	# (가)(나) 모든 단의 모든 길.
	for route in routes:
		_t137_route(errs, bea, route)
	# (나) 6단의 넷째 고리가 첫 고리의 칸에서 아래로 비킨다.
	var double_route := _route_named(routes, "두 겹 속임")
	if double_route == null:
		errs.append("[나] 6단에 '두 겹 속임'이 없다")
	else:
		var none: Array[int] = []
		var rings: Array[Vector2] = _f._ring_positions(bea, _f._solo(double_route), none)
		if rings.size() != 4:
			errs.append("[나] 두 겹 속임의 고리 %d개 (기대 4)" % rings.size())
		elif not rings[3].is_equal_approx(rings[0] + Vector2(0.0, OpponentView.MARK_REPEAT_SHIFT)):
			errs.append("[나] 넷째 고리 %s (기대 첫 고리 %s + (0, %.0f) — 같은 칸이면 아래로 비킨다)" % [str(rings[3]), str(rings[0]), OpponentView.MARK_REPEAT_SHIFT])
	# (다)(라)(마) 같은 씨앗, 봇의 한 판, 실제 베아트리체.
	_t137_runs(errs, bea)
	return _ok(errs)


## 한 길: (가) 키 없는 봇은 속지 않고 끝의 빈틈이 그 길의 값, bite_fn 참인 봇은 속고 끝의 빈틈 0. (나) 타격 시각이 표의 간격.
func _t137_route(errs: Array[String], bea: OpponentData, route: AttackData) -> void:
	var SR := DT.StrikeResult
	var key := _data_key(route)
	var route_name: String = _names_by_key().get(key, "")
	var label := route_name if route_name != "" else key
	var strikes_data: Array[AttackData] = _f._strike_list(route)
	var feint_count := 0
	for strike in strikes_data:
		if strike.feint:
			feint_count += 1
	var real_count := strikes_data.size() - feint_count
	if real_count < 1 or feint_count < 1:
		errs.append("[가·%s] 진짜 %d · 헛손질 %d (기대 둘 다 1 이상)" % [label, real_count, feint_count])
		return
	var opp: OpponentData = _f._drill_opp(bea, _f._solo(route))
	# 속지 않는 손.
	var held: DuelCore = _f._play(opp, {}, _f._stop_strikes(real_count), 40.0)
	var held_strikes: Array[Dictionary] = held.record.of_type(DuelRecord.STRIKE)
	var held_feints: Array[Dictionary] = held.record.of_type(DuelRecord.FEINT)
	if not _f._is(held_strikes, _want_results(real_count - 1, SR.BLOCKED)) or held_feints.size() != feint_count:
		errs.append("[가·%s·속지 않음] 결과 %s · 헛손질 %d개 (기대 막힘 %d번 · %d개)" % [label, _f._result_text(held_strikes), held_feints.size(), real_count, feint_count])
	else:
		for ev in held_feints:
			if ev["bitten"] != false:
				errs.append("[가·%s·속지 않음] FEINT가 속았다고 났다" % label)
		for ev in held_strikes:
			if ev.has("bitten"):
				errs.append("[가·%s·속지 않음] STRIKE에 bitten 열쇠가 있다" % label)
		var held_gap: float = float(held_strikes[real_count - 1]["recovery"])
		if absf(held_gap - route.recovery_time) > 0.01:
			errs.append("[가·%s·속지 않음] 끝의 빈틈 %.2f (기대 그 길의 %.2f)" % [label, held_gap, route.recovery_time])
		_check_times(errs, label, held, strikes_data, route_name)
	# 속는 손: 헛손질의 칸을 막는다. 진짜는 막히지만 끝의 빈틈이 0이다.
	var fooled: DuelCore = _f._play(opp, _bite_cfg(), _f._stop_strikes(real_count), 40.0)
	var fooled_strikes: Array[Dictionary] = fooled.record.of_type(DuelRecord.STRIKE)
	var fooled_feints: Array[Dictionary] = fooled.record.of_type(DuelRecord.FEINT)
	if not _f._is(fooled_strikes, _want_results(real_count - 1, SR.BLOCKED)) or fooled_feints.size() != feint_count:
		errs.append("[가·%s·속음] 결과 %s · 헛손질 %d개 (기대 막힘 %d번 · %d개)" % [label, _f._result_text(fooled_strikes), fooled_feints.size(), real_count, feint_count])
		return
	for ev in fooled_feints:
		if ev["bitten"] != true:
			errs.append("[가·%s·속음] 헛손질의 칸을 막았는데 속지 않았다" % label)
	for i in fooled_strikes.size():
		var last := i == fooled_strikes.size() - 1
		if fooled_strikes[i].has("bitten") != last:
			errs.append("[가·%s·속음] %d번째 타격의 bitten 열쇠 %s (기대 %s)" % [label, i + 1, fooled_strikes[i].has("bitten"), "끝에만 참" if last else "없음"])
	if absf(float(fooled_strikes[real_count - 1]["recovery"])) > 0.001 or bool(fooled_strikes[real_count - 1].get("closed", false)):
		errs.append("[가·%s·속음] 끝의 빈틈 %.2f · 안 열림 %s (기대 0 · 거짓)" % [label, float(fooled_strikes[real_count - 1]["recovery"]), str(fooled_strikes[real_count - 1].get("closed", false))])


## (나) 헛손질과 타격의 이벤트가 길의 차례와 같고, 앞 이벤트로부터 그 걸음의 간격(표) ± 두 틱 뒤에 온다.
func _check_times(errs: Array[String], label: String, core: DuelCore, strikes_data: Array[AttackData], route_name: String) -> void:
	var events := _chain_events(core)
	if events.size() != strikes_data.size():
		errs.append("[나·%s] 이벤트 %d개 (기대 %d)" % [label, events.size(), strikes_data.size()])
		return
	var spec: Array = ROUTE_SPECS.get(route_name, [])
	for i in events.size():
		var is_feint: bool = events[i]["type"] == DuelRecord.FEINT
		if is_feint != strikes_data[i].feint:
			errs.append("[나·%s] %d번째 이벤트가 %s다 (기대 %s)" % [label, i + 1, "헛손질" if is_feint else "타격", "헛손질" if strikes_data[i].feint else "타격"])
			continue
		if i == 0:
			continue
		var want: float = float((spec[i] as Array)[3]) if spec.size() == events.size() else strikes_data[i].tell_time
		var gap := float(events[i]["t"]) - float(events[i - 1]["t"])
		if absf(gap - want) > TIME_TOL:
			errs.append("[나·%s] %d번째와 %d번째 사이 %.3f초 (기대 %.2f ± %.2f)" % [label, i, i + 1, gap, want, TIME_TOL])


## (다) 같은 씨앗이면 마지막 단의 판이 같은 이벤트 줄 (라) 봇의 한 판 (마) 실제 베아트리체(확률 켬)의 속임 베기.
func _t137_runs(errs: Array[String], bea: OpponentData) -> void:
	var last_tier := bea.tier_count() - 1
	var cases: Array = [["키 없는 봇", {}], ["속는 봇", _bite_cfg()]]
	for item: Array in cases:
		var cfg: Dictionary = item[1]
		var first_run: DuelCore = _f._play(bea.at_tier(last_tier).with_opening(1.0), cfg, _f._never(), 40.0)
		var second_run: DuelCore = _f._play(bea.at_tier(last_tier).with_opening(1.0), cfg, _f._never(), 40.0)
		var first_lines: Array[String] = _f._lines(first_run)
		var second_lines: Array[String] = _f._lines(second_run)
		if first_lines.size() < 5 or first_lines != second_lines:
			errs.append("[다·%s] 마지막 단: 같은 씨앗의 이벤트 줄이 다르다 (%d줄 · %d줄)" % [str(item[0]), first_lines.size(), second_lines.size()])
	for tier in [0, last_tier]:
		var full: DuelCore = _f._play(bea.at_tier(tier).with_opening(1.0), Bot.first_blood_cfg(), _f._never(), 100.0)
		if not full.ended or full.record.of_type(DuelRecord.TELL_START).is_empty():
			errs.append("[라] %d단: 봇의 한 판이 끝나지 않았다 (시각 %.1f)" % [tier + 1, full.time])
	var day_rules: DuelRules = _f._rules()
	day_rules.stage_day = 1
	var long_run: DuelCore = _f._play(bea, {}, _f._never(), 60.0, day_rules)
	var feint_tells := 0
	for ev in long_run.record.of_type(DuelRecord.TELL_START):
		if (ev["attack"] as AttackData).attack_name == STYLE_NAME:
			feint_tells += 1
	if feint_tells < 1:
		errs.append("[마] 실제 베아트리체 60초 동안 속임 베기의 예비 동작이 %d번 (1 이상 기대)" % feint_tells)


# ================================================================ T138 표시와 연습 화면

func t138_marks_and_practice() -> String:
	var errs: Array[String] = []
	var bea := load(BEATRICE_PATH) as OpponentData
	if bea == null or bea.tiers.size() < 5:
		return "opponent_06.tres가 없거나 단이 여섯이 아니다"
	_marks_of_all_routes(errs, bea)
	_texts_and_frames(errs, bea)
	_other_five(errs)
	_help_in_duel(errs, bea)
	_f._reset_statics()
	_practice_checks(errs)
	_free_select()
	return _ok(errs)


## 예비 동작이 시작된 직후의 번호 고리들(길 표시는 뺀다).
func _marks_of(opp: OpponentData, route: AttackData) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var brain := OpponentBrain.new(_f._drill_opp(opp, route), _f._seeded())
	brain.start_idle(0.0)
	brain.start_tell(0.0, false)
	if brain.pattern_root == null or brain.state != DT.OpponentState.TELL:
		return out
	for mark in OpponentView.pattern_marks(brain, 0.0):
		if mark["role"] != &"path":
			out.append(mark)
	return out


## ① 베아트리체의 모든 길: feint 열쇠는 헛손질의 고리에만 있고 참이다. ② 다섯 상대의 모든 단 · 길에는 그 열쇠가 없다.
func _marks_of_all_routes(errs: Array[String], bea: OpponentData) -> void:
	var routes := _distinct_routes(_f._tier_lists(bea))
	for route in routes:
		var strikes: Array[AttackData] = _f._strike_list(route)
		var marks := _marks_of(bea, _f._solo(route))
		var label := _data_key(route)
		if marks.size() != strikes.size():
			errs.append("[① %s] 고리 %d개 (타격 %d개)" % [label, marks.size(), strikes.size()])
			continue
		for i in marks.size():
			if marks[i].has("feint") != strikes[i].feint or (marks[i].has("feint") and marks[i]["feint"] != true):
				errs.append("[① %s] %d번째 고리의 feint 열쇠 %s (기대 %s)" % [label, i + 1, str(marks[i].get("feint", "없음")), "참" if strikes[i].feint else "없음"])
	for path: String in [BARTOLO_PATH, BRUNO_PATH, LORENZO_PATH, SERAFINA_PATH, AGOSTINO_PATH]:
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
					for strike in _f._strike_list(route):
						if strike.feint:
							errs.append("[②] %s %d단 %s에 헛손질의 타격이 있다" % [opp.display_name, k + 1, atk.attack_name])
					for mark in _marks_of(opp, _f._solo(route)):
						if mark.has("feint"):
							errs.append("[②] %s %d단 %s의 고리에 feint 열쇠가 있다" % [opp.display_name, k + 1, atk.attack_name])


## 내 막기를 그 칸에 올린다(이미 막는 중이면 조준만 옮긴다). 막기가 서 있으면 참.
func _guard_on(core: DuelCore, direction: int, height: int) -> bool:
	core.set_aim(direction, height)
	if core.player_state != DT.PlayerState.GUARD:
		core.set_guard(true)
	return core.player_state == DT.PlayerState.GUARD


## 화면 칸의 테두리가 칸 (direction, height)의 값이고 막는 중이면 guarded가 참, 다른 칸을 막으면 거짓이다.
func _expect_frame(errs: Array[String], label: String, core: DuelCore, direction: int, height: int) -> void:
	if core.brain.state != DT.OpponentState.TELL:
		errs.append("[%s] 예비 동작이 아니다 (상태 %d)" % [label, core.brain.state])
		return
	if not _guard_on(core, direction, height):
		errs.append("[%s] 표본에서 막기가 서지 않았다" % label)
		return
	var frame := DuelScene.strike_cell_frame(core)
	if frame.is_empty():
		errs.append("[%s] 테두리가 비었다 (기대 칸 %d · %d)" % [label, direction, height])
		return
	var rect: Rect2 = frame["rect"]
	if rect != Rect2(Vector2(direction, height), Vector2.ONE) or int(frame["direction"]) != direction or int(frame["height"]) != height or frame["guarded"] != true:
		errs.append("[%s] 테두리 rect %s · 방향 %s · 높이 %s · guarded %s (기대 칸 %d · %d · 막는 중)" % [
			label, str(rect), str(frame["direction"]), str(frame["height"]), str(frame["guarded"]), direction, height])
	core.set_aim((direction + 1) % 3, height)
	var other := DuelScene.strike_cell_frame(core)
	if other.is_empty() or other["guarded"] != false or (other["rect"] as Rect2) != rect:
		errs.append("[%s] 다른 칸을 막는데 테두리 %s (기대 같은 칸 · guarded 거짓)" % [label, str(other)])


## 헛손질의 예비 동작에는 테두리가 없다(막고 있어도). 그 칸을 막고 있다는 표본이 서 있어야 한다.
func _expect_no_frame(errs: Array[String], label: String, core: DuelCore, direction: int, height: int) -> void:
	if core.brain.state != DT.OpponentState.TELL or not core.brain.current_attack.feint:
		errs.append("[%s] 헛손질의 예비 동작이 아니다 (상태 %d)" % [label, core.brain.state])
		return
	if not _guard_on(core, direction, height):
		errs.append("[%s] 표본에서 막기가 서지 않았다" % label)
		return
	var frame := DuelScene.strike_cell_frame(core)
	if not frame.is_empty():
		errs.append("[%s] 헛손질의 칸을 막고 있는데 테두리가 있다 (%s)" % [label, str(frame)])


## ① 1단 속임 베기(헛 왼상 → 오[중·하])와 2단 가운데 헛손질(왼중 → 헛 가상 → 오하)의 첫 줄 · 귀띔 · 화면 칸의 테두리.
func _texts_and_frames(errs: Array[String], bea: OpponentData) -> void:
	var routes := _distinct_routes(_f._tier_lists(bea))
	var first := _route_named(routes, "오른쪽으로")
	var mid := _route_named(routes, "막고 흘리고")
	if first == null or mid == null:
		errs.append("[①] 길 '오른쪽으로'(%s)나 '막고 흘리고'(%s)가 없다" % [first != null, mid != null])
		return
	# 1단: 헛손질의 예비 동작.
	var tell: DuelCore = _f._play(_f._drill_opp(bea, _f._solo(first)), _bite_cfg(), _f._stop_first_tell(), 30.0)
	var parts := OpponentView.tell_texts(tell, false)
	if parts.size() != 2 or parts[0] != "%s (1/2) · 헛손질" % STYLE_NAME or parts[1] != HINT:
		errs.append("[① 1단 헛손질] 상태 글 %s (기대 ['%s (1/2) · 헛손질', '%s'])" % [str(parts), STYLE_NAME, HINT])
	_expect_no_frame(errs, "① 1단 헛손질", tell, DT.Direction.LEFT, DT.Height.HIGH)
	# 1단: 헛손질을 쥐고 넘긴 뒤 — 진짜의 예비 동작.
	var passed: DuelCore = _f._play(_f._drill_opp(bea, _f._solo(first)), _bite_cfg(), _stop_feints(1), 30.0)
	parts = OpponentView.tell_texts(passed, false)
	if parts.size() != 2 or not parts[0].begins_with("%s (2/2) · 오른쪽" % STYLE_NAME) or parts[1] != HINT or not passed.brain.feint_bitten:
		errs.append("[① 1단 넘긴 뒤] 상태 글 %s (기대 첫 줄 '%s (2/2) · 오른쪽 …' · 귀띔 '%s' · 속은 표지)" % [str(parts), STYLE_NAME, HINT])
	_expect_frame(errs, "① 1단 넘긴 뒤", passed, DT.Direction.RIGHT, passed.brain.current_height())
	# 2단 가운데: 첫 타격(진짜)의 테두리.
	var start: DuelCore = _f._play(_f._drill_opp(bea, _f._solo(mid)), {}, _f._stop_first_tell(), 30.0)
	_expect_frame(errs, "① 2단 첫 타격", start, DT.Direction.LEFT, DT.Height.MID)
	# 2단 가운데의 헛손질: 첫 줄 · 귀띔· 테두리 없음.
	var middle: DuelCore = _f._play(_f._drill_opp(bea, _f._solo(mid)), {}, _stop_at_step(1), 30.0)
	parts = OpponentView.tell_texts(middle, false)
	if parts.size() != 2 or parts[0] != "%s (2/3) · 헛손질" % STYLE_NAME or parts[1] != HINT:
		errs.append("[① 2단 가운데 헛손질] 상태 글 %s (기대 ['%s (2/3) · 헛손질', '%s'])" % [str(parts), STYLE_NAME, HINT])
	_expect_no_frame(errs, "① 2단 가운데 헛손질", middle, DT.Direction.CENTER, DT.Height.HIGH)
	# 2단 가운데: 따라가 속은 뒤.
	var followed: DuelCore = _f._play(_f._drill_opp(bea, _f._solo(mid)), _bite_cfg(), _stop_feints(1), 30.0)
	parts = OpponentView.tell_texts(followed, false)
	if parts.size() != 2 or not parts[0].begins_with("%s (3/3) · 오른쪽" % STYLE_NAME) or parts[1] != HINT or not followed.brain.feint_bitten:
		errs.append("[① 2단 가운데 넘긴 뒤] 상태 글 %s (기대 첫 줄 '%s (3/3) · 오른쪽 …' · 귀띔 '%s' · 속은 표지)" % [str(parts), STYLE_NAME, HINT])
	_expect_frame(errs, "① 2단 가운데 넘긴 뒤", followed, DT.Direction.RIGHT, DT.Height.LOW)


## ① 다섯 상대의 1단 첫 고유 길: 테두리가 지금의 셈(타격의 방향 · 높이 칸, 막으면 guarded)과 같다.
func _other_five(errs: Array[String]) -> void:
	for path: String in [BARTOLO_PATH, BRUNO_PATH, LORENZO_PATH, SERAFINA_PATH, AGOSTINO_PATH]:
		var opp := load(path) as OpponentData
		if opp == null:
			errs.append("[① 다섯] %s가 로드되지 않는다" % path)
			continue
		var roots: Array[AttackData] = _f._signature_roots(opp.attacks)
		if roots.is_empty():
			errs.append("[① 다섯] %s의 1단에 고유 공격이 없다" % opp.display_name)
			continue
		var core: DuelCore = _f._play(_f._drill_opp(opp, _f._solo(roots[0])), {}, _f._stop_first_tell(), 30.0)
		var height: int = core.brain.current_height()
		var direction: int = core.brain.current_attack.direction
		var label := "① 다섯 %s" % opp.display_name
		if core.brain.state != DT.OpponentState.TELL:
			errs.append("[%s] 예비 동작이 아니다" % label)
		elif height < 0:
			if not _guard_on(core, direction, DT.Height.MID) or not DuelScene.strike_cell_frame(core).is_empty():
				errs.append("[%s] 높이 없는 타격에 테두리가 있다" % label)
		else:
			_expect_frame(errs, label, core, direction, height)


## 결투 중 도움말: 헛손질의 줄은 베아트리체에서만(1단과 마지막 단 모두).
func _help_in_duel(errs: Array[String], bea: OpponentData) -> void:
	for path: String in [BARTOLO_PATH, BRUNO_PATH, LORENZO_PATH, SERAFINA_PATH, AGOSTINO_PATH]:
		var opp := load(path) as OpponentData
		if opp != null and DuelHud.help_text(opp).contains(DuelHud.HELP_FEINT):
			errs.append("[도움말] %s에게 헛손질의 줄이 있다" % opp.display_name)
	for tier in [0, bea.tier_count() - 1]:
		if not DuelHud.help_text(bea.at_tier(tier)).contains(DuelHud.HELP_FEINT):
			errs.append("[도움말] 베아트리체 %d단에 헛손질의 줄이 없다" % (tier + 1))


## ③ 연습 화면: 상대 목록 둘째 쪽의 여섯째 칸, 머리 줄, 단 고르기 여섯, 패턴 버튼 하나, 막는 법의 줄.
func _practice_checks(errs: Array[String]) -> void:
	var trials := SelectScript.load_trials()
	var index := -1
	for i in trials.size():
		if trials[i].resource_path == BEATRICE_PATH:
			index = i
	if index < 0:
		errs.append("[③] load_trials()에 베아트리체가 없다")
		return
	if index != 5:
		errs.append("[③] 베아트리체가 %d번째 칸이다 (기대 여섯째)" % (index + 1))
	var entries := trials.size() + (1 if not SelectScript.load_spare_attacks().is_empty() else 0)
	_select = (load(Session.SELECT_PATH) as PackedScene).instantiate()
	_tree.root.add_child(_select)
	var page := _select.find_child("OpponentPage", true, false) as Label
	if page == null or page.text != "1/2":
		errs.append("[③] 처음의 쪽 글 '%s' (기대 1/2 — 상대 목록이 두 쪽)" % ("없음" if page == null else page.text))
	_select.call("pick_opponent", index)
	page = _select.find_child("OpponentPage", true, false) as Label
	if page == null or page.text != "2/2":
		errs.append("[③] 여섯째를 고른 뒤의 쪽 글 '%s' (기대 2/2)" % ("없음" if page == null else page.text))
	var rows := _select.find_children("OpponentPick*", "Button", true, false).size()
	if rows != maxi(entries - SelectScript.LIST_ROWS, 0):
		errs.append("[③] 둘째 쪽의 상대 줄 %d개 (기대 %d)" % [rows, maxi(entries - SelectScript.LIST_ROWS, 0)])
	var head := _select.find_child("TrialHead", true, false)
	var head_texts: Array[String] = []
	if head != null:
		for label in head.find_children("*", "Label", true, false):
			head_texts.append((label as Label).text)
	if not head_texts.has("베아트리체") or not head_texts.has(STYLE_NAME):
		errs.append("[③] TrialHead의 글 %s에 '베아트리체'와 '속임 베기'가 없다" % str(head_texts))
	var pick := _select.find_child("StyleTierPick", true, false) as OptionButton
	if pick == null or pick.item_count != 6:
		errs.append("[③] StyleTierPick의 항목 %s (기대 6)" % ("없음" if pick == null else str(pick.item_count)))
	_check_drill_and_help(errs, "1단")
	if pick != null:
		pick.item_selected.emit(5)
		_check_drill_and_help(errs, "6단")


func _check_drill_and_help(errs: Array[String], label: String) -> void:
	var drills := _select.find_children("PatternDrill*", "Button", true, false)
	if drills.size() != 1:
		errs.append("[③ %s] PatternDrill %d개 (기대 1)" % [label, drills.size()])
	elif (drills[0] as Button).text != STYLE_NAME:
		errs.append("[③ %s] PatternDrill의 글 '%s' (기대 '%s')" % [label, (drills[0] as Button).text, STYLE_NAME])
	if _select.find_child("SlashDrill", true, false) != null:
		errs.append("[③ %s] 베아트리체에게 SlashDrill이 있다" % label)
	var help_node := _select.find_child("PatternHelp", true, false) as Label
	if help_node == null:
		errs.append("[③ %s] PatternHelp가 없다" % label)
		return
	var text := help_node.text
	var has_chain: bool = _f._help_has(text, DuelHud.HELP_CHAIN)
	var has_feint: bool = _f._help_has(text, DuelHud.HELP_FEINT)
	var has_height: bool = _f._help_has(text, DuelHud.HELP_HEIGHT)
	if not has_chain or not has_feint or not has_height:
		errs.append("[③ %s] 막는 법에 이어 치기(%s) · 헛손질(%s) · 높이(%s)의 줄이 다 있지 않다" % [label, has_chain, has_feint, has_height])
	var has_sweep: bool = _f._help_has(text, DuelHud.HELP_SWEEP)
	var has_dive: bool = _f._help_has(text, DuelHud.HELP_DIVE)
	var has_beat: bool = _f._help_has(text, DuelHud.HELP_BEAT)
	if has_sweep or has_dive or has_beat:
		errs.append("[③ %s] 막는 법에 휩쓸기(%s) · 뛰어들기(%s) · 엇박(%s) 줄이 있다" % [label, has_sweep, has_dive, has_beat])


# ================================================================ T139 그림 데이터

const BEA_ART_PATH := "res://data/opponents/beatrice_art.tres"
const BEA_ART_DIR := "res://assets/art/opponents/beatrice/"
const BEA_ART_SIZES := {
	"head": Vector2i(292, 244), "head_oops": Vector2i(291, 245), "head_dizzy": Vector2i(292, 245), "hat": Vector2i(155, 98),
	"feather": Vector2i(196, 55), "torso": Vector2i(246, 441), "legs": Vector2i(417, 431), "arm": Vector2i(66, 226),
	"hand": Vector2i(74, 69), "sword": Vector2i(125, 432), "arm_up_sword": Vector2i(158, 552), "arm_up": Vector2i(92, 292),
	"arm_up_fist": Vector2i(140, 108), "arm_thrust": Vector2i(154, 117), "arm_thrust_fist": Vector2i(154, 238),
	"arm_thrust_sword": Vector2i(285, 289), "arm_thrust_blade": Vector2i(46, 40), "arm_aim": Vector2i(133, 157),
	"arm_aim_fist": Vector2i(133, 192), "arm_aim_sword": Vector2i(187, 197), "arm_aim_blade": Vector2i(107, 109),
}
## 판 S2의 자(결정 693). 한계 가운데 다른 상대와 견주는 것은 데이터에서 읽는다.
const BEA_MAX_BARE_TOP := 345.0
const BEA_MIN_HEAD_MID := 252.0
const BEA_MAX_HAT_TOP := 355.0
const BEA_MIN_FOOT := 195.0
const BEA_MAX_FOOT := 218.0
## 치마 윗선이 골반 위로 올라와 몸판 뒤에 숨는다.
const BEA_MIN_SKIRT_JOINT_Y := 12.0
const BEA_SKIRT_MARGIN := 15.0
const BEA_MAX_SKIRT_WIDTH := 220.0


func t139_beatrice_art() -> String:
	var errs: Array[String] = []
	var bartolo := load(BARTOLO_PATH) as OpponentData
	var bea := load(BEATRICE_PATH) as OpponentData
	if bea == null or bea.art == null or bartolo == null or bartolo.art == null:
		return "opponent_06.tres나 그 그림이 없음"
	var art: OpponentArt = bea.art
	if art.resource_path != BEA_ART_PATH:
		errs.append("그림 데이터 %s (기대 %s)" % [art.resource_path, BEA_ART_PATH])
	if art == bartolo.art:
		errs.append("바르톨로의 그림을 빌려 쓴다")
	_bea_check_files(errs, art, bartolo.art)
	_bea_check_body(errs, art, bartolo.art)
	var client := "res://assets/art/clients/beatrice.png"
	if ResourceLoader.exists(client):
		var tex := load(client) as Texture2D
		if tex == null or Vector2i(tex.get_size()) != Vector2i(450, 675):
			errs.append("의뢰인 그림의 크기 %s (기대 450x675)" % (str(Vector2i(tex.get_size())) if tex != null else "읽을 수 없음"))
	else:
		print("INFO T139: assets/art/clients/beatrice.png가 아직 없다(위험 R7)")
	return _ok(errs)


func _bea_check_files(errs: Array[String], art: OpponentArt, bartolo_art: OpponentArt) -> void:
	for part_name: String in Fourth.ART_PARTS:
		var part := art.get(part_name) as PartArt
		if part == null or part.texture == null or not part.texture.resource_path.begins_with(BEA_ART_DIR):
			errs.append("그림 %s: 없거나 베아트리체의 폴더가 아님" % part_name)
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
				if layer.part != his.layers[k].part or layer.texture == null or not layer.texture.resource_path.begins_with(BEA_ART_DIR):
					errs.append("팔 %s 층 %d: part·그림이 어긋남" % [mine.key, k])
				elif (layer.part == 4) != (layer.outline.size() >= 6):
					errs.append("팔 %s 층 %d: 주먹의 윤곽선이 없거나 주먹이 아닌데 있음" % [mine.key, k])
	var keys: Array[StringName] = []
	for arm_art in art.arm_arts:
		keys.append(arm_art.key)
	for want_key: StringName in [&"armUp", &"armThrust", &"armAim"]:
		if not keys.has(want_key):
			errs.append("팔 묶음 %s가 없음 (%s)" % [want_key, str(keys)])
	for file: String in BEA_ART_SIZES:
		var tex := load(BEA_ART_DIR + file + ".png") as Texture2D
		if tex == null or Vector2i(tex.get_size()) != BEA_ART_SIZES[file]:
			errs.append("%s.png의 크기 %s (기대 %s)" % [file, Vector2i(tex.get_size()) if tex != null else Vector2i.ZERO, BEA_ART_SIZES[file]])


## 몸의 값(결정 693의 식). 눈의 줄 · 이음매 · 상자는 그림을 봐야 아는 값이라 여기서 재지 않는다(판 S2 · S4).
func _bea_check_body(errs: Array[String], art: OpponentArt, bartolo_art: OpponentArt) -> void:
	if art.neck.y < -212.0 or art.neck.y > -198.0:
		errs.append("neck.y %.1f (기대 -212~-198)" % art.neck.y)
	if art.legs == null or art.legs.texture == null or art.head == null or art.hat == null:
		return
	var serafina := load(SERAFINA_PATH) as OpponentData
	if serafina == null or serafina.art == null:
		errs.append("세라피나의 그림이 없음")
		return
	var widest: float = 0.0
	for path: String in [BARTOLO_PATH, BRUNO_PATH, LORENZO_PATH, SERAFINA_PATH, AGOSTINO_PATH]:
		var other := load(path) as OpponentData
		if other == null or other.art == null or other.art.legs == null or other.art.legs.texture == null:
			errs.append("%s의 다리 그림이 없음" % path)
			continue
		widest = maxf(widest, float(other.art.legs.texture.get_width()) * other.art.legs.units_per_px.x)
	var serafina_top: float = _f._bare_top(serafina.art, serafina.art.head)
	var hat_limit: float = minf(_f._hat_top(bartolo_art), BEA_MAX_HAT_TOP)
	var hat_top: float = _f._hat_top(art)
	var foot: float = _f._foot_tip(art)
	var joint_y: float = art.legs.joint.y * art.legs.units_per_px.y
	var skirt: float = float(art.legs.texture.get_width()) * art.legs.units_per_px.x
	print("INFO T139: 모자 쓴 꼭대기 %.1f (바르톨로 %.1f) · 발끝 %.1f · 치마 관절 %.1f · 치마 폭 %.1f (다섯 가운데 가장 넓은 %.1f) · 세라피나 꼭대기 %.1f" % [hat_top, _f._hat_top(bartolo_art), foot, joint_y, skirt, widest, serafina_top])
	if hat_top > hat_limit + 0.01:
		errs.append("모자 쓴 꼭대기 %.2f (바르톨로의 값 %.2f와 %.0f 이하여야 한다)" % [hat_top, _f._hat_top(bartolo_art), BEA_MAX_HAT_TOP])
	for head_part: PartArt in [art.head, art.head_oops, art.head_dizzy]:
		if head_part == null:
			errs.append("머리 셋 가운데 빈 것이 있다")
			continue
		var top: float = _f._bare_top(art, head_part)
		var mid: float = top - head_part.joint.y * head_part.units_per_px.y / 2.0
		print("INFO T139: 모자 없는 꼭대기 %.1f · 머리 가운데 %.1f" % [top, mid])
		if top >= serafina_top - 0.01 or top > BEA_MAX_BARE_TOP + 0.01:
			errs.append("모자 없는 꼭대기 %.2f (세라피나 %.2f보다, 그리고 %.0f 이하로 낮아야 한다)" % [top, serafina_top, BEA_MAX_BARE_TOP])
		if mid < BEA_MIN_HEAD_MID - 0.01:
			errs.append("머리 가운데의 자 %.2f (%.0f 이상이어야 한다)" % [mid, BEA_MIN_HEAD_MID])
	if foot < BEA_MIN_FOOT - 0.01 or foot > BEA_MAX_FOOT + 0.01:
		errs.append("발끝 %.2f (기대 %.0f~%.0f)" % [foot, BEA_MIN_FOOT, BEA_MAX_FOOT])
	if joint_y < BEA_MIN_SKIRT_JOINT_Y:
		errs.append("치마 관절의 높이 %.2f (%.0f 이상이어야 윗선이 몸판 뒤에 숨는다)" % [joint_y, BEA_MIN_SKIRT_JOINT_Y])
	if skirt < widest + BEA_SKIRT_MARGIN - 0.01 or skirt > BEA_MAX_SKIRT_WIDTH + 0.01:
		errs.append("치마 폭 %.2f (다섯의 가장 넓은 다리 %.2f + %.0f 이상, %.0f 이하여야 한다)" % [skirt, widest, BEA_SKIRT_MARGIN, BEA_MAX_SKIRT_WIDTH])
