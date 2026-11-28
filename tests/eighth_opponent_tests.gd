extends RefCounted
## T163~T165: 여덟째 상대 코르넬리아(계획 053, 결정 825~845). 데이터의 틀·송곳 가림 길의 표·가방, 송곳 가림의 판, 표시와 연습 화면.
## 값(길의 칸·간격·가림·빈틈·단·가방)은 결정 834·835·836의 표를 손으로 적은 기대다. 로드한 자원은 고치지 않는다(사본만).
## 값 고침의 차례(결정 838)가 옮길 수 있는 값(찌르기의 가중치·좌우 베기의 빈틈·가림 길의 가중치·빈틈)은 아래 상수와 표가 함께 옮기는 기대다.
## States.put으로 놓은 코어에는 advance · tick을 부르지 않는다. 판은 처음부터 tick으로 몰고, 표시의 정적 함수는 tick 없이 부른다.

const Fourth := preload("res://tests/fourth_opponent_tests.gd")
const Bot := preload("res://tests/duel_bots.gd")
const DT := preload("res://scripts/duel/duel_types.gd")
const SelectScript := preload("res://scripts/commission/commission_select.gd")
const Session := preload("res://scripts/game_session.gd")

const CORNELIA_PATH := "res://data/opponents/opponent_08.tres"
const BARTOLO_PATH := "res://data/opponents/opponent_01.tres"
const BRUNO_PATH := "res://data/opponents/opponent_02.tres"
const LORENZO_PATH := "res://data/opponents/opponent_03.tres"
const SERAFINA_PATH := "res://data/opponents/opponent_04.tres"
const AGOSTINO_PATH := "res://data/opponents/opponent_05.tres"
const BEATRICE_PATH := "res://data/opponents/opponent_06.tres"
const GUGLIELMO_PATH := "res://data/opponents/opponent_07.tres"
const COMMISSION_DIR := "res://data/commissions"
const STYLE_NAME := "송곳 가림"
## 고유 색(결정 833): 녹청빛.
const SIG_COLOR := Color(0.15, 0.5, 0.45, 1.0)
const FROM_DAYS: Array[int] = [10, 11, 12, 13, 14]
const ROOT_TELL := 0.9
const ROOT_WEIGHT := 2.0
const ROOT_RECOVERY := 1.0
const TIME_TOL := 0.04
## 기본 셋(결정 834). 결정 838의 값 고침이 옮길 수 있다.
const THRUST_WEIGHT := 3.0
const CUT_RECOVERY := 0.55
## 가방(결정 836): 찌르기 + 좌우 베기 둘 + 송곳 가림 + 3단의 겹찌르기 + 5단의 찌르고 베기.
const BAG_SIZES: Array[int] = [7, 7, 8, 8, 9, 9]
const BASIC_DIRECTIONS := {"찌르기": 1, "왼쪽 베기": 0, "오른쪽 베기": 2}
const BASIC_HEIGHTS := {"찌르기": [2], "왼쪽 베기": [0], "오른쪽 베기": [0]}
## 길의 표(결정 835). 이름표 -> [뿌리 방향, 뿌리 높이, [[방향, 높이, 앞의 간격], …], 가린 줄]. 방향 0 왼 · 1 가 · 2 오, 높이 0 상 · 1 중 · 2 하.
const ROUTE_SPECS := {
	"A": [0, 0, [[2, 1, 0.65]], [2]],
	"B": [2, 0, [[0, 1, 0.65]], [0]],
	"C": [1, 0, [[2, 1, 0.65]], [1]],
	"D": [0, 0, [[1, 1, 0.65], [2, 2, 0.6]], [2]],
	"E": [2, 2, [[1, 1, 0.65], [0, 0, 0.6]], [1]],
	"F": [0, 1, [[2, 1, 0.65]], [2, 1]],
	"G": [1, 0, [[0, 2, 0.65]], [0, 2]],
	"H": [2, 0, [[0, 1, 0.65], [1, 2, 0.6], [2, 1, 0.55]], [2, 0]],
}
## 단마다의 길(변주까지). 3단은 2단과, 5단은 4단과 같다.
const TIER_ROUTES := [
	["A", "B", "C"],
	["A", "B", "C", "D", "E"],
	["A", "B", "C", "D", "E"],
	["A", "B", "C", "D", "E", "F", "G"],
	["A", "B", "C", "D", "E", "F", "G"],
	["A", "B", "C", "D", "E", "F", "G", "H"],
]
const TIER_NAMES := [
	["찌르기", "왼쪽 베기", "오른쪽 베기", "송곳 가림"],
	["찌르기", "왼쪽 베기", "오른쪽 베기", "송곳 가림"],
	["찌르기", "왼쪽 베기", "오른쪽 베기", "송곳 가림", "겹찌르기"],
	["찌르기", "왼쪽 베기", "오른쪽 베기", "송곳 가림", "겹찌르기"],
	["찌르기", "왼쪽 베기", "오른쪽 베기", "송곳 가림", "겹찌르기", "찌르고 베기"],
	["찌르기", "왼쪽 베기", "오른쪽 베기", "송곳 가림", "겹찌르기", "찌르고 베기"],
]

var _tree: SceneTree
var _f: Fourth = Fourth.new()
var _select: Node = null


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T163", "name": "여덟째 상대: 판정 값이 바르톨로와 같다, 기본 셋의 높이, 송곳 가림 길의 표(방향·높이·간격·가림·빈틈)와 단·가방, 고유 색 하나, 겹침의 몫, 하루에는 서지 않는다, 갈래 글", "fn": t163_eighth_opponent},
		{"id": "T164", "name": "송곳 가림의 판: 읽는 손은 빈 줄로 스치고 안 읽는 마지막 줄 손은 겹치는 길에서 걸린다, 타격의 시각, cover 열쇠, 같은 씨앗, 봇의 한 판, 실제 코르넬리아", "fn": t164_cover_duel},
		{"id": "T165", "name": "표시와 연습 화면: 가림의 예고, 첫 줄·귀띔, 일곱 상대는 그대로, 결투 중 도움말, 연습의 둘째 쪽과 막는 법, CoverMarks 노드", "fn": t165_marks_and_practice},
		{"id": "T166", "name": "그림 데이터: 스물한 장과 팔 셋, 모자 없는 꼭대기·머리 가운데의 자·모자 쓴 꼭대기·발끝, 키가 여덟의 아래쪽 셋, 다리 관절, 몸통 그림의 골반 아래 길이(긴 상자), 의뢰인 그림", "fn": t166_cornelia_art},
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


## 표의 길 하나의 열쇠: 타격마다 "방향/높이@간격"을 ">"로 잇고 끝에 "#가린 줄".
func _spec_key(spec: Array) -> String:
	var parts: Array[String] = ["%d/%d@%.2f" % [int(spec[0]), int(spec[1]), ROOT_TELL]]
	for step: Array in spec[2]:
		parts.append("%d/%d@%.2f" % [int(step[0]), int(step[1]), float(step[2])])
	return ">".join(parts) + "#" + str(spec[3])


func _data_key(route: AttackData) -> String:
	var parts: Array[String] = []
	for s in _f._strike_list(route):
		parts.append("%d/%s@%.2f" % [s.direction, str(s.heights[0]) if s.heights.size() == 1 else "?", s.tell_time])
	return ">".join(parts) + "#" + str(route.cover_columns)


func _names_by_key() -> Dictionary:
	var out := {}
	for key: String in ROUTE_SPECS:
		out[_spec_key(ROUTE_SPECS[key])] = key
	return out


## 단 하나의 고유 뿌리(없거나 여럿이면 null).
func _the_root(opp: OpponentData, k: int) -> AttackData:
	var roots: Array[AttackData] = _f._signature_roots(opp.at_tier(k).attacks)
	return roots[0] if roots.size() == 1 else null


func _tell_core(opp: OpponentData, route: AttackData) -> DuelCore:
	return _f._play(_f._drill_opp(opp, _f._solo(route)), {}, _f._stop_first_tell(), 30.0)


# ================================================================ T163 데이터

func t163_eighth_opponent() -> String:
	var errs: Array[String] = []
	var bartolo := load(BARTOLO_PATH) as OpponentData
	var cor := load(CORNELIA_PATH) as OpponentData
	if cor == null or bartolo == null:
		return "opponent_08.tres나 opponent_01.tres가 로드되지 않는다"
	if cor.display_name != "코르넬리아" or cor.style_name != STYLE_NAME:
		errs.append("이름 '%s' · 갈래 '%s'" % [cor.display_name, cor.style_name])
	if cor.sword_side != DT.Direction.LEFT:
		errs.append("칼 든 팔이 왼쪽이 아니다 (%d)" % cor.sword_side)
	if cor.art == null:
		errs.append("그림 데이터(art)가 비었다")
	_f._compare(bartolo, cor, "opponent", errs, Fourth.FREE_FIELDS + ["attacks"] + Fourth.SWORD_FIELDS)
	_check_basics(errs, cor, bartolo)
	_check_tiers(errs, cor, bartolo)
	for k in cor.tier_count():
		var brain := OpponentBrain.new(cor.at_tier(k), _f._seeded())
		brain.start_idle(0.0)
		brain.start_tell(0.0, false)
		var cards: int = brain.bag_remaining() + 1
		if k >= BAG_SIZES.size() or cards != BAG_SIZES[k]:
			errs.append("%d단의 가방 %d장 (기대 %s)" % [k + 1, cards, str(BAG_SIZES[k]) if k < BAG_SIZES.size() else "없음"])
	var users: Array[String] = []
	for commission in CommissionLibrary.load_tree(COMMISSION_DIR):
		if commission.opponent != null and commission.opponent.resource_path == CORNELIA_PATH:
			users.append(commission.resource_path.get_file())
	if not users.is_empty():
		errs.append("코르넬리아를 거는 의뢰 %s (기대 없음 — 계획 057이 만든다)" % str(users))
	if cor.style_label(8) != "코르넬리아 · 송곳 가림":
		errs.append("style_label(8) '%s' (기대 '코르넬리아 · 송곳 가림')" % cor.style_label(8))
	for i in FROM_DAYS.size():
		var want := "코르넬리아 · 송곳 가림 %d단" % (i + 2)
		if cor.style_label(FROM_DAYS[i]) != want:
			errs.append("style_label(%d) '%s' (기대 '%s')" % [FROM_DAYS[i], cor.style_label(FROM_DAYS[i]), want])
	if cor.style_label(20) != "코르넬리아 · 송곳 가림 6단":
		errs.append("style_label(20) '%s' (기대 마지막 단 6단에 머문다)" % cor.style_label(20))
	return _ok(errs)


## 1단: 공격 넷(찌르기 · 좌우 베기 · 송곳 가림). 방향 · 예비는 바르톨로와 같고 높이는 아래로 찌르고 위로 벤다(결정 834).
func _check_basics(errs: Array[String], cor: OpponentData, bartolo: OpponentData) -> void:
	if cor.attacks.size() != 4:
		errs.append("1단의 공격 %d개 (기대 4)" % cor.attacks.size())
		return
	for attack_name: String in BASIC_DIRECTIONS:
		var mine: AttackData = _f._find_named(cor.attacks, attack_name)
		var his: AttackData = _f._find_named(bartolo.attacks, attack_name)
		if mine == null or his == null:
			errs.append("1단에 %s가 없다 (코르넬리아 %s · 바르톨로 %s)" % [attack_name, mine != null, his != null])
			continue
		if mine.direction != BASIC_DIRECTIONS[attack_name] or not _near(mine.tell_time, his.tell_time):
			errs.append("%s의 방향 %d · 예비 %.2f (기대 %d · %.2f)" % [attack_name, mine.direction, mine.tell_time, BASIC_DIRECTIONS[attack_name], his.tell_time])
		if str(mine.heights) != str(BASIC_HEIGHTS[attack_name]):
			errs.append("%s의 높이 %s (기대 %s)" % [attack_name, str(mine.heights), str(BASIC_HEIGHTS[attack_name])])
		var want_recovery := 0.0 if attack_name == "찌르기" else CUT_RECOVERY
		var want_weight := THRUST_WEIGHT if attack_name == "찌르기" else 1.0
		if not _near(mine.recovery_time, want_recovery) or not _near(mine.weight, want_weight):
			errs.append("%s의 빈틈 %.2f · 가중치 %.1f (기대 %.2f · %.1f)" % [attack_name, mine.recovery_time, mine.weight, want_recovery, want_weight])
		if mine.signature or not mine.cover_columns.is_empty():
			errs.append("%s가 고유나 가림 길이다" % attack_name)
	var pair_name := "겹찌르기"
	var cut_name := "찌르고 베기"
	var three := _f._find_named(cor.at_tier(2).attacks, pair_name)
	if three == null or str(three.heights) != "[2]" or three.chain.size() != 1 or str((three.chain[0] as AttackData).heights) != "[2]":
		errs.append("3단의 겹찌르기 높이가 [2] · [2]가 아니다")
	var five := _f._find_named(cor.at_tier(4).attacks, cut_name)
	if five == null or str(five.heights) != "[2]" or five.chain.size() != 1 or str((five.chain[0] as AttackData).heights) != "[0]":
		errs.append("5단의 찌르고 베기 높이가 [2] · [0]이 아니다")
	elif five.variants.size() != 1 or str(((five.variants[0] as AttackData).chain[0] as AttackData).heights) != "[0]":
		errs.append("5단의 찌르고 베기 변주의 높이가 [0]이 아니다")


## 단마다: 공격 이름, 길 표, 뿌리의 값, 걸음의 칸, 3·5단의 같은 뿌리, 고유 색 하나, 겹침의 몫.
func _check_tiers(errs: Array[String], cor: OpponentData, _bartolo: OpponentData) -> void:
	var names := _names_by_key()
	var colors: Array[Color] = []
	for k in cor.tier_count():
		var list: Array = cor.at_tier(k).attacks
		var got: Array[String] = []
		for atk: AttackData in list:
			got.append(atk.attack_name)
		if k >= TIER_NAMES.size() or str(got) != str(TIER_NAMES[k]):
			errs.append("%d단의 공격 %s (기대 %s)" % [k + 1, str(got), str(TIER_NAMES[k]) if k < TIER_NAMES.size() else "없음"])
			continue
		var root := _the_root(cor, k)
		if root == null:
			errs.append("%d단의 고유 뿌리가 하나가 아니다" % (k + 1))
			continue
		var found: Array[String] = []
		var overlap := 0
		var routes := 0
		for route in _f._routes(root):
			routes += 1
			var key := _data_key(route)
			if not names.has(key):
				errs.append("%d단의 길 '%s'가 표에 없다" % [k + 1, key])
				continue
			found.append(names[key])
			var spec: Array = ROUTE_SPECS[names[key]]
			if not _near(route.tell_time, ROOT_TELL) or not _near(route.weight, ROOT_WEIGHT) or route.is_big or route.tell_hint != "":
				errs.append("%d단 길 %s: 예비 %.2f · 가중치 %.1f · 큰 공격 %s · 귀띔 '%s'" % [k + 1, names[key], route.tell_time, route.weight, str(route.is_big), route.tell_hint])
			if not _near(route.recovery_time, ROOT_RECOVERY) or route.attack_name != STYLE_NAME or not route.signature:
				errs.append("%d단 길 %s: 빈틈 %.2f · 이름 '%s' · 고유 %s" % [k + 1, names[key], route.recovery_time, route.attack_name, str(route.signature)])
			if route.withdraw or route.feint or route.sweep or route.dive or route.needs_raised_guard or route.mark_shape != &"":
				errs.append("%d단 길 %s에 다른 갈래의 칸이 있다" % [k + 1, names[key]])
			for s in _f._strike_list(route):
				colors.append(s.pose_color)
				if s != route and (not s.cover_columns.is_empty() or s.recovery_time != 0.0):
					errs.append("%d단 길 %s의 걸음에 cover_columns나 빈틈이 있다" % [k + 1, names[key]])
			var last := _f._strike_list(route).back() as AttackData
			if (spec[3] as Array).has(last.direction):
				overlap += 1
		found.sort()
		var want: Array[String] = []
		for n: String in TIER_ROUTES[k]:
			want.append(n)
		want.sort()
		if str(found) != str(want):
			errs.append("%d단의 길 %s (기대 %s)" % [k + 1, str(found), str(want)])
		# 겹침의 몫(결정 835): 가림 길의 반 이상이 마지막 타격의 줄을 가린다.
		if overlap * 2 < routes:
			errs.append("%d단의 겹치는 길 %d/%d (반 이상이어야 한다)" % [k + 1, overlap, routes])
		# 가림 길마다 한 줄은 늘 빈다.
		for route in _f._routes(root):
			if route.cover_columns.size() < 1 or route.cover_columns.size() > 2:
				errs.append("%d단의 가림 줄 %s (1~2개여야 한다)" % [k + 1, str(route.cover_columns)])
	for c in colors:
		if absf(c.r - SIG_COLOR.r) > 0.01 or absf(c.g - SIG_COLOR.g) > 0.01 or absf(c.b - SIG_COLOR.b) > 0.01:
			errs.append("고유 색이 녹청빛 하나가 아니다 (%s)" % str(c))
			break
	# 3단은 2단의, 5단은 4단의 뿌리를 같은 자원으로 가리킨다.
	for pair: Array in [[1, 2], [3, 4]]:
		var a := _the_root(cor, pair[0])
		var b := _the_root(cor, pair[1])
		if a == null or b == null or a != b:
			errs.append("%d단과 %d단의 뿌리가 같은 자원이 아니다" % [int(pair[0]) + 1, int(pair[1]) + 1])


# ================================================================ T164 판

func t164_cover_duel() -> String:
	var errs: Array[String] = []
	var cor := load(CORNELIA_PATH) as OpponentData
	if cor == null:
		return "opponent_08.tres가 로드되지 않는다"
	_t164_routes(errs, cor)
	_t164_same_seed(errs, cor)
	_t164_whole(errs, cor)
	return _ok(errs)


func _last_cell() -> Callable:
	return func(ev: Dictionary) -> Variant:
		var atk := ev["attack"] as AttackData
		var height := int(ev.get("height", -1))
		return [atk.direction, height if height >= 0 else DT.Height.MID]


func _first_attack(core: DuelCore) -> Dictionary:
	var seen := core.record.of_type(DuelRecord.ATTACK)
	return seen[0] if not seen.is_empty() else {}


func _stop_first_attack() -> Callable:
	return func(core: DuelCore) -> bool: return not core.record.of_type(DuelRecord.ATTACK).is_empty()


## 모든 단의 모든 길: (가) 읽는 손과 안 읽는 마지막 줄 손 (나) 타격의 시각과 cover 열쇠.
func _t164_routes(errs: Array[String], cor: OpponentData) -> void:
	var names := _names_by_key()
	for k in cor.tier_count():
		var root := _the_root(cor, k)
		if root == null:
			errs.append("[%d단] 고유 뿌리가 없다" % (k + 1))
			continue
		for route in _f._routes(root):
			var key := _data_key(route)
			var label := "%d단 %s" % [k + 1, names.get(key, key)]
			if not names.has(key):
				continue
			var spec: Array = ROUTE_SPECS[names[key]]
			var solo := _f._drill_opp(cor.at_tier(k), _f._solo(route))
			# (나) 막기만: 타격의 시각과 cover.
			var held: DuelCore = _f._play(solo, {"guard_fn": func(_a: AttackData, _i: int) -> StringName: return &"hold"}, _f._stop_after_strike(route.chain.size() + 1, 0.05), 30.0)
			var strikes := held.record.of_type(DuelRecord.STRIKE)
			if strikes.size() != route.chain.size() + 1:
				errs.append("[%s] 타격 %d번 (기대 %d)" % [label, strikes.size(), route.chain.size() + 1])
				continue
			for i in range(1, strikes.size()):
				var gap := float(strikes[i]["t"]) - float(strikes[i - 1]["t"])
				var want_gap := float((spec[2] as Array)[i - 1][2])
				if absf(gap - want_gap) > TIME_TOL:
					errs.append("[%s] %d번째 간격 %.2f (기대 %.2f)" % [label, i + 1, gap, want_gap])
			for i in strikes.size():
				var has := strikes[i].has("cover")
				if (i == strikes.size() - 1) != has or (has and str(strikes[i]["cover"]) != str(spec[3])):
					errs.append("[%s] %d번째 STRIKE의 cover %s (기대 %s)" % [label, i + 1, str(strikes[i].get("cover", "없음")), str(spec[3]) if i == strikes.size() - 1 else "없음"])
			# (가) 마지막 줄로 받아치는 손: 읽으면 스치고 안 읽으면 겹치는 길에서만 걸린다.
			var overlap := (spec[3] as Array).has((_f._strike_list(route).back() as AttackData).direction)
			var reads: DuelCore = _f._play(solo, {"counter_fn": _last_cell(), "counter_delay": 0.25}, _stop_first_attack(), 30.0)
			var read_ev := _first_attack(reads)
			if read_ev.is_empty() or bool(read_ev.get("spiked", false)) or int(read_ev["result"]) != DT.AttackResult.GRAZE:
				errs.append("[%s] 읽는 손이 스치지 못했다 (%s)" % [label, str(read_ev.get("result", "판정 없음"))])
			var blind_cfg := {"counter_fn": _last_cell(), "counter_delay": 0.25, "cover_read_fn": func(_ev: Dictionary) -> bool: return false}
			var blind: DuelCore = _f._play(solo, blind_cfg, _stop_first_attack(), 30.0)
			var blind_ev := _first_attack(blind)
			if blind_ev.is_empty() or bool(blind_ev.get("spiked", false)) != overlap:
				errs.append("[%s] 안 읽는 손의 걸림 %s (기대 %s)" % [label, str(blind_ev.get("spiked", false)), str(overlap)])


## (다) 같은 씨앗이면 마지막 단의 판이 같은 이벤트 줄이다.
func _t164_same_seed(errs: Array[String], cor: OpponentData) -> void:
	var last := cor.at_tier(cor.tier_count() - 1)
	var cfg := {"counter_fn": _last_cell(), "counter_delay": 0.25}
	var a: DuelCore = _f._play(last, cfg, _f._never(), 20.0)
	var b: DuelCore = _f._play(last, cfg.duplicate(), _f._never(), 20.0)
	if _f._lines(a) != _f._lines(b):
		errs.append("[다] 같은 씨앗의 마지막 단 판이 다르다")


## (라)(마) 봇이 1단과 마지막 단을 상대로 한 판을 끝내고, 실제 코르넬리아에서 cover 열쇠가 한 번 이상 선다.
func _t164_whole(errs: Array[String], cor: OpponentData) -> void:
	for k in [0, cor.tier_count() - 1]:
		var core: DuelCore = _f._play(cor.at_tier(k), Bot.first_blood_cfg(), _f._never(), 150.0)
		if not core.ended:
			errs.append("[라] %d단 판이 150초 안에 끝나지 않았다" % (k + 1))
	var run: DuelCore = _f._play(cor, {"counter_fn": _last_cell(), "counter_delay": 0.25}, _f._never(), 60.0)
	var covers := 0
	for ev in run.record.of_type(DuelRecord.STRIKE):
		if ev.has("cover"):
			covers += 1
	if covers < 1:
		errs.append("[마] 실제 코르넬리아 60초에 cover 열쇠가 한 번도 없다")


# ================================================================ T165 표시와 연습 화면

func t165_marks_and_practice() -> String:
	var errs: Array[String] = []
	var cor := load(CORNELIA_PATH) as OpponentData
	if cor == null:
		return "opponent_08.tres가 로드되지 않는다"
	_marks_and_texts(errs, cor)
	_seven_untouched(errs)
	_help_in_duel(errs, cor)
	_practice_checks(errs)
	_scene_node(errs)
	_free_select()
	return _ok(errs)


func _route_of(cor: OpponentData, k: int, key_name: String) -> AttackData:
	for route in _f._routes(_the_root(cor, k)):
		if _data_key(route) == _spec_key(ROUTE_SPECS[key_name]):
			return route
	return null


## 표지 한 줄의 예고: 첫 예비 동작에 {columns, live 거짓}, 고리의 열쇠는 그대로, 첫 줄에 가림의 글이 없다.
func _marks_and_texts(errs: Array[String], cor: OpponentData) -> void:
	var route_a := _route_of(cor, 0, "A")
	if route_a == null:
		errs.append("[①] 1단에 길 A가 없다")
		return
	var tell := _tell_core(cor, route_a)
	var marks := CoverMarks.cover_marks_of(tell)
	if marks.is_empty() or str(marks["columns"]) != "[2]" or bool(marks["live"]):
		errs.append("[① 1단 A] cover_marks_of %s (기대 {[2], 거짓})" % str(marks))
	for mark in OpponentView.pattern_marks(tell.brain, tell.time):
		if mark["role"] == &"path":
			continue
		var names: Array[String] = []
		for key in mark.keys():
			names.append(str(key))
		names.sort()
		if ",".join(names) != "number,pos,role,time":
			errs.append("[① 1단 A] 고리의 열쇠 %s (기대 number,pos,role,time)" % ",".join(names))
	var parts := OpponentView.tell_texts(tell, false)
	if parts.size() != 2 or not parts[0].begins_with("%s (1/2) · " % STYLE_NAME) or parts[1] != "" or parts[0].contains("송곳 —"):
		errs.append("[① 1단 A] 상태 글 %s (기대 첫 줄 '%s (1/2) · …' · 귀띔 빈 글)" % [str(parts), STYLE_NAME])
	# 6단 H(4타): 첫 예비부터 빈틈 끝까지 매 틱 표지가 이어진다.
	var route_h := _route_of(cor, 5, "H")
	if route_h == null:
		errs.append("[①] 6단에 길 H가 없다")
		return
	var solo := _f._drill_opp(cor.at_tier(5), _f._solo(route_h))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var weapon := (load("res://data/weapons/rapier.tres") as WeaponData).duplicate() as WeaponData
	weapon.close_bind_time = 0.0
	var core := DuelCore.new()
	var none: Array[CommissionCondition] = []
	core.setup(_f._rules(), weapon, solo, rng, none, false)
	var bot := Bot.new(core, {"guard_fn": func(_a: AttackData, _i: int) -> StringName: return &"hold"})
	core.step(1)
	var started := false
	var gaps := 0
	var closed := false
	while not core.ended and core.time < 30.0:
		core.tick(1.0 / 60.0)
		bot.update()
		if not started:
			started = not core.record.of_type(DuelRecord.TELL_START).is_empty()
			if not started:
				continue
		var seen := CoverMarks.cover_marks_of(core)
		if core.brain.state == DT.OpponentState.IDLE and core.record.of_type(DuelRecord.STRIKE).size() >= 4:
			closed = seen.is_empty()
			break
		if seen.is_empty() or str(seen["columns"]) != "[2, 0]":
			gaps += 1
	if not closed or gaps != 0:
		errs.append("[① 6단 H] 표지가 끊긴 틱 %d · 빈틈 뒤 비움 %s (기대 0 · 참)" % [gaps, str(closed)])


## ② 일곱 상대의 모든 단·길에 cover_columns가 비고, 봇 판 20초 동안 표지가 늘 빈 사전이다(1단 · 마지막 단).
func _seven_untouched(errs: Array[String]) -> void:
	for path: String in [BARTOLO_PATH, BRUNO_PATH, LORENZO_PATH, SERAFINA_PATH, AGOSTINO_PATH, BEATRICE_PATH, GUGLIELMO_PATH]:
		var opp := load(path) as OpponentData
		if opp == null:
			errs.append("[②] %s가 로드되지 않는다" % path)
			continue
		for list: Array in _f._tier_lists(opp):
			for atk: AttackData in list:
				for route in _f._routes(atk):
					for s in _f._strike_list(route):
						if not s.cover_columns.is_empty():
							errs.append("[②] %s의 '%s'에 cover_columns가 있다" % [opp.display_name, route.attack_name])
		for k in [0, opp.tier_count() - 1]:
			var rng := RandomNumberGenerator.new()
			rng.seed = 1
			var weapon := (load("res://data/weapons/rapier.tres") as WeaponData).duplicate() as WeaponData
			weapon.close_bind_time = 0.0
			var core := DuelCore.new()
			var none: Array[CommissionCondition] = []
			core.setup(_f._rules(), weapon, opp.at_tier(k), rng, none, false)
			var bot := Bot.new(core, Bot.first_blood_cfg())
			core.step(1)
			var shown := 0
			while not core.ended and core.time < 20.0:
				core.tick(1.0 / 60.0)
				bot.update()
				if not CoverMarks.cover_marks_of(core).is_empty():
					shown += 1
			if shown != 0:
				errs.append("[②] %s %d단의 표지가 %d틱 선다 (기대 0)" % [opp.display_name, k + 1, shown])


## ③ 결투 중 도움말: 가림의 줄은 코르넬리아에서만(1단과 마지막 단 모두).
func _help_in_duel(errs: Array[String], cor: OpponentData) -> void:
	for path: String in [BARTOLO_PATH, BRUNO_PATH, LORENZO_PATH, SERAFINA_PATH, AGOSTINO_PATH, BEATRICE_PATH, GUGLIELMO_PATH]:
		var opp := load(path) as OpponentData
		if opp != null and DuelHud.help_text(opp).contains(DuelHud.HELP_COVER):
			errs.append("[도움말] %s에게 송곳 가림의 줄이 있다" % opp.display_name)
	for tier in [0, cor.tier_count() - 1]:
		if not DuelHud.help_text(cor.at_tier(tier)).contains(DuelHud.HELP_COVER):
			errs.append("[도움말] 코르넬리아 %d단에 송곳 가림의 줄이 없다" % (tier + 1))


## ③ 연습 화면: 상대 목록 둘째 쪽의 여덟째 칸, 머리 줄, 단 고르기 여섯, 패턴 버튼 하나, 막는 법의 줄.
func _practice_checks(errs: Array[String]) -> void:
	var trials := SelectScript.load_trials()
	var index := -1
	for i in trials.size():
		if trials[i].resource_path == CORNELIA_PATH:
			index = i
	if index < 0:
		errs.append("[③] load_trials()에 코르넬리아가 없다")
		return
	if index != 7 or index < SelectScript.LIST_ROWS:
		errs.append("[③] 코르넬리아 %d번째 칸 (기대 여덟째 — 둘째 쪽)" % (index + 1))
	var entries := trials.size() + (1 if not SelectScript.load_spare_attacks().is_empty() else 0)
	_select = (load(Session.SELECT_PATH) as PackedScene).instantiate()
	_tree.root.add_child(_select)
	_select.call("pick_opponent", index)
	var page := _select.find_child("OpponentPage", true, false) as Label
	if page == null or page.text != "2/2":
		errs.append("[③] 여덟째를 고른 뒤의 쪽 글 '%s' (기대 2/2)" % ("없음" if page == null else page.text))
	var rows := _select.find_children("OpponentPick*", "Button", true, false).size()
	if rows != maxi(entries - SelectScript.LIST_ROWS, 0):
		errs.append("[③] 둘째 쪽의 상대 줄 %d개 (기대 %d)" % [rows, maxi(entries - SelectScript.LIST_ROWS, 0)])
	var head := _select.find_child("TrialHead", true, false)
	var head_texts: Array[String] = []
	if head != null:
		for label in head.find_children("*", "Label", true, false):
			head_texts.append((label as Label).text)
	if not head_texts.has("코르넬리아") or not head_texts.has(STYLE_NAME):
		errs.append("[③] TrialHead의 글 %s에 '코르넬리아'와 '송곳 가림'이 없다" % str(head_texts))
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
		errs.append("[③ %s] 코르넬리아에게 SlashDrill이 있다" % label)
	var help_node := _select.find_child("PatternHelp", true, false) as Label
	if help_node == null:
		errs.append("[③ %s] PatternHelp가 없다" % label)
		return
	var text := help_node.text
	var has_cover: bool = _f._help_has(text, DuelHud.HELP_COVER)
	var has_height: bool = _f._help_has(text, DuelHud.HELP_HEIGHT)
	if not has_cover or not has_height:
		errs.append("[③ %s] 막는 법에 가림(%s) · 높이(%s)의 줄이 다 있지 않다" % [label, has_cover, has_height])
	var has_sweep: bool = _f._help_has(text, DuelHud.HELP_SWEEP)
	var has_dive: bool = _f._help_has(text, DuelHud.HELP_DIVE)
	var has_beat: bool = _f._help_has(text, DuelHud.HELP_BEAT)
	var has_feint: bool = _f._help_has(text, DuelHud.HELP_FEINT)
	var has_withdraw: bool = _f._help_has(text, DuelHud.HELP_WITHDRAW)
	if has_sweep or has_dive or has_beat or has_feint or has_withdraw:
		errs.append("[③ %s] 막는 법에 휩쓸기 · 뛰어들기 · 엇박 · 헛손질 · 빠지기 줄이 있다" % label)
	if want_chain and not _f._help_has(text, DuelHud.HELP_CHAIN):
		errs.append("[③ %s] 막는 법에 이어 치기 줄이 없다 (이어지는 길이 있는 단)" % label)


## ④ 결투 씬: CoverMarks가 OpponentView 뒤, HUD 앞에 있다.
func _scene_node(errs: Array[String]) -> void:
	var scene: Node = (load("res://scenes/duel/duel.tscn") as PackedScene).instantiate()
	scene.set("mouse_aim_enabled", false)
	scene.set("rng_seed", 1)
	_tree.root.add_child(scene)
	var marks := scene.get_node_or_null(^"CoverMarks")
	var opponent_view := scene.get_node_or_null(^"OpponentView")
	var hud := scene.get_node_or_null(^"HUD")
	if marks == null or opponent_view == null or hud == null:
		errs.append("[④] CoverMarks %s · OpponentView %s · HUD %s" % [str(marks != null), str(opponent_view != null), str(hud != null)])
	elif marks.get_index() != opponent_view.get_index() + 1 or marks.get_index() > hud.get_index():
		errs.append("[④] CoverMarks의 차례 %d (OpponentView %d · HUD %d)" % [marks.get_index(), opponent_view.get_index(), hud.get_index()])
	scene.free()

# ================================================================ T166 그림 데이터(계획 053b, 결정 856)

const COR_ART_PATH := "res://data/opponents/cornelia_art.tres"
const COR_ART_DIR := "res://assets/art/opponents/cornelia/"
## 작업 6이 자른 스물한 장의 크기(파츠는 P1b 시트, 팔은 A1a 시트).
const COR_ART_SIZES := {
	"head": Vector2i(226, 223), "head_oops": Vector2i(226, 223), "head_dizzy": Vector2i(225, 223), "hat": Vector2i(253, 79),
	"feather": Vector2i(173, 85), "torso": Vector2i(353, 551), "legs": Vector2i(189, 306), "arm": Vector2i(79, 243),
	"hand": Vector2i(88, 76), "sword": Vector2i(137, 483), "arm_up_sword": Vector2i(158, 557), "arm_up": Vector2i(109, 327),
	"arm_up_fist": Vector2i(116, 78), "arm_thrust": Vector2i(150, 144), "arm_thrust_fist": Vector2i(150, 216),
	"arm_thrust_sword": Vector2i(283, 297), "arm_thrust_blade": Vector2i(57, 44), "arm_aim": Vector2i(123, 189),
	"arm_aim_fist": Vector2i(123, 140), "arm_aim_sword": Vector2i(187, 189), "arm_aim_blade": Vector2i(98, 103),
}
## 몸의 값의 한계(계획 053b "몸의 값" 표).
const COR_MIN_NECK_Y := -206.0
const COR_MAX_NECK_Y := -196.0
const COR_MIN_BARE_TOP := 312.0
const COR_MAX_BARE_TOP := 324.0
const COR_MIN_HEAD_MID := 252.0
const COR_MAX_HAT_TOP := 355.0
const COR_MIN_FOOT := 188.0
const COR_MAX_FOOT := 200.0
## 키(모자 없는 꼭대기 + 발끝)는 518 이하이고 여덟 가운데 아래쪽 셋(결정 845).
const COR_MAX_HEIGHT := 518.0
const COR_MAX_RANK := 3
## 다리 윗선이 옷자락 뒤에 숨는다.
const COR_MIN_LEGS_JOINT_Y := 12.0
## 긴 상자가 데이터에서도 보인다: 몸통 그림이 골반 아래로 50 이상 내려간다(일곱의 값은 문턱이 아니라 INFO — 계획 v2.1 T3).
const COR_MIN_TORSO_BELOW := 50.0


func t166_cornelia_art() -> String:
	var errs: Array[String] = []
	var bartolo := load(BARTOLO_PATH) as OpponentData
	var cor := load(CORNELIA_PATH) as OpponentData
	if cor == null or cor.art == null or bartolo == null or bartolo.art == null:
		return "opponent_08.tres나 그 그림이 없음"
	var art: OpponentArt = cor.art
	if art.resource_path != COR_ART_PATH:
		errs.append("그림 데이터 %s (기대 %s)" % [art.resource_path, COR_ART_PATH])
	if art == bartolo.art:
		errs.append("바르톨로의 그림을 빌려 쓴다")
	_cor_check_files(errs, art, bartolo.art)
	_cor_check_body(errs, art, bartolo.art)
	var client := "res://assets/art/clients/cornelia.png"
	if ResourceLoader.exists(client):
		var tex := load(client) as Texture2D
		if tex == null or Vector2i(tex.get_size()) != Vector2i(450, 675):
			errs.append("의뢰인 그림의 크기 %s (기대 450x675)" % (str(Vector2i(tex.get_size())) if tex != null else "읽을 수 없음"))
	else:
		print("INFO T166: assets/art/clients/cornelia.png가 아직 없다(위험 R7)")
	return _ok(errs)


func _cor_check_files(errs: Array[String], art: OpponentArt, bartolo_art: OpponentArt) -> void:
	for part_name: String in Fourth.ART_PARTS:
		var part := art.get(part_name) as PartArt
		if part == null or part.texture == null or not part.texture.resource_path.begins_with(COR_ART_DIR):
			errs.append("그림 %s: 없거나 코르넬리아의 폴더가 아님" % part_name)
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
				if layer.part != his.layers[k].part or layer.texture == null or not layer.texture.resource_path.begins_with(COR_ART_DIR):
					errs.append("팔 %s 층 %d: part·그림이 어긋남" % [mine.key, k])
				elif (layer.part == 4) != (layer.outline.size() >= 6):
					errs.append("팔 %s 층 %d: 주먹의 윤곽선이 없거나 주먹이 아닌데 있음" % [mine.key, k])
	for file: String in COR_ART_SIZES:
		var tex := load(COR_ART_DIR + file + ".png") as Texture2D
		if tex == null or Vector2i(tex.get_size()) != COR_ART_SIZES[file]:
			errs.append("%s.png의 크기 %s (기대 %s)" % [file, Vector2i(tex.get_size()) if tex != null else Vector2i.ZERO, COR_ART_SIZES[file]])


## 상자 · 송곳 · 안경 · 모자의 덮음은 그림을 봐야 아는 값이라 판 S2 · S4의 몫이다.
func _cor_check_body(errs: Array[String], art: OpponentArt, bartolo_art: OpponentArt) -> void:
	if art.neck.y < COR_MIN_NECK_Y or art.neck.y > COR_MAX_NECK_Y:
		errs.append("neck.y %.1f (기대 %.0f~%.0f)" % [art.neck.y, COR_MIN_NECK_Y, COR_MAX_NECK_Y])
	if art.legs == null or art.legs.texture == null or art.torso == null or art.torso.texture == null or art.hat == null or art.head == null:
		errs.append("다리·몸통·모자·머리 그림 가운데 빈 것이 있다")
		return
	var hat_limit: float = minf(_f._hat_top(bartolo_art), COR_MAX_HAT_TOP)
	var hat_top: float = _f._hat_top(art)
	var foot: float = _f._foot_tip(art)
	var joint_y: float = art.legs.joint.y * art.legs.units_per_px.y
	var below: float = _torso_below(art)
	print("INFO T166: 모자 쓴 꼭대기 %.1f (바르톨로 %.1f) · 발끝 %.1f · 다리 관절 %.1f · 몸통 그림의 골반 아래 %.1f" % [hat_top, _f._hat_top(bartolo_art), foot, joint_y, below])
	if hat_top > hat_limit + 0.01:
		errs.append("모자 쓴 꼭대기 %.2f (바르톨로의 값 %.2f와 %.0f 이하여야 한다)" % [hat_top, _f._hat_top(bartolo_art), COR_MAX_HAT_TOP])
	for head_part: PartArt in [art.head, art.head_oops, art.head_dizzy]:
		if head_part == null:
			errs.append("머리 셋 가운데 빈 것이 있다")
			continue
		var top: float = _f._bare_top(art, head_part)
		var mid: float = top - head_part.joint.y * head_part.units_per_px.y / 2.0
		if top < COR_MIN_BARE_TOP - 0.01 or top > COR_MAX_BARE_TOP + 0.01:
			errs.append("모자 없는 꼭대기 %.2f (기대 %.0f~%.0f)" % [top, COR_MIN_BARE_TOP, COR_MAX_BARE_TOP])
		if mid < COR_MIN_HEAD_MID - 0.01:
			errs.append("머리 가운데의 자 %.2f (%.0f 이상이어야 한다)" % [mid, COR_MIN_HEAD_MID])
	if foot < COR_MIN_FOOT - 0.01 or foot > COR_MAX_FOOT + 0.01:
		errs.append("발끝 %.2f (기대 %.0f~%.0f)" % [foot, COR_MIN_FOOT, COR_MAX_FOOT])
	if joint_y < COR_MIN_LEGS_JOINT_Y:
		errs.append("다리 관절의 높이 %.2f (%.0f 이상이어야 윗선이 옷자락 뒤에 숨는다)" % [joint_y, COR_MIN_LEGS_JOINT_Y])
	if below < COR_MIN_TORSO_BELOW - 0.01:
		errs.append("몸통 그림의 골반 아래 길이 %.2f (%.0f 이상 — 무릎 위까지의 긴 상자)" % [below, COR_MIN_TORSO_BELOW])
	_cor_check_height(errs, art)


func _torso_below(art: OpponentArt) -> float:
	return (float(art.torso.texture.get_height()) - art.torso.joint.y) * art.torso.units_per_px.y


## 키 = 모자 없는 꼭대기 + 발끝. 여덟 상대의 같은 식을 데이터에서 읽어 그녀가 아래쪽 셋 안인지 본다(결정 845). 일곱의 골반 아래 길이는 INFO로만 적는다.
func _cor_check_height(errs: Array[String], art: OpponentArt) -> void:
	var mine: float = _f._bare_top(art, art.head) + _f._foot_tip(art)
	var lower := 0
	var dir := DirAccess.open("res://data/opponents")
	if dir == null:
		errs.append("data/opponents를 열 수 없음")
		return
	for file: String in dir.get_files():
		if not (file.begins_with("opponent_") and file.ends_with(".tres")):
			continue
		var opp := load("res://data/opponents/" + file) as OpponentData
		if opp == null or opp.art == null or opp.art == art or opp.art.head == null or opp.art.legs == null or opp.art.torso == null:
			continue
		var height: float = _f._bare_top(opp.art, opp.art.head) + _f._foot_tip(opp.art)
		if height < mine:
			lower += 1
		print("INFO T166: %s 키 %.1f · 몸통 그림의 골반 아래 %.1f" % [file.get_basename(), height, _torso_below(opp.art)])
	print("INFO T166: 코르넬리아 키 %.1f (아래에서 %d번째)" % [mine, lower + 1])
	if mine > COR_MAX_HEIGHT + 0.01:
		errs.append("키 %.2f (%.0f 이하여야 한다)" % [mine, COR_MAX_HEIGHT])
	if lower + 1 > COR_MAX_RANK:
		errs.append("키 %.2f가 여덟 가운데 아래에서 %d번째 (%d번째 안이어야 한다)" % [mine, lower + 1, COR_MAX_RANK])
